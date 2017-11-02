//
//  ANRefreshHeader.m
//  AnimationRefresh
//
//  Created by xrh on 2017/10/31.
//  Copyright © 2017年 xrh. All rights reserved.
//

#import "ANRefreshHeader.h"
#import "UIView+SURefresh.h"

const CGFloat SURefreshHeaderHeight = 35.0;
const CGFloat SURefreshPointRadius = 5.0;

const CGFloat SURefreshPullLen     = 55.0;
const CGFloat SURefreshTranslatLen = 5.0;

#define topPointColor    [UIColor colorWithRed:90 / 255.0 green:200 / 255.0 blue:200 / 255.0 alpha:1.0].CGColor
#define leftPointColor   [UIColor colorWithRed:250 / 255.0 green:85 / 255.0 blue:78 / 255.0 alpha:1.0].CGColor
#define bottomPointColor [UIColor colorWithRed:92 / 255.0 green:201 / 255.0 blue:105 / 255.0 alpha:1.0].CGColor
#define rightPointColor  [UIColor colorWithRed:253 / 255.0 green:175 / 255.0 blue:75 / 255.0 alpha:1.0].CGColor

@interface ANRefreshHeader ()

@property (weak, nonatomic) UIScrollView *srcollView;
@property (strong, nonatomic) CAShapeLayer *lineLayer;
@property (strong, nonatomic) CAShapeLayer *TopPointLayer;
@property (strong, nonatomic) CAShapeLayer *BottomPointLayer;
@property (strong, nonatomic) CAShapeLayer *leftPointLayer;
@property (strong, nonatomic) CAShapeLayer *rightPointLayer;

@property (assign, nonatomic) CGFloat progress;
@property (assign, nonatomic) BOOL animating;

@end

@implementation ANRefreshHeader

- (instancetype)init {
    
    if (self = [super initWithFrame:CGRectMake(0, 0, SURefreshHeaderHeight, SURefreshHeaderHeight)]) {
        [self initLayers];
    }
    return self;
}


- (void)initLayers {
    
    /*
     1) 固定4个点 ，然后设置这几个点的显示与否，在通过第二步的连接介质进行关联
     */
    CGFloat centerLine = SURefreshHeaderHeight / 2;
    CGFloat radius     = SURefreshPointRadius;
    
    CGPoint toPoint = CGPointMake(centerLine, radius);
    _TopPointLayer = [self layerWithPoint:toPoint color:topPointColor];
    _TopPointLayer.hidden = NO;
    _TopPointLayer.opacity = 0.0f;//不透明度
    [self.layer addSublayer:_TopPointLayer];
    
    CGPoint leftPoint = CGPointMake(radius, centerLine);
    _leftPointLayer = [self layerWithPoint:leftPoint color:leftPointColor];
    [self.layer addSublayer:_leftPointLayer];
    
    CGPoint bottomPoint = CGPointMake(centerLine, SURefreshHeaderHeight - radius);
    _BottomPointLayer = [self layerWithPoint:bottomPoint color:bottomPointColor];
    [self.layer addSublayer:_BottomPointLayer];
    
    CGPoint rightPoint = CGPointMake(SURefreshHeaderHeight - radius, centerLine);
    _rightPointLayer = [self layerWithPoint:rightPoint color:rightPointColor];
    [self.layer addSublayer:_rightPointLayer];
    
    /*
       2 ） 4个点的链接介质对
       应一个Layer，Layer的路径是由4段直线拼接而成，直线的直径和圆形的直接一致，初始的渲染结束位置为0。
     8个阶段的动画，可以看成是Layer的渲染开始和结束位置不断变化，并通过改变其渲染的起始和结束位置来改变其形状
     */
    _lineLayer = [CAShapeLayer layer];
    _lineLayer.frame = self.bounds;
    _lineLayer.lineWidth = radius * 2;
    _lineLayer.lineCap = kCALineCapRound;//线条拐点
    _lineLayer.lineJoin = kCALineJoinRound;//终点处理
    _lineLayer.fillColor = topPointColor;
    _lineLayer.strokeColor = topPointColor;
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    [path moveToPoint:toPoint];//起始点
    [path addLineToPoint:leftPoint];//终点
    [path moveToPoint:leftPoint];
    [path addLineToPoint:bottomPoint];
    [path moveToPoint:bottomPoint];
    [path addLineToPoint:rightPoint];
    [path moveToPoint:rightPoint];
    [path addLineToPoint:toPoint];
    
    _lineLayer.path = path.CGPath;
    
    /*
     strokeStart和strokeEnd可以设置一条Path的起始和终止的位置，通过利用strokeStart和strokeEnd这两个属性支持动画的特点
     */
    _lineLayer.strokeStart = 0.0f;
    _lineLayer.strokeEnd = 0.0f;
    [self.layer insertSublayer:self.lineLayer above:self.TopPointLayer];
}

- (CAShapeLayer *)layerWithPoint:(CGPoint)center color:(CGColorRef)color {

    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = CGRectMake(center.x - SURefreshPointRadius, center.y - SURefreshPointRadius, SURefreshPointRadius * 2, SURefreshPointRadius * 2);
    layer.fillColor = color;
    layer.path = [self pointPath];
    layer.hidden = YES;
    return layer;
}


- (CGPathRef)pointPath {
    return [UIBezierPath bezierPathWithArcCenter:CGPointMake(SURefreshPointRadius, SURefreshPointRadius) radius:SURefreshPointRadius startAngle:0 endAngle:M_PI * 2 clockwise:YES].CGPath;
}

#pragma mark - Override
- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        self.srcollView = (UIScrollView *)newSuperview;
        self.center = CGPointMake(self.srcollView.centerX, self.centerY);
        [self.srcollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    } else {
        [self.superview removeObserver:self forKeyPath:@"contentOffset"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        self.progress = - self.srcollView.contentOffset.y;
    }
}

/*
 滑动过程控制
 
 该步骤的核心是通过下拉的长度计算LineLayer的开始和结束位置，并在适当的时候显示或隐藏对应的点
 */
- (void)setlineLayerStrokeWithProgress:(CGFloat)progress {
    
    float startProgress = 0.0f;
    float endProgress   = 0.0f;
    
    //没有下拉，隐藏动画
    if (progress < 0) {
        
        self.TopPointLayer.opacity = 0.0f;//不透明度
        [self adjustPointStateWithIndex:0];
        
    } else if (progress >= 0 && progress < (SURefreshPullLen - 40)) {//下拉前奏：顶部的point的可见度渐变过程
        self.TopPointLayer.opacity = progress / 20;
        [self adjustPointStateWithIndex:0];
        
    } else if (progress >= (SURefreshPullLen - 40) && progress < SURefreshPullLen) { //开始动画，这里将下拉的进度分为4个大阶段，方便处理
        self.TopPointLayer.opacity = 1.0f;
        
        //大阶段 0 ~ 3
        NSInteger stage = (progress - (SURefreshPullLen - 40)) / 10;
        //应对每个大阶段的前半段
        CGFloat subProgress = (progress - (SURefreshPullLen - 40)) - (stage * 10);
        if (subProgress >= 0 && subProgress <= 5) {
            [self adjustPointStateWithIndex:stage * 2];
            startProgress = stage / 4.0f;
            endProgress = stage / 4.0f + subProgress / 40.0f * 2;
        }
        //对应每个大阶段的后半段
        if (subProgress > 5 && subProgress < 10) {
            [self adjustPointStateWithIndex:stage * 2 + 1];
            startProgress = stage / 4.0f + (subProgress - 5) / 40.0f * 2;
            if (startProgress < (stage + 1) / 4.0f - 0.1) {
                startProgress =(stage + 1) / 4.0f - 0.1;
            }
            endProgress = (stage + 1) / 4.0f;
        }
    }
    
    //下拉超过一定长度, 4个点已经完全显示
    else {
        self.TopPointLayer.opacity = 1.0f;
        [self adjustPointStateWithIndex:NSIntegerMax];
        startProgress = 1.0f;
        endProgress   = 1.0f;
    }
    //计算完毕，设置LineLayer的开始和结束位置
    self.lineLayer.strokeStart = startProgress;
    self.lineLayer.strokeEnd   = endProgress;
}

- (void)adjustPointStateWithIndex:(NSInteger)index {//index : 小阶段： 0 ~ 7
    self.leftPointLayer.hidden   = index > 1 ? NO : YES;
    self.BottomPointLayer.hidden = index > 3 ? NO : YES;
    self.rightPointLayer.hidden  = index > 5 ? NO : YES;
    self.lineLayer.strokeColor   = index > 5 ? rightPointColor : index > 3 ? bottomPointColor : index > 1 ? leftPointColor : topPointColor;
}

//达到条件时进入刷新状态
- (void)setProgress:(CGFloat)progress {
    
    _progress = progress;
    //如果不是正在刷新, 则渐变动画
    if (!self.animating) {
        if (progress >= SURefreshPullLen) {//大于下拉的设定值
            self.y = - (SURefreshPullLen - (SURefreshPullLen - SURefreshHeaderHeight) / 2);
        } else {
            if (progress <= self.h) {
                self.y = - progress;
            } else {
                self.y = - (self.h + (progress - self.h) / 2);
            }
        }
        [self setlineLayerStrokeWithProgress:progress];
    }
    
    //如果达到临界点，则执行刷新动画
    if (progress >= SURefreshPullLen && !self.animating && !self.srcollView.dragging) {
        [self startAnimation];
        if (self.handle) {
            self.handle();
        }
    }
}

- (void)startAnimation {
    
    self.animating = YES;
    [UIView animateWithDuration:0.5 animations:^{
        UIEdgeInsets inset = self.srcollView.contentInset;
        inset.top          = SURefreshPullLen;
        self.srcollView.contentInset = inset;
    }];
    
    //4个点来回移动
    [self addTranslationAniToLayer:self.TopPointLayer xValue:0 yValue:SURefreshTranslatLen];
    [self addTranslationAniToLayer:self.leftPointLayer xValue:SURefreshTranslatLen yValue:0];
    [self addTranslationAniToLayer:self.BottomPointLayer xValue:0 yValue:-SURefreshTranslatLen];
    [self addTranslationAniToLayer:self.rightPointLayer xValue:-SURefreshTranslatLen yValue:0];
    
    [self addRotationAniToLayer:self.layer];
}

- (void)addTranslationAniToLayer:(CALayer *)layer xValue:(CGFloat)x yValue:(CGFloat)y {
    CAKeyframeAnimation *translationKeyframeAni = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    translationKeyframeAni.duration = 1.0f;
    translationKeyframeAni.repeatCount = HUGE;
    translationKeyframeAni.removedOnCompletion = NO;
    translationKeyframeAni.fillMode = kCAFillModeForwards;
    translationKeyframeAni.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    NSValue *fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, 0, 0.f)];
    NSValue *toValue = [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(x, y, 0.f)];
    translationKeyframeAni.values = @[fromValue, toValue, fromValue, toValue, fromValue];
    [layer addAnimation:translationKeyframeAni forKey:@"translationKeyframeAni"];
    
}

- (void)addRotationAniToLayer:(CALayer *)layer {
    
    CABasicAnimation *rotationAni = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAni.fromValue = @(0);
    rotationAni.toValue = @(M_PI * 2);
    rotationAni.duration = 1.0f;
    rotationAni.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    rotationAni.repeatCount = HUGE;
    rotationAni.fillMode = kCAFillModeForwards;
    rotationAni.removedOnCompletion = NO;
    [layer addAnimation:rotationAni forKey:@"rotationAni"];
}

- (void)removAni {
    
    [UIView animateWithDuration:0.5 animations:^{
        UIEdgeInsets inset = self.srcollView.contentInset;
        inset.top = 0.0f;
        self.srcollView.contentInset = inset;
    } completion:^(BOOL finished) {
        
        [self.TopPointLayer removeAllAnimations];
        [self.leftPointLayer removeAllAnimations];
        [self.BottomPointLayer removeAllAnimations];
        [self.rightPointLayer removeAllAnimations];
        [self.layer removeAllAnimations];
        [self adjustPointStateWithIndex:0];
        self.animating = NO;
    }];
}

- (void)endRefreshing {
    [self removAni];
}


@end
