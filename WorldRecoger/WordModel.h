//
//  WordModel.h
//  WorldRecoger
//
//  Created by tianchi.shao on 13-9-12.
//  Copyright (c) 2013年 noez. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WordModel : NSObject
@property (assign,nonatomic) CGRect frameInImage;
@property (strong,nonatomic) NSDictionary *blackDic;
@property (strong,nonatomic) NSArray *blackArr_X;
@property (strong,nonatomic) NSDictionary *blackDic_Y;
@property (strong,nonatomic) NSArray *blackArr_Y;
@property (strong,nonatomic) NSDictionary *blackDic_Up;
@property (strong,nonatomic) NSArray *blackArr_Up;
@property (strong,nonatomic) NSDictionary *blackDic_Down;
@property (strong,nonatomic) NSArray *blackArr_Down;
@property (strong,nonatomic) UIImage *wordImage;
@end
