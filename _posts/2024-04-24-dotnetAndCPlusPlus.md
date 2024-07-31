---
layout: mypost
title:  "C#调用C/C++"
date:   2024-04-24 19:13:17 +0800
categories: c#
location: HangZhou,China
description:
---
---

## StructLayout 属性

* Sequential, 顺序布局
* Explicit, 精确布局

主要是了解精确布局:

```c#
//需要用FieldOffset()设置每个成员的位置
这样就可以实现类似c的公用体的功能
[StructLayout(LayoutKind.Explicit)]
struct S1
{
  [FieldOffset(0)]
  int a;
  [FieldOffset(0)]
  int b;
}
```
这样a和b在内存中地址相同。


StructLayout特性支持三种附加字段：CharSet、Pack、Size
* CharSet定义在结构中的字符串成员在结构被传给DLL时的排列方式。可以是Unicode、Ansi或Auto。默认为Auto，在WINNT/2000/XP中表示字符串按照Unicode字符串进行排列，在WIN95/98/Me中则表示按照ANSI字符串进行排列。
* Pack定义了结构的封装大小, 可以是1、2、4、8、16、32、64、128或特殊值0(当前操作平台默认)
* Size定义了结构的绝对大小, 此字段必须为等于或大于总大小

转载自: https://blog.csdn.net/qq826364410/article/details/82743823

## 委托

转载自: https://www.cnblogs.com/SkySoot/archive/2012/04/05/2433639.html