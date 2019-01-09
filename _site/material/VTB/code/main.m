%MemeTao  2017.1.16 


%第一步：产生M序列
%今天天气好热啊
%我们的M序列寄存器的初始值为1 0 0 0 ... 0
mes = [1 0 0 1];
init = [1,zeros(1,length(mes)-1)];
mseq = createMsequence(mes,init)
%第二部加密、卷积
secret = randint(1,length(mseq));
mseq = bitxor(mseq,secret);
convolution = Convolution(mseq);

%第三部：模拟信道噪声
convolution(3) = 1;
convolution(4) = 0;

%第四步：接收、差错纠正
recevive = convolution;
decode_out = decode(recevive);    
decode_out = bitxor(decode_out,secret)