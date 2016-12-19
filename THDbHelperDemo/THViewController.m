//
//  THViewController.m
//  test4
//
//  Created by Junyan Wu on 16/12/6.
//  Copyright © 2016年 THU. All rights reserved.
//

#import "THViewController.h"

@interface THViewController ()

@end

@implementation THViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)setupViews {
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"template";
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
