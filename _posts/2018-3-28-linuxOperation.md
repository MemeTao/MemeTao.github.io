---
layout: mypost
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

### 压缩、解压

**tar**
* -c: 建立压缩档案
* -x：解压
* -t：查看内容
* -r：向压缩归档文件末尾追加文件
* -u：更新原压缩包中的文件

这五个是独立的命令，压缩解压都要用到其中一个，可以和别的命令连用但只能用其中一个。下面的参数是根据需要在压缩或解压档案时可选的。

* -z：有gzip属性的
* -j：有bz2属性的
* -Z：有compress属性的
* -v：显示所有过程
* -O：将文件解开到标准输出

下面的参数-f是必须的

* -f: 使用档案名字，切记，这个参数是最后一个参数，后面只能接档案名。
 tar -cf all.tar *.jpg
> 这条命令是将所有.jpg的文件打成一个名为all.tar的包。-c是表示产生新的包，-f指定包的文件名。

* tar -rf all.tar *.gif
> 这条命令是将所有.gif的文件增加到all.tar的包里面去。-r是表示增加文件的意思。

* tar -uf all.tar logo.gif
> 这条命令是更新原来tar包all.tar中logo.gif文件，-u是表示更新文件的意思。

* tar -tf all.tar
> 这条命令是列出all.tar包中所有文件，-t是列出文件的意思

* tar -xf all.tar
> 这条命令是解出all.tar包中所有文件，-t是解开的意思

#### 压缩
* tar -cvf jpg.tar *.jpg //将目录里所有jpg文件打包成tar.jpg 
* tar -czf jpg.tar.gz *.jpg   //将目录里所有jpg文件打包成jpg.tar后，并且将其用gzip压缩，生成一个gzip压缩过的包，命名为jpg.tar.gz
* tar -cjf jpg.tar.bz2 *.jpg //将目录里所有jpg文件打包成jpg.tar后，并且将其用bzip2压缩，生成一个bzip2压缩过的包，命名为jpg.tar.bz2
* tar -cZf jpg.tar.Z *.jpg   //将目录里所有jpg文件打包成jpg.tar后，并且将其用compress压缩，生成一个umcompress压缩过的包，命名为jpg.tar.Z
* rar a jpg.rar *.jpg //rar格式的压缩，需要先下载rar for linux
* zip jpg.zip *.jpg //zip格式的压缩，需要先下载zip for linux

#### 解压
* tar -xvf file.tar //解压 tar包
* tar -xzvf file.tar.gz //解压tar.gz
* tar -xjvf file.tar.bz2   //解压 tar.bz2
* tar -xZvf file.tar.Z   //解压tar.Z
* unrar e file.rar //解压rar
* unzip file.zip //解压zip

解压jdk到指定文件夹：
> tar -xzvf jdk-8u131-linux-x64.tar.gz -C /usr/local/java

### 统计代码行数
* 1.find ./ -name *.cpp | xargs wc -l
* 2.find ./ -name *.cpp | xargs wc -l | sort -n
### 常用shell
* 环境变量添加 1.echo export PATH=$(pwd):$PATH
* 进制xx服务开机启动:update-rc disable xx
