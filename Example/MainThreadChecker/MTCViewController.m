//
//  MTCViewController.m
//  MainThreadChecker
//
//  Created by LiuBinPeng on 02/04/2022.
//  Copyright (c) 2022 LiuBinPeng. All rights reserved.
//

#import "MTCViewController.h"
#import "MTCTestView.h"

@interface MTCViewController ()

@property (nonatomic, strong) MTCTestView *testView;
@end

@implementation MTCViewController

#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
//    [self mockSubThreadUIError];
    [self mockCustomViewError];
}

#pragma mark - private method
- (void)mockSubThreadUIError
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.view.backgroundColor = [UIColor brownColor];
    });
}

- (void)mockCustomViewError
{
    [self.testView setName:@"MainThreadDetector"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.testView.backgroundColor = [UIColor yellowColor];
        [self.view addSubview:self.testView];
        NSLog(@"%@", self.view.description);
    });
}

#pragma mark - getters and setters
- (MTCTestView *)testView
{
    if (!_testView) {
        _testView = [[MTCTestView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 50, self.view.frame.size.height/2 - 50, 100, 100)];
    }
    return _testView;
}

@end
