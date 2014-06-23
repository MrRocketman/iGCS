//
//  SimpleArtificialHorizonView.m
//  iGCS
//
//  Created by James Adams on 6/18/14.
//
//

#import "SimpleArtificialHorizonView.h"

@implementation SimpleArtificialHorizonView

@synthesize pitch = _pitch;
@synthesize roll = _roll;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.width);
        
        self.layer.cornerRadius = self.frame.size.width / 2;
        self.layer.masksToBounds = YES;
        
        self.groundColor = [UIColor colorWithRed:0.0 green:0.75 blue:0.47 alpha:0.9];
        self.skyColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:0.9];
        self.groundDetailsColor = [UIColor colorWithRed:0.4 green:1.0 blue:0.73 alpha:0.9];
        self.skyDetailsColor = [UIColor colorWithRed:0.4 green:0.8 blue:1.0 alpha:0.9];
    }
    
    return self;
}

- (void)setPitch:(float)thePitch
{
    if(thePitch < M_PI / 2)
    {
        _pitch = thePitch;
    }
    else
    {
        _pitch = -fmodf(thePitch, (M_PI / 2));
    }
}

- (float)pitch
{
    return _pitch;
}

- (void)setRoll:(float)theRoll
{
    if(theRoll < M_PI / 2)
    {
        _roll = theRoll;
    }
    else
    {
        _roll = -fmodf(theRoll, (M_PI / 2));
    }
}

- (float)roll
{
    return _roll;
}

- (void)drawBackgroundWithContext:(CGContextRef)context andRect:(CGRect)rect
{
    CGPoint centerPoint = CGPointMake(CGRectGetMidX(rect) , CGRectGetMidY(rect));
    
    // Define variables
    float r = self.frame.size.width / 2;
    float xMinorDelta = 0.1 * r;
    float yMinorDelta = 1.0 / 5.0 * r; // the 1/5 adjust the spacing of the pitch lines
    
    CGContextSaveGState(context);
    // Rotate about the centr point
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, centerPoint.x, centerPoint.y);
    transform = CGAffineTransformRotate(transform, self.roll);
    transform = CGAffineTransformTranslate(transform, -centerPoint.x, -centerPoint.y);
    transform = CGAffineTransformTranslate(transform, 0, RADIANS_TO_DEGREES(self.pitch) / 5.0 * yMinorDelta);
    CGContextConcatCTM(context, transform);
    
    // Draw the 'Ground"
    CGContextSetFillColorWithColor(context, [self.groundColor CGColor]);
    CGContextFillRect(context, CGRectMake(0, centerPoint.y, self.frame.size.width, self.frame.size.height));
    
    // Draw the 'Sky"
    CGContextSetFillColorWithColor(context, [self.skyColor CGColor]);
    CGContextFillRect(context, CGRectMake(0, -centerPoint.y, self.frame.size.width, self.frame.size.height));
    
    // Draw pitch lines
    for (int i = 1; i <= 4; i++)
    {
        // Increasing size of horizontal stroke moving out from centre
        float xMajorDelta = (i + 1) * xMinorDelta;
        float yOffset = i * 2.0 * yMinorDelta;
        
        NSString *label = [NSString stringWithFormat:@"%d", i * 10];
        // For both above and below the horizon
        for (int j = 0; j < 2; j++)
        {
            // Main stroke
            float y = centerPoint.y + (j == 0 ? yOffset : -yOffset);
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, centerPoint.x - xMajorDelta, y);
            CGContextAddLineToPoint(context, centerPoint.x + xMajorDelta, y);
            CGContextSetStrokeColorWithColor(context, j != 0 ? self.skyDetailsColor.CGColor : self.groundDetailsColor.CGColor);
            CGContextStrokePath(context);
            
            // Draw the label
            [label drawInRect:CGRectMake(centerPoint.x - xMajorDelta - r * 0.20, y - 7.5, 15, 15) withAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Helvetica" size:12], NSForegroundColorAttributeName: j != 0 ? self.skyDetailsColor : self.groundDetailsColor}];
            [label drawInRect:CGRectMake(centerPoint.x + xMajorDelta + r * 0.05, y - 7.5, 15, 15) withAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Helvetica" size:12], NSForegroundColorAttributeName: j != 0 ? self.skyDetailsColor : self.groundDetailsColor}];
            
            // Minor stroke
            y += (j == 0 ? -yMinorDelta : yMinorDelta);
            CGContextBeginPath(context);
            CGContextMoveToPoint   (context, centerPoint.x - xMinorDelta, y);
            CGContextAddLineToPoint(context, centerPoint.x + xMinorDelta, y);
            CGContextSetStrokeColorWithColor(context, j != 0 ? self.skyDetailsColor.CGColor : self.groundDetailsColor.CGColor);
            CGContextStrokePath(context);
        }
    }
    
    // Restore identity transformation
    CGContextRestoreGState(context);
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    //self.pitch += 0.01;
    //[self performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:0.033];
    
    CGPoint centerPoint = CGPointMake(CGRectGetMidX(rect) , CGRectGetMidY(rect));
    
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw the background
    [self drawBackgroundWithContext:context andRect:rect];
    
    // Draw the center line
    float centerLineHeight = self.frame.size.height / 34.0; // 5.0
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(self.frame.size.width / 8, centerPoint.y - centerLineHeight / 2, self.frame.size.width * 0.75, centerLineHeight) cornerRadius:2.0];
    [bezierPath fill];
    
    // Draw the vertical line
    float verticalLineWidth = self.frame.size.height / 56.0; // 3.0
    float verticalLineHeight = self.frame.size.height / 8;
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    bezierPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(centerPoint.x - verticalLineWidth / 2, centerPoint.y - verticalLineHeight, verticalLineWidth, verticalLineHeight) cornerRadius:2.0];
    [bezierPath fill];
    
    //Draw the center dot
    float centerDotDiameter = self.frame.size.height / 9.5; // 18.0
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextFillEllipseInRect(context, CGRectMake(centerPoint.x - centerDotDiameter / 2, centerPoint.y - centerDotDiameter / 2, centerDotDiameter, centerDotDiameter));
    float redCenterDotDiameter = centerDotDiameter * 0.6;
    CGContextSetFillColorWithColor(context, [[UIColor redColor] CGColor]);
    CGContextFillEllipseInRect(context, CGRectMake(centerPoint.x - redCenterDotDiameter / 2, centerPoint.y - redCenterDotDiameter / 2, redCenterDotDiameter, redCenterDotDiameter));
    
    // Draw the circle border
    float borderWidth = self.frame.size.height / 17.0; // 10.0
    CGContextSetLineWidth(context, borderWidth);
    CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextStrokeEllipseInRect(context, CGRectMake(borderWidth / 2, borderWidth / 2, self.frame.size.width - borderWidth, self.frame.size.height - borderWidth));
    
    // Draw the yaw indicator
    float yawIndicatorWidth = borderWidth / 2; // 5.0
    float yawIndicatorHeight = borderWidth;
    CGContextSetFillColorWithColor(context, [[UIColor redColor] CGColor]);
    CGContextSaveGState(context);
    // Rotate about the centr point
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, centerPoint.x, centerPoint.y);
    transform = CGAffineTransformRotate(transform, self.yaw);
    transform = CGAffineTransformTranslate(transform, -centerPoint.x, -centerPoint.y);
    //transform = CGAffineTransformTranslate(transform, 0, pitch*RAD2DEG/5.0 * yMinorDelta);
    CGContextConcatCTM(context, transform);
    // Draw it
    CGContextFillRect(context, CGRectMake(self.frame.size.width / 2 - yawIndicatorWidth / 2, 0, yawIndicatorWidth, yawIndicatorHeight));
    CGContextRestoreGState(context);
}

@end
