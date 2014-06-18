//
//  SmallDataView.m
//  iGCS
//
//  Created by James Adams on 6/18/14.
//
//

#import "SmallDataView.h"

@implementation SmallDataView

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
        self.layer.cornerRadius = self.frame.size.height / 2;
        self.layer.masksToBounds = YES;
    }
    
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
