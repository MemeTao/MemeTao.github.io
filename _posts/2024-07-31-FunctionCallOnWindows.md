---
layout: mypost
title: "函数调用与寄存器"
date:   2024-07-31 21:13:17 +0800
categories: windows
location: HangZhou,China
---
---

## 寄存器

32位操作系统的寄存器:
![alt text](image-1.png)

大部分EXE都是64位了, 这里只记录64的情况:

![alt text](image-2.png)

**MSVC使用RSP作为栈顶指针(注意栈的增长方向)。**

## 函数调用约定

![alt text](image-3.png)

C/C++代码默认使用__cdecl约定。x86的程序中, 参数的转递是靠栈, x64中参数的传递是靠寄存器, 只有当参数个数大于6时才回使用栈。

![alt text](image-4.png)


## 函数调用过程

```c++
class FunctionCall {
public:
    void foo(int a1, int a2, float f1, float f2, int a3, int a4, int a5) {
        std::printf("a1:%d, %d, %0.2f, %0.2f, %d, %d, %d\n", a1, a2, f1, f2, a3, a4, a5);
    }

private:
    int a_ = 0;
};

int main() {
    FunctionCall call;
    call.foo(1, 2, 3.0, 4.0, 5, 6, 7);
    return 0;
}

```

汇编代码解释：

```nasm
00007FF7DEB96E14  lea         rcx,[call]
00007FF7DEB96E19  call        FunctionCall::FunctionCall (07FF7DEB91299h)
00007FF7DEB96E1E  mov         dword ptr [rsp+38h],7  # 参数入栈, 注意入栈顺序
00007FF7DEB96E26  mov         dword ptr [rsp+30h],6
00007FF7DEB96E2E  mov         dword ptr [rsp+28h],5
00007FF7DEB96E36  movss       xmm0,dword ptr [__real@40800000 (07FF7DEB9B144h)]  # 浮点数放到xmm0-xmm3寄存器
00007FF7DEB96E3E  movss       dword ptr [rsp+20h],xmm0
00007FF7DEB96E44  movss       xmm3,dword ptr [__real@40400000 (07FF7DEB9B140h)]
00007FF7DEB96E4C  mov         r8d,2  #因为只有2个整形, 所以只用了edx和r8寄存器
00007FF7DEB96E52  mov         edx,1
00007FF7DEB96E57  lea         rcx,[call]   #取call变量的地址,也就是this指针的值到rcx寄存器
00007FF7DEB96E5C  call        FunctionCall::foo (07FF7DEB91294h) # call
```

### 函数栈帧

栈帧（Stack Frame）是每次函数调用时，在线程栈上为该函数分配的一块内存区域，用于存储该函数的局部变量、返回地址、参数、保存的寄存器等信息。

每调用一个函数，系统就会在栈上“推入”一个新的栈帧；函数返回时再“弹出”这个栈帧。

举个例子：C++ 函数调用过程
```cpp
int add(int a, int b) {
    int result = a + b;
    return result;
}

int main() {
    int sum = add(2, 3);
}
```
当 main() 调用 add(2, 3) 时，大致会发生：
* 当前 CPU 会记录返回地址（也就是 main() 中调用 add 的下一条指令）
* 系统会为 add() 在线程栈上开辟一个栈帧
* 函数参数 a = 2，b = 3
* 局部变量 result
* 保存调用者的一些寄存器（如 rbp、rsp、rdi）
* 当 add() 返回时：
* 弹出栈帧
* 恢复寄存器
* 程序回到 main() 中继续执行

栈帧通常包含哪些内容？
| 内容                           | 描述                               |
| ------------------------------ | ---------------------------------- |
| 返回地址（Return Address）     | 函数调用返回后，跳转到调用点的地址 |
| 上一个栈帧指针（Saved `rbp`）  | 用于恢复上一个函数的栈帧           |
| 函数参数（参数传递方式视架构） | 有的在栈中，有的在寄存器中         |
| 局部变量                       | 当前函数定义的变量                 |
| 临时寄存器保存区域             | 某些调用约定需要保存的寄存器       |
