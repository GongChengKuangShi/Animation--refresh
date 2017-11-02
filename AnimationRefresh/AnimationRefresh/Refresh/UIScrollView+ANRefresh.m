//
//  UIScrollView+ANRefresh.m
//  AnimationRefresh
//
//  Created by xrh on 2017/10/31.
//  Copyright © 2017年 xrh. All rights reserved.
//

#import "UIScrollView+ANRefresh.h"
#import "ANRefreshHeader.h"
#import <objc/runtime.h>

@implementation UIScrollView (ANRefresh)

- (void)addRefreshHeaderWithHandle:(void (^)(void))handle {
    ANRefreshHeader *header = [[ANRefreshHeader alloc] init];
    header.handle = handle;
    self.header = header;
    [self insertSubview:header atIndex:0];
}

- (void)setHeader:(ANRefreshHeader *)header {
    objc_setAssociatedObject(self, @selector(header), header, OBJC_ASSOCIATION_ASSIGN);
}

- (ANRefreshHeader *)header {
    return objc_getAssociatedObject(self, @selector(header));
}

#pragma mark - Swizzle
+ (void)load {
    Method originalMethod = class_getInstanceMethod([self class], NSSelectorFromString(@"dealloc"));
    Method swizzleMethod  = class_getInstanceMethod([self class], NSSelectorFromString(@"su_dealloc"));
    method_exchangeImplementations(originalMethod, swizzleMethod);
}

- (void)su_dealloc {
    self.header = nil;
    [self su_dealloc];
}

@end
