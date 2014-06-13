//
//  iCGCRadioConfig.m
//  iGCS
//
//  Created by Andrew Brown on 9/5/13.
//
//

#import "iGCSRadioConfig.h"

NSString * const GCSRadioConfigCommandQueueHasEmptied = @"com.fightingwalrus.radioconfig.queue.emptied";
NSString * const GCSRadioConfigCommandBatchResponseTimeOut = @"com.fightingwalrus.radioconfig.commandbatch.timeout";

@implementation NSMutableArray (Queue)
-(id)gcs_pop{
    id anObject = [self lastObject];
    [self removeLastObject];
    return anObject;
}
@end

@interface iGCSRadioConfig () {
    NSTimer *_batchResponseTimer;
    NSMutableString *_buffer;
    NSMutableArray *_possibleCommands;
    NSMutableDictionary *_currentSettings;
    NSString *_previousHayesResponse;
    // Queue of selectors of commands to perform
    NSMutableArray *_commandQueue;
    GCSSikAT *_privateSikAt;
}

 -(void)sendATCommand:(NSString *)atCommand;
@end

@implementation iGCSRadioConfig

-(id) init {
    self = [super init];
    if (self) {
        // public
        _sikAt = [[GCSSikAT alloc] init];
        _privateSikAt = [[GCSSikAT alloc] init];
        _localRadioSettings = [[GCSRadioSettings alloc] init];
        _remoteRadioSettings = [[GCSRadioSettings alloc] init];
        _buffer = [[NSMutableString alloc] init];
        _possibleCommands = [[NSMutableArray alloc] init];
        _currentSettings = [[NSMutableDictionary alloc] init];
        _hayesResponseState = HayesEnd;
        _commandQueue = [[NSMutableArray alloc] init];
        _ATCommandTimeout = 0.25f;
        _RTCommandTimeout = 0.5f;

        // observe
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commandQueueHasEmptied) name:GCSRadioConfigCommandQueueHasEmptied object:nil];
    }
    return self;
}

// receiveBytes processes bytes forwarded from another interface
-(void)consumeData:(uint8_t*)bytes length:(int)length {
    NSData *data = [NSData dataWithBytes:bytes length:length];
    NSString *aString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];

    NSString *currentString = [aString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSLog(@"iGCSRadioConfig consumeData: %@", currentString);

    [_buffer appendString:[NSString stringWithFormat:@"%@|", currentString]];

    if (_hayesResponseState == HayesStart) {
        if ([_possibleCommands containsObject:currentString]) {
            @synchronized(self) {
                _hayesResponseState = HayesCommand;
            }
            _previousHayesResponse = currentString;
        }
    } else if (_hayesResponseState == HayesCommand && _previousHayesResponse) {
        [self updateModelWithKey:_previousHayesResponse andValue:currentString];
        _currentSettings[_previousHayesResponse] = currentString;
        @synchronized(self) {
            _hayesResponseState = HayesEnd;
            [self dispatchCommandFromQueue];
        }
        _previousHayesResponse = nil;

    }
}

-(void)produceData:(uint8_t*)bytes length:(int)length {
    NSLog(@"iGCSRadioConfig produceData");
    [super produceData:bytes length:length];
}

-(void) close {
    NSLog(@"iGCSRadioClose: close is a noop");
}


#pragma public mark - send commands

-(void)prepareQueueForNewCommands{
    [_commandQueue removeAllObjects];
}

-(void)resetBatchResponseTimer {
    // set a timeout for the batch
    if (_batchResponseTimer) {
        [_batchResponseTimer invalidate];
        _batchResponseTimer = nil;
    }

    float commandTimeout = (self.sikAt.hayesMode == AT) ? self.ATCommandTimeout : self.RTCommandTimeout;
    float batchTimeoutInterval = commandTimeout * _commandQueue.count;

    NSLog(@"Set batch timeout of %f seconds for %ld %@ commands ",
          batchTimeoutInterval,
          (unsigned long)_commandQueue.count,
          GCSSikHayesModeDescription[AT]);

    _batchResponseTimer = [NSTimer scheduledTimerWithTimeInterval:batchTimeoutInterval target:self
                                                    selector:@selector(hayesBatchResponseTimeout)
                                                    userInfo:nil repeats:NO];
}

-(void)exitConfigMode {
    [self prepareQueueForNewCommands];

    __weak iGCSRadioConfig *weakSelf = self;
    [_commandQueue addObject:^(){[weakSelf exit];}];

    [self resetBatchResponseTimer];
    [self dispatchCommandFromQueue];
}

-(void)enterConfigMode {
    [self prepareQueueForNewCommands];

    __weak iGCSRadioConfig *weakSelf = self;
    [_commandQueue addObject:^(){[weakSelf sendConfigModeCommand];}];

    [self resetBatchResponseTimer];
    [self dispatchCommandFromQueue];
}

-(void)loadSettings{
    [self prepareQueueForNewCommands];

    __weak iGCSRadioConfig *weakSelf = self;
//    [_commandQueue addObject:^(){[weakSelf boadType];}];
//    [_commandQueue addObject:^(){[weakSelf boadFrequency];}];
//    [_commandQueue addObject:^(){[weakSelf boadVersion];}];

//  TODO: need more logic to parse response from this command.
//  eepromParams are currently gathered one by one.
//  [_commandQueue addObject:^(){[weakSelf eepromParams];}];
//    [_commandQueue addObject:^(){[weakSelf tdmTimingReport];}];
//
//    [_commandQueue addObject:^(){[weakSelf RSSIReport];}];
    [_commandQueue addObject:^(){[weakSelf serialSpeed];}];
    [_commandQueue addObject:^(){[weakSelf airSpeed];}];
    [_commandQueue addObject:^(){[weakSelf netId];}];
    [_commandQueue addObject:^(){[weakSelf transmitPower];}];
//    [_commandQueue addObject:^(){[weakSelf ecc];}];
    [_commandQueue addObject:^(){[weakSelf radioVersion];}];
//    [_commandQueue addObject:^(){[weakSelf mavLink];}];
//    [_commandQueue addObject:^(){[weakSelf oppResend];}];
    [_commandQueue addObject:^(){[weakSelf minFrequency];}];
    [_commandQueue addObject:^(){[weakSelf maxFrequency];}];
//    [_commandQueue addObject:^(){[weakSelf numberOfChannels];}];
//    [_commandQueue addObject:^(){[weakSelf dutyCycle];}];
//    [_commandQueue addObject:^(){[weakSelf listenBeforeTalkRssi];}];

    // Kick things off by sending a command from Queue.
    // Once we get a response back the next command will
    // be sent via the consume data method after we have
    // processed the previous response.
//    [_commandQueue addObject:^(){[weakSelf save];}];
//    [_commandQueue addObject:^(){[weakSelf setNetId:400];}];
//    [_commandQueue addObject:^(){[weakSelf rebootRadio];}];

    [_commandQueue addObject:^(){[weakSelf RSSIReport];}];
    [_commandQueue addObject:^(){[weakSelf radioVersion];}];

    [self resetBatchResponseTimer];
    [self dispatchCommandFromQueue];
}

-(void)saveAndReset{
    [self prepareQueueForNewCommands];

    __weak iGCSRadioConfig *weakSelf;
    [_commandQueue addObject:^(){[weakSelf save];}];
    [_commandQueue addObject:^(){[weakSelf rebootRadio];}];

    [self resetBatchResponseTimer];
    [self dispatchCommandFromQueue];
}

-(void)commandQueueHasEmptied {
    NSLog(@"commandQueueHasEmptied");
    if (_sikAt.hayesMode == RT) {
        _sikAt.hayesMode = AT;
        return;
    }

//    _sikAt.hayesMode = RT;
//    [self loadSettings];
}

#pragma mark - read radio settings via AT/RT commands
-(void)radioVersion {
    [self sendATCommand:_sikAt.showRadioVersionCommand];
}

-(void)boadType {
    [self sendATCommand:_sikAt.showBoardTypeCommand];
}

-(void)boadFrequency {
    [self sendATCommand:_sikAt.showBoardFrequencyCommand];
}

-(void)boadVersion {
    [self sendATCommand:_sikAt.showBoardVersionCommand];
}

-(void)eepromParams {
    [self sendATCommand:_sikAt.showEEPROMParamsCommand];
}

-(void)tdmTimingReport {
    [self sendATCommand:_sikAt.showTDMTimingReport];
}

-(void)RSSIReport {
    [self sendATCommand:_sikAt.showRSSISignalReport];
}

-(void)serialSpeed {
    [self sendATCommand:[_sikAt showRadioParamCommand:SerialSpeed]];
}

-(void)airSpeed {
    [self sendATCommand:[_sikAt showRadioParamCommand:AirSpeed]];
}

-(void)netId {
    [self sendATCommand:[_sikAt showRadioParamCommand:NetId]];
}

-(void)transmitPower {
    [self sendATCommand:[_sikAt showRadioParamCommand:TxPower]];
}

-(void)ecc {
    [self sendATCommand:[_sikAt showRadioParamCommand:EnableECC]];
}

-(void)mavLink {
    [self sendATCommand:[_sikAt showRadioParamCommand:MavLink]];
}

-(void)oppResend {
    [self sendATCommand:[_sikAt showRadioParamCommand:OppResend]];
}

-(void)minFrequency {
    [self sendATCommand:[_sikAt showRadioParamCommand:MinFrequency]];
}

-(void)maxFrequency {
    [self sendATCommand:[_sikAt showRadioParamCommand:MaxFrequency]];
}

-(void)numberOfChannels {
    [self sendATCommand:[_sikAt showRadioParamCommand:NumberOfChannels]];
}

-(void)dutyCycle {
    [self sendATCommand:[_sikAt showRadioParamCommand:DutyCycle]];
}

-(void)listenBeforeTalkRssi {
    [self sendATCommand:[_sikAt showRadioParamCommand:LbtRssi]];
}

#pragma mark - write radio settings via AT/RT commands
-(void)setNetId:(NSInteger) aNetId {
    [self sendATCommand:[_sikAt setRadioParamCommand:NetId withValue:aNetId]];
}

-(void)enableRSSIDebug {
    [self sendATCommand:[_sikAt enableRSSIDebugCommand]];
}

-(void)disableDebug {
    [self sendATCommand:[_sikAt disableDebugCommand]];
}

-(void)rebootRadio {
    [self sendATCommand:[_sikAt rebootRadioCommand]];
}

-(void)save {
    [self sendATCommand:[_sikAt writeCurrentParamsToEEPROMCommand]];
}

-(void)exit {
    [self sendATCommand:[_sikAt exitATModeCommand]];
}


#pragma mark - private

-(void)sendConfigModeCommand {
    if (_hayesResponseState != HayesEnd) {
        NSLog(@"Waiting for previous response. Can't send command: %@", @"+++");
        return;
    }

    @synchronized(self) {
        _hayesResponseState = HayesStart;
    }

    [_possibleCommands addObject:@"+++"];
    [_possibleCommands addObject:@"OK"];

    const char* buf;

    // no trailing CRLF for +++ as with AT commands
    buf = [@"+++" cStringUsingEncoding:NSASCIIStringEncoding];
    uint32_t len = (uint32_t)strlen(buf);
    [self produceData:buf length:len];
}

-(void)sendATCommand:(NSString *)atCommand {
    if (_hayesResponseState != HayesEnd) {
        NSLog(@"Waiting for previous response. Can't send command: %@", atCommand);
        return;
    }

    @synchronized(self) {
        _hayesResponseState = HayesStart;
    }

    [_possibleCommands addObject:atCommand];
    NSString *command = [NSString stringWithFormat:@"\r\n%@\r\n", atCommand];
    const char* buf;
    buf = [command cStringUsingEncoding:NSASCIIStringEncoding];
    uint32_t len = (uint32_t)strlen(buf);
    [self produceData:buf length:len];
}

-(void)hayesBatchResponseTimeout {
    @synchronized(self) {
        NSLog(@"Timeout for command: %@", _possibleCommands.lastObject);
        [_batchResponseTimer invalidate];
        _batchResponseTimer = nil;
        _previousHayesResponse = nil;
        _hayesResponseState = HayesEnd;
        [[NSNotificationCenter defaultCenter] postNotificationName:GCSRadioConfigCommandBatchResponseTimeOut object:_possibleCommands.lastObject];
    }
}

-(void) dispatchCommandFromQueue {
    if (_commandQueue.count == 0) {
        [_batchResponseTimer invalidate];
        _batchResponseTimer = nil;
        _previousHayesResponse = nil;
        _hayesResponseState = HayesEnd;

        NSLog(@"_currentSettings: %@", _currentSettings);
        NSLog(@"localSettings: %@", _localRadioSettings);
        NSLog(@"remoteRadioSettings: %@", _remoteRadioSettings);
        if (_sikAt.hayesMode == AT) {
            [[NSNotificationCenter defaultCenter] postNotificationName:GCSRadioConfigCommandQueueHasEmptied object:nil];
        }
        return;
    }

    @synchronized(self) {
        if (_hayesResponseState == HayesEnd) {
            void(^ hayesCommand)() = [_commandQueue gcs_pop];
            hayesCommand();
        }
    }
}

// brute force
-(void)updateModelWithKey:(NSString *)key andValue:(id) value {
    _privateSikAt.hayesMode = AT;
    // local radio settings
    if ([key isEqualToString:tShowLocalRadioVersion]) {
        [_localRadioSettings setRadioVersion:value];

    }else if ([key isEqualToString:tShowLocalBoardType]) {
        [_localRadioSettings setBoadType:value];

    }else if ([key isEqualToString:tShowLocalBoardFrequency]) {
        [_localRadioSettings setBoadFrequency:value];

    }else if ([key isEqualToString:tShowLocalBoardVersion]) {
        [_localRadioSettings setBoadVersion:value];

    }else if ([key isEqualToString:tShowLocalTDMTimingReport]) {
        [_localRadioSettings setTdmTimingReport:value];

    }else if ([key isEqualToString:tShowLocalRSSISignalReport]) {
        [_localRadioSettings setRSSIReport:value];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:SerialSpeed]]) {
        [_localRadioSettings setSerialSpeed:[value integerValue]];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:AirSpeed]]) {
        [_localRadioSettings setAirSpeed:[value integerValue]];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:NetId]]) {
        [_localRadioSettings setNetId:[value integerValue]];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:TxPower]]) {
        [_localRadioSettings setTransmitterPower:[value integerValue]];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:EnableECC]]) {
        [_localRadioSettings setIsECCenabled:[value boolValue]];

    } else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:MavLink]]) {
        [_localRadioSettings setIsMavlinkEnabled:[value boolValue]];

    } else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:OppResend]]) {
        [_localRadioSettings setIsOppResendEnabled:[value boolValue]];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:MinFrequency]]) {
        [_localRadioSettings setMinFrequency:[value integerValue]];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:MaxFrequency]]) {
        [_localRadioSettings setMaxFrequency:[value integerValue]];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:NumberOfChannels]]) {
        [_localRadioSettings setNumberOfChannels:[value integerValue]];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:DutyCycle]]) {
        [_localRadioSettings setDutyCycle:[value integerValue]];

    } else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:LbtRssi]]) {
        _localRadioSettings.isListenBeforeTalkRSSIEnabled = value;
        [_localRadioSettings setIsListenBeforeTalkRSSIEnabled:[value boolValue]];
    }

    // remote radio settings
    _privateSikAt.hayesMode = RT;
    if ([key isEqualToString:tShowRemoteRadioVersion]) {
        _remoteRadioSettings.radioVersion = value;

    }else if ([key isEqualToString:tShowRemoteBoardType]) {
        _remoteRadioSettings.boadType = value;

    }else if ([key isEqualToString:tShowRemoteBoardFrequency]) {
        _remoteRadioSettings.boadFrequency = value;

    }else if ([key isEqualToString:tShowRemoteBoardVersion]) {
        _remoteRadioSettings.boadVersion = value;

    }else if ([key isEqualToString:tShowRemoteTDMTimingReport]) {
        _remoteRadioSettings.tdmTimingReport = value;

    }else if ([key isEqualToString:tShowRemoteRSSISignalReport]) {
        _remoteRadioSettings.RSSIReport = value;

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:SerialSpeed]]) {
        _remoteRadioSettings.serialSpeed = [value integerValue];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:AirSpeed]]) {
        _remoteRadioSettings.airSpeed = [value integerValue];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:NetId]]) {
        _remoteRadioSettings.netId = [value integerValue];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:TxPower]]) {
        _remoteRadioSettings.transmitterPower = [value integerValue];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:EnableECC]]) {
        _remoteRadioSettings.isECCenabled = [value boolValue];

    } else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:MavLink]]) {
        _remoteRadioSettings.isMavlinkEnabled = [value boolValue];

    } else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:OppResend]]) {
        _remoteRadioSettings.isOppResendEnabled = [value boolValue];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:MinFrequency]]) {
        _remoteRadioSettings.minFrequency = [value integerValue];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:MaxFrequency]]) {
        _remoteRadioSettings.maxFrequency = [value integerValue];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:NumberOfChannels]]) {
        _remoteRadioSettings.numberOfChannels = [value integerValue];

    }else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:DutyCycle]]) {
        _remoteRadioSettings.dutyCycle = [value integerValue];

    } else if ([key isEqualToString:[_privateSikAt showRadioParamCommand:LbtRssi]]) {
        _remoteRadioSettings.isListenBeforeTalkRSSIEnabled = value;
        
    }

}

@end


