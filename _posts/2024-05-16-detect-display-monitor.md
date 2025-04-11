---
layout: mypost
title:  "显示器插拔通知"
date:   2024-05-16 10:13:17 +0800
categories: windows
location: HangZhou,China
description:
---
---

## 向windows注册显示器设备事件

GUID 是固定的, 可以从微软文档查到
```c++
static GUID monitor_guid = {
    (unsigned long)0xE6F07B5F, (unsigned short)0xEE97, (unsigned short)0x4a90, (unsigned char)0xB0,
    (unsigned char)0x76,       (unsigned char)0x33,    (unsigned char)0xF5,    (unsigned char)0x7B,
    (unsigned char)0xF4,       (unsigned char)0xEA,    (unsigned char)0xA7};

// For informational messages and window titles.
PWSTR g_pszAppName;

BOOL DoRegisterDeviceInterfaceToHwnd(IN GUID InterfaceClassGuid, IN HWND hWnd,
                                     OUT HDEVNOTIFY* hDeviceNotify) {
    DEV_BROADCAST_DEVICEINTERFACE NotificationFilter;

    ZeroMemory(&NotificationFilter, sizeof(NotificationFilter));
    NotificationFilter.dbcc_size = sizeof(DEV_BROADCAST_DEVICEINTERFACE);
    NotificationFilter.dbcc_devicetype = DBT_DEVTYP_DEVICEINTERFACE;
    NotificationFilter.dbcc_classguid = InterfaceClassGuid;

    *hDeviceNotify =
        RegisterDeviceNotification(hWnd,                       // events recipient
                                   &NotificationFilter,        // type of device
                                   DEVICE_NOTIFY_WINDOW_HANDLE // type of recipient handle
        );
    if (NULL == *hDeviceNotify) {
        return FALSE;
    }

    return TRUE;
}
```

## 处理PDEV_BROADCAST_HDR消息

```c++
bool onDeviceChanged(WPARAM wParam, LPARAM lParam) {
    PDEV_BROADCAST_HDR lpdb = (PDEV_BROADCAST_HDR)lParam;
    switch (wParam) {
    case DBT_DEVICEARRIVAL:
    {
        auto devicetype = lpdb->dbch_devicetype;
        if (devicetype == DBT_DEVTYP_DEVICEINTERFACE) {
            auto* lptr = (PDEV_BROADCAST_DEVICEINTERFACE)lParam;
            lptr->dbcc_name;
            return true;
        }
        break;
    }
    case DBT_DEVICEREMOVECOMPLETE:
    {
        auto devicetype = lpdb->dbch_devicetype;
        if (devicetype == DBT_DEVTYP_DEVICEINTERFACE) {
            auto* lptr = (PDEV_BROADCAST_DEVICEINTERFACE)lParam;
            lptr->dbcc_name;
            return true;
        }
    } break;
    default:
        break;
    }
    return false;
}

// this is the main message handler for the program
LRESULT CALLBACK WindowProc2(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
    static HDEVNOTIFY hDeviceNotify;
    static HWND hEditWnd;
    static ULONGLONG msgCount = 0;
    // sort through and find what code to run for the message given
    switch (message) {
    case WM_CREATE:
        DoRegisterDeviceInterfaceToHwnd(monitor_guid, hWnd, &hDeviceNotify);
        break;
    case WM_DEVICECHANGE:
        if (onDeviceChanged(wParam, lParam)) {
            return 0;
        }
        break;
    case WM_DESTROY:
        // close the application entirely
        PostQuitMessage(0);
        return 0;
        break;
    }
    return DefWindowProc(hWnd, message, wParam, lParam);
}

```

这里获取的dbcc_name可以和这个device_name对比:

```c++

for (int i = 0;; i++) {
    char buf[1024] = {0};
    if (!GetMonitorInfo(i, buf)) {
        break;
    }
}

BOOL GetMonitorInfo(int nDeviceIndex, LPSTR lpszMonitorInfo) {
    DISPLAY_DEVICE DispDev = {0};
    DispDev.cb = sizeof(DISPLAY_DEVICE);
    if (!EnumDisplayDevices(nullptr, nDeviceIndex, &DispDev, EDD_GET_DEVICE_INTERFACE_NAME)) {
        return false;
    }
    char szDeviceName[32];
    lstrcpy(szDeviceName, DispDev.DeviceName);
    // after second call DispDev.DeviceString contains monitor's name
    if (!EnumDisplayDevices(szDeviceName, 0, &DispDev, EDD_GET_DEVICE_INTERFACE_NAME)) {
        return true;
    }
    lstrcpy(lpszMonitorInfo, DispDev.DeviceString);
    return true;
}
```
匹配上了就说明是同一个显示器。

### 后续

还需要再关注WM_SETTINGCHANGE事件，关注DISPLAY_DEVICEA中的DeviceName。
