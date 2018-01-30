---
layout: post
title:  "TCP缓冲区与write系统调用"
date:   2018-1-29 15:13:17 +0800
categories: network program 
location: HangZhou,China 
description:  
---
---

### 背景：
在非阻塞多线程TCP网络编程中，设想一个场景:

> 程序A想通过TCP连接发送100KB的数据,我们通过系统调用write()来写入数据。因为我不希望程序长时间阻塞在write()，我希望操作系统迅速将我的100KB数据放入TCP缓冲区，然后write()系统调用返回，内核自动将我们的100KB数据通过TCP发送出去。这里不经有个疑问:TCP缓冲区可以放下我的100KB数据么？

以上的*TCP缓冲区*我故意描述的比较有歧义，网上很多关于TCP缓冲区大小的资料都有一定的误导。首先查阅Linux man手册：
>   SO_SNDBUF----------------
          Sets or gets the maximum socket send buffer in bytes.  The
          kernel doubles this value (to allow space for bookkeeping
          overhead) when it is set using setsockopt(2), and this doubled
          value is returned by getsockopt(2).  The default value is set
          by the /proc/sys/net/core/wmem_default file and the maximum
          allowed value is set by the /proc/sys/net/core/wmem_max file.
          The minimum (doubled) value for this option is 2048.

我随即查看我的电脑上的配置
```java 
运行结果：
$ cat /proc/sys/net/core/wmem_default (套接字缓冲区大小-写)
212992 
$ cat /proc/sys/net/ipv4/tcp_wmem   
4096	16384	4194304          min/default/max 

```
为了确认这些数据，我在自己电脑上用以下程序做了实验:
```c++ 
//#include some head file
int main()
{
    int optval = 0;
    socklen_t optlen = sizeof(optval);
    int fd = ::socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
    int err = ::getsockopt(fd,SOL_SOCKET,SO_SNDBUF,&optval,&optlen);
    if(err != 0)
        std::cout<<"error"<<std::endl;
    else
        std::cout<<"val:"<<optval<<std::endl;
    return 0;
}
```
结果是16384。

为什么我程序输出的却是/pro/sys/ipv4/tcp_wmen的默认值呢？我迷惑了，难道是Linux man 手册说错了?

这是网上相当多博客最大的误解，有人将其看作是TCP缓冲区大小，有人将其看作是TCP发送窗口大小。

后来我在IBM的文档中找到了这么一行:
>   /proc/sys/net/ipv4/tcp_wmem	 4096 16384 131072	
-----为自动调优定义每个 socket 使用的内存。第一个值是为 socket 的发送缓冲区分配的最少字节数。第二个值是默认值（该值会被 wmem_default 覆盖），缓冲区在系统负载不重的情况下可以增长到这个值。第三个值是发送缓冲区空间的最大字节数（该值会被 wmem_max 覆盖）。

我彻底明白了，每当我们新建一个socket，Linux内核认为大多数时候我们并不会用到如此之大的socket缓冲区，为了内存方面的考虑，所以用16384 = 16KB作为优化值。当我们的数据大于16KB时，是会自动往上增加的，一直到/pro/sys/net/wmem_default,也就是212992 = 208KB。
看到这里，有人会有疑问，也是我在网上搜索资料时遇到的误解:**滑动窗口最大才2^16 = 65536 = 64KB，你这208KB怎么还比64KB大了？**
为此我又重新翻阅了一下<<TCP/IP VO.1>>
> 就 window scaling 来说，TCP 最初可以支持最大为 64KB 的窗口（使用 16 位的值来定义窗口的大小）。采用 window scaling（RFC 1323）扩展之后，您就可以使用 32 位的值来表示窗口的大小了。GNU/Linux 中提供的 TCP/IP 栈可以支持这个选项（以及其他一些选项）。提示：Linux 内核还包括了自动对这些 socket 缓冲区进行优化的能力（请参阅下面 表 1 中的 tcp_rmem 和 tcp_wmem），不过这些选项会对整个栈造成影响。如果您只需要为一个连接或一类连接调节窗口的大小，那么这种机制也许不能满足您的需要了。

那么我的电脑上有没有这所谓的window scaling呢？
```java 
运行结果：
~$ cat /proc/sys/net/ipv4/tcp_window_scaling
1   
```
有的。依稀记得好像有这么一句化：当前的以太网带宽发展很快，以前的双绞线10MB以太网现在已经发展到千兆以太网，所以16位的窗口值在一些场合已经不适用了。

##### 用一个例子来理解一下上面所说的概念:socket缓冲区大小
举个小例子：
> 当我们建立一个socket的时候，内核自动给我分配的是16KB的缓存区,假设程序有100KB数据，我们调用write(fd,data)将数据写入的是套接字缓冲区，由于100KB > 16KB ，缓冲区自动增大，由于100 < 208 故，操作系统将数据从用户态拷到内核缓存区后，write系统调用就返回了，然后TCP从该缓冲区中取数据，TCP得搬运好多次，但是这都是内核的事情，我们管不着。如果数据是209KB，很显然，write()调用势必要阻塞了，阻塞到什么时候?我的理解是,阻塞到TCP将多余的1KB发送出去，并收到回复。(例子可能不是很恰当,如果有不明确的自己google吧)

这下我放心了，100KB是可以放下的。但是我不免有点后怕，我并不确定我的程序到底会有多大的数据,如果下次我们数据是250KB怎么办？我并不想程序阻塞在这里，我得尽快抽身去忙活其它紧急的事情，那该怎么办呢？往下看。

### 如何解决write调用阻塞的问题？

* 1.**将accept返回的已连接TCP套接字设置成non-blocking** ------ 比方我要写100KB，假设内核只接收了64KB,这时候,write写了64KB之后会返回,程序不会阻塞在这里，而是继续运行。那么又会引入另一个问题,**剩余的36KB数据怎么办？**
* 2.**在程序中引入应用层缓冲区**------对于应用程序来说,我只管产生数据,并调用sendMessage()函数,你最终要分几次发送我不管,但是你不能阻塞我。具体做法是,封装sendMessage()函数:
> 判断write函数的返回值,将剩余的数据丢给Buffer,注册POLLOUT事件,等到对应的fd可读时，再将数据写入。这时候还有*第二点好处*,当buffer有多余数据时，我们可以判断出socket缓冲区已经满了，我们不要调用write(),而是应该将数据添加到buffer中统一写入，这样做好处是什么：**省了一次系统调用,岂不是美滋滋!**  

### 如何确定要多大的socket缓冲区，是不是越大越好？

IBM是这么说的,*[click heare link to IBM!](https://www.ibm.com/support/knowledgecenter/en/SSQPD3_2.6.0/com.ibm.wllm.doc/UDPSocketBuffers.html)*

> On the Linux platform Tx ring buffer overruns can occur when transmission rates approach 1Gbps and the default send socket buffer is greater than 65536. It is therefore recommended to set the net.core.wmem_default kernel parameter to 65536 bytes on all Linux systems.

也就说在千兆以太网上，为了避免产生TX环形缓冲区溢出，我们最好将core/net/wmem_default设置成小于65536,也即64KB的一个值。但是这可是占内存的，如果我们给每一个socket都设置64KB，不考虑虚拟内存,假设机器内存是4GB，4GB / 64 KB = 16K，也即理论上在4G机器上，我们最多连接16K个TCP连接，这当然是不能接收的。所以这个问题要用毛泽东思想来解决：具体问题具体分析！

### 如何确定应用层Buffer的大小？

同样，这也是占内存的,我们不能过大也不能过少，这看起来好像也无解。

这里推荐一个**[Muduo网络库](https://github.com/chenshuo/muduo)**的做法:动态增长。具体做法是，给每个Buffer初始分配1024B字节，并在栈上分配一个65536字节的数组。
* 读取：使用readv,buffer作为第一个地址，数组作为第二个地址，这样超过1024的数据全都读到了数组上，等读取结束在将buffer扩增，将数组内的数据追加到buffer。
* 写入：比较简单，判断一下长度即可。

这样做利用了临时栈上空间，避免每个连接的初始Buffer过大造成内存浪费，也避免反复调用read()的系统开销。
