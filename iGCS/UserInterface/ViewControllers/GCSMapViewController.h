//
//  GCSMapViewController.h
//  iGCS
//
//  Created by Claudio Natoli on 5/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WaypointMapBaseController.h"

#import "MavLinkPacketHandler.h"
#import "CorePlot-CocoaTouch.h"
#import "SimpleDataView.h"
#import "SmallDataView.h"
#import "SimpleArtificialHorizonView.h"

#import "RequestedPointAnnotation.h"
#import "GuidedPointAnnotation.h"

#import "GCSSidebarController.h"

@interface GCSMapViewController : WaypointMapBaseController <MavLinkPacketHandler, GCSFollowMeCtrlChangeProtocol>

@property (weak) id <GCSFollowMeCtrlProtocol> followMeControlDelegate;

@property(nonatomic, retain) NSDate *lastHeartbeatDate;
@property(nonatomic, retain) UIAlertView *connectionAlert;

@property(nonatomic, strong) NSArray *myFriends;
@property(nonatomic, strong) NSArray *myIdentifiers;

@property (nonatomic, retain) IBOutlet UIButton *sidebarButton;
- (IBAction)toggleSidebar:(id)sender;

@property (nonatomic, strong) IBOutlet MKMapView *mapView;

@property (nonatomic, retain) IBOutlet SimpleDataView *altitudeView;
@property (nonatomic, retain) IBOutlet SimpleDataView *airspeedView;
@property (nonatomic, retain) IBOutlet SimpleDataView *climbrateView;
@property (nonatomic, retain) IBOutlet SmallDataView *rollView;
@property (nonatomic, retain) IBOutlet SmallDataView *pitchView;
@property (nonatomic, retain) IBOutlet SmallDataView *yawView;
@property (nonatomic, retain) IBOutlet SimpleArtificialHorizonView *artificialHorizonView;

@property (nonatomic, retain) IBOutlet UILabel *armedLabel;
@property (nonatomic, retain) IBOutlet UILabel *customModeLabel;
@property (nonatomic, retain) IBOutlet UISegmentedControl *controlModeSegment;
@property (nonatomic, retain) IBOutlet NSLayoutConstraint *controlModeSegmentSizeConstraint;

@property (nonatomic, retain) IBOutlet UILabel *signalStrengthLabel;
@property (nonatomic, retain) IBOutlet UILabel *throttleLabel;
@property (nonatomic, retain) IBOutlet UILabel *lipoLabel;
@property (nonatomic, retain) IBOutlet UILabel *gpsLabel;
@property (nonatomic, retain) IBOutlet UILabel *voltageLabel;

- (IBAction) changeControlModeSegment;

+ (BOOL) isAcceptableFollowMePosition:(CLLocation*)pos;

@end
