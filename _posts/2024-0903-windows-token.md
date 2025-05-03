---
layout: mypost
title:  "Windows访问权限控制"
date:   2024-09-03 22:13:17 +0800
categories: windows
location: HangZhou,China
description:
---
---

## 前言

在做windows桌面程序画面采集的时候经常会遇到"GPU打满, 普通进程获取不到GPU的调度机会, Dxgi\D3D11相关的API会发生上百ms的阻塞"。D3DK给了用户调整GPU调度优先级的API，但是在部分windows(不是少列)上调整优先级并不能生效，本文基于此背景探索一下windows权限控制的原理。

## OpenProcess

A进程
```c++
CreateWindow();
while (GetMessageW(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessageW(&msg);
    // using namespace std::chrono_literals;
    // std::this_thread::sleep_for(3000ms);
    LOG_INFO("Alive %s", (mlib::Timestamp::now() - t0).to_str().c_str());
}
```

B进程
```c++
::OpenProcess(Flag, false, process_a);
```
以普通权限启动A\B: 
| Flag      | Ret |
| ----------- | ----------- |
| PROCESS_QUERY_LIMITED_INFORMATION      | Y       |
| PROCESS_QUERY_INFORMATION   | Y        |
| PROCESS_CREATE_THREAD | Y |
| PROCESS_ALL_ACCESS | Y |

管理员启动A, 普通权限启动B:

| Flag      | Ret |
| ----------- | ----------- |
| PROCESS_QUERY_LIMITED_INFORMATION      | Y       |
| PROCESS_QUERY_INFORMATION   | N       |
| PROCESS_CREATE_THREAD | N |
| PROCESS_ALL_ACCESS | N |

管理员启动A, 普通权限启动B后提权:
```c++

```

| Flag      | Ret |
| ----------- | ----------- |
| PROCESS_QUERY_LIMITED_INFORMATION      | Y       |
| PROCESS_QUERY_INFORMATION   | N       |
| PROCESS_CREATE_THREAD | N |
| PROCESS_ALL_ACCESS | N |

## 访问控制模型

访问控制模型有两个主要的组成部分，访问令牌（Access Token）和安全描述符（Security Descriptor），它们分别是访问者和被访问者拥有的东西。通过访问令牌和安全描述符的内容，Windows可以确定持有令牌的访问者能否访问持有安全描述符的对象。

* 访问令牌（Access tokens）：包含了有关已登录用户的信息（与特定的windows账户关联）
* 安全描述符（Security descriptors）：包含了保护安全对象的安全信息（与被访问对象关联）

用户登录时，系统将创建一个访问令牌，用户通过使用令牌的副本去创建和访问进程。访问令牌包含安全标识符，包含：

* 标识用户帐户以及用户所属组
* 用户或用户组所拥有的权限列表

当进程尝试访问安全对象或执行需要特权的系统管理任务时，系统将使用此令牌来标识关联的用户是否拥有相应的权限。

### 安全对象

具有安全描述符的对象就是安全对象。window上的安全对象有：
* 进程、线程
* 文件、目录
* 服务
* 计划任务
* 互斥体
* 管道
* 油槽
* 文件共享
* 访问令牌
* 注册表
* 打印机
* 作业
* ...

创建安全对象后，系统会为其分配安全描述符，该描述符包含由其创建者指定的安全信息(未指定则为默认值)。应用程序可以使用函数来检索和设置现有对象的安全性信息。安全描述符标识指出对象的所有者，并且还可以包含以下访问控制列表：
* discretionary access control list（DACL）: 用于标识哪些用户和组对目标对象有访问权限
* system access control list（SACL）: 用于记录对安全对象访问的日志

ACL包含访问控制项（access control entries）（ACEs）的列表。每个ACE指定一组访问权限，并包含一个SID，用于标识其权限被允许、拒绝或审核的受托者。受托者可以是用户帐户、组帐户或登录会话。

Windows访问控制流程:
 > 当一个线程尝试去访问一个对象时，系统会检查线程持有的令牌以及被访问对象的安全描述符中的DACL。 如果安全描述符中不存在DACL，则系统会允许线程进行访问。如果存在DACL，系统会顺序遍历DACL中的每个ACE（ACE是ACL中一个一个的条目），检查ACE中的SID在线程的令牌中是否存在。以访问者中的User SID或Group SID作为关键字查询被访问对象中的DACL。顺序是：先查询类型为DENY的ACE，若命中且权限符合则访问拒绝；未命中再在ALLOWED类型的ACE中查询，若命中且类型符合则可以访问；以上两步后还没命中那么访问拒绝。

 ### 访问令牌（Access Token）

 与特定的windows账户关联，账户环境下启动的所有进程都会获得该令牌的副本，进程中的线程默认获得这个令牌，用于描述"安全上下文"。
 令牌中的信息包括与进程或线程关联的用户帐户的标识和特权信息。

 当线程与安全对象进行交互或尝试执行需要特权的系统任务时，系统使用访问令牌来标识用户。访问令牌包含以下信息：

* 用户帐户的安全标识符（SID）（关SID是什么后续章节会详细介绍）
* 用户所在组的SID
* 标识当前登录会话（logon session）的登录SID
* 用户或用户组拥有的特权列表
* 所有者SID
* 主要组的SID
* 用户创建安全对象而不指定安全描述符时系统使用的默认DACL
* 访问令牌的来源
* 令牌是主要令牌（内核分配的令牌）还是模拟令牌（模拟而来的令牌）
* 受限制SID的可选列表（如UAC存在时会针对某些账户删除某些特权）
* 当前的模拟级别
* 其他数据

产生AccessToken的过程:

* 使用凭据(用户密码)进行认证
* 当前登录会话的Session创建
* Windows此时会返回用户sid和用户组sid
* LSA(Local Security Authority)创建一个Token
* 依据该token创建进程、线程(如果CreaetProcess时自己指定了 Token, LSA会用该Token， 否则就继承父进程Token进行运行)

Access Token分两种：
* 主令牌（Primary token） 
* 模拟令牌（Impersonation token）， 在默认的情况下，当线程被开启的时候，所在进程的主令牌会自动附加到当前线程上，作为线程的安全上下文。而线程可以运行在另一个非主令牌的访问令牌下执行，而这个令牌被称为模拟令牌。而指定线程的模拟令牌的过程被称为模拟）

主令牌是由windows内核创建并分配给进程的默认访问令牌，每一个进程有一个主令牌，它描述了与当前进程相关的用户帐户的安全上下文。同时，一个线程可以模拟一个客户端帐户，允许此线程与安全对象交互时用客户端的安全上下文。一个正模拟客户端的线程拥有一个主令牌和一个模拟令牌。

### 安全描述符(Security Descriptors,SD)


安全描述符是与被访问对象关联的，它含有这个对象所有者的SID，以及一个访问控制列表（ACL，Access Control List），访问控制列表又包括了DACL（Discretionary Access Control List）和SACL（System Access Control List）以及一组控制位，用于限定安全描述符含义。

安全描述符可以包括以下安全信息：

* 对象的所有者和所属组的安全标识符（SID）
* DACL：它里面包含零个（可以为0，之后会有详细介绍）或多个访问控制项（ACE，Access Control Entry），每个访问控制项的内容描述了允许或拒绝特定账户对这个对象执行特定操作。
* SACL：主要是用于系统审计的，它的内容指定了当特定账户对这个对象执行特定操作时，记录到系统日志中。
* 一组控制位，用于限定安全描述符或其单个成员的含义
具体见: https://rootclay.gitbook.io/windows-access-control/er-an-quan-miao-shu-fu

### 访问控制列表

ACL包含两个东西:
* DACL
* SACL

DACL：自主访问控制列表(DACL)是安全描述符中最重要的，它里面包含零个或多个访问控制项（ACE，Access Control Entry），每个访问控制项的内容描述了允许或拒绝特定账户对这个对象执行特定操作。

SACL：系统访问控制列表（SACL） 主要是用于系统审计的，它的内容指定了当特定账户对这个对象执行特定操作时，记录到系统日志中。

### 参考链接

* https://www.cnblogs.com/cdaniu/p/15634485.html
* https://rootclay.gitbook.io/windows-access-control/1.-windows-fang-wen-kong-zhi-mo-xing