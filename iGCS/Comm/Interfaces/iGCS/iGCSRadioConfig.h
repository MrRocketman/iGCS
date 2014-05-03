//
//  iCGCRadioConfig.h
//  iGCS
//
//  Created by Andrew Brown on 9/5/13.
//
//

#import "CommInterface.h"
#import "GCSSikAT.h"

typedef NS_ENUM(NSUInteger, GCSHayesReponseState) {
    HayesStart,
    HayesCommand,
    HayesEnd,
};

@interface iGCSRadioConfig : CommInterface
// subsclasses must assign this property to use produceData
@property (strong) CommConnectionPool *connectionPool;
@property (nonatomic, strong) GCSSikAT *sikAt;
@property (nonatomic, strong) NSMutableDictionary *responses;

// receiveBytes processes bytes forwarded from another interface
-(void)consumeData:(uint8_t*)bytes length:(int)length;
-(void)produceData:(uint8_t*)bytes length:(int)length;
-(void)close;

// state
@property (readwrite) GCSHayesReponseState hayesResponseState;

#pragma public mark - AT/RT commands

-(void)loadSettings;

//read
-(void)radioVersion;
-(void)boadType;
-(void)RSSIReport;

// read/write
-(void)enableRSSIDebug;
-(void)disableDebug;
-(void)netId;
-(void)setNetId:(NSInteger) netId;
-(void)save;

@end
