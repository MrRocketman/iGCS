//
//  SimpleArtificialHorizonView.h
//  iGCS
//
//  Created by James Adams on 6/18/14.
//
//

#import <UIKit/UIKit.h>

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface SimpleArtificialHorizonView : UIView

@property(assign) float roll; // In radians
@property(assign) float pitch; // In radians
@property(assign) float yaw; // In radians

@property(nonatomic, readwrite) UIColor *groundColor;
@property(nonatomic, readwrite) UIColor *skyColor;
@property(nonatomic, readwrite) UIColor *groundDetailsColor;
@property(nonatomic, readwrite) UIColor *skyDetailsColor;

@end
