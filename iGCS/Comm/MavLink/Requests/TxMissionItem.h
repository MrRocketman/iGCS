//
//  TxMissionItem.h
//  iGCS
//
//  Created by Claudio Natoli on 13/10/13.
//
//

#import <Foundation/Foundation.h>
#import "MavLinkRetryingRequestHandler.h"
#import "iGCSMavLinkInterface.h"

@interface TxMissionItem : NSObject <MavLinkRetryableRequest>

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *subtitle;
@property (nonatomic, readonly) double timeout;

@property (nonatomic, readonly) iGCSMavLinkInterface* interface;
@property (nonatomic, readonly) WaypointsHolder *mission;
@property (nonatomic, readonly) uint16_t currentIndex;

- (id)initWithInterface:(iGCSMavLinkInterface*)interface withMission:(WaypointsHolder*)mission andCurrentIndex:(uint16_t)currentIndex;

@end
