//
//  ViewController.m
//  AnimationRefresh
//
//  Created by xrh on 2017/10/31.
//  Copyright © 2017年 xrh. All rights reserved.
//

//简书详解地址:http://www.jianshu.com/p/3c51e4896632

#import "ViewController.h"
#import "ANRefreshHeader.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property(strong, nonatomic) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.automaticallyAdjustsScrollViewInsets = NO;
    self.title = @"RefreshAnimation";
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64 + 22, self.view.bounds.size.width, self.view.bounds.size.height - 64 - 22) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView addRefreshHeaderWithHandle:^{
        NSLog(@"开始刷新");
    }];
    [self.view addSubview:self.tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [UITableViewCell new];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor colorWithRed:0.0277 green:0.7235 blue:0.5135 alpha:1.0];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 200;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
     NSLog(@"结束刷新");
    [tableView.header endRefreshing];
}
@end
