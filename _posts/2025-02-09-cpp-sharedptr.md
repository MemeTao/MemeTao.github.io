---
layout: mypost
title: "面试问题-实现cpp智能指针"
date: 2025-02-09 13:13:17 +0800
categories: c++
location: HangZhou,China
---
---

## UniquePtr

### 第一步

* 有个ptr指针
* 有构造函数和析构函数
```c++
template <typename T> class unique_ptr {
public:
    unique_ptr(T* ptr = nullptr)
        : ptr_(ptr) {}

    ~unique_ptr() {
        if (ptr_) {
            delete ptr_;
        }
    }

private:
    T* ptr_;
};
```
### 第二步

* 禁止拷贝和赋值运算符
* 支持移动构造
* 支持移动赋值运算发
```c++
    unique_ptr(const unique_ptr&) = delete;
    unique_ptr& operator=(const unique_ptr&) = delete;

    unique_ptr(unique_ptr&& other) noexcept : ptr_(other.ptr_) {
        other.ptr_ = nullptr;
    }

    unique_ptr& operator=(unique_ptr&& other) noexcept {
        if (ptr_) {
            delete ptr_;
        }
        ptr_ = other.ptr_;
        other.ptr = nullptr;
        return *this;
    }
```
出现问题了: **如果other==this? 所以需要判断一下是否就是自己**
```c++
if (this != &other) {
    delete ptr;
    ptr = other.ptr;
    other.ptr = nullptr;
}
```

### 第三步
* 解引用
* ->操作符

```c++
T* operator->() const { return ptr_; }
T& operator*() const { return *ptr_; }
```

## shared_ptr

```c++
template <typename T> class DefaultDeletor {
public:
    void operator()(const T* ptr) {
        if (ptr) {
            delete ptr;
        }
    }
};

template <typename T, typename Deleter = DefaultDeletor<T>> class shared_ptr {
public:
    shared_ptr(T* ptr = nullptr)
        : ptr_(ptr) {
        ref_ = new int64_t(1);
    }

    ~shared_ptr() { release(); }

    shared_ptr(const shared_ptr& other)
        : ptr_(other.ptr_)
        , ref_(ohter.ref_) {
        (*ref_)++;
    }

    shared_ptr& operator=(const shared_ptr& other) {
        if (this == ohter) {
            return;
        }
        ref_ = other.ref_;
        ptr_ = other.ptr_;
        (*ref_)++;
    }

    shared_ptr(shared_ptr&& other)
        : ptr_(other.ptr_) {
        ref_ = other.ref_;
        other.ptr_ = nullptr;
        other.ref_ = nullptr;
    }

    void reset(T* ptr) {
        release();
        ref_ = new int64_t(1);
        ptr_ = ptr;
    }

    void swap(shared_ptr& other) {
        std::swap(ptr, other.ptr);
        std::swap(refCount, other.refCount);
    }

    T* get() const { return ptr_; }
    T& operator*() const { return *ptr_; }
    T* operator->() const { return ptr_; }
    int64_t use_count() const { return *ref_; }

private:
    void release() {
        --(*ref_);
        if (ref_ == 0 && ptr_) {
            deleter(ptr_);
            delete ref_;
            ptr_ = nullptr;
            ref_ = nullptr;
        }
    }

private:
    T* ptr_ = nullptr;
    int64_t* ref_ = 0;
    Deleter deleter;
};
```

## weak_ptr

* 可以从 shared_ptr 构造，但不会增加引用计数。
* 不会影响资源的生命周期，weak_ptr 不会影响 shared_ptr 的引用计数。
* 可以检测资源是否存活，通过 expired() 判断 shared_ptr 是否仍然存在。
* 可以升级到 shared_ptr，使用 lock() 获取 shared_ptr（如果资源仍然存在）。
* 支持拷贝和赋值。

### 第一步
```c++
template <typename T>
class SharedPtr;

template <typename T>
class WeakPtr {
private:
    T* ptr;
    std::atomic<unsigned>* refCount;   // 强引用计数
    std::atomic<unsigned>* weakCount;  // 弱引用计数

public:
    // 默认构造
    WeakPtr() : ptr(nullptr), refCount(nullptr), weakCount(nullptr) {}

    // 允许从 SharedPtr 构造
    WeakPtr(const SharedPtr<T>& sp) noexcept
        : ptr(sp.ptr), refCount(sp.refCount), weakCount(sp.weakCount) {
        if (weakCount) {
            ++(*weakCount);
        }
    }
    WeakPtr(const WeakPtr& other) noexcept
        : ptr(other.ptr), refCount(other.refCount), weakCount(other.weakCount) {
        if (weakCount) {
            ++(*weakCount);
        }
    }
    WeakPtr& operator=(const WeakPtr& other) noexcept {
        if (this != &other) {
            release();
            ptr = other.ptr;
            refCount = other.refCount;
            weakCount = other.weakCount;
            if (weakCount) {
                ++(*weakCount);
            }
        }
        return *this;
    }
    void release() {
        if (weakCount && --(*weakCount) == 0) {
            delete weakCount;
        }
    }

    ~WeakPtr() {
        release();
    }

    bool expired() const {
        return !refCount || *refCount == 0;
    }

    SharedPtr<T> lock() const {
        return (expired()) ? SharedPtr<T>() : SharedPtr<T>(*this);
    }
};
```

### 第二步
修改shared_ptr以支持weak_ptr

```c++
    T* ptr;
    std::atomic<unsigned>* refCount;   // 强引用计数
    std::atomic<unsigned>* weakCount;  // 弱引用计数
```
```c++
 // 从 WeakPtr 构造
SharedPtr(const WeakPtr<T>& wp) noexcept
    : ptr(wp.ptr), refCount(wp.refCount), weakCount(wp.weakCount) {
    if (refCount && *refCount > 0) {
        ++(*refCount);
    } else {
        ptr = nullptr;  // 资源已释放
    }
}
```

## shared_from_this

关键的关键，需要在shared_ptr的构造函数中调用set_ref:
```c++
template <typename T>
class enable_shared_from_this {
protected:
    // 构造函数将 `shared_ptr` 管理的引用计数保存下来
    enable_shared_from_this() = default;
    ~enable_shared_from_this() = default;

public:
    // 获取一个指向当前对象的 shared_ptr
    std::shared_ptr<T> shared_from_this() {
        // 先验证是否已经由 shared_ptr 管理
        assert(refCount != nullptr && *refCount > 0);
        return std::shared_ptr<T>(this);  // 返回指向当前对象的 shared_ptr
    }

    // 共享对象时创建一个强引用计数
    void set_refCount(std::atomic<unsigned>* ref) {
        refCount = ref;
    }

private:
    std::atomic<unsigned>* refCount = nullptr;  // 用来跟踪引用计数
};
```
```c++
explicit SharedPtr(T* p = nullptr)
    : ptr(p), refCount(new std::atomic<unsigned>(1)) {
    if (ptr) {
        set_refCount(ptr, refCount);  // 将控制块传给对象
    }
}
```

那么，对于没有继承enable_shared_form_this的类怎么办呢？实现两套：
```c++
template<typename T>
void set_refCount(shared_ptr<T> t, enable_shared_from_this<T>* e)
{
    e->set_refCount(t);
}

void set_refCount(...)
{
    //do nothing
}
```