---
layout: mypost
title:  "Compute Shader (D3D11)"
date:   2025-06-21 10:13:17 +0800
categories: graphics
location: HangZhou,China
description:
---
---

### ✅ 什么是线程组（Thread Group）？

在 Compute Shader 中，一个 Dispatch 调用会启动大量 GPU 线程，这些线程被组织成若干个“线程组”（Thread Group，有时也叫 工作组 workgroup）。

    可以理解成：
    ➤ 每个线程组就像是一个小团队（block）
    ➤ 每个线程是团队里的一个成员（thread）
    ➤ GPU 同时运行多个线程组，线程组内部又并行运行多个线程

### 🧠 示例：线程组的定义方式

在 HLSL 的 Compute Shader 中，你通过 numthreads(x, y, z) 来定义线程组的结构：
```hlsl
[numthreads(8, 8, 1)]
void CSMain(uint3 DTid : SV_DispatchThreadID)
{
    // 这是一个 8×8 的线程组，总共 64 个线程
}
```

🔧 接下来由 CPU 发起执行：

```cpp
context->Dispatch(32, 32, 1);
/*
这表示：一共创建 32×32×1 = 1024 个线程组
每个线程组内部有 8×8×1 = 64 个线程
所以总共启动了 1024 × 64 = 65536 个线程！
*/
```
🎯 每个线程都有三个 ID：

| ID 名称               | 含义                                          |
| --------------------- | --------------------------------------------- |
| `SV_DispatchThreadID` | 全局线程 ID（所有线程中的唯一编号）           |
| `SV_GroupID`          | 当前线程组的 ID（每组一个）                   |
| `SV_GroupThreadID`    | 当前线程组内的线程编号（组内唯一）            |
| `SV_GroupIndex`       | 当前线程在线性编号下的位置（等于 flat index） |

可以用这些 ID 来决定当前线程应该处理哪一段数据，比如：
```hlsl
[numthreads(16, 16, 1)]
void CSMain(uint3 DTid : SV_DispatchThreadID)
{
    // DTid.x 和 DTid.y 表示我要处理的图像像素坐标
}

```

## 🚀 对应的硬件资源 —— GPU 的执行模型

### 🧱 一、需要掌握的几个核心硬件概念

### 1. SM（Streaming Multiprocessor） GPU 中的计算核心单元

👉 每个 SM 相当于一个“调度器”，可以调度多个线程组（Thread Groups）

### 2. Warp

* GPU 的最小调度单位，是一组 32 个线程
* 每次执行指令，一个 Warp 的所有线程一起执行同一条指令（SIMD，单指令多数据）
* 所以我们定义的线程数必须“考虑对齐 Warp 大小”，才能避免浪费执行单元


### ✅ 二、线程组和 Warp 的关系图（关键！）

比如我写了：

```hlsl
[numthreads(16, 16, 1)] // = 256 个线程
```

| 项目                | 说明                                          |
| ------------------- | --------------------------------------------- |
| 每个线程组包含      | `256` 个线程                                  |
| 每个 Warp 32 个线程 | 所以线程组会拆成 `256 / 32 = 8` 个 Warp       |
| GPU 执行时          | 把这 8 个 Warp 安排到一个 SM（或多个 SM）执行 |


### 语义

| 语义名                | 类型    | 说明                                                  |
| --------------------- | ------- | ----------------------------------------------------- |
| `SV_DispatchThreadID` | `uint3` | 当前线程在整个 Dispatch 网格中的绝对坐标（常用）      |
| `SV_GroupID`          | `uint3` | 当前线程组的坐标（就是 Dispatch 时传的 x/y/z）        |
| `SV_GroupThreadID`    | `uint3` | 当前线程在线程组内的索引（即 \[0..numthreads-1]）     |
| `SV_GroupIndex`       | `uint`  | 当前线程在线程组中展开为线性索引（0 到 numthreads-1） |

DispatchThreadID 如何计算：
```hlsl
uint3 DTid = GroupID * numthreads + GroupThreadID;
```

| 语义                  | 类型    | 含义                     | 范围由什么决定                | 典型用途               |
| --------------------- | ------- | ------------------------ | ----------------------------- | ---------------------- |
| `SV_DispatchThreadID` | `uint3` | 全局线程 ID              | `Dispatch()` × `numthreads()` | 图像处理 / 全局计算    |
| `SV_GroupID`          | `uint3` | 当前线程所属线程组索引   | `Dispatch(x, y, z)`           | 分块、组间协作         |
| `SV_GroupThreadID`    | `uint3` | 当前线程在组内的本地索引 | `[numthreads(x, y, z)]`       | `groupshared` 协作计算 |
| `SV_GroupIndex`       | `uint`  | 当前线程在组内的线性索引 | `[0, numthreads_total-1]`     | 一维访存/并行归约等    |
