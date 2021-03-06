//
//  WaypointMapBaseController.h
//  iGCS
//
//  Created by Claudio Natoli on 20/03/13.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MKMapView.h>

#import "WaypointsHolder.h"
#import "WaypointAnnotation.h"

#define WAYPOINT_TOUCH_TARGET_SIZE 36

#define MAP_MINIMUM_PAD       100
#define MAP_MINIMUM_ARC       0.0010 // ~100m
#define MAP_REGION_PAD_FACTOR 1.10


@interface WaypointMapBaseController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate> {
@private
    MKPolyline *waypointRoutePolyline;
    int currentWaypointNum;

    MKPolyline *trackPolyline;
    MKMapPoint *trackMKMapPoints;
    unsigned int trackMKMapPointsLen;
    unsigned int numTrackPoints;
    
@protected
    MKMapView *map;
    bool draggableWaypointsP;
    
    CLLocationManager *locationManager;
    CLLocation *userPosition;
}

@property (nonatomic, retain) IBOutlet MKMapView *_mapView;

- (void) removeExistingWaypointAnnotations;
- (WaypointAnnotation *) getWaypointAnnotation:(int)waypointSeq;
- (void) resetWaypoints:(WaypointsHolder *)_waypoints;
- (void) maybeUpdateCurrentWaypoint:(int)newCurrentWaypointSeq;

- (void) makeWaypointsDraggable:(bool)_draggableWaypointsP;
- (NSString*) waypointNumberForAnnotationView:(mavlink_mission_item_t)item;

- (void) addToTrack:(CLLocationCoordinate2D)pos;

// Following methods are intended to be overridden by subclasses
- (void) waypointWithSeq:(int)waypointSeq wasMovedToLat:(double)latitude andLong:(double)longitude;
- (void) customizeWaypointAnnotationView:(MKAnnotationView*)view;
- (void) handleLongPressGesture:(UIGestureRecognizer*)sender;

+ (void) animateMKAnnotationView:(MKAnnotationView*)view from:(float)from to:(float)to duration:(float)duration;

@end
