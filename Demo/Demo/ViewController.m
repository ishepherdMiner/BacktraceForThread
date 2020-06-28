//
//  ViewController.m
//  Demo
//
//  Created by Shepherd on 2020/6/29.
//  Copyright © 2020 Shepherd. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self tailCallA];
}

- (void)tailCallA {
    [self tailCallB];
}

- (void)tailCallB {
    NSLog(@"%s",__func__);
}

@end
