//
//  ViewController.h
//  WorldRecoger
//
//  Created by noez on 13-8-19.
//  Copyright (c) 2013年 noez. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *targetImageView;

@end

@interface CutPoint : NSObject
@property (assign,nonatomic) CGFloat startValue;
@property (assign,nonatomic) CGFloat endValue;
@property (assign,nonatomic) BOOL isEndOfImage;
@end

@interface CutParam : NSObject
@property (assign,nonatomic) int firstLength;
@property (assign,nonatomic) int secondLength;
@property (assign,nonatomic) CGSize imageSize;
@property (nonatomic) const UInt8 *bitInfo;
@property (assign,nonatomic) float startValue;
@property (assign,nonatomic) int cutType;//0竖 1横
@property (assign,nonatomic) int startXValue;
@end
