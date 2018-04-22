---
layout: post
title:  "webRtc预研结果"
date:   2018-4-22 17:13:17 +0800
categories: algorithm
location: HangZhou,China 
description:  
---
---

### webRtc简介
webRtc是google开源的chrome浏览器内置项目。
* 采用C++构建了底层API，为上层封装了JS API
* 支持p2p音频、视频、数据流传输能力
源码地址(需要翻墙)：https://chromium.googlesource.com/external/webrtc/

### webRtc信息交互过程
**无论是使用前端JS的WebRTC API接口，还是在WebRTC源码上构建自己的对聊框架，都需要遵循以下执行流程：**
![Process](../material/WEBRTC/frame.png)

最后建立的是一条点对点通道，用于传输数据。

在浏览器端，上述过程是**必须**执行的。

注,上图中:
* 1.signal Server:信令服务器，**必须由使用方自行实现**。
* 2.stun Server:内网穿透。
* 3.SDP:双方的编码方式、采样频率等信息


### 3.要集成到设备上需要做哪些事情

#### 3.1如果直接使用webRtc的现有源码(C++)
* 1.升级编译器，设备上目前是arm-linux-gcc4.4.0，需要升级到4.8.0以上版本以支持C++11。
* 2.整个webRtc项目的编译采用的是google的gn工具。如果要使用make，需要我们自行编写，必须要对代码结构、功能模块有熟悉的认识。
* 3.与对方协商，确定信令格式，以实现信令服务器。
* 4.如果浏览器方和设备不在同一局域网内，需要设置stun服务器。
* 5.暂时不确定webRtc编译后的所有.a文件大小，以及运行后所占内存大小。

#### 3.2不使用webRtc源码，自行模拟webRtc的通信流程

**要非常熟悉webRtc项目才行**
### 结论
* 1.技术上可行。
* 2.工作量非常大(webRtc项目本身很复杂)。
