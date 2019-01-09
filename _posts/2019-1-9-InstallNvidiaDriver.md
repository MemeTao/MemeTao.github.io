---
layout: post
title:  "ubuntu18.04上安装英伟达驱动"
date: 2019-1-9 12:13:17 +0800
categories: Linux
location: Hangzhou, China 
description: fuck nvidia
---
---

### 1.查看显卡设备

```shell
#lspci 
00:02.0 VGA compatible controller: Intel Corporation HD Graphics 620 (rev 02)
302:00.0 3D controller: NVIDIA Corporation GM108M [GeForce 940MX]
```
一个是集成显卡,一个是独立显卡。点击”设置"-”详细信息”可以看到当前所使用的是哪一个显卡。

查看推荐的显卡驱动
```shell
# sudo ubuntu-drivers devices
== /sys/devices/pci0000:00/0000:00:1c.0/0000:02:00.0 ==
modalias : pci:v000010DEd0000134Dsv000017AAsd00002246bc03sc02i00
vendor   : NVIDIA Corporation
model    : GM108M [GeForce 940MX]
driver   : nvidia-driver-390 - distro non-free recommended
driver   : xserver-xorg-video-nouveau - distro free builtin
```
或者
```shell
#sudo add-apt-repository ppa:graphics-drivers
Current long-lived branch release: `nvidia-410` (410.66)
Old long-lived branch release: `nvidia-390` (390.87)
(不知道为啥，找不到410)
#sudo apt update
```
### 2.安装

```shell

#sudo apt-get install nvidia-390   //安装390驱动
#重启
#重启完就ojbk了

```


