---
layout: post
title:  "enable_shared_from_this 实现机制"
date:   2019-7-16 09:13:17 +0800
categories: c++
location: HangZhou,China 
description:  
---

```C++
template<typename T>
class shared_ptr{
public:
    shared_ptr<T>(T* t)
    {
        set_ptr(this,t);
    }
};

template<typename T>
class enable_shared_from_this{
public:
    shared_ptr<T> shared_from_this(){
        //if sp_ not null
        return sp_;
    }
private:
    shared_ptr<T> sp_; //FIXME:weak_ptr
};

template<typename T>
void set_ptr(shared_ptr<T> t, enable_shared_from_this<T>* e)
{
    e->set_ptr(t);
}

void set_ptr(...)
{
    //do nothing
}

class t: public enable_shared_from_this<t>{
public:
    t() = default;
};

```
