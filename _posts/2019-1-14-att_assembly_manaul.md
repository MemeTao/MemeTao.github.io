---
layout: post
title:  "AT&T汇编"
date:   2019-01-14 17:13:17 +0800
categories: Linux
---

### 1. intel x86_64寄存器介绍
**通用寄存器**:

共有16个通用寄存器，如下图所示:
![generalRegister](../material/X86_64ASSEMBLY/general_register.png)

**Segment Register**:
* 1. CS:存放程序在内存中的基地址
* 2. DS:数据段地址(.data?)

<<Linux 0.11完全注释>>P90有关于这个的介绍

**指令指针寄存器(EIP)**
* 1. 远跳转:在分段模式下，当跳转到另一个段中的指令时
* 2. 短跳转:当跳转偏移量小于128字节时
* 3. 近跳转:除12外的所有其它跳转
**堆栈指针寄存器(ESP)**
* 0.指向栈顶
* 1.函数调用:通常和EBP一起配合使用

### 2. 函数
**声明函数**:
```c++
.type foo, @function
foo:
    pushl %ebp
    movl %esp, %ebp
    #code from here
    movl %ebp, %esp
    popl %ebp
    ret
```
堆栈情况:
![stackOverview](../material/X86_64ASSEMBLY/stack_overview.png)
### 2.链接器
一段程序包含.text .data .bss 段链接器会将所有的目标文件的这些段合并在一块。
![ldOverview](../material/X86_64ASSEMBLY/link_object.png)
### 3. 内存寻址
虚拟地址：[16][32] 16位段选择符、32位偏移地址

所有段可以有14^2个，段内偏移可以达到4G

![memory_addressing](../material/X86_64ASSEMBLY/memeory_addressing.png)

