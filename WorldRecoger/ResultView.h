//
//  ResultView.h
//  WorldRecoger
//
//  Created by noez on 13-8-19.
//  Copyright (c) 2013年 noez. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ResultView : UIView
@property (nonatomic,weak) NSArray *points;
-(id)initWithFrame:(CGRect)frame andPoints:(NSArray *)points;
@end
