//
//  SimpleDataView.m
//  iGCS
//
//  Created by James Adams on 6/17/14.
//
//

#import "SimpleDataView.h"
/*
#define X_EDGE_INSET 10
#define Y_EDGE_INSET 5
#define LABEL_FONT_SIZE 20
#define VALUE_FONT_SIZE 40*/

@implementation SimpleDataView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        /*_value = 0.0;
        _label = @"Label";
        _unitsLabel = @"m";
        _color = [UIColor colorWithRed:0.1 green:0.6 blue:0.9 alpha:0.8];
        
        self.layer.cornerRadius = 5;
        self.layer.masksToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;*/
    }
    
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
/*- (void)drawRect:(CGRect)rect
{
    // Drawing code
    //NSLog(@"simpleView: Drawing to {%f,%f, %f,%f}", self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw the background
    CGContextClearRect(context, rect);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextSetFillColorWithColor(context, [_color CGColor]);
    CGContextFillRect(context, rect);
    
    // Draw the label
    [_label drawInRect:CGRectMake(X_EDGE_INSET, (self.frame.size.height - Y_EDGE_INSET) - LABEL_FONT_SIZE, self.frame.size.width - X_EDGE_INSET * 2, self.frame.size.height / 4) withAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Helvetica" size:LABEL_FONT_SIZE], NSForegroundColorAttributeName: [UIColor blackColor]}];
    
    // Draw the value
    NSString *valueString = [NSString stringWithFormat:@"%.1f", _value];
    [valueString drawInRect:CGRectMake(X_EDGE_INSET, Y_EDGE_INSET, (self.frame.size.width * 0.75) - X_EDGE_INSET * 2, self.frame.size.height / 4) withAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Helvetica" size:LABEL_FONT_SIZE], NSForegroundColorAttributeName: [UIColor blackColor]}];
}*/

@end
