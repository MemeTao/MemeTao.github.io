---
layout: post
title:  "总结c++中的cast"
date:   2019-3-11 12:13:17 +0800
categories: c++ 
location: HangZhou,China 
description:  
---
---

### 前言
此文算是一个notes，总结一下C++中的各类cast用法和原理。
### static_cast
**总结:反转一个定义良好的隐式类型转换**

> static_cast 执行关联类型之间的转换，比如一种指针类型向同一个类层次中其它指针类型的转换，或者整数类型向枚举类型的转换，或者浮点类型向整数类型的转换。它还能执行构造函数和转换运算符。

**同一类层次**

```C++
class B{
};
class D : public B{
}
```
B和D就叫做同一个类层次。
```C++
char* ptr_c = nullptr;
int* ptr_i = static_cast<int*>(ptr_c); //编译失败
B* ptr_b = new B();
D* ptr_d = ptr_b; //编译失败
D* ptr_d = static_cast<D*>(ptr_b); //fine
```
但是，down_cast是没有任何保证的，程序员必须明白会发生什么事情。

**整数类型向枚举类型的转换**
```C++
enum class E : uint8_t{
    kValue = 1
};
uint8_t v = E::kValue ; //编译失败
uint8_t v = static_cast<uint8_t>(E::kValue); //fine
```

### const_cast
const_cast<type>(expression)
> **参与转换的类型仅在const修饰符及volatile修饰符上有所区别**，除此以外new_type和expression的类型是一样。
* 常量指针被转化成非常量的指针，并且仍然指向原来的对象。
* 常量引用被转化成非常量的引用，并且仍然指向原来的对象。

### dynamic_cast
dynamic_cast<type*>(e) 执行指针或者引用向类层次体系的类型转换，并执行运行时检查。

不管是向上或者向下或者向左右都可以调用dynamic_cast。

对于upcast，可以但没必要，向上塑性直接写就完事儿了。

### reinterpret_cast
reinterpret_cast<type>(expression)

这玩意就用的比较少了，和static_cast不一样，只有以下情况可以使用reinterpret_cast:

* 1.表达式是整形、枚举、指针、或者成员指针
* 2.指针和整形互转
* 3.T1* 可以和 T2* 互转   
* 4.T1左值可以转化为T2引用
* 5.函数指针可以随便转，不用管类型。这里的函数指针包括类成员函数。
相对与static_cast的区别，有以下一个例子:

```C++
class A {
    public:
    int m_a;
};
class B {
    public:
    int m_b;
};
class C : public A, public B {};

C c;
printf("%p, %p, %p", &c, reinterpret_cast<B*>(&c), static_cast <B*>(&c));
```

    >前两个的输出值是相同的，最后一个则会在原基础上偏移4个字节，这是因为static_cast计算了父子类指针转换的偏移量，并将之转换到正确的地址（c里面有m_a,m_b，转换为B*指针后指到m_b处），而reinterpret_cast却不会做这一层转换。因此, 你需要谨慎使用 reinterpret_cast。

### static_pointer_cast

### dynamic_pointer_cast

### const_pointer_cast

### reinterpret_cast

总结上述4个:

```C++
template< class T, class U > 
std::shared_ptr<T> static_pointer_cast( const std::shared_ptr<U>& r ) noexcept
{
    auto p = static_cast<typename std::shared_ptr<T>::element_type*>(r.get());
    return std::shared_ptr<T>(r, p);
}

template< class T, class U > 
std::shared_ptr<T> dynamic_pointer_cast( const std::shared_ptr<U>& r ) noexcept
{
    if (auto p = dynamic_cast<typename std::shared_ptr<T>::element_type*>(r.get())) {
        return std::shared_ptr<T>(r, p);
    } else {
        return std::shared_ptr<T>();
    }
}

template< class T, class U > 
std::shared_ptr<T> const_pointer_cast( const std::shared_ptr<U>& r ) noexcept
{
    auto p = const_cast<typename std::shared_ptr<T>::element_type*>(r.get());
    return std::shared_ptr<T>(r, p);
}

template< class T, class U > 
std::shared_ptr<T> reinterpret_pointer_cast( const std::shared_ptr<U>& r ) noexcept
{
    auto p = reinterpret_cast<typename std::shared_ptr<T>::element_type*>(r.get());
    return std::shared_ptr<T>(r, p);
}
```
