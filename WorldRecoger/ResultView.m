//
//  ResultView.m
//  WorldRecoger
//
//  Created by noez on 13-8-19.
//  Copyright (c) 2013年 noez. All rights reserved.
//

#import "ResultView.h"

@implementation ResultView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame andPoints:(NSArray *)points{
    self = [self initWithFrame:frame];
    if (self) {
        // Initialization code
        self.points=points;
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    for (NSValue *value in self.points) {
        CGPoint point=[value CGPointValue];
        //// Color Declarations
        UIColor* strokeColor = [UIColor colorWithRed: 0.886 green: 0 blue: 0 alpha: 1];
        
        //// Oval Drawing
        UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(point.x, point.y, 1, 1)];
        [strokeColor setFill];
        [ovalPath fill];
        [strokeColor setStroke];
        ovalPath.lineWidth = 0;
        [ovalPath stroke];
    }
}


@end
