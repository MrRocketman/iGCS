//
//  GCSMapViewController.m
//  iGCS
//
//  Created by Claudio Natoli on 5/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "GCSMapViewController.h"
#import "SWRevealViewController.h"

#import "MainViewController.h"
#import "GaugeViewCommon.h"

#import "MavLinkUtility.h"
#import "MiscUtilities.h"

#import "CommController.h"

#import "CXAlertView.h"

@implementation GCSMapViewController {
    MKPointAnnotation *uavPos;
    MKAnnotationView *uavView;
    
    GuidedPointAnnotation *currentGuidedAnnotation;
    RequestedPointAnnotation *requestedGuidedAnnotation;
    
    CLLocationCoordinate2D gotoCoordinates;
    float gotoAltitude;
    
    BOOL showProposedFollowPos;
    NSDate *lastFollowMeUpdate;
    uint32_t lastCustomMode;
    
    int	gamePacketNumber;
    int	gameUniqueID;
}

// 3 modes
//  * auto (initiates/returns to mission)
//  * misc (manual, stabilize, etc; not selectable)
//  * guided (goto/follow me)
@synthesize controlModeSegment;

enum {
    CONTROL_MODE_RC       = 0,
    CONTROL_MODE_AUTO     = 1,
    CONTROL_MODE_GUIDED   = 2
};


static const double FOLLOW_ME_MIN_UPDATE_TIME   = 2.0;
static const double FOLLOW_ME_REQUIRED_ACCURACY = 10.0;

static const int AIRPLANE_ICON_SIZE = 48;


// GameKit Session ID for app
#define kTankSessionID @"groundStation"


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
    
    // Release any cached data, images, etc that aren't in use.
#if DO_NSLOG
    if ([self isViewLoaded]) {
        NSLog(@"\t\tGCSMapViewController::didReceiveMemoryWarning: view is still loaded");
    } else {
        NSLog(@"\t\tGCSMapViewController::didReceiveMemoryWarning: view is NOT loaded");
    }
#endif
}

- (void)awakeFromNib {
    
    uavPos  = [[MKPointAnnotation alloc] init];
    [uavPos setCoordinate:CLLocationCoordinate2DMake(0, 0)];

    uavView = [[MKAnnotationView  alloc] initWithAnnotation:uavPos reuseIdentifier:@"uavView"];
    uavView.image = [MiscUtilities imageWithImage: [UIImage imageNamed:@"airplane.png"]
                                     scaledToSize:CGSizeMake(AIRPLANE_ICON_SIZE,AIRPLANE_ICON_SIZE)
                                         rotation: 0];
    uavView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(airplanTapped:)];
    [uavView addGestureRecognizer:tap];
    uavView.centerOffset = CGPointMake(0, 0);
    
    currentGuidedAnnotation   = nil;
    requestedGuidedAnnotation = nil;
    
    gotoAltitude = 50;
    
    showProposedFollowPos = NO;
    lastFollowMeUpdate = [NSDate date];
}

-(void)airplanTapped:(UITapGestureRecognizer *)gesture {
    NSLog(@"airplane tapped");
    //[self connectToVideoStream];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // initialize debug console buffer
    //[DebugLogger start:self.debugConsoleLabel];

    // Adjust view for iOS6 differences
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        // This constraint is used to fix the size of the mode segmented control, principally
        // to allow sufficient header space for other labels on supported iPhone (7.0+). Because
        // the constrained width is too narrow for iPad 6.X, we'll just remove it.
        [controlModeSegment removeConstraint:_controlModeSegmentSizeConstraint];
    }
    
	// Do any additional setup after loading the view, typically from a nib.
    [map addAnnotation:uavPos];
}



- (void)toggleSidebar:(id)sender {
    self.revealViewController.rearViewRevealWidth = 210;
    [self.revealViewController revealToggle:sender];
}

- (void)viewDidUnload
{
    //[self setDebugConsoleLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

#ifdef VIDEOSTREAMING
    NSString *videoSource = [[NSUserDefaults standardUserDefaults] objectForKey:@"videoSource"];
    NSString *videoDisplayLocation =  [[NSUserDefaults standardUserDefaults] objectForKey:@"videoDisplayLocation"];
    
    float scaleFactor;
    
    if ([videoSource isEqualToString:@"Z3"]) {
        
        if ([videoDisplayLocation isEqualToString:@"corner"]) {
            scaleFactor = 0.4;
        } else {
            scaleFactor = 1.0;
        }
        
        [self configureVideoStreamWithName:kGCSZ3Stream andScaleFactor:scaleFactor];
    }else {
        
        if ([videoDisplayLocation isEqualToString:@"corner"]) {
            scaleFactor = 0.4;
        } else {
            scaleFactor = 1.0;
        }
        [self configureVideoStreamWithName:kGCSBryansTestStream andScaleFactor:scaleFactor];
    }
#endif
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}


#pragma mark -
#pragma mark Button Click callbacks

- (IBAction) changeControlModeSegment {
    NSInteger idx = controlModeSegment.selectedSegmentIndex;
    NSLog(@"changeControlModeSegment: %d", idx);
    [self deactivateFollowMe];
    switch (idx) {
        case CONTROL_MODE_RC:
            break;
            
        case CONTROL_MODE_AUTO:
            [[[CommController sharedInstance] mavLinkInterface] issueSetAUTOModeCommand];
            break;
            
        case CONTROL_MODE_GUIDED:
            break;
    }
}

- (void) clearGuidedPositions {
    if (currentGuidedAnnotation != nil) {
        [map removeAnnotation:currentGuidedAnnotation];
    }
    currentGuidedAnnotation = nil;
    
    if (requestedGuidedAnnotation != nil) {
        [map removeAnnotation:requestedGuidedAnnotation];
    }
    requestedGuidedAnnotation = nil;
}

- (void) issueGuidedCommand:(CLLocationCoordinate2D)coordinates withAltitude:(float)altitude withFollowing:(BOOL)following {
    NSLog(@" - issueGuidedCommand");
    if (!following) {
        [self deactivateFollowMe];
    }
    
    [self clearGuidedPositions];

    // Drop an icon for the proposed GUIDED point
    currentGuidedAnnotation = [[GuidedPointAnnotation alloc] initWithCoordinate:coordinates];
    [map addAnnotation:currentGuidedAnnotation];
    [map setNeedsDisplay];

    [[[CommController sharedInstance] mavLinkInterface] issueGOTOCommand:coordinates withAltitude:altitude];
}


- (void) followMeControlChange:(FollowMeCtrlValues*)vals {
    showProposedFollowPos = YES;
    [self updateFollowMePosition:vals];
}

- (void) deactivateFollowMe {
    [_followMeControlDelegate followMeDeactivate];
    showProposedFollowPos = NO;
}

+ (BOOL) isAcceptableFollowMePosition:(CLLocation*)pos {
    return (pos.horizontalAccuracy >= 0 && pos.horizontalAccuracy <= FOLLOW_ME_REQUIRED_ACCURACY);
}

- (void) updateFollowMePosition:(FollowMeCtrlValues*)ctrlValues {
    // Determine user coord
    // CLLocationCoordinate2D userCoord = CLLocationCoordinate2DMake(47.258842, 11.331070); // Waypoint 0 in demo mission - useful for HIL testing
    CLLocationCoordinate2D userCoord = userPosition.coordinate;
    
    // Determine new position
    double bearing  = M_PI + (2 * M_PI * ctrlValues.bearing);
    double distance = (5 + 195 * ctrlValues.distance); // 5 - 200 m away
    float fmHeightOffset = (30 * ctrlValues.altitudeOffset);  // 0 -  30 m relative to home
    
    static const double R = 6371009.0; // (approx) mean Earth radius in m
    
    double userLat  = userCoord.latitude *DEG2RAD;
    double userLong = userCoord.longitude*DEG2RAD;
    
    // Compute follow me coordinates
    double angD = distance/R;
    double followMeLat  = asin(sin(userLat)*cos(angD) + cos(userLat)*sin(angD)*cos(bearing));
    double followMeLong = userLong + atan2(sin(bearing)*sin(angD)*cos(userLat), cos(angD) - sin(userLat)*sin(followMeLat));
    followMeLong = fmod((followMeLong + 3*M_PI), (2*M_PI)) - M_PI;

    CLLocationCoordinate2D fmCoords = CLLocationCoordinate2DMake(followMeLat*RAD2DEG, followMeLong*RAD2DEG);
    
    // Update map
    if (requestedGuidedAnnotation != nil)
        [map removeAnnotation:requestedGuidedAnnotation];
    
    if (showProposedFollowPos) {
        requestedGuidedAnnotation = [[RequestedPointAnnotation alloc] initWithCoordinate:fmCoords];
        [map addAnnotation:requestedGuidedAnnotation];
        [map setNeedsDisplay];
    }

#if DO_NSLOG
    NSLog(@"FollowMe lat/long: %f,%f [accuracy: %f]", followMeLat*RAD2DEG, followMeLong*RAD2DEG, userPosition.horizontalAccuracy);
#endif
    if (ctrlValues.isActive &&
        (-[lastFollowMeUpdate timeIntervalSinceNow]) > FOLLOW_ME_MIN_UPDATE_TIME &&
        [GCSMapViewController isAcceptableFollowMePosition:userPosition]) {
        lastFollowMeUpdate = [NSDate date];
        
        [self issueGuidedCommand:fmCoords withAltitude:fmHeightOffset withFollowing:YES];
    }
}

+ (NSString*) formatGotoAlertMessage:(CLLocationCoordinate2D)coord withAlt:(float)alt {
    return [NSString stringWithFormat:@"%@, %@\nAlt: %0.1fm\n(pan up/down to change)",
            [MiscUtilities prettyPrintCoordAxis:coord.latitude  as:GCSLatitude],
            [MiscUtilities prettyPrintCoordAxis:coord.longitude as:GCSLongitude],
            alt];
}

// Recognizer for long press gestures => GOTO point
-(void)handleLongPressGesture:(UIGestureRecognizer*)sender {
    if (sender.state != UIGestureRecognizerStateBegan)
        return;

    // Set the coordinates of the map point being held down
    gotoCoordinates = [map convertPoint:[sender locationInView:map] toCoordinateFromView:map];
    
    // Confirm acceptance of GOTO point
    CXAlertView *alertView = [[CXAlertView alloc] initWithTitle:@"Fly-to position?"
                                                        message:[GCSMapViewController formatGotoAlertMessage: gotoCoordinates withAlt:gotoAltitude]
                                              cancelButtonTitle:nil];
    [alertView addButtonWithTitle:@"Confirm" // Order buttons as per Apple's HIG ("destructive" action on left)
                             type:CXAlertViewButtonTypeCustom
                          handler:^(CXAlertView *alertView, CXAlertButtonItem *button) {
                              [self issueGuidedCommand:gotoCoordinates withAltitude:gotoAltitude withFollowing:NO];
                              [alertView dismiss];
                          }];
    [alertView addButtonWithTitle:@"Cancel"
                             type:CXAlertViewButtonTypeCustom
                          handler:^(CXAlertView *alertView, CXAlertButtonItem *button) {
                              [alertView dismiss];
                          }];
    alertView.showBlurBackground = YES;

    // Add pan gesture to allow modification of target altitude
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handlePanGesture:)];
    panGesture.minimumNumberOfTouches = 1;
    panGesture.maximumNumberOfTouches = 1;
    [alertView addGestureRecognizer:panGesture];

    [alertView show];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender {
    CGPoint translate = [sender translationInView:self.view];

    static CGPoint lastTranslate;
    if (sender.state == UIGestureRecognizerStateBegan) {
        lastTranslate = translate;
        return;
    }
    
    gotoAltitude += (lastTranslate.y-translate.y)/10;
    lastTranslate = translate;
    
    CXAlertView *alertView = (CXAlertView*)(sender.view);
    [(UILabel*)[alertView contentView] setText:[GCSMapViewController formatGotoAlertMessage: gotoCoordinates withAlt:gotoAltitude]];
}

- (void) handlePacket:(mavlink_message_t*)msg {
    
    switch (msg->msgid) {
        
        // Temporarily disabled in favour of MAVLINK_MSG_ID_GPS_RAW_INT
        /*case MAVLINK_MSG_ID_GLOBAL_POSITION_INT:
        {
            mavlink_global_position_int_t gpsPosIntPkt;
            mavlink_msg_global_position_int_decode(msg, &gpsPosIntPkt);
            
            CLLocationCoordinate2D pos = CLLocationCoordinate2DMake(gpsPosIntPkt.lat/10000000.0, gpsPosIntPkt.lon/10000000.0);
            [uavPos setCoordinate:pos];
            [self addToTrack:pos];
        }
        break;*/
        
        case MAVLINK_MSG_ID_GPS_RAW_INT:
        {
            mavlink_gps_raw_int_t gpsRawIntPkt;
            mavlink_msg_gps_raw_int_decode(msg, &gpsRawIntPkt);
            
            NSString *lockString = (gpsRawIntPkt.fix_type <= 1) ? @"No GPS" : ((gpsRawIntPkt.fix_type == 2) ? @"2D Fix" : ((gpsRawIntPkt.fix_type == 3) ? @"3D Fix" : @""));
            [self.gpsLabel setText:[NSString stringWithFormat:@"%d, %@", gpsRawIntPkt.satellites_visible, lockString]];
            
            CLLocationCoordinate2D pos = CLLocationCoordinate2DMake(gpsRawIntPkt.lat/10000000.0, gpsRawIntPkt.lon/10000000.0);
            [uavPos setCoordinate:pos];
            [self addToTrack:pos];
        }
        break;
            
        case MAVLINK_MSG_ID_ATTITUDE:
        {
            mavlink_attitude_t attitudePkt;
            mavlink_msg_attitude_decode(msg, &attitudePkt);
            
            uavView.image = [MiscUtilities imageWithImage: [UIImage imageNamed:@"airplane.png"]
                                             scaledToSize: CGSizeMake(AIRPLANE_ICON_SIZE,AIRPLANE_ICON_SIZE)
                                                 rotation: attitudePkt.yaw];
            
            [self.rollView.valueLabel setText:[NSString stringWithFormat:@"%.1f", RADIANS_TO_DEGREES(attitudePkt.roll)]];
            [self.pitchView.valueLabel setText:[NSString stringWithFormat:@"%.1f", RADIANS_TO_DEGREES(attitudePkt.pitch)]];
            [self.yawView.valueLabel setText:[NSString stringWithFormat:@"%.1f", RADIANS_TO_DEGREES((attitudePkt.yaw < 0 ? attitudePkt.yaw + M_PI * 2 : attitudePkt.yaw))]];
            self.artificialHorizonView.roll = attitudePkt.roll;
            self.artificialHorizonView.pitch = attitudePkt.pitch;
            self.artificialHorizonView.yaw = attitudePkt.yaw;
            [self.artificialHorizonView setNeedsDisplay];
        }
        break;

        case MAVLINK_MSG_ID_VFR_HUD:
        {
            mavlink_vfr_hud_t  vfrHudPkt;
            mavlink_msg_vfr_hud_decode(msg, &vfrHudPkt);
            
            //[compassView setHeading:vfrHudPkt.heading];
            [self.climbrateView.valueLabel setText:[NSString stringWithFormat:@"%.2f", vfrHudPkt.climb]];
            [self.airspeedView.valueLabel setText:[NSString stringWithFormat:@"%.2f", vfrHudPkt.groundspeed]];
            [self.altitudeView.valueLabel setText:[NSString stringWithFormat:@"%.2f", vfrHudPkt.alt]];
            [self.throttleLabel setText:[NSString stringWithFormat:@"%d%%", vfrHudPkt.throttle]];
        }
        break;
            
        case MAVLINK_MSG_ID_NAV_CONTROLLER_OUTPUT:
        {
            mavlink_nav_controller_output_t navCtrlOutPkt;
            mavlink_msg_nav_controller_output_decode(msg, &navCtrlOutPkt);
            
            //[compassView setNavBearing:navCtrlOutPkt.nav_bearing];
            //[airspeedView setTargetDelta:navCtrlOutPkt.aspd_error]; // m/s
            //[altitudeView setTargetDelta:navCtrlOutPkt.alt_error];  // m
        }
        break;
            
        case MAVLINK_MSG_ID_MISSION_CURRENT:
        {
            mavlink_mission_current_t currentWaypoint;
            mavlink_msg_mission_current_decode(msg, &currentWaypoint);
            [self maybeUpdateCurrentWaypoint:currentWaypoint.seq];
        }
        break;
            
        case MAVLINK_MSG_ID_SYS_STATUS:
        {
            mavlink_sys_status_t sysStatus;
            mavlink_msg_sys_status_decode(msg, &sysStatus);
            
            [self.lipoLabel setText:[NSString stringWithFormat:@"%d%%", sysStatus.battery_remaining]];
            [self.voltageLabel setText:[NSString stringWithFormat:@"%0.2fV", sysStatus.voltage_battery/1000.0f]];
            [self.signalStrengthLabel setText:[NSString stringWithFormat:@"%d%%", 100 - sysStatus.drop_rate_comm]];
        }
        break;

        case MAVLINK_MSG_ID_WIND:
        {
            mavlink_wind_t wind;
            mavlink_msg_wind_decode(msg, &wind);
            //windIconView.transform = CGAffineTransformMakeRotation(((360 + (int)wind.direction + WIND_ICON_OFFSET_ANG) % 360) * M_PI/180.0f);
        }
        break;
            
        case MAVLINK_MSG_ID_HEARTBEAT:
        {
            mavlink_heartbeat_t heartbeat;
            mavlink_msg_heartbeat_decode(msg, &heartbeat);
            BOOL isArmed = (heartbeat.base_mode & MAV_MODE_FLAG_SAFETY_ARMED);
            [_armedLabel setText:isArmed ? @"Armed" : @"Disarmed"];
            [_armedLabel setTextColor:isArmed ? [UIColor redColor] : [UIColor greenColor]];
            [_customModeLabel setText:[MavLinkUtility mavCustomModeToString:  heartbeat]];

            NSInteger idx = CONTROL_MODE_RC;
            switch (heartbeat.custom_mode)
            {
                case AUTO:
                    idx = CONTROL_MODE_AUTO;
                    break;

                case GUIDED:
                    idx = CONTROL_MODE_GUIDED;
                    break;
            }
            
            // Change the segmented control to reflect the heartbeat
            if (idx != controlModeSegment.selectedSegmentIndex) {
                controlModeSegment.selectedSegmentIndex = idx;
            }
            
            // If the current mode is not GUIDED, and has just changed
            //   - unconditionally switch out of Follow Me mode
            //   - clear the guided position annotation markers
            if (heartbeat.custom_mode != GUIDED && heartbeat.custom_mode != lastCustomMode) {
                [self deactivateFollowMe];
                [self clearGuidedPositions];
            }
            lastCustomMode = heartbeat.custom_mode;
        }
        break;
    }
}

// Handle taps on "Set Waypoint" inside WaypointAnnotation view callouts
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    if ([[view annotation] isKindOfClass:[WaypointAnnotation class]]) {
        WaypointAnnotation *annotation = (WaypointAnnotation*)[view annotation];
        mavlink_mission_item_t item = annotation.waypoint;
        [[[CommController sharedInstance] mavLinkInterface] startSetWaypointRequest:item.seq];
    }
}

- (void) customizeWaypointAnnotationView:(MKAnnotationView*)view {
    // Add a Set Waypoint button
    UIButton *setWPButton = [UIButton buttonWithType:UIButtonTypeCustom];
    setWPButton.frame = CGRectMake(0, 0, 90, 32);
    [setWPButton setTitle:@"Set Waypoint" forState:UIControlStateNormal];
    [setWPButton setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    setWPButton.titleLabel.font = [UIFont fontWithName: @"Helvetica" size: 14];
    [setWPButton setBackgroundImage:[MiscUtilities imageWithColor:[UIColor darkGrayColor]] forState:UIControlStateNormal];
    setWPButton.layer.cornerRadius = 6.0;
    setWPButton.layer.borderWidth  = 1.0;
    setWPButton.layer.borderColor = [UIColor darkTextColor].CGColor;
    setWPButton.clipsToBounds = YES;
    view.rightCalloutAccessoryView = setWPButton;
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKAnnotationView* v = [super mapView:theMapView viewForAnnotation:annotation];
    if (v != nil)
        return v;
    
    // Handle our custom point annotations
    if ([annotation isKindOfClass:[CustomPointAnnotation class]]) {
        CustomPointAnnotation *customPoint = (CustomPointAnnotation*)annotation;
        
        MKAnnotationView *view = (MKAnnotationView*) [map dequeueReusableAnnotationViewWithIdentifier:[customPoint viewIdentifier]];
        if (view == nil) {
            view = [[MKAnnotationView alloc] initWithAnnotation:customPoint reuseIdentifier:[customPoint viewIdentifier]];
            [view.layer removeAllAnimations];
        } else {
            view.annotation = customPoint;
        }
        
        view.enabled = YES;
        view.canShowCallout = YES;
        view.centerOffset = CGPointMake(0,0);      
        view.image = [MiscUtilities image:[UIImage imageNamed:@"13-target.png"]
                                withColor:[customPoint color]];
        
        if ([customPoint doAnimation]) {
            [WaypointMapBaseController animateMKAnnotationView:view from:1.2 to:0.8 duration:2.0];
        }
        return view;
    }
    
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        return uavView;
    }
    
    return nil;
}

@end
