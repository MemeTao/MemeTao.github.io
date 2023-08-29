---
layout: mypost
title:  "C++ 犄角旮旯"
date:   2023-06-17 11:13:17 +0800
categories: C++
location: HangZhou,China
description:
---
---

## 神魔问题

我真是服了噢, C++面试现在怎么是这个样子的，问的都是一些"神魔"的问题。

### 构造函数可以调用虚函数么

可以, 但是没有意义。进入基类就是调用的基类函数, 进入子类就是子类的函数

### 析构函数可以调用虚函数么

可以, 同上。

### 多继承的"缩型"问题

### 多继承的虚函数表

## 有意义的问题
### volatile 真正的作用
https://zhuanlan.zhihu.com/p/33074506

### 多继承

地址的关系:

```c++
class A {
public:
    int a = 0x01;
};

class B {
public:
    int b = 0x02;
};

class C : public A, public B {
public:
    int c = 0x03;
};

C c;
A* p_a = &c;    // p_a 指向起始地址
B* p_b = &c;    // p_b 指向p_a + sizoef(int)

A* pa = new C;
B* pb = new C;  // 地址所指向的内容是一样的

```

虚函数与虚函数表(重要):

* https://blog.csdn.net/qq_36359022/article/details/81870219
