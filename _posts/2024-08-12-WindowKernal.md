---
layout: mypost
title:  "Windows内核机制摘记"
date:   2024-08-12 21:13:17 +0800
categories: windows
location: HangZhou,China
description:
---
---

## Interrupt Request Level (IRQL)

修改IRQL:
```c++
KIRQL oldIrql; // typedefed as UCHAR
KeRaiseIrql(DISPATCH_LEVEL, &oldIrql);
// 
KeLowerIrql(oldIrql);
```

线程优先级是线程的属性, IRQL是"CPU核"的属性, 这里不能搞混。

## DPC (Deferred Procedure Call)

为了在高IRQL中调用"IoCompleteRequest"，DPC对象封装了一个"函数", 在这个"函数“中调用"IoCompleteRequest"。那为什么不能在ISR中主动降低IRQL呢？因为会造成死锁。
>> 当CPU执行完高级别任务后，就回来执行DPC（降低级别并执行？）。