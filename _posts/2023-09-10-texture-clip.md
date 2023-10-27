---
layout: mypost
title:  "D3D11 裁剪texture"
date:   2023-08-26 10:13:17 +0800
categories: graphics
location: HangZhou,China
description:
---
---

### 定义输入格式

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
注意, 顶点pos使用的是3D坐标系, tex使用的是纹理坐标系, 他们俩没有任何关系。 由于我们添加了纹理坐标, 所以每个顶点都有了自己的2D纹理坐标（即建立了3D->2D的映射关系, 仅此而已）

### 设置4个顶点

分别是 左上角、右上角、左下角、右下角。

```C++
VERTEX OurVertices[] = {
    {DirectX::XMFLOAT3{-1.0f, 1.f, 0.0f}, DirectX::XMFLOAT2(0.f,0.f)},
    {DirectX::XMFLOAT3{1.f, 1.f, 0.0f}, DirectX::XMFLOAT2(0.0f, 1.f)},
    {DirectX::XMFLOAT3{-1.f, 0.f, 0.0f}, DirectX::XMFLOAT2(0.0f, -1.f)},
    {DirectX::XMFLOAT3{1.f, 0.f, 0.0f}, DirectX::XMFLOAT2(1.f,1.f)}};
```

shader中定义输入、输出:

```HLSL
struct VInput{
    float4 pos : POSITION;
    float2 tex : TEXCOORD;
};
struct VOut {
    float4 pos : SV_POSITION;
    float2 tex : TEXCOORD;
};
```

### 设置ConstantBuffer

为了方便在shader中处理坐标, 设置我们要裁剪的范围:

```C++
struct ConstBuffer {
    DirectX::XMFLOAT2 offset;
    DirectX::XMFLOAT2 ratio;
};

bd = {0};
bd.ByteWidth = sizeof(ConstBuffer);
bd.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
bd.Usage = D3D11_USAGE_DEFAULT;
d3d11_dev_->CreateBuffer(&bd, nullptr, &const_buf_);
```
```HLSL
cbuffer ConstantBuffer : register(b0) {
    float2 offset;
    float2 ratio;
};
```

关于如何访问常量缓冲区中的成员: 当成全局变量。

### 设置SamplerState和ShaderReource
```C++
    D3D11_SAMPLER_DESC sd;
    RtlZeroMemory(&sd, sizeof(sd));
    sd.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
    sd.MaxAnisotropy = 8;
    sd.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP;
    sd.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP;
    sd.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
    sd.ComparisonFunc = D3D11_COMPARISON_NEVER;
    sd.MinLOD = 0.0f;
    sd.MaxLOD = D3D11_FLOAT32_MAX;
    auto hr = d3d11_dev_->CreateSamplerState(&sd, &sampler_state_);
    //...
    // tell the GPU which texture to use
    devcon->PSSetShaderResources(0, 1, texture.GetAddressOf());
```

在shader中这样使用它们:

```HLSL
    Texture2D tex : register(t0);
    SamplerState sampl : register(s0);
```

###  完整Shader

```HLSL
cbuffer ConstantBuffer : register(b0) {
    float2 offset;
    float2 ratio;
};

Texture2D texture1 : register(t0);
SamplerState sampler1 : register(s0);

struct VInput {
    float4 pos : POSITION;
    float2 tex : TEXCOORD;
};

struct VOut {
    float4 pos : SV_POSITION;
    float2 tex : TEXCOORD;
};

VOut VShader(VInput input) {
    VOut output;
    output.pos = input.pos;
    output.tex = input.tex;
    return output;
}

// 画个图好理解
float4 PShader(VOut input)
    : SV_TARGET {
    float x = input.tex.x * ratio.x + offset.x;
    float y = input.tex.y * ratio.y + offset.y;
    float2 pos = float2(x, y);
    return texture1.Sample(sampler1, pos);
}
```

注: 可以使用以下命令验证shader有没有手误

>> fxc.exe   /T fx_4_0 /Fo "output.fxo" "shaders.shader"