%MemeTao  2017.1.16 


%��һ��������M����
%�����������Ȱ�
%���ǵ�M���мĴ����ĳ�ʼֵΪ1 0 0 0 ... 0
mes = [1 0 0 1];
init = [1,zeros(1,length(mes)-1)];
mseq = createMsequence(mes,init)
%�ڶ������ܡ����
secret = randint(1,length(mseq));
mseq = bitxor(mseq,secret);
convolution = Convolution(mseq);

%��������ģ���ŵ�����
convolution(3) = 1;
convolution(4) = 0;

%���Ĳ������ա�������
recevive = convolution;
decode_out = decode(recevive);    
decode_out = bitxor(decode_out,secret)