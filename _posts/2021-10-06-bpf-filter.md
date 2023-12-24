---
layout: mypost
title: bpf filter code 解释
date:   2021-10-06 13:13:17 +0800
categories: network
location: HangZhou,China 
---
---

### 背景

在linux下编写网络包过滤程序的时候，希望内核只投递指定规则的报文。

### 概要

主要是记录如何分析bpf filter的规则码。

### tcpdump 生成bpf code

```shell
tcpdump -i lo ip and udp and dst port 65500 -d 
```
如下:

``` asm
(000) ldh      [12]                             # 加载第12字节的word
(001) jeq      #0x800           jt 2	jf 10   # 判断是否是ipv4, 分别跳转到2 或 10
(002) ldb      [23]                             # 加载23字节
(003) jeq      #0x11            jt 4	jf 10   # 判断是否是udp(17), 分别跳转
(004) ldh      [20]                             # 加载第20字节的word
(005) jset     #0x1fff          jt 10	jf 6    # 分析是否出现了 frament(分包)
(006) ldxb     4*([14]&0xf)                     # 计算ip头部长度
(007) ldh      [x + 16]                         # 取ip后的第16字节(word), udp源端口
(008) jeq      #0xffdc          jt 9	jf 10   # 判断源端口是否是65500
(009) ret      #262144                          # match
(010) ret      #0                               # discard
```
通过 -dd 参数产生具体的struct sock_filter结构的数据:
```shell
tcpdump -i lo ip and udp and dst port 65500 -dd
```

### 注意点

创建raw socket的时候需要指定收包是从数据链路层开始，还是从ip开始。

使用上述的规则码的时候，必须是从数据链路层开始，即:
> 	int fd = ::socket(PF_PACKET, SOCK_RAW , htons(ETH_P_IP));

如果
> 	int fd = ::socket(PF_PACKET, SOCK_DGRAM , htons(ETH_P_IP));

那么就需要自行修改这个规则码，将所有的"地址" 减去 14（一般来说是以太网，以太网帧头部长14字节）.

知道了上述规则后，就具备了修改code的能力。
