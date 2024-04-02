---
layout: mypost
title: WinUI3之容器布局
date:   2024-03-18 13:13:17 +0800
categories: WinUI3
location: HangZhou,China 
---
---

## StackPanel

```xaml
<Grid>
    <StackPanel>
        <TextBox Padding="50"/>
        <TextBox Width="100"/>
        <TextBox>margin="100"</TextBox>
    </StackPanel>
</Grid>
```

![alt text](stackpane-1.png)

注意，margin的格式 margin="left, top, right, bottom"