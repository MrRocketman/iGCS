//
//  WaypointMapBaseController.m
//  iGCS
//
//  Created by Claudio Natoli on 20/03/13.
//
//

#import "WaypointMapBaseController.h"
#import "MiscUtilities.h"
#import "FillStrokePolyLineView.h"
#import "WaypointAnnotationView.h"

@implementation WaypointMapBaseController

@synthesize _mapView = map;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do any additional setup after loading the view.
    map.delegate = self;
    
    currentWaypointNum = -1;
    
    trackMKMapPointsLen = 1000;
    trackMKMapPoints = malloc(trackMKMapPointsLen * sizeof(MKMapPoint));
    numTrackPoints = 0;
    
    draggableWaypointsP = false;
    
    // Add recognizer for long press gestures
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]
                                                      initWithTarget:self action:@selector(handleLongPressGesture:)];
    longPressGesture.numberOfTapsRequired = 0;
    longPressGesture.numberOfTouchesRequired = 1;
    longPressGesture.minimumPressDuration = 1.0;
    [map addGestureRecognizer:longPressGesture];
    
    // Start listening for location updates
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.delegate = self;
    locationManager.distanceFilter = 2.0f;
    [locationManager startUpdatingLocation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray*) getWaypointAnnotations {
    return [map.annotations
            filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(self isKindOfClass: %@)",
                                         [WaypointAnnotation class]]];
}

- (void) removeExistingWaypointAnnotations {
    [map removeAnnotations:[self getWaypointAnnotations]];
}

- (WaypointAnnotation *) getWaypointAnnotation:(int)waypointSeq {
    NSArray* waypointAnnotations = [self getWaypointAnnotations];
    for (unsigned int i = 0; i < [waypointAnnotations count]; i++) {
        WaypointAnnotation *waypointAnnotation = (WaypointAnnotation*)[waypointAnnotations objectAtIndex:i];;
        if ([waypointAnnotation isCurrentWaypointP:waypointSeq]) {
            return waypointAnnotation;
        }
    }
    return nil;
}

- (void) resetWaypoints:(WaypointsHolder *)_waypoints {
    
    // Clean up existing objects
    [self removeExistingWaypointAnnotations];
    [map removeOverlay:waypointRoutePolyline];
    
    // Get the nav-specfic waypoints
    WaypointsHolder *navWaypoints = [_waypoints getNavWaypoints];
    unsigned int numWaypoints = [navWaypoints numWaypoints];
    
    MKMapPoint *navMKMapPoints = malloc(sizeof(MKMapPoint) * numWaypoints);
    
    // Add waypoint annotations, and convert to array of MKMapPoints
    for (unsigned int i = 0; i < numWaypoints; i++) {
        mavlink_mission_item_t waypoint = [navWaypoints getWaypoint:i];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(waypoint.x, waypoint.y);
        
        // Add the annotation
        WaypointAnnotation *annotation = [[WaypointAnnotation alloc] initWithCoordinate:coordinate
                                                                            andWayPoint:waypoint
                                                                                atIndex:[_waypoints getIndexOfWaypointWithSeq:waypoint.seq]];
        [map addAnnotation:annotation];
        
        // Construct the MKMapPoint
        navMKMapPoints[i] = MKMapPointForCoordinate(coordinate);
    }
    
    // Add the polyline overlay
    waypointRoutePolyline = [MKPolyline polylineWithPoints:navMKMapPoints count:numWaypoints];
    [map addOverlay:waypointRoutePolyline];
    
    // Set the map extents
    MKMapRect bounds = [waypointRoutePolyline boundingMapRect];
    if (!MKMapRectIsNull(bounds)) {
        // Extend the bounding rect of the polyline slightly
        MKCoordinateRegion region = MKCoordinateRegionForMapRect(bounds);
        region.span.latitudeDelta  = MIN(MAX(region.span.latitudeDelta  * MAP_REGION_PAD_FACTOR, MAP_MINIMUM_ARC),  90);
        region.span.longitudeDelta = MIN(MAX(region.span.longitudeDelta * MAP_REGION_PAD_FACTOR, MAP_MINIMUM_ARC), 180);
        [map setRegion:region animated:YES];
    } else if ([waypointRoutePolyline pointCount] == 1) {
        // Fallback to a padded box centered on the single waypoint
        CLLocationCoordinate2D coord = MKCoordinateForMapPoint([waypointRoutePolyline points][0]);
        [map setRegion:MKCoordinateRegionMakeWithDistance(coord, MAP_MINIMUM_PAD, MAP_MINIMUM_PAD) animated:YES];
    }
    [map setNeedsDisplay];
    
    free(navMKMapPoints);
}

- (void)updateWaypointIcon:(WaypointAnnotation*)annotation {
    if (annotation) {
        [WaypointMapBaseController updateWaypointIconFor:(WaypointAnnotationView*)[map viewForAnnotation: annotation]
                                     selectedWaypointSeq:currentWaypointNum];
    }
}

- (void) maybeUpdateCurrentWaypoint:(int)newCurrentWaypointSeq {
    if (currentWaypointNum != newCurrentWaypointSeq) {
        // We've reached a new waypoint, so...
        int previousWaypointNum = currentWaypointNum;
        
        //  first, update the current value (so we get the desired
        // side-effect when resetting the waypoints), then...
        currentWaypointNum = newCurrentWaypointSeq;

        //  reset the previous and new current waypoints
        [self updateWaypointIcon: [self getWaypointAnnotation:previousWaypointNum]];
        [self updateWaypointIcon: [self getWaypointAnnotation:currentWaypointNum]];
    }
}

- (void) makeWaypointsDraggable:(bool)_draggableWaypointsP {
    draggableWaypointsP = _draggableWaypointsP;
    
    NSArray* waypointAnnotations = [self getWaypointAnnotations];
    for (unsigned int i = 0; i < [waypointAnnotations count]; i++) {
        WaypointAnnotation *waypointAnnotation = (WaypointAnnotation*)[waypointAnnotations objectAtIndex:i];
        
        // See also viewForAnnotation
        MKAnnotationView *av = [map viewForAnnotation:waypointAnnotation];
        [av setCanShowCallout: !draggableWaypointsP];
        [av setDraggable: draggableWaypointsP];
        [av setSelected: draggableWaypointsP];
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView
   didChangeDragState:(MKAnnotationViewDragState)newState
   fromOldState:(MKAnnotationViewDragState)oldState
{
    if ([annotationView.annotation isKindOfClass:[WaypointAnnotation class]]) {
        WaypointAnnotation* annot = annotationView.annotation;
        if (newState == MKAnnotationViewDragStateEnding) {
            CLLocationCoordinate2D coord = annot.coordinate;
            [self waypointWithSeq:annot.waypoint.seq wasMovedToLat:coord.latitude andLong:coord.longitude];
        }
    }
    
    // Force the annotationView (which may have been disconnected from its annotation, such as due
    // to an add/remove of waypoint annotation during or on completion of dragging) to close out the drag state.
    if (newState == MKAnnotationViewDragStateEnding || newState == MKAnnotationViewDragStateCanceling) {
        [annotationView setDragState:MKAnnotationViewDragStateNone animated:YES];
    }
}


// FIXME: Ugh. This was a quick and dirty way to promote waypoint changes (due to dragging etc) to
// the subclass (which overrides this method). Adopt a more idomatic pattern for this?
- (void) waypointWithSeq:(int)waypointSeq wasMovedToLat:(double)latitude andLong:(double)longitude {
}

// FIXME: consider more efficient (and safe?) ways to do this - see iOS Breadcrumbs sample code
- (void) addToTrack:(CLLocationCoordinate2D)pos {
    MKMapPoint newPoint = MKMapPointForCoordinate(pos);
    
    // Check distance from 0
    if (MKMetersBetweenMapPoints(newPoint, MKMapPointForCoordinate(CLLocationCoordinate2DMake(0, 0))) < 1.0) {
        return;
    }
    
    // Check distance from last point
    if (numTrackPoints > 0) {
        if (MKMetersBetweenMapPoints(newPoint, trackMKMapPoints[numTrackPoints-1]) < 1.0) {
            return;
        }
    }
    
    // Check array bounds
    if (numTrackPoints == trackMKMapPointsLen) {
        MKMapPoint *newAlloc = realloc(trackMKMapPoints, trackMKMapPointsLen*2 * sizeof(MKMapPoint));
        if (newAlloc == nil)
            return;
        trackMKMapPoints = newAlloc;
        trackMKMapPointsLen *= 2;
    }
    
    // Add the next coord
    trackMKMapPoints[numTrackPoints] = newPoint;
    numTrackPoints++;
    
    // Clean up existing objects
    [map removeOverlay:trackPolyline];
    
    trackPolyline = [MKPolyline polylineWithPoints:trackMKMapPoints count:numTrackPoints];
    
    // Add the polyline overlay
    [map addOverlay:trackPolyline];
    [map setNeedsDisplay];
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay
{
    GCSThemeManager *theme = [GCSThemeManager sharedInstance];
    
    if (overlay == waypointRoutePolyline) {
        FillStrokePolyLineView *waypointRouteView = [[FillStrokePolyLineView alloc] initWithPolyline:overlay];
        waypointRouteView.strokeColor = [theme waypointLineStrokeColor];
        waypointRouteView.fillColor   = [theme waypointLineFillColor];
        waypointRouteView.lineWidth   = 1;
        waypointRouteView.fillWidth   = 2;
        waypointRouteView.lineCap     = kCGLineCapRound;
        waypointRouteView.lineJoin    = kCGLineJoinRound;
        return waypointRouteView;
    } else if (overlay == trackPolyline) {
        MKPolylineView *trackView = [[MKPolylineView alloc] initWithPolyline:overlay];
        trackView.fillColor     = [theme trackLineColor];
        trackView.strokeColor   = [theme trackLineColor];
        trackView.lineWidth     = 2;
        return trackView;
    }
    
    return nil;
}

- (NSString*) waypointNumberForAnnotationView:(mavlink_mission_item_t)item {
    // Base class uses the mission item sequence number
    return [NSString stringWithFormat:@"%d", item.seq];
}

// NOOPs - intended to be overrriden as needed
- (void) customizeWaypointAnnotationView:(MKAnnotationView*)view {
}
- (void) handleLongPressGesture:(UIGestureRecognizer*)sender {
}

+ (void) animateMKAnnotationView:(MKAnnotationView*)view from:(float)from to:(float)to duration:(float)duration {
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.duration = duration;
    scaleAnimation.repeatCount = HUGE_VAL;
    scaleAnimation.autoreverses = YES;
    scaleAnimation.fromValue = @(from);
    scaleAnimation.toValue   = @(to);
    [view.layer addAnimation:scaleAnimation forKey:@"scale"];
}

+ (void)updateWaypointIconFor:(WaypointAnnotationView*)view selectedWaypointSeq:(int)selectedWaypointSeq{
    static const int ICON_VIEW_TAG = 101;

    WaypointAnnotation *waypointAnnotation = (WaypointAnnotation*)view.annotation;
    
    UIImage *icon = nil;
    if ([waypointAnnotation isCurrentWaypointP:selectedWaypointSeq]) {
        // Animate the waypoint view
        [WaypointMapBaseController animateMKAnnotationView:view from:1.0 to:1.1 duration:1.0];
        
        // Create target icon
        icon = [MiscUtilities image:[UIImage imageNamed:@"13-target.png"]
                          withColor:[[GCSThemeManager sharedInstance] waypointNavNextColor]];
    } else {
        [view.layer removeAllAnimations];
    }

    // Note: We don't just set view.image, as we want a touch target that is larger than the icon itself
    UIImageView *imgSubView = [[UIImageView alloc] initWithImage:icon];
    imgSubView.tag = ICON_VIEW_TAG;
    imgSubView.center = [view convertPoint:view.center fromView:view.superview];
    
    // Remove existing icon subview (if any) and add the new icon
    [[view viewWithTag:ICON_VIEW_TAG] removeFromSuperview];
    [view addSubview:imgSubView];
    [view sendSubviewToBack:imgSubView];
    
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    static const int LABEL_TAG = 100;
    
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    // Handle our custom annotations
    //
    if ([annotation isKindOfClass:[WaypointAnnotation class]]) {
        static NSString* const identifier = @"WAYPOINT";
        // FIXME: Dequeuing disabled due to issue observed on iOS7.1 only - cf IGCS-110
        //MKAnnotationView *view = (MKAnnotationView*) [map dequeueReusableAnnotationViewWithIdentifier:identifier];
        WaypointAnnotationView *view = nil;
        if (view == nil) {
            view = [[WaypointAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            [view setFrame:CGRectMake(0,0,WAYPOINT_TOUCH_TARGET_SIZE,WAYPOINT_TOUCH_TARGET_SIZE)];
            [view setBackgroundColor:[UIColor clearColor]];

            UILabel *label = [[UILabel alloc]  initWithFrame:CGRectMake(WAYPOINT_TOUCH_TARGET_SIZE/2, -WAYPOINT_TOUCH_TARGET_SIZE/3, 32, 32)];
            label.backgroundColor = [UIColor clearColor];
            label.textColor = [UIColor whiteColor];
            label.tag = LABEL_TAG;
            label.layer.shadowColor = [[UIColor blackColor] CGColor];
            label.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
            label.layer.shadowOpacity = 1.0f;
            label.layer.shadowRadius  = 1.0f;
            
            [view addSubview:label];
        } else {
            view.annotation = annotation;
        }
        
        view.enabled = YES;
        
        // See also makeWaypointsDraggable
        view.canShowCallout = !draggableWaypointsP;
        view.draggable = draggableWaypointsP;
        view.selected = draggableWaypointsP;
        
        // Set the waypoint label
        WaypointAnnotation *waypointAnnotation = (WaypointAnnotation*)annotation;
        UILabel *label = (UILabel *)[view viewWithTag:LABEL_TAG];
        label.text = [self waypointNumberForAnnotationView: waypointAnnotation.waypoint];
        
        // Add appropriate icon
        [WaypointMapBaseController updateWaypointIconFor:view selectedWaypointSeq:currentWaypointNum];

        // Provide subclasses with a chance to customize the waypoint annotation view
        [self customizeWaypointAnnotationView:view];
        
        return view;
    }
    
    return nil;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // FIXME: mark some error
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    userPosition = locationManager.location;
}

@end
