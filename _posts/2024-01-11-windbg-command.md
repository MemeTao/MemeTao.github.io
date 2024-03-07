---
layout: mypost
title:  "Windbg 常用命令"
date:   2023-06-22 10:13:17 +0800
categories: windows
location: HangZhou,China
description:
---
---

## 排查野指针

前提: 开启Gflag全页堆

```c++
// 堆栈
VZVCamDshow!DllMain+0xd8d:
00007ffe`7270313d 8982d8000000    mov     dword ptr [rdx+0D8h],eax ds:00000267`e03d0fd8=????????
```
访问 00000267`e03d0fd8时crash, 先看一下这个地址的情况。

>> !address 00000267`e03d0fd8


```shell
Usage:                  PageHeap
Base Address:           00000267`e03cf000
End Address:            00000267`e03d2000
Region Size:            00000000`00003000 (  12.000 kB)
State:                  00002000          MEM_RESERVE
Protect:                <info not present at the target>
Type:                   00020000          MEM_PRIVATE
Allocation Base:        00000267`e0160000
Allocation Protect:     00000001          PAGE_NOACCESS
More info:              !heap -p 0x267fbcd1000
More info:              !heap -p -a 0x267e03d0fd8


```