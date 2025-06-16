---
layout: mypost
title:  "Windows中的内存一： 内存的分类"
date:   2025-04-20 11:13:17 +0800
categories: windows
location: HangZhou,China
description:
---
---

### 概要

此文记录windows中的内存分类

### VVMap 工具

有个事情是这样子的，程序临近发版突然发现V2版本的内存绝对值比V1版本增加了30MB。

各模块负责人都坚称自己的修改不会引入额外的内存，于是领导让我搞清楚是哪里占用了更多的内存。

用VMMap打开两个进程, 来观看两个进程的内存分布：

V1:
![V1](image.png)
V2:
![VV](image-1.png)

比较清晰的看到了V2版本的Image区域比V1版本多了46MB, 大概就是这个区域里面有个新增的dll影响了进程的内存大小（任务管理器中见到的）

对比这两个版本加载的dll, 发现V2比V1新增了一个nvoglv64.dll。

各个模块的同学很多时候可能是无意调用了第三方库导致了新dll的加载，他自己也不知道。必须要进一步确定这个dll是由哪段代码加载的才能找到相应的同学来排查。

Windbg加载V2进程并设置好PDB路径:

> lm #打印此时加载的dll列表发现没有这个nvoglv64.dll

> sxe ld:nvoglv64.dll #当这个dll加载时中断

> go #继续跑, 出现断点的时候打印函数栈就一目了然

### 内存分类

从VVMap看到内存分为了三大类：Committed、Private Bytes、Working Set.
从一个程序来分析（内存页4K）：
```c++
int main() {
    constexpr SIZE_T SIZE = 100 * 1024 * 1024; // 100 MB
    // Reserve address space, but do not commit yet
    void* ptr = VirtualAlloc(nullptr, SIZE, MEM_RESERVE, PAGE_READWRITE);
    std::cout << "Reserved only. Press Enter...\n";
    std::cin.get();

    if (!VirtualAlloc(ptr, SIZE, MEM_COMMIT, PAGE_READWRITE)) {
        std::cerr << "Commit failed: " << GetLastError() << "\n";
    }
    std::cout << "Committed. Press Enter...\n";
    std::cin.get();

    char* data = static_cast<char*>(ptr);
    for (size_t i = 0; i < SIZE; i += 4096)
        data[i] = 1;
    std::cout << "Accessed memory. Press Enter to exit...\n";
    std::cin.get();
    VirtualFree(ptr, 0, MEM_RELEASE);
    return 0;
}
```

从VVMap中可以明显观察到有个102,000KB的段从Reserve(Protection描述)变成了Read/Write（Commited）, 并且当对这个内存段进行写之后，Working Sets部分也会突然增大。

### MEM_RESERVE

预留地址空间以便将来使用，以下情况下会失败：
* 系统虚拟地址空间紧张（x86进程2GB限制）
* 试图保留一个不对齐或非法的地址
* 忘记释放旧的空间，反复 reserve 尽管没 commit，依然会耗尽虚拟地址空间

**只分配了地址和页表（PTE）,不分配物理内存、Pagefile空间，并且访问会触发异常Access Violation**

### Private

Private内存指的是只属于当前进程的内存区域，这些内存不与其他进程共享。一般来说，Private 内存是由进程自己的代码、堆、栈或者通过 VirtualAlloc 分配的内存所占用的。

#### 1. 私有且不共享：
* Private 内存是 进程独占的，不会被其他进程访问。
* 对它的修改只影响当前进程，不会影响其他进程。

#### 2. 不同于映射文件或共享内存：
* 如果是 映射文件（通过 CreateFileMapping + MapViewOfFile），内存区域会显示为 Mapped 类型，且这些内存区域是可共享的。
* Private 内存 只属于当前进程，不会被映射到其他进程的地址空间。

#### 3. 可以通过 MEM_COMMIT 或 MEM_RESERVE申请:
* 在 VirtualAlloc调用时，若申请的是Private内存区域，它会被标记为Private类型。
* 只要申请的是没有被其他进程共享的内存，它就是Private。

如何通过API来获取一个进程的内存分配信息:
```c++
SIZE_T GetPrivateCommittedMemory() {
    SIZE_T total = 0;
    MEMORY_BASIC_INFORMATION mbi = {};
    BYTE* addr = 0;

    while (VirtualQuery(addr, &mbi, sizeof(mbi)) == sizeof(mbi)) {
        if ((mbi.State == MEM_COMMIT) && (mbi.Type == MEM_PRIVATE)) {
            total += mbi.RegionSize;
        }
        addr += mbi.RegionSize;
    }

    return total;
}

```

### Working Set
Working Set是进程当前驻留在物理内存（RAM）中的、最近被访问过的虚拟内存页集合。

换句话说：
* Working Set ≠ 已分配的所有内存；
* 它只包含**当前加载在物理内存中且活跃使用的内存页**；
* Windows会动态调整 Working Set大小（增大或收缩），以满足系统的内存压力和进程活跃度。

**任务管理器中见到的内存就属于working set**

### malloc 和 new

注意到 VirtualAlloc分配的内存在VMMap里有明显的**Reserve**和**Commit**显示，但用 malloc 或 new 却看不到类似的现象。这是因为它们之间的本质差别在于：
| 特性                  | `VirtualAlloc`                       | `malloc` / `new`                             |
| --------------------- | ------------------------------------ | -------------------------------------------- |
| 调用层级              | 直接调用内核 API                     | 调用 CRT（C Runtime）堆管理器                |
| 目标                  | 分配整个虚拟内存页（通常4KB对齐）    | 管理小块内存、适配频繁分配释放               |
| Reserve/Commit 可见性 | 直接体现为 VAD（虚拟地址描述符）结构 | CRT 堆由一整块 VirtualAlloc 支撑，不暴露细节 |
| 是否可控内存属性      | 是（如 PAGE\_NOACCESS）              | 否，由 CRT 控制                              |
| 适合                  | 大内存、显式控制                     | 小块频繁分配                                 |


**malloc(size) ≠ VirtualAlloc(size)**

它的实际流程大致如下：
* malloc → 调用 CRT 的堆分配器（例如 Windows 上的 RtlAllocateHeap）；
* CRT 在初始化时使用 VirtualAlloc 创建了大块的 reserved+committed 区域；
*  malloc 在这个区域中管理小块（通过 free list 等结构）；
* 只有当分配超过一定阈值（如大于 1MB）时，才会直接使用 VirtualAlloc。

也就是说：**小块的 malloc 实际上是从某个已经提交的堆中“划出来”的，你看不到新的 commit/reserve 显示，因为那是堆的事，不是单个malloc的事**。

### 内存优先级（Memory Priority）

Memory Priority 是操作系统对进程或其内存页在内存中的“重要性”评估指标。Windows 会根据这个优先级，决定在内存压力大时，谁的页面先被驱逐出**Working Set**。优先级越低，越容易被回收。

## 虚拟内存地址空间

在 Windows x64 下，一个进程的虚拟地址空间划分为：
| 区域     | 范围                                               | 用途                   |
| -------- | -------------------------------------------------- | ---------------------- |
| 用户空间 | 0x00000000`00000000 ~ 0x00007FFF`FFFFFFFF（128TB） | 程序可用空间           |
| 内核空间 | 0xFFFF0800`00000000 ~ 0xFFFFFFFF`FFFFFFFF（128TB） | 内核使用空间，不可访问 |

默认使用4K大小为一页，每一页有几个状态:
| 状态      | 说明                                 |
| --------- | ------------------------------------ |
| Free      | 未分配                               |
| Reserved  | 保留地址空间（尚未使用物理内存）     |
| Committed | 实际申请了物理页（或 Pagefile 空间） |
| Mapped    | 映射文件内存                         |
| Guard     | 特殊保护页，用于栈扩展检测           |

当你访问一个未在物理内存中的虚拟页时，会触发：
| Page Fault 类型  | 说明                                     |
| ---------------- | ---------------------------------------- |
| Soft Page Fault  | 页面在 Pagefile 或被换出，加载即可       |
| Hard Page Fault  | 需要从磁盘读取数据                       |
| Access Violation | 地址无效或无权限，进程崩溃（0xC0000005） |

一个进程的地址空间大致如下：
```
低地址
↓
[code] [.data] [.bss] [heap --> ...] ............. [stack <--]
↑
高地址
```

### Windows 进程地址空间中主模块和 DLL 是如何被映射进内存的？

在一个 Windows 进程中，EXE文件和所依赖的DLL会以一种**映射文件**的方式被加载进虚拟地址空间。这个过程是操作系统通过**CreateProcess + LoadLibrary**等机制完成的。

| 类型          | 映射位置                    | 内容                    | 示例段                     |
| ------------- | --------------------------- | ----------------------- | -------------------------- |
| 主模块（EXE） | 较低地址（如 `0x00400000`） | 程序本体                | `.text`, `.data`, `.rdata` |
| DLL 模块      | 稍高地址（如 `0x7xxx0000`） | 静态/动态依赖库         | 同样有 `.text` 等段        |
| Mapped File   | DLL 通过内存映射进来        | 只读页、页保护          |                            |
| Stack         | 高地址向下                  | 每个线程一个栈          |                            |
| Heap          | 程序启动后分配              | 多个堆（默认 + 创建的） |                            |

### 加载时机
* 静态加载：EXE 启动时，系统 loader 会自动加载链接到的 DLL（来自 import table）
* 动态加载：代码中调用 LoadLibrary("xxx.dll")，系统会在调用点动态加载 DLL

不论哪种方式，本质上系统都会调用**NtMapViewOfSection**来将**DLL映射进进程的虚拟地址空间**。

### 寻找地址：系统如何决定 DLL 加载到哪里？
每个 DLL 都有一个默认的 ImageBase 地址（PE 头中定义）：
* 常见如：0x10000000、0x6xxxxxxx 等
* 可以通过/BASE:0x18000000 指定（或者默认生成）
![alt text](image-2.png)

加载过程如下：
* 1. Windows 首先尝试按 DLL 的默认 ImageBase 加载。
* 2. 如果那个地址已经被占用（比如其他 DLL 已加载在那里），就会：
* * 寻找一个附近的空闲地址段；
* * 加载 DLL 到那个地址；
* * 并进行 重定位（relocation）。

