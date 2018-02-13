---
layout: post
title:  "Socket注意事项:非阻塞connect的返回值"
date:   2018-2-10 15:13:17 +0800
categories: network program 
location: HangZhou,China 
description:  
---
---

### 问题引入：
为了测试1S内TCP服务器单线程能accept多少并发TCP连接，由于正常的TCP建立可能需要几十毫秒，所以客户端发起的连接应该是这样子的:
```c++ 
bool connect()
{
    fd = socket(AF_INET,SOCK_STREAM | SOCK_NONBLOCK,0);//非阻塞connect
    res = connect(fd_,serverAddr,sizeof(struct sockaddr));
    return res == 0;
}
```
代码运行后，我发现connect()返回值一直是false，但是使用tcpdump抓包发现tcp三次握手正常，也就是说仅仅是connect函数的返回值不符合预期。

### 解决问题
我再一次翻开<<UNP>>，在书上发现：**当在一个非阻塞的TCP套接字上调用connect时，将立即返回一个EINPROGRESS错误，不过已经发起的TCP三路握手继续进行**，
这样问题就清晰了，修改代码如下：
```c++ 
bool connect()
{
    fd = socket(AF_INET,SOCK_STREAM | SOCK_NONBLOCK,0);//非阻塞connect
    res = connect(fd_,serverAddr,sizeof(struct sockaddr));
    return res == 0 || errno == EINPROGRESS ;
}
```
注:errno是线程安全的，每个线程都保留一份errno。
### 总结
**纸上得来终觉浅，绝知此事需躬行**

