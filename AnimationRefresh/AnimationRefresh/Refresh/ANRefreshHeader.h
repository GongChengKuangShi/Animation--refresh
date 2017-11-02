//
//  ANRefreshHeader.h
//  AnimationRefresh
//
//  Created by xrh on 2017/10/31.
//  Copyright © 2017年 xrh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIScrollView+ANRefresh.h"

@interface ANRefreshHeader : UIView

UIKIT_EXTERN const CGFloat SURefreshHeaderHeight;
UIKIT_EXTERN const CGFloat SURefreshPointRadius;

@property (nonatomic, copy) void(^handle)(void);

#pragma mark - 停止动画
- (void)endRefreshing;

@end
