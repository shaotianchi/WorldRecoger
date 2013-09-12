//
//  ShowPointView.m
//  WorldRecoger
//
//  Created by tianchi.shao on 13-9-12.
//  Copyright (c) 2013年 noez. All rights reserved.
//

#import "ShowPointView.h"

@implementation ShowPointView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    [super drawRect:rect];
    for (id value in _pointArray) {

        CGPoint point =[value CGPointValue];
//        NSLog(@"rgb: at Point:%f,%f",point.x,point.y);
        //// Color Declarations
        UIColor* fillColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
        
        //// Oval Drawing
        UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(point.x, point.y, 0.7, 0.7)];
        [fillColor setFill];
        [ovalPath fill];
        [fillColor setStroke];
        ovalPath.lineWidth = 1;
        [ovalPath stroke];
    }
}


@end
