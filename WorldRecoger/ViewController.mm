//
//  ViewController.m
//  WorldRecoger
//
//  Created by noez on 13-8-19.
//  Copyright (c) 2013年 noez. All rights reserved.
//

#import "ViewController.h"
#import "UIImage+RecogerCategory.h"
#import "Image.h"
#import "ResultView.h"
#import "WordModel.h"
#import "ShowPointView.h"

#define kUp(x) -1*x
#define kDown(x)   
#define kPF(x) powf(x,2)
#define kKF(x) sqrtf(x)

@interface ViewController ()
@property (nonatomic,strong) NSMutableArray *points;
@property (nonatomic,strong) NSMutableArray *rows;
@property (nonatomic,strong) NSMutableArray *words;

@property (nonatomic,strong) NSMutableArray *modelArr;
@property (assign,nonatomic) int rowHeight;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _points=[[NSMutableArray alloc] init];
    UIImage *srcImage=[UIImage imageNamed:@"waisong.png"]; 
    [_targetImageView setImage:srcImage];             
    CGRect rect=_targetImageView.frame;
    rect.size.height=61;
    [_targetImageView setFrame:rect];
    ImageWrapper *greyScale=Image::createImage(srcImage, srcImage.size.width/1, srcImage.size.height/1);
    ImageWrapper *edges=greyScale.image->autoThreshold();
    UIImage *thresholdImage=edges.image->toUIImage();
    [self.targetImageView setImage:thresholdImage];
    _rows=[[NSMutableArray alloc] init];
    _words=[[NSMutableArray alloc] init];
    _modelArr=[[NSMutableArray alloc] init];
    [self filteToRows:thresholdImage startValue:0];
    
    for (UIImage *image in _rows) {
        _rowHeight=70*[_rows indexOfObject:image];
        CFDataRef bitmapData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
        const UInt8 *bitInfo=CFDataGetBytePtr(bitmapData);
        [self getWordProjection:0 :image.size :bitInfo :image];
        CFRelease(bitmapData);
    }
    for(int i=0;i<_words.count;i++){
        UIImage *image=_words[i];
        UIImageView *imageView=[[UIImageView alloc] initWithImage:image];
        [imageView setFrame:CGRectMake(30*i+50*i, 10, image.size.width, image.size.height)];
        [self.view addSubview:imageView];
    }
    
    for (id model in _modelArr) {
        //二值化出错
        ImageWrapper *greyScale=Image::createImage([model wordImage], [model wordImage].size.width/1, [model wordImage].size.height/1);
        ImageWrapper *edges=greyScale.image->autoThreshold();
        UIImage *thresholdImage=edges.image->toUIImage();
        ImageWrapper *greyScale2=Image::createImage(thresholdImage, thresholdImage.size.width/1, thresholdImage.size.height/1);
        ImageWrapper *edges2=greyScale2.image->autoThreshold();
        UIImage *thresholdImage2=edges2.image->toUIImage();
        NSArray *blackArr_Y=[self filteInY:thresholdImage2];
        [model setBlackArr_Y:blackArr_Y];
        
        NSArray *blackArr_Up=[self filtInUpFourtyFive:thresholdImage2];
        [model setBlackArr_Up:blackArr_Up];
        
        NSArray *blackArr_Down=[self fileInDownFourtyFive:thresholdImage];
        [model setBlackArr_Down:blackArr_Down];
    }

    ShowPointView *spv=[[ShowPointView alloc] init];
    spv.pointArray=[[_modelArr objectAtIndex:0] blackArr_Up];
    [spv setFrame:CGRectMake(220, 40, 100, 100)];
    spv.backgroundColor=[UIColor blackColor];
    [self.view addSubview:spv]; 
//    for (id view in self.view.subviews) {
//        [view removeFromSuperview];
//    }
//    [self filteToRows:[[_modelArr objectAtIndex:0] wordImage] startValue:0];
//    UIImageView *i=[[UIImageView alloc] initWithImage:[[_modelArr objectAtIndex:0] wordImage]];
////    [i setFrame:CGRectMake(0, 0, 300, 300)];
//    [self.view addSubview:i];
//    
//    CFDataRef bitmapData = CGDataProviderCopyData(CGImageGetDataProvider([[_modelArr objectAtIndex:0] wordImage].CGImage));
//    const UInt8 *bitInfo=CFDataGetBytePtr(bitmapData);
//    for (int i=0 ;i<22;i++) {
//        int rgb=[self readImageRofRGBAtPoint:CGPointMake(i, 12) forimage:bitInfo ofimageSize:[[_modelArr objectAtIndex:0] wordImage].size];
//        NSLog(@"%i",rgb);
//    }
//    //NSLog(@"%@",[[_modelArr objectAtIndex:0] blackDic_Up]);
}

-(void)printPix:(UIImage *)heightmap{
    CFDataRef bitmapData = CGDataProviderCopyData(CGImageGetDataProvider(heightmap.CGImage));
    const UInt8 *bitInfo=CFDataGetBytePtr(bitmapData);
    for (int i=0; i<heightmap.size.width; i++) {
        for (int j=0; j<heightmap.size.height; j++) {
            CGPoint point=CGPointMake(i, j);
            int rgb=[self readImageRofRGBAtPoint:point forimage:bitInfo ofimageSize:heightmap.size];
            if (rgb!=0) {
                [_points addObject:[NSValue valueWithCGPoint:point]];
            }
        }
    }
    CFRelease(bitmapData);
    [self drawPoints];
}

-(int)readImageRofRGBAtPoint:(CGPoint) point forimage:(const UInt8 *)imagedata ofimageSize:(CGSize)size
{
    int index=4*size.width*point.y+4*point.x;
    return imagedata[index+1];
}

-(void)drawPoints{
    CGRect frame=_targetImageView.frame;
    frame.origin.x=0;
    frame.origin.y=0;
    ResultView *rv=[[ResultView alloc] initWithFrame:frame andPoints:_points];
    rv.backgroundColor=[UIColor whiteColor];
    [self.view addSubview:rv];
}

#pragma mark -
#pragma mark 角度过滤
//分割成行 y轴阴影
-(void)filteToRows:(UIImage *)image startValue:(int)startYValue{
    CFDataRef bitmapData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    const UInt8 *bitInfo=CFDataGetBytePtr(bitmapData);
    int noBlackY_s=0;
    int noBlackY_e=0;
    BOOL beforeHaveBlack=NO;
    int writeRow=0;
    BOOL isEnd=NO;
    NSMutableArray *pointArr=[[NSMutableArray alloc] init];
    for (int i=startYValue; i<image.size.height; i++) {
        BOOL haveBlack=NO;
        for (int j=0; j<image.size.width; j++) {
            CGPoint point=CGPointMake(j, i);
            int rgb=[self readImageRofRGBAtPoint:point forimage:bitInfo ofimageSize:image.size];
            if (rgb!=0) {
                [pointArr addObject:[NSValue valueWithCGPoint:point]];
                haveBlack=YES;
                beforeHaveBlack=YES;
            }
        }
        
        if (haveBlack==NO) {
            writeRow=i;
        }
        //一行中有黑色 && 之前行也没有黑色 && i大于启示切割x
        if (haveBlack==YES && writeRow==i-1 && i>noBlackY_s) {
            noBlackY_s=i-1;
        }else if (haveBlack==NO && beforeHaveBlack==YES && i>noBlackY_e) {
            NSLog(@"end of row:%i",i);
            noBlackY_e=i;
            break;
        }
        if (i==image.size.height-1) {
            isEnd=YES;
        }
    }
    if (isEnd) {
        ShowPointView *spv=[[ShowPointView alloc] init];
        spv.pointArray=pointArr;
        [spv setFrame:CGRectMake(220, 40, 100, 100)];
        spv.backgroundColor=[UIColor greenColor];
        [self.view addSubview:spv];
        CFRelease(bitmapData);
        return;
    }
    CGRect frame=CGRectMake(0,noBlackY_s, image.size.width, noBlackY_e-noBlackY_s);
    UIImage *wordImg=[self cropImage:image withRect:frame];
    [_rows addObject:wordImg];
    UIImageView *imageView=[[UIImageView alloc] initWithImage:wordImg];
    [imageView setFrame:CGRectMake(20, 110+startYValue, image.size.width, noBlackY_e-noBlackY_s)];
    [self.view addSubview:imageView];
    [self filteToRows:image startValue:noBlackY_e];
    CFRelease(bitmapData);
}

//废弃
-(void)worldFilter:(UIImage *)image :(int)startXVaule{
    if (startXVaule>=image.size.width) {
        return;
    }
    CGPoint startPoint=CGPointMake(image.size.width, image.size.height);
    CGPoint endPoint=CGPointMake(0, 0);
    CFDataRef bitmapData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    const UInt8 *bitInfo=CFDataGetBytePtr(bitmapData);
    CutParam *f_param=[[CutParam alloc] init];
    f_param.imageSize=image.size;
    
    f_param.firstLength=image.size.width;
    f_param.secondLength=image.size.height;
    
    f_param.startValue=startPoint.y;
    f_param.bitInfo=bitInfo;
    f_param.cutType=0;
    f_param.startXValue=startXVaule;
    CutPoint *cutPoint=[self getPointWithParam:f_param];
    startPoint.y=cutPoint.startValue;
    endPoint.x=cutPoint.endValue;
    
    f_param.firstLength=image.size.height;
    f_param.secondLength=endPoint.x;
    
    f_param.startValue=startPoint.x;
    f_param.bitInfo=bitInfo;
    f_param.cutType=1;
    CutPoint *cutPoint2=[self getPointWithParam:f_param];
    startPoint.x=cutPoint2.startValue;
    endPoint.y=cutPoint2.endValue;
    if (cutPoint2.isEndOfImage) {
        CFRelease(bitmapData);
        return;
    }
    CGRect frame=CGRectMake(startPoint.x, startPoint.y, endPoint.x-startPoint.x, endPoint.y-startPoint.y);
    NSLog(@"↓cut frame:x:%f y:%f width:%f height:%f",frame.origin.x,frame.origin.y,frame.size.width,frame.size.height);
    NSLog(@"↑end point:x:%f y:%f",endPoint.x,endPoint.y);
    NSLog(@"----------------------------------------------");
    UIImage *wordImg=[self cropImage:image withRect:frame];
    [_words addObject:wordImg];
    [self worldFilter:image :endPoint.x];
    CFRelease(bitmapData);
}
//废弃
-(CutPoint *)getPointWithParam:(CutParam *)param{
    CutPoint *cutPoint=[[CutPoint alloc] init];
    float startValue=param.startValue;
    BOOL isBlack=NO;
    BOOL hasBlack=NO;
    int i=0,j=0;
    if (param.cutType==0) {
        i=param.startXValue;
    }else{
        j=param.startXValue;
    }
    for (i=param.cutType==0?param.startXValue:0; i<param.firstLength; i++) {
        hasBlack=NO;
        for (j=param.cutType==0?0:param.startXValue; j<param.secondLength; j++) {
            CGPoint point=CGPointZero;
            if (param.cutType==0) {
                point=CGPointMake(i, j);
            }else{
                point=CGPointMake(j, i);
            }
            int rgb=[self readImageRofRGBAtPoint:point forimage:param.bitInfo ofimageSize:param.imageSize];
            if (rgb!=0) {
                if (j<startValue) {
                    startValue=j;
                    cutPoint.startValue=j;
                }
                isBlack=YES;
                hasBlack=YES;
            }
        }
        if (hasBlack==NO&&isBlack==YES) {
            
            cutPoint.endValue=i;
            break;
        }
        if (param.cutType==1 && j==param.secondLength) {
            cutPoint.endValue=i;
        }
    }
    if (isBlack==NO && param.cutType==1) {
        cutPoint.isEndOfImage=YES;
    }
    return cutPoint;
}

//x轴阴影与X轴过滤
-(void)getWordProjection:(int)xStartValue :(CGSize)imageSize :(const UInt8 *)bitInfo :(UIImage *)image{
    int x_start,x_end=0;
    int whiteRow=0;
    BOOL beforeHaveBlack=NO;
    BOOL isContinue=NO;
    BOOL isEnd=NO;
    int maxBlackY=0;
    int minBlackY=imageSize.height;
    NSMutableDictionary *blackDic=[[NSMutableDictionary alloc] init];
    NSMutableArray *blackArr=[[NSMutableArray alloc] init];
    for (int i=xStartValue; i<imageSize.width; i++) {
        BOOL haveBlackAtRow=NO;
        int blackCount=0;
        for (int j=0; j<imageSize.height; j++) {
            CGPoint point=CGPointMake(i,j);
            int rgb=[self readImageRofRGBAtPoint:point forimage:bitInfo ofimageSize:imageSize];
            if (rgb!=0) {
                [blackArr addObject:[NSValue valueWithCGPoint:point]];
                blackCount++;
                haveBlackAtRow=YES;
                beforeHaveBlack=YES;
                if (j>maxBlackY) {
                    maxBlackY=j;
                }else if(j<minBlackY){
                    minBlackY=j;
                }
            }
        }
        [blackDic setObject:[NSNumber numberWithInt:blackCount] forKey:[NSNumber numberWithInt:i]];
        if (haveBlackAtRow==NO) {
            whiteRow=i;
        }
        //如果之前一列是白色列 当前列位黑色列 判断为开始X坐标
        if (whiteRow==i-1 && haveBlackAtRow==YES && isContinue==NO) {
            x_start=i;
        }else if (beforeHaveBlack==YES && haveBlackAtRow==NO){//如果之前有黑色行 当前行为白色行 判断为结束X坐标
            x_end=i;
            if (abs(x_end-x_start-imageSize.height)<=3 ) {//如果宽高之间小于3个像素 判断为正常字 否则不认为是一个字
                break;
            }
            isContinue=YES;
        }
        if (i==imageSize.width-1) {
            isEnd=YES;
        }
    }
    if (isEnd) {
        return;
    }
    CGRect frame=CGRectMake(x_start, 0, x_end-x_start, imageSize.height);
    UIImage *imageR=[self cropImage:image withRect:frame];
    
    WordModel *word=[[WordModel alloc] init];
    word.blackDic=blackDic;
    word.blackArr_X=blackArr;
    word.frameInImage=frame;
    word.wordImage=imageR;
    [_modelArr addObject:word];
    [_words addObject:imageR];
    [self getWordProjection:x_end :imageSize :bitInfo :image];
}


-(UIImage *)cropImage:(UIImage *)image withRect:(CGRect)imageRect{
    CGImageRef subImageRef = CGImageCreateWithImageInRect(image.CGImage, imageRect);
    CGRect smallBounds = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef));
    UIGraphicsBeginImageContext(smallBounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, smallBounds, subImageRef);
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    UIGraphicsEndImageContext();
    return smallImage;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -
#pragma mark 过滤

//Y轴过滤
-(NSArray *)filteInY:(UIImage *)image{
    CFDataRef bitmapData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    const UInt8 *bitInfo=CFDataGetBytePtr(bitmapData);
    
    NSMutableArray *blackArr=[[NSMutableArray alloc] init];
    for (int i=0;i<image.size.height; i++) {
        for (int j=0; j<image.size.width; j++) {
            CGPoint point=CGPointMake(j, i);
            int rgb=[self readImageRofRGBAtPoint:point forimage:bitInfo ofimageSize:image.size];
            if (rgb!=0) {
                [blackArr addObject:[NSValue valueWithCGPoint:point]];
                NSLog(@"rgb: at Point:%f,%f",point.x,point.y);
            }
        }
    }
    CFRelease(bitmapData);
    return blackArr;
}

//左下至右上过滤
-(NSArray *)filtInUpFourtyFive:(UIImage *)image{
    CFDataRef bitmapData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    const UInt8 *bitInfo=CFDataGetBytePtr(bitmapData);
//    CGFloat diagonal= kKF(kPF(image.size.width) + kPF(image.size.height));
    CGFloat filtDiagonal= kKF((kPF(image.size.height)*2));
    CGFloat minusHeight= image.size.width-image.size.height;
    CGFloat ff=image.size.height;
    if (image.size.width<image.size.height) {
        filtDiagonal=kKF((kPF(image.size.width)*2));
        minusHeight=image.size.height-image.size.width;
        ff=image.size.width;
    }
    CGFloat longOfLast=minusHeight*ff/filtDiagonal;
    CGFloat longOfFiltLine=filtDiagonal+longOfLast;
    
    NSMutableArray *blackArr=[[NSMutableArray alloc] init];
    for (int i=0; i<longOfFiltLine; i++) {
        CGFloat xChangeLength=kKF(2*kPF(i));
        for (float j=0;j<=xChangeLength;j++) {
            CGFloat x=j;
            CGFloat y=kUp(j)+xChangeLength;
            CGPoint point = CGPointMake(x, y);
            if (x>image.size.width || y>image.size.height) {
                continue;
            }
            int rgb=[self readImageRofRGBAtPoint:point forimage:bitInfo ofimageSize:image.size];
            //NSLog(@"i:%i rgb:%i at point:%f,%f",i,rgb,point.x,point.y);
            if (rgb!=0) {
                [blackArr addObject:[NSValue valueWithCGPoint:point]];
            }
        }
    }
    CFRelease(bitmapData);
    return blackArr;
}

//左上至右下过滤
-(NSArray *)fileInDownFourtyFive:(UIImage *)image{
    CFDataRef bitmapData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    const UInt8 *bitInfo=CFDataGetBytePtr(bitmapData);
    CGFloat diagonal= kKF(kPF(image.size.width) + kPF(image.size.height));
    CGFloat filtDiagonal= kKF((kPF(image.size.height)*2));
    CGFloat minusHeight= image.size.width-image.size.height;
    if (image.size.width<image.size.height) {
        filtDiagonal=kKF((kPF(image.size.width)*2));
        minusHeight=image.size.height-image.size.width;
    }
    CGFloat longOfLast=(kPF(diagonal)-kPF(filtDiagonal)-kPF(minusHeight))/(2*filtDiagonal);
    CGFloat longOfFiltLine=filtDiagonal+longOfLast;
    
    NSMutableArray *blackArr=[[NSMutableArray alloc] init];
    for (int i=0; i<longOfFiltLine; i++) {
        CGFloat xChangeLength=kKF(2*kPF(i));
        for (float j=0;j<=xChangeLength;j++) {
            CGFloat x=j;
            CGFloat y=xChangeLength==0?0:((image.size.height-xChangeLength)/xChangeLength)*x+xChangeLength;
            CGPoint point = CGPointMake(x, y);
            if (x>image.size.width || y<0|| y>image.size.height) {
                continue;
            }
            int rgb=[self readImageRofRGBAtPoint:point forimage:bitInfo ofimageSize:image.size];
            if (rgb!=0) {
                [blackArr addObject:[NSValue valueWithCGPoint:point]];
            }
        }
    }
    CFRelease(bitmapData);
    return blackArr;
}

@end

@implementation CutPoint



@end

@implementation CutParam



@end
