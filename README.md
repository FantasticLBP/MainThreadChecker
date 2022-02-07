# MainThreadChecker

一款监控子线程操纵 UI 的能力，也可以添加自定义的 API 进行监控（实现在子线程监控某些 API 的时候捕获具体堆栈信息，帮助定位问题）

### 背景介绍

可能有些人一直没有遇到过因为在子线程操作 UI，导致在开发阶段 Xcode console 输出了一堆日志，大体如下

![](https://raw.githubusercontent.com/FantasticLBP/knowledge-kit/master/assets/2022-0204-SubThreadUIXcode1@2x.png)

其实我们可以给 Xcode 打个 `Runtime Issue Breakpoint` ，type 选择 `Main Thread Checker`， 在发生子线程操作 UI 的时候就会被系统检测到并触发断点，同时可以看到堆栈情况

![](https://raw.githubusercontent.com/FantasticLBP/knowledge-kit/master/assets/2022-0204-SubThreadUISymbolBreakpoints@2x.png)

效果如下

![](https://raw.githubusercontent.com/FantasticLBP/knowledge-kit/master/assets/2022-0204-SubThreadUIXcodeBreakingPointsHappened@2x.png)

### 问题及解决方案

上述的功能是在 Xcode 自带的，连接 Xcode 做调试才具备的功能，线上包无法检测到。

经过探索 Xcode 实现该功能是依赖于设备上的` libMainThreadChecker.dylib` 库，我们可以通过 `dlopen` 方法强制加载该库让非 Xcode 环境下也拥有监测功能。

另外在监控到子线程调用 UI 调用时，在 Xcode 环境下，会将调用栈输出到控制台，经过测试，`libMainThreadChecker.dylib` 使用的是进行输出的，由于 NSLog 是将信息输出到 `STDERR`中，我们可以通过 `NSPipe` 与 `dup2` 将 `STDERR` 输出拦截，通过对信息的文案的判断，进而获取监测到的 UI 调用，最后可以通过堆栈打印出来，就可以帮助定位到具体问题。

`libMainThreadChecker.dylib` 库具有局限性，仅仅对系统提供的一些特定类的特定 API 在子线程调用会被监控到（例如 UIKit 框架中 UIView 类）。
但是某些类有些 API 我们也不希望在子线程被调用，这时候 `libMainThreadChecker.dylib`是无法满足的。

对 `libMainThreadChecker.dylib` 库的汇编代码研究，发现 `libMainThreadChecker.dylib` 是通过内部 `__main_thread_add_check_for_selector` 这个方法来进行类和方法的注册的。所以如果我们同样可以通过 `dlsym` 来调用该方法，以达到对自定义类和方法的主线程调用监测。
![](https://raw.githubusercontent.com/FantasticLBP/knowledge-kit/master/assets/2022-0204-SubThreadUIMonitor@2x.PNG)

另外该功能可以在线下 debug 阶段开启，判断是否是在 Xcode debug 状态，可以通过苹果提供的[官方判断方法](https://developer.apple.com/library/archive/qa/qa1361/_index.html#//apple_ref/doc/uid/DTS10003368)实现。

对 [dlopen](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/dlopen.3.html)、[dlsym](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/dlsym.3.html) 陌生的小伙伴可以直接看 Apple 官方文档，这里不做展开。