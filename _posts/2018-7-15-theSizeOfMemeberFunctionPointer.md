---
layout: mypost
title:  "C++成员函数指针的大小"
date:   2018-7-12 17:13:17 +0800
categories: c++ 
location: China,HangZhou
description: 
---
---

### c++中的函数指针(假定在64位机器上)

我们知道指针的大小恒定的,跟机器位数有关,32位机下,指针是4字节大小,64位机下指针是8字节大小.但是在C++中,有一个比较特殊的地方是C++的类成员函数
指针,它的大小是普通指针的2倍.先看一个实例:
```C++
void foo(void)
{
}
class A{
public:
    void foo(){}
}

int main()
{
    void (*pfun)(void);
    pfun = foo;
    void (A::*pMfun)(void);
    pMfun = &A::foo;
    std::cout<<"normal function pointer size:"<<sizeof(pfun)<<std::endl;
    std::cout<<"member function pointer size:"<<sizeof(pMfun)<<std::endl;
    return 0;
}
```
运行结果:
```shell
normal function pointer size:8
member function pointer size:16
```
证明完毕.下面解释为什么会这样.
### this指针的调整 

再看一个例子:
```C++
class A{
public;
    void foo()
    {
        //假设我们需要在这里去使用数组a
        std::cout<<"addr of this:%x"<<this<<std::endl;
    }
private:
    int a[4];
};
class B{
public:
    void bar()
    { 
        //假设我们需要在这里去使用数组b
        std::cout<<"addr of this:%x"<<this<<std::endl;
    }
prviate:
    int b[4];
};
class C: public A,B{

};

int main()
{
    C c; 
    c.foo();
    c.bar();
    return 0;
}
```
结果
```shell
addr of this:%x0x7ffd30f4ec00
addr of this:%x0x7ffd30f4ec10
```
这时候可以看到,传递给foo和bar函数的this指针是不一样的?为什么会不一样呢? 考虑一下函数中的注释.
所以调用类成员函数指针时,就需要将this指针进行调整,这个调整的信息在哪里?就在这个函数指针中,所以就需要另外的空间去存放这些信息,这也就是为什么类成员函数指针是16字节的原因,因为多出来的8字节,用于编译期的this指针调整.


