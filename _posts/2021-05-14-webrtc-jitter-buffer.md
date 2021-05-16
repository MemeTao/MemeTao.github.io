---
layout: mypost
title: "webrtc接收端jitter估计器原理推导"
date: 2021-05-14 14:13:17 +0800
categories: webrtc
location: HangZhou,China 
---
---


### 卡尔曼增益简单介绍及推导

> 有一把尺子测量一枚硬币的直径, 记录每次测量出的结果(测量值):$x_1$, $x_2$, $x_3$, ....

那么, 对硬币直径的估计值:

<center> 
    $\overline{x}_n$ = $\frac {(x_1+x_2+x_3+...+x_n)} {n}$
</center>

进一步, 写成递归形式:
<center> 
    $\overline{x}_n$ =  $\overline{x}_{n-1}$ + $\frac{1}{n} (x_n - \overline{x}_{n-1})$ 
</center>
可见, 随着 ${n\to+\infty}$, 测量结果已经不再重要.

文字表示为:

> 当前的估计值 = 上一次的估计值 + 系数 * (当前的测试量 - 上一次的估计值) $$

假设要考虑上一次的估计误差和本次的测量误差, 一个很直观的想法就是:

* 如果估计误差大于测量误差, 也就是说测量的更佳准确, 那么当前的估计值应该偏向于本次的测量值
* 如果估计误差小于测量误差, 也就是说测量的不准确, 那么当前的估计值应该偏向于上一次的估计值

这就是数据融合的思想, 此时, 这个**系数**就是卡尔曼增益系数:

$$ G = \frac {估计误差}{估计误差+测量误差} $$

对于一个确定性离散时间系统的状态方程:

$x_{n+1} = Ax_n + Bu_k + w_k$, $w_k$ 表示过程噪声

$y_n = Cx_n + v_k$, $v_k$ 表示测量误差

那么，从数据融合的角度看，对于状态的估计其实就是：

$\overline{x}_{n+1} = \overline{x}^{calc}_{n} + G(\overline{x}^{mess}_n - \overline{x}^{calc}_n)$

进一步， 对G做转换:

$ G = KC $

我们称K是可以将测量值转换为真实值的卡尔曼增益, 从而有:

$\overline{x}_{n+1} = \overline{x}^{mess}_{calc} + K(y_k - C\overline{x}^{calc}_n)$

那么，误差就可以表示为:
$e_n = x_n - \overline{x}_n $ 

$ = x_n - \overline{x}^{calc}_n - K(Cx_n + v_k) + KC\overline{x}^{calc}_n $

$ = (I - KC)x_n - (I - KC)\overline{x}^{calc}_n - Kv_n $

$ = (I -KC)(x_n - \overline{x}^{calc}_n) - Kv_n$

上述中的I代表单位矩阵，如果是1阶就是1， 二阶则是2X2的单位矩阵

需要假设这个误差满足正太分布: $e\sim N(0, P_k)$ 

$P_k$ 就是随机变量的方差，对于多维随机变量来说就是指协方差矩阵的迹（对角线元素之和），可以表示为:(证明略) 

$P_k = E[e_k * e^t_k]$, ($e^t$ 表示矩阵的转置) 

带入各式:

$P_k = E{(I-KC)(x_k - x^{calc}_k) - Kv_k}{(I-KC)(x_k-x^{calc}_k)-Kv_k}^T $

将乘积展开，同时引入估计误差: $e_k = x_k - x^{calc}_k$

最终:

$ P_k = (I-KC)E[e_k*e^t_k] (I-KC)^t+KE[v_k * v^t_k]K^t $

注意， 上式中的 $e_k$代表的是估计误差, 将 $E[e_k * e^t_k]记作\overline{P}_k$ 从而:

$P_k = (\overline{P}_k - KC\overline{P}_k)(I-C^tK^T) + kRK^t , R = E[e_k * e^t_k] $

我们要让误差最小, 就是要让导数为0（且二次导小于0）, 矩阵的求导过程略:

$ \frac{dP_k} {dK} = K(CP_kC^t + R) - P_kC^t = 0 $

$ K = \frac{P_kC^t}{CP_kC^t + R} $

### 信道速率 + 排队时延的估计

webrtc认为帧的抖动被认为是帧大小的变化引起的:

$ delay = Rate_{channel} * Delta_{frame} + Noise $, 即信道速率 * 帧大小的变化 + 噪声

webrtc 使用卡尔曼滤波去估计信道速率和排队延迟, 从而进一步确定jitter

首先，建立数学模型，这是个二元系统，信道速率(R) + 排队延迟(D)。

从模型上说，这两个值当然是不变的，也即:

$ R_k = 1 * R_{k-1} + 0 $

$ D_k = 1 * D_{k-1} + 0 $

系统的状态转换方程用矩阵可以表示为:
$$
\begin{bmatrix}
    R\\
    D\\
\end{bmatrix}
=
\begin {bmatrix}
    1&&0 \\
    0&&1 \\
\end {bmatrix}
* 
\begin {bmatrix}
    R_{k_1}&&D_{k-1} \\
\end {bmatrix}

$$

系统输出(只有一个jitter)

$$ jitter = deltaF * R + D  $$

用矩阵表示为:

$$
\begin {bmatrix}
    jitter \\
\end {bmatrix}
=
\begin {bmatrix}
    deltaF && 1 \\
\end {bmatrix}
*
\begin {bmatrix}
    R \\
    D \\
\end {bmatrix}

$$

下面引入一条卡尔曼滤波中的公式，先验的误差协方差矩阵(证明略，还没学会):

$$ P_k = AP_{k-1}A^T + Q  $$ 
$$ Q = E[v_k * v^t_k], 测量误差的协方差矩阵$$

A就是系统的转换矩阵, 那么就有:

$$
P_k = AP_{k-1}A^T + Q 
\begin {bmatrix}
    1&&0 \\
    0&&1 \\
\end {bmatrix}
*  P_{k-1}
*
\begin {bmatrix} 
    1&&0 \\ 
    0&&1 \\
\end {bmatrix}
  + Q 
= P_{k-1} + Q
$$

这时候，再看webrtc中的代码:

```C++
    // Prediction
    // M = M + Q
    _thetaCov[0][0] += _Qcov[0][0];
    _thetaCov[0][1] += _Qcov[0][1];
    _thetaCov[1][0] += _Qcov[1][0];
    _thetaCov[1][1] += _Qcov[1][1]; 
```

一样一样的。接着更新卡尔曼增益系数(第一部分已经给出证明):
$$ K = \frac{P_kC^t}{CP_kC^t + R} $$

$$
C =
\begin {bmatrix}
    deltaF && 1 
\end {bmatrix}, 前面已经给出
$$

再对应源码, 注意是二阶（R,D）:
```C++
    Mh[0] = _thetaCov[0][0] * deltaFSBytes + _thetaCov[0][1];
    Mh[1] = _thetaCov[1][0] * deltaFSBytes + _thetaCov[1][1];
    // sigma weights measurements with a small deltaFS as noisy and
    // measurements with large deltaFS as good
    if (_maxFrameSize < 1.0) {
        return;
    }
    double sigma = (300.0 * exp(-fabs(static_cast<double>(deltaFSBytes))/(1e0*_maxFrameSize))+1)*sqrt(_varNoise);
    if (sigma < 1.0) {
        sigma = 1.0;
    }
    hMh_sigma = deltaFSBytes * Mh[0] + Mh[1] + sigma;
    if ((hMh_sigma < 1e-9 && hMh_sigma >= 0) || (hMh_sigma > -1e-9 && hMh_sigma <= 0)) {
        assert(false);
        return;
    }
    kalmanGain[0] = Mh[0] / hMh_sigma;
    kalmanGain[1] = Mh[1] / hMh_sigma;
```

接下去， 计算得到本次的最优估计值:

```C++
    // Correction
    // theta = theta + K*(dT - h*theta)
    measureRes = frameDelayMS - (deltaFSBytes * _theta[0] + _theta[1]);
    _theta[0] += kalmanGain[0] * measureRes;
    _theta[1] += kalmanGain[1] * measureRes;
```

继续引进卡尔曼公式2, 更新先验误差协方差矩阵(证明略，还没有学会):

$$ P_{k+1} = (I-KH)P_k $$

对应源码:

```C++
    // M = (I - K*h)*M
    t00 = _thetaCov[0][0];
    t01 = _thetaCov[0][1];
    _thetaCov[0][0] = (1 - kalmanGain[0] * deltaFSBytes) * t00 -
                    kalmanGain[0] * _thetaCov[1][0];
    _thetaCov[0][1] = (1 - kalmanGain[0] * deltaFSBytes) * t01 -
                    kalmanGain[0] * _thetaCov[1][1];
    _thetaCov[1][0] = _thetaCov[1][0] * (1 - kalmanGain[1]) -
                    kalmanGain[1] * deltaFSBytes * t00;
    _thetaCov[1][1] = _thetaCov[1][1] * (1 - kalmanGain[1]) -
                    kalmanGain[1] * deltaFSBytes * t01;
```

至此，一波卡尔曼滤波结束。

本文详细证明了卡尔曼滤波算法公式中的**卡尔曼增益系数**，以及说明了**系统转换方程**、**测量方程**。

对于**先验误差公式** 以及 **误差协方差的更新公式** 未给出证明。

并且未对webrtc中如何**deltaF**、**noise** 进行说明(比较简单)。
