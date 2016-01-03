//
//  YLRemindBtn.m
//  QQ粘性布局
//
//  Created by 张银龙 on 16/1/1.
//  Copyright © 2016年 张银龙. All rights reserved.
//

#import "YLRemindBtn.h"

@interface YLRemindBtn ()

@property (nonatomic, weak)  UIView *smallCircle;

@property (nonatomic, weak) CAShapeLayer *shapL;

@end

@implementation YLRemindBtn

-(CAShapeLayer *)shapL{
    
    if (_shapL == nil) {
        CAShapeLayer *shap = [CAShapeLayer layer];
        shap.fillColor = [UIColor redColor].CGColor;
        _shapL = shap;
        [self.superview.layer insertSublayer:shap atIndex:0];
    }
    return _shapL;
}
//不管是通过storyboard还是代码创建都可以创建
- (void)awakeFromNib
{
    [self setUp];
}
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setUp];
    }
    return self;
}
//创建按钮
- (void)setUp
{
    self.layer.cornerRadius = self.bounds.size.width * 0.5;
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor redColor];
    self.titleLabel.font = [UIFont systemFontOfSize:12];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    //添加手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];
    
    //添加小圆
    UIView *smallCircle = [[UIView alloc]init];
    smallCircle.backgroundColor = self.backgroundColor;
    smallCircle.frame = self.frame;
    smallCircle.layer.cornerRadius = self.layer.cornerRadius;
    self.smallCircle = smallCircle;
    [self.superview insertSubview:smallCircle belowSubview:self];
}

- (void)pan:(UIPanGestureRecognizer*)pan
{
    CGPoint transP = [pan translationInView:self];
    //并不能改变中心点的位置
    //self.transform = CGAffineTransformTranslate(self.transform, transP.x, transP.y);
    CGPoint center = self.center;
    center.x += transP.x;
    center.y += transP.y;
    self.center = center;
    
    
    //获取两原的距离
    CGFloat distance = [self distanceWithSmallCircle:self.smallCircle bigCirle:self];
    NSLog(@"%f",distance);
    CGFloat smallRadius = self.frame.size.width * 0.5;
    smallRadius = (smallRadius) - distance /10.0;
    self.smallCircle.bounds = CGRectMake(0, 0,smallRadius*2 ,smallRadius*2);
    self.smallCircle.layer.cornerRadius = smallRadius;
    
    UIBezierPath *path = [self  pathWithSmallCircle:self.smallCircle bigCirle:self];
    
    //形状图层
    if (self.smallCircle.hidden == NO) {
        self.shapL.path = path.CGPath;
    }
    //判断距离
    if (distance >= 60) {
        self.smallCircle.hidden = YES;
        [self.shapL removeFromSuperlayer];
    }
    
    //判断手势结束时,按钮的位置
    if(pan.state == UIGestureRecognizerStateEnded)
    {
        if (distance < 60) {
            self.frame = self.smallCircle.frame;
            self.smallCircle.hidden = NO;
            [self.shapL removeFromSuperlayer];
        }else{//播放爆炸动画
            UIImageView *imageV = [[UIImageView alloc]initWithFrame:self.bounds];
            NSMutableArray *imageArray = [NSMutableArray array];
            for (int i = 0; i < 8; ++i) {
                NSString *imageName = [NSString stringWithFormat:@"%d",i+1];
                UIImage *image = [UIImage imageNamed:imageName];
                [imageArray addObject:image];
            }
            imageV.animationImages = imageArray;
            [imageV setAnimationDuration:1];
            [imageV startAnimating];
            //添加到按钮上
            [self addSubview:imageV];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeFromSuperview];
            });
        }
    }
    
    //归零
    [pan setTranslation:CGPointZero inView:self];
    
}

//计算两个圆之间的距离
- (CGFloat)distanceWithSmallCircle:(UIView *)smallCircle bigCirle:(UIView *)bigCircle
{
    CGFloat x = bigCircle.center.x - smallCircle.center.x;
    CGFloat y = bigCircle.center.y - smallCircle.center.y;
    return sqrt(x * x + y * y);
}
//根据两个圆计算不规则的路径
- (UIBezierPath *)pathWithSmallCircle:(UIView *)smallCircle bigCirle:(UIView *)bigCircle {
    
    CGFloat x1 = smallCircle.center.x;
    CGFloat y1 = smallCircle.center.y;
    
    CGFloat x2 = bigCircle.center.x;
    CGFloat y2 = bigCircle.center.y;
    
    CGFloat d = [self distanceWithSmallCircle:smallCircle bigCirle:bigCircle];
    
    if (d <= 0) {
        return nil;
    }
    
    
    CGFloat cosθ = (y2 - y1) / d;
    CGFloat sinθ = (x2 - x1) / d;
    
    CGFloat r1 = smallCircle.bounds.size.width * 0.5;
    CGFloat r2 = bigCircle.bounds.size.width * 0.5;
    
    //创建点
    CGPoint pointA = CGPointMake(x1 - r1 * cosθ, y1 + r1 * sinθ);
    CGPoint pointB = CGPointMake(x1 + r1 * cosθ, y1 - r1 * sinθ);
    CGPoint pointC = CGPointMake(x2 + r2 * cosθ, y2 - r2 * sinθ);
    CGPoint pointD = CGPointMake(x2 - r2 * cosθ, y2 + r2 * sinθ);
    CGPoint pointO = CGPointMake(pointA.x + d * 0.5 * sinθ, pointA.y + d * 0.5 * cosθ);
    CGPoint pointP = CGPointMake(pointB.x + d * 0.5 * sinθ, pointB.y + d * 0.5 * cosθ);
    
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    //AB
    [path moveToPoint:pointA];
    [path addLineToPoint:pointB];
    //BC(曲线)
    [path addQuadCurveToPoint:pointC controlPoint:pointP];
    //CD
    [path addLineToPoint:pointD];
    //DA(曲线)
    [path addQuadCurveToPoint:pointA controlPoint:pointO];
    
    return path;
}
- (void)drawRect:(CGRect)rect {
    
}

//取消高亮
- (void)setHighlighted:(BOOL)highlighted
{
    
}

@end
