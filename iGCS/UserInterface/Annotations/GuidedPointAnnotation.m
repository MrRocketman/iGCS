//
//  GotoPointAnnotation.m
//  iGCS
//
//  Created by Claudio Natoli on 6/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GuidedPointAnnotation.h"
#import "WaypointAnnotation.h"

@implementation GuidedPointAnnotation

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    if ((self = [super init])) {
        _coordinate = coordinate;
        _title = @"Flying to";
        _viewIdentifer = @"GUIDED";
        _color = [[GCSThemeManager sharedInstance] waypointNavColor];
        _doAnimation = YES;
    }
    return self;
}

@end
