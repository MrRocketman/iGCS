//
//  GCSMapViewController.h
//  iGCS
//
//  Created by Claudio Natoli on 5/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WaypointMapBaseController.h"
#import <GLKit/GLKit.h>

#import "ArtificialHorizonView.h"
#import "CompassView.h"
#import "MavLinkPacketHandler.h"
#import "CorePlot-CocoaTouch.h"
#import "SimpleDataView.h"

#import "RequestedPointAnnotation.h"
#import "GuidedPointAnnotation.h"

#ifdef VIDEOSTREAMING
#import "KxMovieViewController.h"
#endif

#import "GCSSidebarController.h"

@class DataRateRecorder;

@interface GCSMapViewController : WaypointMapBaseController <MavLinkPacketHandler, GLKViewDelegate, GCSFollowMeCtrlChangeProtocol, CPTPlotDataSource>

@property (weak) id <GCSFollowMeCtrlProtocol> followMeControlDelegate;
@property (nonatomic, weak) DataRateRecorder *dataRateRecorder;

@property(nonatomic, retain) NSDate		 *lastHeartbeatDate;
@property(nonatomic, retain) UIAlertView *connectionAlert;

@property(nonatomic, strong) NSArray *myFriends;
@property(nonatomic, strong) NSArray *myIdentifiers;
@property (strong, nonatomic) IBOutlet UILabel *debugConsoleLabel;

@property (nonatomic, retain) IBOutlet UIButton *sidebarButton;
- (IBAction)toggleSidebar:(id)sender;

#define WIND_ICON_OFFSET_ANG 135

@property (nonatomic, retain) IBOutlet UIImageView *windIconView;
@property (nonatomic, retain) IBOutlet ArtificialHorizonView *ahIndicatorView;
@property (nonatomic, retain) IBOutlet CompassView           *compassView;
@property (nonatomic, retain) IBOutlet SimpleDataView *altitudeView;
@property (nonatomic, retain) IBOutlet SimpleDataView *airspeedView;

@property (nonatomic, retain) IBOutlet UILabel *armedLabel;
@property (nonatomic, retain) IBOutlet UILabel *customModeLabel;
@property (nonatomic, retain) IBOutlet UISegmentedControl *controlModeSegment;
@property (nonatomic, retain) IBOutlet NSLayoutConstraint *controlModeSegmentSizeConstraint;

@property (nonatomic, retain) IBOutlet CPTGraphHostingView *dataRateSparklineView;
@property (nonatomic, retain) IBOutlet UILabel *dataRateLabel;
@property (nonatomic, retain) IBOutlet UILabel *voltageLabel;
@property (nonatomic, retain) IBOutlet UILabel *batteryPercentageLabel;

#ifdef VIDEOSTREAMING
@property (nonatomic, retain) KxMovieViewController *kxMovieVC;
@property (nonatomic, retain) NSDictionary *availableStreams;
#endif

- (IBAction) changeControlModeSegment;

+ (BOOL) isAcceptableFollowMePosition:(CLLocation*)pos;

@end
