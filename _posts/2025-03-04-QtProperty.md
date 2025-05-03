---
layout: mypost
title:  "每日一个QT知识点: 属性"
date:   2025-03-04 12:13:17 +0800
categories: QT
location: HangZhou,China
description:
---
---

## The Property System

语法是这样的:

```shell
Q_PROPERTY(type name
           (READ getFunction [WRITE setFunction] |
            MEMBER memberName [(READ getFunction | WRITE setFunction)])
           [RESET resetFunction]
           [NOTIFY notifySignal]
           [REVISION int | REVISION(int[, int])]
           [DESIGNABLE bool]
           [SCRIPTABLE bool]
           [STORED bool]
           [USER bool]
           [BINDABLE bindableProperty]
           [CONSTANT]
           [FINAL]
           [REQUIRED])
```
举个例子来说的话：
```shell
Q_PROPERTY(bool focus READ hasFocus)
Q_PROPERTY(bool enabled READ isEnabled WRITE setEnabled)
Q_PROPERTY(QCursor cursor READ cursor WRITE setCursor RESET unsetCursor)
```

上边是一些成员函数(通过成员函数来读写成员变量)，如果是想要省略get/set函数的话可以直接对某一个成员变量加上"MEMBER"关键字。
```shell
    Q_PROPERTY(QColor color MEMBER m_color NOTIFY colorChanged)
    Q_PROPERTY(qreal spacing MEMBER m_spacing NOTIFY spacingChanged)
    Q_PROPERTY(QString text MEMBER m_text NOTIFY textChanged)
    ...
signals:
    void colorChanged();
    void spacingChanged();
    void textChanged(const QString &newText);

private:
    QColor  m_color;
    qreal   m_spacing;
    QString m_text;
```

举一个现实的例子:
```c++
class MyClass : public QObject {
    Q_OBJECT
    Q_PROPERTY(int value READ getValue WRITE setValue NOTIFY valueChanged)

public:
    explicit MyClass(QObject *parent = nullptr) : QObject(parent), m_value(0) {}

    int getValue() const { return m_value; }
    void setValue(int val) {
        if (m_value != val) {
            m_value = val;
            emit valueChanged(val);
        }
    }

signals:
    void valueChanged(int);

private:
    int m_value;
};

// 省略get/set的方式
class MyClass : public QObject {
    Q_OBJECT
    Q_PROPERTY(int value MEMBER m_value NOTIFY valueChanged)

public:
    explicit MyClass(QObject *parent = nullptr) : QObject(parent), m_value(0) {}

signals:
    void valueChanged(int);  // 变量变化时通知

private:
    int m_value;
};

int main(){
    MyClass obj;
    obj.setProperty("value", 42);  // 设置属性
    qDebug() << obj.property("value").toInt();  // 读取属性
    return 0;
}
```

好理解吧！