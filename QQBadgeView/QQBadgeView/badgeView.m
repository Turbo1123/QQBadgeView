//
//  badgeView.m
//  QQbadgeView
//
//  Created by 李云龙 on 15/8/21.
//  Copyright (c) 2015年 hihilong. All rights reserved.
//

#import "badgeView.h"

@interface badgeView ()

/** 小圆控件 */
@property (nonatomic, weak) UIView *smallCircleView;

// 不规则形状图形
@property (nonatomic, weak) CAShapeLayer *shapeLayer;


@end

@implementation badgeView

/*
 粘性控件实现步骤:
 0.初始化大圆界面
 1.让大圆随着手指移动而移动
 2.让小圆半径，随着手指移动而缩小
 3.绘制不规则的矩形。
 4.处理粘性视图的业务逻辑
 */

- (CAShapeLayer *)shapeLayer
{
    if (_shapeLayer == nil) {
        //  创建形状图层,根据一个路径生成一个图层
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        
        _shapeLayer = shapeLayer;
        
        // 设置填充颜色
        shapeLayer.fillColor = self.backgroundColor.CGColor;
        
        // 添加形状图层到父控件的图层
        [self.superview.layer insertSublayer:shapeLayer atIndex:0];
    }
    return _shapeLayer;
}

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

// 初始化
- (void)setUp
{
    // 文字颜色
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    // 文字字体
    self.titleLabel.font = [UIFont systemFontOfSize:12];
    
    // 设置背景色
    self.backgroundColor = [UIColor redColor];
    
    // 获取控件的宽度
    CGFloat badgeW = self.bounds.size.width;
    
    // 设置圆角
    self.layer.cornerRadius = badgeW * 0.5;
    
    // 添加手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];
    
    // 添加一个小圆, 默认跟大圆一样，有几个相同的属性，frame,y圆角半径，背景色
    // copy:有相同属性的新对象
    // copy底层其实是调用copyWithZone：
    UIView *smallCircleView = [self copy];
    _smallCircleView = smallCircleView;
    
    // 把小圆添加到大圆的父控件
    [self.superview insertSubview:smallCircleView belowSubview:self];
    
    
}

// 告诉系统如何拷贝
// 有相同属性的新对象
- (id)copyWithZone:(NSZone *)zone
{
    
    UIView *smallCircleView = [[UIView alloc] init];
    smallCircleView.frame = self.frame;
    smallCircleView.layer.cornerRadius = self.layer.cornerRadius;
    smallCircleView.backgroundColor = self.backgroundColor;
    
    return smallCircleView;
    
}

// 当手指在按钮上拖动的时候调用
- (void)pan:(UIPanGestureRecognizer *)pan
{
    
    // 获取手指的偏移量
    CGPoint transP = [pan translationInView:self];
    
    
    // 让badgeView随着手指移动而移动,frame,center,transform
    // 修改transform，并不会改变center，底层改frame
    //    self.transform = CGAffineTransformTranslate(self.transform, transP.x, transP.y);
    // 只能修改center，去移动大圆的位置
    CGPoint center = self.center;
    center.x += transP.x;
    center.y += transP.y;
    self.center = center;
    
    // 复位
    [pan setTranslation:CGPointZero inView:self];
    
    // 让小圆随着手指拖动，如果拖动很远，半径慢慢减小
    // 根据两个圆之间圆心距离形成一段比例
    // 计算两个圆之间的圆心距离
    CGFloat d = [self distanceWithSmallCircleView:_smallCircleView bigCircleView:self];
    
    
    // 获取小圆半径
    CGFloat oriR = self.bounds.size.width * 0.5;
    CGFloat smallR = oriR - d / 10.0;
    
    // 设置小圆尺寸
    _smallCircleView.bounds = CGRectMake(0, 0, smallR * 2, smallR * 2);
    // 必须要重新设置圆角半径
    _smallCircleView.layer.cornerRadius = smallR;
    
    if (_smallCircleView.hidden == NO) { // 小圆显示的时候，才需要设置不规则矩形
        
        // 计算不规则路径
        UIBezierPath *path =  [self pathWithSmallCircleView:_smallCircleView bigCircleView:self];
        
        // 描述不规则路径
        self.shapeLayer.path = path.CGPath;
    }
    
    
    // 粘性布局业务逻辑处理
    // 判断下圆心距离，如果大于60，隐藏小圆，不规则矩形
    if (d > 60) {
        _smallCircleView.hidden = YES;
        //        _shapeLayer.hidden = YES;
        [self.shapeLayer removeFromSuperlayer];
    }
    
    // 手指抬起的时候
    if (pan.state == UIGestureRecognizerStateEnded) {
        // 判断下当前圆心的距离是否大于60，如果大于60，就播放gif图片
        NSLog(@"%f",d);
        if (d > 60) { // 拖了很远，播放gif动画
            
            UIImageView *imageV =[[UIImageView alloc] init];
            
            imageV.frame = self.bounds;
            
            NSMutableArray *images = [NSMutableArray array];
            for (int i = 1; i <= 8; i++) {
                NSString *imageName = [NSString stringWithFormat:@"%d",i];
                UIImage *image = [UIImage imageNamed:imageName];
                [images addObject:image];
            }
            
            imageV.animationImages = images;
            
            imageV.animationDuration = 1;
            
            // 开始动画
            [imageV startAnimating];
            
            [self addSubview:imageV];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.9 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeFromSuperview];
            });
            
        }else{ // 还原
            
            _smallCircleView.hidden = NO;
            
            [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.3 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^{
                
                self.center =  _smallCircleView.center;
                
            } completion:^(BOOL finished) {
                
            }];
            
        }
    }
    
    
}

// 计算两个圆之间圆心距离
- (CGFloat)distanceWithSmallCircleView:(UIView *)smallCircleView bigCircleView:(UIView *)bigCircleView
{
    // 获取x,y轴偏移量
    CGFloat offsetX = bigCircleView.center.x - smallCircleView.center.x;
    
    CGFloat offsetY = bigCircleView.center.y - smallCircleView.center.y;
    
    // sqrtf开根
    return sqrtf(offsetX * offsetX + offsetY * offsetY);
    
}

// 根据两个圆描述一个不规则的矩形路径
- (UIBezierPath *)pathWithSmallCircleView:(UIView *)smallCircleView bigCircleView:(UIView *)bigCircleView
{
    
    // 获取x1,y1,r1,小圆
    CGFloat x1 = smallCircleView.center.x;
    CGFloat y1 = smallCircleView.center.y;
    CGFloat r1 = smallCircleView.bounds.size.width * 0.5;
    
    // 获取x2,y2,r2,大圆
    CGFloat x2 = bigCircleView.center.x;
    CGFloat y2 = bigCircleView.center.y;
    CGFloat r2 = bigCircleView.bounds.size.width * 0.5;
    
    
    // 计算两个圆之间的圆心距离
    CGFloat d = [self distanceWithSmallCircleView:_smallCircleView bigCircleView:self];
    
    if (d <= 0) return nil;
    
    // cosθ
    CGFloat cosθ = (y2 - y1) / d;
    
    // sinθ
    CGFloat sinθ = (x2 - x1) / d;
    
    // A
    CGPoint pointA = CGPointMake(x1 - r1 * cosθ, y1 + r1 * sinθ);
    
    // B
    CGPoint pointB = CGPointMake(x1 + r1 * cosθ, y1 - r1 * sinθ);
    
    // C
    CGPoint pointC = CGPointMake(x2 + r2 * cosθ, y2 - r2 * sinθ);
    
    // D
    CGPoint pointD = CGPointMake(x2 - r2 * cosθ, y2 + r2 * sinθ);
    
    // O
    CGPoint pointO = CGPointMake(pointA.x + d * 0.5 * sinθ, pointA.y + d * 0.5 * cosθ);
    
    // P
    CGPoint pointP = CGPointMake(pointB.x + d * 0.5 * sinθ, pointB.y + d * 0.5 * cosθ);
    
    // 描述路径
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    // AB
    [path moveToPoint:pointA];
    [path addLineToPoint:pointB];
    // BC
    [path addQuadCurveToPoint:pointC controlPoint:pointP];
    // CD
    [path addLineToPoint:pointD];
    //DA
    [path addQuadCurveToPoint:pointA controlPoint:pointO];
    
    return path;
}

// 取消高亮时候做的事情
- (void)setHighlighted:(BOOL)highlighted
{
    // 无动作
}


@end
