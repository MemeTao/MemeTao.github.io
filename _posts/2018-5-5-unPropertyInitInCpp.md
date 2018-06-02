

今天碰到了一个非常棘手的问题：
```c++
Login::Login(InetAddress& addr)
    :loopThread_(new LoopThread()),
     client_(TcpClient(nullptr,addr))
{
    loopThread_->start();
    sleep(1);
    client_=  TcpClient(loopThread_->getLoop(),addr);
    //gui_.setCallback(std::bind(&Login::handleLoginButton,this,_1,_2));
    client_.setMessageCallback(std::bind(&Login::handleMessage,this,_1,_2,_3));
    client_.setConnectionCallback(std::bind(&Login::connectionEstablished,this,_1));
    client_.connect();
}
```
最后导致了很严重的问题，我怀疑是client的数据成员被破坏了，可能原因是我没有给他一个合适的赋值运算符
