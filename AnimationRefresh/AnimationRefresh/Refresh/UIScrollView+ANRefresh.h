//
//  UIScrollView+ANRefresh.h
//  AnimationRefresh
//
//  Created by xrh on 2017/10/31.
//  Copyright © 2017年 xrh. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ANRefreshHeader;
@interface UIScrollView (ANRefresh)

@property (nonatomic, weak) ANRefreshHeader *header;

- (void)addRefreshHeaderWithHandle:(void (^)(void))handle;

@end
