---
layout: mypost
title:  "D3D11 坐标变换"
date:   2023-06-22 10:13:17 +0800
categories: graphics 
location: HangZhou,China 
description:  
---
---


 
## World Transformation

旋转
![raster](rotation.jpg)
![rotaion](rotation.jpg)

缩放

![scaling](scaling.jpg)

## View Transformation

世界坐标下的摄像机位置:

![view1](!viewTransformation1.jpg)

根据摄像机位置转换坐标:

![view1](!viewTransformation2.jpg)

## Projection Transformation

从摄像机视野转变为屏幕视野:

![view1](!screenTransformation.jpg)

以上的转换都是针对顶点坐标而言!