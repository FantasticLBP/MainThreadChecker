//
//  LBPMainThreadChecker.m
//  MainThreadChecker
//
//  Created by LBP on 2/4/22.
//

#import "MainThreadChecker.h"
#include <sys/sysctl.h>
#include <dlfcn.h>

static char * const MonitorQueueName = "com.LBP.MainThreadMonitor";
static char * const MonitorLibSimulatorPath = "/Applications/Xcode.app/Contents/Developer/usr/lib/libMainThreadChecker.dylib";
static char * const MonitorLibiPhonePath = "/Developer/usr/lib/libMainThreadChecker.dylib";
static NSString * const SystemMainThreadCheckerString = @"Main Thread Checker: UI API called on a background thread:";
static char * const MainThreadCheckerAddCustomRule = "__main_thread_add_check_for_selector";

@interface MainThreadChecker()

@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, weak) id<MainThreadCheckerDelegate> delegate;

@end

@implementation MainThreadChecker

#pragma mark - life cycle

static MainThreadChecker *monitor = nil;
+ (MainThreadChecker *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor = [[MainThreadChecker alloc] init];
    });
    return monitor;
}

#pragma mark - public Method
+ (void)startMonitorWithDelegate:(id<MainThreadCheckerDelegate>)delegate
{
    NSAssert([NSThread isMainThread], @"[MDMMainThreadChecker startCheckerWithDelegate:]需在主线程中进行调用！！！");
    if (![NSThread isMainThread]) {
        return;
    }
    [[MainThreadChecker sharedInstance] startMonitorWithDelegate:delegate];
}

+ (void)addMonitorForClass:(Class)class selector:(SEL)selector
{
    if (class == nil || selector == nil) {
        return;
    }
    void *handle = dlopen(NULL, RTLD_LAZY);
    if (handle == NULL) {
        return;
    }
    void(*func)(Class, SEL) = dlsym(handle, MainThreadCheckerAddCustomRule);
    if (func == NULL) {
        return;
    }
    func(class, selector);
}

#pragma mark - private method

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
- (void)startMonitorWithDelegate:(id<MainThreadCheckerDelegate>)delegate
{
    self.delegate = delegate;
    if (self.isRunning) {
        return;
    }
    self.isRunning = YES;
    if (AmIBeingDebugged()) {
        return;
    }
#if TARGET_IPHONE_SIMULATOR
    return;
#endif
    [self redirectSTD:STDERR_FILENO];
#if TARGET_IPHONE_SIMULATOR
    dlopen(MonitorLibSimulatorPath, RTLD_LAZY);
#else
    dlopen(MonitorLibiPhonePath, RTLD_LAZY);
#endif
}
#pragma clang diagnostic pop

- (void)redirectSTD:(int)fd
{
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *pipeReadHandler = [pipe fileHandleForReading];
    dup2([[pipe fileHandleForWriting] fileDescriptor], fd);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(redirectNotificationHandle:) name:NSFileHandleReadCompletionNotification
                                               object:pipeReadHandler];
    [pipeReadHandler readInBackgroundAndNotify];
}


- (void)redirectNotificationHandle:(NSNotification *)notification
{
    dispatch_async(self.queue, ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(mainThreadCheckerSendReport:)]) {
            NSData *data = [notification.userInfo objectForKey:NSFileHandleNotificationDataItem];
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if ([string containsString:SystemMainThreadCheckerString]) {
                [self.delegate mainThreadCheckerSendReport:string];
            }
        }
    });
    if (![notification.object isKindOfClass:[NSFileHandle class]]) {
        return;
    }
    NSFileHandle *pipeReadHandler = (NSFileHandle *)notification.object;
    [pipeReadHandler readInBackgroundAndNotify];
}

/// 判断当前运行环境是否为连接Xcode调试环境，方法由苹果提供
/// https://developer.apple.com/library/archive/qa/qa1361/_index.html#//apple_ref/doc/uid/DTS10003368
static bool AmIBeingDebugged(void)
    // Returns true if the current process is being debugged (either
    // running under the debugger or has a debugger attached post facto).
{
    int                 junk;
    int                 mib[4];
    struct kinfo_proc   info;
    size_t              size;
 
    // Initialize the flags so that, if sysctl fails for some bizarre
    // reason, we get a predictable result.
 
    info.kp_proc.p_flag = 0;
 
    // Initialize mib, which tells sysctl the info we want, in this case
    // we're looking for information about a specific process ID.
 
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
 
    // Call sysctl.
 
    size = sizeof(info);
    junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    assert(junk == 0);
 
    // We're being debugged if the P_TRACED flag is set.
 
    return ( (info.kp_proc.p_flag & P_TRACED) != 0 );
}


#pragma mark - getters and setters
- (dispatch_queue_t)queue
{
    if (!_queue) {
        _queue = dispatch_queue_create(MonitorQueueName, DISPATCH_QUEUE_SERIAL);
    }
    return _queue;
}

@end
