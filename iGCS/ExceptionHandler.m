//
//  ExceptionHandler.m
//  iGCS
//
//  Created by Andrew Aarestad on 2/25/13.
//
//

#import "ExceptionHandler.h"

#import "DebugViewController.h"

@implementation ExceptionHandler

static DebugViewController *debugVC;

+(void) start:(DebugViewController*)dVC
{
    debugVC = dVC;
    NSSetUncaughtExceptionHandler(&catchUnhandledException);
}



void catchUnhandledException(NSException* e)
{
    NSLog(@"Exception raised: ");
    NSLog(@"%@",[e description]);
    
    
    
    //[ConstrucsExceptionHandler uploadExceptionReport:e.name desc:e.description type:@"Exception" callstack:[e callStackSymbols]];
    
    
}



@end
