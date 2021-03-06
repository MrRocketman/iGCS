//
//  GCSSidebarController.m
//  iGCS
//
//  Created by Claudio Natoli on 31/01/2014.
//
//

#import "GCSSidebarController.h"
#import "MavLinkUtility.h"

@implementation FollowMeCtrlValues

- (id) initWithBearing:(double)bearing distance:(double)distance altitudeOffset:(double)altitudeOffset isActive:(BOOL)isActive {
    self = [super init];
    if (self) {
        _bearing  = bearing;
        _distance = distance;
        _altitudeOffset = altitudeOffset;
        _isActive = isActive;
    }
    return self;
}

@end


@interface GCSSidebarController ()

@end

@implementation GCSSidebarController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

// Forced clear background as per suggestion: http://stackoverflow.com/questions/18878258/uitableviewcell-show-white-background-and-cannot-be-modified-on-ios7
// Unclear why the cell clear color set in IB is not respected.
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell setBackgroundColor:[UIColor clearColor]];
}

- (void) handlePacket:(mavlink_message_t*)msg {
    switch (msg->msgid) {
            
        // Status section
        case MAVLINK_MSG_ID_HEARTBEAT:
        {
            mavlink_heartbeat_t heartbeat;
            mavlink_msg_heartbeat_decode(msg, &heartbeat);
            [_mavBaseModeLabel   setText:[MavLinkUtility mavModeEnumToString:    heartbeat.base_mode]];
            [_mavCustomModeLabel setText:[MavLinkUtility mavCustomModeToString:  heartbeat]];
            [_mavStatusLabel     setText:[MavLinkUtility mavStateEnumToString:   heartbeat.system_status]];
        }
            break;
            
        // Aircraft section
        case MAVLINK_MSG_ID_VFR_HUD:
        {
            mavlink_vfr_hud_t  vfrHudPkt;
            mavlink_msg_vfr_hud_decode(msg, &vfrHudPkt);
            [_acThrottleLabel    setText:[NSString stringWithFormat:@"%d%%", vfrHudPkt.throttle]];
            [_acClimbRateLabel   setText:[NSString stringWithFormat:@"%0.1f m/s", vfrHudPkt.climb]];
            [_acGroundSpeedLabel setText:[NSString stringWithFormat:@"%0.1f m/s", vfrHudPkt.groundspeed]];
        }
            break;
            
        case MAVLINK_MSG_ID_SYS_STATUS:
        {
            mavlink_sys_status_t sysStatus;
            mavlink_msg_sys_status_decode(msg, &sysStatus);
            [_acVoltageLabel setText:[NSString stringWithFormat:@"%0.1fV", sysStatus.voltage_battery/1000.0f]];
            [_acCurrentLabel setText:[NSString stringWithFormat:@"%0.1fA", sysStatus.current_battery/100.0f]];
        }
            break;

            
        // GPS section
        case MAVLINK_MSG_ID_GPS_RAW_INT:
        {
            mavlink_gps_raw_int_t gpsRawIntPkt;
            mavlink_msg_gps_raw_int_decode(msg, &gpsRawIntPkt);
            [_numSatellitesLabel setText:[NSString stringWithFormat:@"%d", gpsRawIntPkt.satellites_visible]];
            [_gpsFixTypeLabel    setText: (gpsRawIntPkt.fix_type == 3) ? @"3D" : ((gpsRawIntPkt.fix_type == 2) ? @"2D" : @"No fix")];
        }
            break;

        case MAVLINK_MSG_ID_GPS_STATUS:
        {
            mavlink_gps_status_t gpsStatus;
            mavlink_msg_gps_status_decode(msg, &gpsStatus);
            [_numSatellitesLabel setText:[NSString stringWithFormat:@"%d", gpsStatus.satellites_visible]];
        }
            break;
            
        
        // Wind section
        case MAVLINK_MSG_ID_WIND:
        {
            mavlink_wind_t wind;
            mavlink_msg_wind_decode(msg, &wind);
            [_windDirLabel    setText:[NSString stringWithFormat:@"%d", (int)wind.direction]];
            [_windSpeedLabel  setText:[NSString stringWithFormat:@"%0.1f m/s", wind.speed]];
            [_windSpeedZLabel setText:[NSString stringWithFormat:@"%0.1f m/s", wind.speed_z]];
        }
            break;
    

        // System section
        case MAVLINK_MSG_ID_ATTITUDE:
        {
            mavlink_attitude_t attitudePkt;
            mavlink_msg_attitude_decode(msg, &attitudePkt);
            [_sysUptimeLabel  setText:[NSString stringWithFormat:@"%0.1f s", attitudePkt.time_boot_ms/1000.0f]];
        }
            break;
            
        case MAVLINK_MSG_ID_HWSTATUS:
        {
            mavlink_hwstatus_t hwStatus;
            mavlink_msg_hwstatus_decode(msg, &hwStatus);
            [_sysVoltageLabel setText:[NSString stringWithFormat:@"%0.2fV", hwStatus.Vcc/1000.f]];
        }
            break;
            
        case MAVLINK_MSG_ID_MEMINFO:
        {
            mavlink_meminfo_t memFree;
            mavlink_msg_meminfo_decode(msg, &memFree);
            [_sysMemFreeLabel setText:[NSString stringWithFormat:@"%0.1fkB", memFree.freemem/1024.0f]];
        }
            break;
    }
}

- (IBAction) followMeSliderChanged:(UISlider*)slider {
    [_followMeChangeListener followMeControlChange:[self followMeControlValues]];
}

- (IBAction) followMeSwitchChanged:(UISwitch*)s {
    [_followMeChangeListener followMeControlChange:[self followMeControlValues]];
}

- (void) followMeDeactivate {
    [_followMeSwitch setOn:NO animated:YES];
}

- (FollowMeCtrlValues*) followMeControlValues {
    return [[FollowMeCtrlValues alloc] initWithBearing:_followMeBearingSlider.value
                                              distance:_followMeDistanceSlider.value
                                        altitudeOffset:_followMeHeightSlider.value
                                              isActive:_followMeSwitch.isOn];
}

- (void) followMeLocationAccuracy:(CLLocationAccuracy)accuracy isAcceptable:(BOOL)acceptable {
    _userLocationAccuracyLabel.text = [NSString stringWithFormat:@"%0.1fm", accuracy];
    _userLocationAccuracyLabel.textColor = acceptable ? [UIColor greenColor] : [UIColor redColor];
}

@end
