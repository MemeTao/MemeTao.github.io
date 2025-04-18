---
layout: mypost
title:  "C++ 犄角旮旯"
date:   2023-06-17 11:13:17 +0800
categories: C++
location: HangZhou,China
description:
---
---

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
* https://www.cnblogs.com/QG-whz/p/4909359.html

### 左值和右值

不是很严谨的来说，左值指的是既能够出现在等号左边也能出现在等号右边的变量(或表达式)，右值指的则是只能出现在等号右边的变量(或表达式)。举例来说我们定义的变量 a 就是一个左值，而malloc返回的就是一个右值。或者左值就是在程序中能够寻值的东西，右值就是一个具体的真实的值或者对象，没法取到它的地址的东西(不完全准确)，因此没法对右值进行赋值，但是右值并非是不可修改的，比如自己定义的class, 可以通过它的成员函数来修改右值。

归纳一下就是：
* 可以取地址的，有名字的，非临时的就是左值。
* 不能取地址的，没有名字的，临时的，通常生命周期就在某个表达式之内的就是右值

详细见这个: https://www.cnblogs.com/david-china/p/17080072.html(重要)