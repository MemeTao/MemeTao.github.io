---
layout: post
title:  "webrtc接收端jitter公式推导"
date:   2021-05-14 14:13:17 +0800
categories: webrtc
location: HangZhou,China 
description:  
---
---


### 卡尔曼增益简单介绍及推导

> 有一把尺子测量一枚硬币的直径, 记录每次测量出的结果:$x_1$, $x_2$, $x_3$, ....

那么, 对硬币直径的估计值:

> $\overline{\text{x}}_n$ = ($x_1$+$x_2$+$x_3$+...+$x_n$) / n

进一步, 写成递归形式:

> $\overline{\text{x}}_n$ = ($x_1$+$x_2$+$x_3$+...+$x_n$) / n
