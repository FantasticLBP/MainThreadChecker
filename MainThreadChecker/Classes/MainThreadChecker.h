//
//  LBPMainThreadChecker.h
//  MainThreadChecker
//
//  Created by LBP on 2/4/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MainThreadCheckerDelegate <NSObject>

@required
/// 当监测到子线程操作 UI 的时候，该方法会回调，回调可能发生在子线程
/// @param reportString 案发线程的堆栈
- (void)mainThreadCheckerSendReport:(NSString *)reportString;

@end


/// 子线程操作 UI 检查类
@interface MainThreadChecker : NSObject

/// 开启对子线程操作 UI 的监控，在主线程中开始调用
/// @param delegate 代理对象
+ (void)startMonitorWithDelegate:(id<MainThreadCheckerDelegate>)delegate;

/// 添加自定义的 API 监控，如果在子线程上操作某个 API 则会触发代理方法
/// @param class 需要监控的类
/// @param selector 需要监控的方法
+ (void)addMonitorForClass:(Class)class selector:(SEL)selector;

@end

NS_ASSUME_NONNULL_END
