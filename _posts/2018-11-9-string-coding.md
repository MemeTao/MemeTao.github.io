---
layout: mypost
title:  "字符串编码"
date:   2018-11-08 17:13:17 +0800
categories: c++ 
location: Florence, Italy
description:
---
---

### 前言
一直以来，字符串编码总是我摸不着头脑。对待字符串编码问题的策略也是简单粗暴，直接规避：一律使用utf-8。但是，猿在码界漂，哪能不挨刀。今天就总结一下字符串编码问题。
### 编码类型介绍
#### ascii
编码格式花样很多。由于计算机是老美发明的，因此，最早只有127个字符被编码到计算机中，着127个字符被称为ascii编码集。由于ascii字符集只有127个字符，故只要一个字节就可以表示。

#### else
但是，世界上那么多国家、那么多语言，全世界人民都想体验一把先进文化，于是八仙过海，各显神通，日本把日文编码到Shift-jis中，韩国把韩文编码到Euc-kr中。我们国家陆续有gb2312、gbk、gb18030，后者都是对前者的扩展。拿我们汉字举例，汉字有成千上万个，所以一个字节表示不了那么多的汉字，所以就需要多个字节(2个或3个)来表示。
#### unicode
大家要是没有一套统一的编码格式的话，还怎么促进文化的交流、各国码农感情的培养。于是，unicode应运而生，unicode把所有语言都统一到一套编码中，这样大家就可以顺畅的交流了。为了表示那么多的语言，unicode也只能采用多字节表示法，就是一个字符用多个字节的数据表示。

于是，新的问题又出现了。对于大部分西方国家，他们使用的英语，一个字节就可以表示一个字符。如果使用unicode，那岂不是很浪费空间。于是又有人想出来了一种更佳妙的方式：对unicode继续编码。（可以理解成对unicode压缩编码）

也就说，utf-8,utf-16,utf-32是在unicode基础上，对unicode再次编码。

以UTF-8来说：UTF-8编码把一个Unicode字符根据不同的数字大小编码成1-6个字节，常用的英文字母被编码成1个字节，汉字通常是3个字节，只有很生僻的字符才会被编码成4-6个字节。如果你要传输的文本包含大量英文字符，用UTF-8编码就能节省空间：

| 字符 | ascii    | unicode                             | utf-8                      |
| :--  | :--      | :--------                           | :------------              |
| A    | 01000001 | 00000000 01000001                   | 01000001                   |
| 中   | ?        | 01001110 00101101  11100100 10111000| 10101101                   |


这么多编码格式，大家的一个共同点就是：完全对ascii码兼容。也就是说ascii中的'a'，和gb2312中的'a'是同样的表示方法(假设是0x63)。

### 实际环境
#### Linux
如果您是在linux上开发，通常是碰不到这些问题的。(没错，我就是舔狗)

在Linux上，系统默认就是utf-8格式。这是什么意思？

举例来说，当你 "touch main.cpp" 这个文件就是采用的utf-8来编码里面的所有数据。
当你
```c++
int main()
{
    const char* pstr = "中文ABC";
    printf("%s\n",pstr);
    return 0;
}
```
这个pstr中的内容就会以utf-8格式存储。
当你:
```shell
$ g++ main.cpp -o a.out
& ./a.out
```
编译器会忠于你的文件编码格式，按此编码格式处理该源文件。pstr中的内容会被取出来放在内存中，并以utf-8格式输出在终端环境上。终端能不能正常显示，就看你的终端能不能支持utf-8。

任何的字符串乱码问题，就是上面这三种中的某一个或多个编码格式不一样导致。
#### Windows
在windows上，呵呵呵了。中文windows默认采用gb2312格式。

举例来说。当你"新建一个文件"，这个文件通常是gb2312格式，如果这个文件只在本地使用，这时候通常是没问题的。

但是当你因为某些原因需要使用在windows上使用”unicode”，问题就来了。
还是以上面main.cpp为例：
* 1.如果main.cpp为gb2312，用vs编译，pstr为gb2312格式，终端可以显示。
* 2.如果main.cpp为纯unicode，用vs编译，pstr在内存里为gb2312格式，终端可以显示。
* 3.如果main.cpp为utf-8(无bom)，用vs编译，pstr在内存里为utf-8格式，但是终端显示不了中文。
* 4.如果main.cpp为utf-8(bom)，用vs编译，pstr在内存里为gb2312格式，终端可以显示。

看到了吧，vs的”睿智"。这个问题如果搭配上"wchar_t"，更加让人恼火。

上面的测试可以采用如下程序：
```c++
void foo(unsigned char* pstr,size_t size)
{
    for(size_t i = 0 ; i< size;i++)
    {
        printf("%x,",pstr[i]);
    }
    printf("\n");
}

int main()
{
    std::string str = "abc中文ABC";
    char* pstr = const_cast<char*> (str.c_str());
    foo((unsigned char*) pstr,sizeof str);

    std::wstring wstr = L"abc中文ABC";
    wchar_t* pwstr = const_cast<wchar_t*> (wstr.c_str());
    foo((unsigned char*) pwstr,sizeof str);

    return 0;
}
```
将结果和各个编码表进行对照，既可得出结论。

在unicode方面，对windows的批评滔滔不绝，"utf-8 everywhere"认为微软在字符串处理上误入歧途，因为他们比别的厂商更早做了决定。微软虽然有理由说，windows先于unicode问世。但是这么多年过去了，windows的API还是不完全支持unicode。

windows不遵守基本法，也不是一天两天了，嘻嘻。

关于如何在windows处理utf-8，以及对windwos的更多批评，可以从这篇文章起步: [utf8 everywhere](http://utf8everywhere.org/zh-cn#faq.almostfw) "
### char与wchar_t，string与wstring
如果您不幸遇到了string和wstring方便的困扰，恭喜您。

首先，std::string 和 std::wstring都继承与std::basic_string。
只不过std::string的模板参数是char，std::wstring的模板参数是wchar_t。
在linux上，wchar_t占用4个字节，windows上则是占用2个字节。他们之间的差别，**仅此而已。**

你如果使用wstring存放字符串，Linux是没有啥问题的，采用utf-32编码wstring。

但是如果是windows上，嘻嘻，问题又来了。假设在main.cpp中存放了一个std::wstring = "abc中文",那么：
* 1.a.cpp如果是gb2312格式，wstring在内存中是unicode格式。
* 2.a.cpp如果是unicode格式，wstring在内存中是unicode格式。
* 3.a.cpp如果是utf-8格式，wstring在内存中是ucs-2be格式。
* 4.a.cpp如果是utf-8-bom格式，wstring在内存中是unicode格式。

您肯定还有一个疑惑，**关于wstring和string之间的互相转换**。
那么，您需要确保你非常了解待转换的数据的格式，或者待转换数据仅来自本地。

在windows上，windows有一个奇技淫巧：

**WideCharToMultiByte系列API，通过参数设定你就可以获得你所希望的结果。**

详见windows api说明，如何正确使用，请看： [stackoverflow](https://stackoverflow.com/questions/215963/how-do-you-properly-use-widechartomultibyte)

当然，c++标准库也可以做到：std::locale、std::codecvt结合使用。

### 帮组文档

[utf8 everywhere](http://utf8everywhere.org/zh-cn#faq.almostfw)

[潜谈C/C++编程中的字符编码转换](https://blog.csdn.net/benkaoya/article/details/59522148)

[C++字符编码问题探究和中文乱码的产生](https://my.oschina.net/ybusad/blog/363139)

### 获得帮助
meemetao@gmail.com
