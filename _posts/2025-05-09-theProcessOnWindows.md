---
layout: mypost
title:  "Windows中的线程与进程"
date:   2025-05-09 11:13:17 +0800
categories: windows
location: HangZhou,China
description:
---
---

## 启动一个线程
```c++
HANDLE hThread = CreateThread(
    nullptr,         // 默认安全属性
    0,               // 默认栈大小
    ThreadProc,      // 线程函数
    pParam,          // 传给线程的参数
    0,               // 创建选项（0 = 立即运行）
    &dwThreadId      // 返回线程ID
);
```
在使用 C 运行库（CRT，如 printf、malloc 等）的应用程序中，更推荐使用 _beginthreadex，因为它会正确初始化线程的 CRT 状态。
```c++
uintptr_t hThread = _beginthreadex(
    nullptr, 0,
    ThreadProc, pParam,
    0, &dwThreadId
);
```

| 创建方式   | 接口                              | 特点 & 适用场景                 |
| ---------- | --------------------------------- | ------------------------------- |
| Win32 API  | `CreateThread`                    | 最底层、没有初始化 CRT          |
| CRT 封装   | `_beginthread` / `_beginthreadex` | 初始化 C 运行时（重要）         |
| C++ 标准库 | `std::thread`                     | 跨平台、类型安全，自动初始化CRT |


### 什么是CRT状态

在使用 Visual C++ 编写的程序中，CRT（C Runtime Library，C运行库） 会为每个线程维护一些线程本地的上下文信息，比如：
* 当前线程的 errno、_doserrno（线程本地错误号）
* locale 设置
* stdio 缓冲
* C++ 异常支持状态
* _beginthread 和 _beginthreadex 创建线程时的清理机制
* TLS（Thread Local Storage）索引和对应的内容

这些信息都保存在 CRT 自己分配的一段线程本地结构里，初始化过程由_beginthread/_beginthreadex 来处理。

CreateThread 启动是可以运行的，但如果在线程中使用 malloc/free、strtok、errno、C++ 异常等，就可能出现内存泄漏、崩溃或者行为异常。尤其是在线程退出时不会自动清理 TLS 和堆内存。

详见: https://www.cnblogs.com/liangzige/p/12915879.html
> CreateThread()和_beginthreadex()在Jeffrey的《Windows核心编程》中讲的很清楚，应当尽量避免使用CreateThread()。
事实上，_beginthreadex()在内部先为线程创建一个线程特有的tiddata结构，然后调用CreateThread()。在某些非线程安全的CRT函数中会请求这个结构。如果直接使用CreateThread()的话，那些函数发现请求的tiddata为NULL，就会在现场为该线程创建该结构，此后调用EndThread()时会引起内存泄漏。_endthreadex()可以释放由CreateThread()创建的线程，实际上，在它的内部会先释放由_beginthreadex()创建的tiddata结构，然后调用EndThread()。
因此，应当使用_beginthreadex()和_endthreadex()，而避免使用CreateThread()和EndThread()。当然，_beginthread()和_endthread()也是应当避免使用的。

### TEB
TEB 是线程级别的环境信息块，每个线程都有一份，位于用户模式内存空间。它包含了：
* TLS（Thread Local Storage）数据
* 当前堆栈信息
* 异常处理信息
* 线程 ID
* 对应的 PEB（Process Environment Block）指针
* Windows 异常机制结构（SEH）
* 语言区域设置等
```c++
// windbg: dt ntdll!_TEB
typedef struct _TEB {
    NT_TIB NtTib;                         // 包括堆栈和 SEH 链
    PVOID EnvironmentPointer;            // 一般为 NULL
    CLIENT_ID ClientId;                  // 包含进程ID和线程ID
    PVOID ActiveRpcHandle;
    PVOID ThreadLocalStoragePointer;     // TLS数据的指针
    PPEB ProcessEnvironmentBlock;        // 指向 PEB
    ULONG LastErrorValue;                // 对应 GetLastError()
    ULONG CountOfOwnedCriticalSections;
    PVOID CsrClientThread;               // CSR 线程信息（用于子系统通信）
    PVOID Win32ThreadInfo;
    ULONG User32Reserved[26];
    ULONG UserReserved[5];
    PVOID WOW32Reserved;                 // 用于 WOW64
    LCID CurrentLocale;
    ULONG FpSoftwareStatusRegister;
    PVOID SystemReserved1[54];
    LONG ExceptionCode;
    // 还有更多字段...
} TEB, *PTEB;
```

windbg查看每个线程的TEB结构：
```shell
# ~ ; 打印所有线程

.  0  Id: c514.e4f8 Suspend: 1 Teb: 00000051`3d612000 Unfrozen
   1  Id: c514.cba8 Suspend: 1 Teb: 00000051`3d614000 Unfrozen
   2  Id: c514.c538 Suspend: 1 Teb: 00000051`3d616000 Unfrozen
   3  Id: c514.dc58 Suspend: 1 Teb: 00000051`3d618000 Unfrozen
# !teb 513d612000 (用户模式下只能用小写)
TEB at 000000513d612000
    ExceptionList:        0000000000000000
    StackBase:            000000513d880000
    StackLimit:           000000513d86f000
    SubSystemTib:         0000000000000000
    FiberData:            0000000000001e00
    ArbitraryUserPointer: 0000000000000000
    Self:                 000000513d612000
    EnvironmentPointer:   0000000000000000
    ClientId:             000000000000c514 . 000000000000e4f8
    RpcHandle:            0000000000000000
    Tls Storage:          0000016c7ad88a80
    PEB Address:          000000513d611000
    LastErrorValue:       0
    LastStatusValue:      0
    Count Owned Locks:    0
    HardErrorMode:        0
```

### 线程局部变量
| API                          | 说明                       |
| ---------------------------- | -------------------------- |
| `TlsAlloc()`                 | 分配一个 TLS 索引（DWORD） |
| `TlsSetValue(index, lpVoid)` | 设置当前线程对应索引的值   |
| `TlsGetValue(index)`         | 获取当前线程对应索引的值   |
| `TlsFree(index)`             | 释放索引                   |

* 系统最多支持约 1088 个 TLS 索引（0~0xFFF）
* TLS 索引是全局的，但索引值与线程私有数据一一映射
TLS 数据存储在每个线程自己的 TEB（Thread Environment Block） 中。

| 机制                       | 线程隔离 | 自动释放 | 可用于类成员 | 常见使用场景       |
| -------------------------- | -------- | -------- | ------------ | ------------------ |
| `thread_local`             | ✅ 是     | ✅ 是     | ❌ 否         | 普通变量           |
| `__declspec(thread)`       | ✅ 是     | ❌ 否     | ❌ 否         | 静态链接 DLL / EXE |
| `TlsAlloc` + `TlsSetValue` | ✅ 是     | ❌ 否     | ✅ 是         | 灵活控制资源       |

C++中的 thread_local:
```c++
thread_local std::string name = "thread name";
```
编译器会：
* 为变量分配 .tls 段中的偏移
* 为该线程在首次访问变量时生成构造代码
* 在线程退出时自动调用析构函数（仅 C++ 支持）

在动态加载的dll中使用TLS(LoadLibrary)：
* __declspec(thread) / thread_local 变量 不会自动初始化；
* 如果在DLL中使用这种TLS变量，线程在调用它之前，必须显式调用 TlsAlloc 等 API 管理 TLS 数据，否则行为未定义，甚至 crash。

### 为什么会有这个限制？

TLS 的原理是操作系统在创建线程的时候，会查看该模块（EXE/DLL）的 TLS Directory（.tls 段中的结构），并为每个 TLS slot 分配内存并初始化。
 但是这个机制仅在模块加载时由系统 PE 加载器（Loader）识别和初始化。
* 对于静态链接的 DLL，系统在主模块加载和线程创建时会一并处理。
* 对于 LoadLibrary 动态加载的 DLL，如果此时已有线程存在，这些线程不会重新初始化 TLS 相关结构，因为操作系统没法“回过头”给所有现存线程更新 TLS 块。

应尽量避免在动态库中使用thread_local关键字，改成使用windows api自己管理。

### 线程优先级

| 宏常量                          | 数值 | 含义说明              |
| ------------------------------- | ---- | --------------------- |
| `THREAD_PRIORITY_IDLE`          | -15  | 几乎不运行            |
| `THREAD_PRIORITY_LOWEST`        | -2   | 非常低                |
| `THREAD_PRIORITY_BELOW_NORMAL`  | -1   | 比正常低一点          |
| `THREAD_PRIORITY_NORMAL`        | 0    | 默认值                |
| `THREAD_PRIORITY_ABOVE_NORMAL`  | +1   | 比正常高一点          |
| `THREAD_PRIORITY_HIGHEST`       | +2   | 非常高                |
| `THREAD_PRIORITY_TIME_CRITICAL` | +15  | 接近实时级别，慎用！⚠️ |

光设置线程优先级还不顶用，还得把进程的优先级也提高：

| 宏定义                        | 调度优先级类 |
| ----------------------------- | ------------ |
| `IDLE_PRIORITY_CLASS`         | 最低         |
| `BELOW_NORMAL_PRIORITY_CLASS` | 较低         |
| `NORMAL_PRIORITY_CLASS`       | 默认         |
| `ABOVE_NORMAL_PRIORITY_CLASS` | 稍高         |
| `HIGH_PRIORITY_CLASS`         | 高           |
| `REALTIME_PRIORITY_CLASS`     | 实时         |

**线程的实际优先级 = 基于类的基准 + SetThreadPriority 设置的偏移值**

### 调度机制
* Windows 使用 基于优先级的抢占式调度，每个 CPU 都有自己的就绪线程队列。
* 高优线程会立即抢占低优线程。
* 时间片（量子）随优先级调整：高优线程时间片更长。
* Windows 会根据线程是否频繁 I/O，是否长期阻塞等特征，临时提升优先级。
* 比如 GUI 线程收到输入事件后，其优先级会被短时间提高以提升响应性。
* 优先级提升后，系统会逐步衰减回原始值（优先级衰减）。

### 线程上下文切换

* 保存当前线程的执行状态（CPU 寄存器、栈指针、程序计数器等）
* 加载另一个线程的执行状态
* 修改调度队列和线程状态

好复杂，驱动开发才需要详细了解吧？

### 线程栈

默认大小1MB, 可以修改。线程栈地址可以通过!teb打印：
```shell
0:000> !teb
...
    Stack Base:  0019F000
    Stack Limit: 0019A000
```

### 结束线程

TerminateThread

## 进程

### 创建进程

| 方法                                 | 描述                                             |
| ------------------------------------ | ------------------------------------------------ |
| `CreateProcess`                      | 最底层、功能最全的方式。                         |
| `ShellExecute / ShellExecuteEx`      | 启动应用程序或打开文档（调用 `CreateProcess`）。 |
| `WinExec`（不推荐）                  | 老式API，已被淘汰。                              |
| 命令行调用（例如 system(), popen()） | 底层也调用 `CreateProcess`。                     |

我们重点讲解 CreateProcess 背后的原理。

CreateProcess 是创建子进程的最底层 API，它做了很多复杂的工作：

1️⃣ 解析可执行文件
* 解析 EXE 的 PE 头，找到入口地址（EntryPoint）和映像基址。
* 加载器将其映射到新的地址空间。

2️⃣ 创建新进程内核对象
* 分配并初始化内核对象 EPROCESS。
* 初始化其 PEB 和 TEB（主线程）。
* 创建新的页目录，为进程分配虚拟地址空间。

3️⃣ 创建主线程
* 创建一个新的线程对象 ETHREAD。
* 绑定到新进程。
* 设置初始栈，TEB 和栈空间。
* 初始化线程上下文（CS:EIP指向 EntryPoint）。

4️⃣ 复制父进程句柄表（如果指定了继承）
* bInheritHandles = TRUE 时复制句柄。

5️⃣ 通知调试器、附加 DLL
* 如果注册了调试器，会触发 CREATE_PROCESS_DEBUG_EVENT。
* 加载器调用所有模块的 DLLMain(DLL_PROCESS_ATTACH)。

6️⃣ 启动线程
* ResumeThread 让子进程主线程开始运行。

子进程不会自动继承父进程的上下文（线程、变量等），父子之间不共享堆栈或静态变量，但可以通过句柄、管道等IPC机制通信。

🎯 问题：CreateProcess 创建的进程什么时候才真正开始执行入口函数？

```shell
STARTUPINFO si = { sizeof(si) };
PROCESS_INFORMATION pi = {};
CreateProcess(..., CREATE_SUSPENDED, ..., &si, &pi);
```
* 子进程的地址空间、PEB、TEB、主线程、堆栈都已经创建完毕；
* 但主线程 并未运行，它处于“挂起”状态；
* 必须手动调用 ResumeThread(pi.hThread)，主线程才会开始运行，即跳转到 EntryPoint。即使你没有显式指定 CREATE_SUSPENDED，系统也会在内部在某一时刻控制线程“未立即运行”，然后在合适时机自动 resume。

| 点位                   | 状态说明                               |
| ---------------------- | -------------------------------------- |
| `CreateProcess` 返回前 | 子进程内核对象已创建，但线程不一定运行 |
| `ResumeThread` 调用后  | 主线程开始运行，执行 EntryPoint        |
| 所以入口函数执行点     | 是在 `ResumeThread` 调用之后           |

