---
layout: mypost
title:  "D3D11 缩放texture"
date:   2023-08-26 10:13:17 +0800
categories: graphics 
location: HangZhou,China 
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

### 设置SamplerState和ShaderReource
```C++
    D3D11_SAMPLER_DESC sd;
    sd.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
    sd.MaxAnisotropy = 8;
    sd.AddressU = D3D11_TEXTURE_ADDRESS_BORDER;
    sd.AddressV = D3D11_TEXTURE_ADDRESS_BORDER;
    sd.AddressW = D3D11_TEXTURE_ADDRESS_BORDER;
    sd.BorderColor[0] = 1.0f; // set the border color to white
    sd.BorderColor[1] = 1.0f;
    sd.BorderColor[2] = 1.0f;
    sd.BorderColor[3] = 1.0f;
    sd.MinLOD = 0.0f;
    sd.MaxLOD = FLT_MAX;
    sd.MipLODBias = 2.0f;
    auto hr = d3d11_dev_->CreateSamplerState(&sd, &sampler_state_);
    if (FAILED(hr)) {
        return false;
    }
    return true;
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

我们的目标很简单: 将texture1中的(x,y)填上texture2中的(x*scaling, y*scaling)的像素, 由于我们使用的SV_POSITION (齐次裁剪空间中的坐标值, -1<->1的范围), 因此"缩放"工作已经自动完成了
```HLSL
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

float4 PShader(VOut input)
    : SV_TARGET {
    return texture1.Sample(sampler1, input.tex);
}
```

注: 可以使用以下命令验证shader有没有手误

>> fxc.exe   /T fx_4_0 /Fo "output.fxo" "shaders.shader"