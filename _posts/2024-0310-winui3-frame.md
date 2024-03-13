---
layout: mypost
title: WinUI3之页面导航
date:   2024-03-13 13:13:17 +0800
categories: WinUI3
location: HangZhou,China 
---
---


## Frame

微软的[文档](https://learn.microsoft.com/en-us/windows/windows-app-sdk/api/winrt/microsoft.ui.xaml.controls.frame?view=windows-app-sdk-1.5)说Frame是"展示Page，支持导航到新的Page，并且记录了导航的历史"。


先新建一个SettingPage
```xaml
<Page
    x:Class="fdesk.Settings"
    ...>
    <Grid>
        <TextBlock>hello,WinUI3</TextBlock>
    </Grid>
</Page>
```

按照微软文档说的, 给NavigationView添加一个Frame
```xaml
<NavigationView>
    <Frame x:Name="contentFrame"/>
</NavigationView>
```
现在我们可以用这个Frame来导航了
```c#
private void OnNavigationViewSelectionChanged(NavigationView sender, NavigationViewSelectionChangedEventArgs args)
{
    if (args.IsSettingsSelected)
    {
        // x:Name 就是成员名
        contentFrame.Navigate(typeof(Settings));
    }
}
```