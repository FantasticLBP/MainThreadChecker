//
//  MTCAppDelegate.m
//  MainThreadChecker
//
//  Created by LiuBinPeng on 02/04/2022.
//  Copyright (c) 2022 LiuBinPeng. All rights reserved.
//

#import "MTCAppDelegate.h"
#import "MTCTestView.h"
#import <MainThreadChecker/MainThreadChecker.h>

@interface MTCAppDelegate ()<MainThreadCheckerDelegate>

@property (nonatomic, strong) NSMutableArray<NSString *> *reports;
@property (nonatomic, strong) UIAlertController *alertController;

@end

@implementation MTCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [MainThreadChecker startMonitorWithDelegate:self];
    [MainThreadChecker addMonitorForClass:[MTCTestView class] selector:@selector(setName:)];
    [MainThreadChecker addMonitorForClass:[MTCTestView class] selector:@selector(setBackgroundColor:)];
    [MainThreadChecker addMonitorForClass:[MTCTestView class] selector:@selector(description)];
    return YES;
}

#pragma mark - LBPMainThreadCheckerDelegate
- (void)mainThreadCheckerSendReport:(NSString *)reportString
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.reports addObject:reportString];
        [self reportWhenNeeded];
    });
}

#pragma mark - private method
- (void)reportWhenNeeded
{
    if (self.reports.count <= 0 ||
        self.alertController) {
        return;
    }
    
    NSString *report = self.reports.firstObject;
    self.alertController = [UIAlertController alertControllerWithTitle:@"监测到子线程调用UI"
                                                                             message:report
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"确定"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
        [self.reports removeObject:report];
        self.alertController = nil;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self reportWhenNeeded];
        });
    }];
    [self.alertController addAction:alertAction];
    [self.window.rootViewController presentViewController:self.alertController animated:YES completion:nil];
}


#pragma mark - getters and setters
- (NSMutableArray<NSString *> *)reports
{
    if (!_reports) {
        _reports = [NSMutableArray array];
    }
    return _reports;
}

@end
