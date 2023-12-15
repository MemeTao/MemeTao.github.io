---
layout: mypost
title:  "D3D11 渲染时评"
date:   2023-06-22 10:13:17 +0800
categories: graphics
location: HangZhou,China
description:
---
---

## 需求描述

正常的视频渲染需求, 另外要支持的功能:

* 1. 视频渲染
* 2. 支持旋转[ 90, 180, 270]
* 3. 镜像
* 4. Alpha 通道 (写代码时先不考虑)


## 过程

1. 填充yuv数据:
* 使用解码后的内存数据
* 使用解码后的纹理
这一步主要是将 TextureY 和 TextureUV填上。

2. 镜像

主要是矩阵变化

3. 旋转

主要是矩阵变化

4. alpha 通道, 这个比较好办

## 管线初始化

### 顶点

* 描述顶点坐标: 3D空间 (x,y,z)
* 描述texture坐标: 2D空间 (纹理坐标系:u, v)

```C++
struct VERTEX {
    DirectX::XMFLOAT3 pos;
    DirectX::XMFLOAT2 tex;
    static const D3D11_INPUT_ELEMENT_DESC input_desc[2];
}; // a struct to define a vertex

const D3D11_INPUT_ELEMENT_DESC VERTEX::input_desc[2] = {
    {"POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, D3D11_INPUT_PER_VERTEX_DATA, 0},
    {"TEXCOORD", 0, DXGI_FORMAT_R32G32_FLOAT, 0, 12, D3D11_INPUT_PER_VERTEX_DATA, 0},
};
```

### 旋转矩阵


### 镜像矩阵
