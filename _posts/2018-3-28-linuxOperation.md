---
layout: post
title:  "linux操作记录"
date:   2017-4-12 17:13:17 +0800
categories: linux 
location: HangZhou,China 
description:  
---
---

### 安装与卸载
* apt-get install xxx #安装xxx
* apt-get remove xxx  #卸载xxx
* apt-get update      #更新软件信息数据库 
* apt-get upgrade     #进行系统升级 
* apt-cache search    #搜索软件包 
### 文件查找
* 1. find / -name filename 
### 替换操作    
#### 语法为 :[addr]s/源字符串/目的字符串/[option]
```c++
[addr] //表示检索范围，省略时表示当前行。
//如:"1，20":表示从第1行到20行；
"%"://表示整个文件，同“1,$”；
".,$"://从当前行到文件尾；
s: //表示替换操作
[option]://表示操作类型
//如: g 表示全局替换; 
//c 表示进行确认
//p 表示替代结果逐行显示（Ctrl + L恢复屏幕）；
//省略option时仅对每行第一个匹配串进行替换；
//如果在源字符串和目的字符串中出现特殊字符，需要用”\”转义
```
### 统计代码行数
* 1.find ./ -name *.cpp | xargs wc -l
* 2.find ./ -name *.cpp | xargs wc -l | sort -n
### 常用shell

* 环境变量添加 1.echo export PATH=$(pwd):$PATH
* 进制xx服务开机启动:update-rc disable xx
