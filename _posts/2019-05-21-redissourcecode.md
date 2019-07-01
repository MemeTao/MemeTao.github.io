---
layout: post
title:  "redis摘记"
date:   2019-5-21 15:13:17 +0800
categories: redis 
location: HangZhou,China 
description:  
---
---

### redis源码阅读小笔记
* 1. 解决键冲突的时候，总是将新加入的node放到队首(O1复杂度)
