%MemeTao 2017.4.16 
%ά�ر��㷨 ��֧��(3,1,3)����� 
%PS:���ڵ���ǰ��֤���г��� >= 3*3   Ϊʲô? �ⲻ�ǳ�ʶô����

function [out] = receive(vector)

len = length(vector);   %��ȡ�������г���
if(mod(len,3) > 0)
    disp('fuck you!');  %���г��ȿ϶���3�ı�������Ϊ313������
end 
%������Ҫ��ʼ��ʼ��route��
%����������������·����ʼ��,
%���û���,������û�������������Ƶ�,��ȥ����
a = [0 0];
b = [0 1];
c = [1 0];
d = [1 1];

aa = [0 0 0]; 
ab = [1 1 1];

bc = [0 0 1];
bd = [1 1 0];

ca = [0 1 1];
cb = [1 0 0];

dc = [0 1 0];
dd = [1 0 1];
%�㻹�ǿ������� ����ô�죿���������������   ^_^   ^_^ 
%��������,ÿһ�ν�����8��·����Ȼ���о���4���Ҵ�·��
%������
route = cell(1,8); 
route_survive = cell(1,4);  
status = cell(1,8);
dis_cur = zeros(1,8);
dis_survive = zeros(1,8);
%--------------------------------8��·��+4���Ҵ�-----------------------------------%
route{1} = [aa,aa,aa]; status{1} = a; dis_cur(1) = hanmingDis(route{1},vector(1:9)); 
route{2} = [ab,bc,ca]; status{2} = a; dis_cur(2) = hanmingDis(route{2},vector(1:9));  
route{3} = [aa,aa,ab]; status{3} = b; dis_cur(3) = hanmingDis(route{3},vector(1:9)); 
route{4} = [ab,bc,cb]; status{4} = b; dis_cur(4) = hanmingDis(route{4},vector(1:9)); 
route{5} = [aa,ab,bc]; status{5} = c; dis_cur(5) = hanmingDis(route{5},vector(1:9)); 
route{6} = [ab,bd,dc]; status{6} = c; dis_cur(6) = hanmingDis(route{6},vector(1:9)); 
route{7} = [aa,ab,bd]; status{7} = d; dis_cur(7) = hanmingDis(route{7},vector(1:9)); 
route{8} = [ab,bd,dd]; status{8} = d; dis_cur(8) = hanmingDis(route{8},vector(1:9));

for i = 1 : 4
	if( dis_cur(2*i-1) <= dis_cur(2*i) )
		route_survive{i} = route{2*i-1};
		dis_survive(i) = dis_cur(2*i-1);
	else
		route_survive{i} = route{2*i};
		dis_survive(i) = dis_cur(2*i);
	end
end

for index = 10 : 3 : len
	%���²�������·��
	%case a    ״̬A,��ͬ                  
	route  {1}  = [route_survive{1},aa];   %����һ��a-a·��
	dis_cur(1)  = dis_survive(1) + hanmingDis(aa,vector(index:index+2)); %���º�������
	route  {3} 	= [route_survive{1},ab];   %����һ��a-b·��
	dis_cur(3)  = dis_survive(1) + hanmingDis(ab,vector(index:index+2)); %���º�������
	%case b:
	route  {5}  = [route_survive{2},bc];   %����һ��b-c·��
	dis_cur(5)  = dis_survive(2) + hanmingDis(bc,vector(index:index+2)); %���º�������
	route  {7} 	= [route_survive{2},bd];   %����һ��b-d·��
	dis_cur(7)  = dis_survive(2) + hanmingDis(bd,vector(index:index+2));
	%case c:
	route  {2}  = [route_survive{3},ca];   %����һ��c-a·��
	dis_cur(2)  = dis_survive(3) + hanmingDis(ca,vector(index:index+2)); %���º�������
	route  {4}  = [route_survive{3},cb];   %����һ��c-b·��
	dis_cur(4)  = dis_survive(3) + hanmingDis(cb,vector(index:index+2)); %���º�������
	%case d:
	route  {6}  = [route_survive{4},dc];   %����һ��d-c·��
	dis_cur(6)  = dis_survive(4) + hanmingDis(dc,vector(index:index+2)); %���º�������
	route  {8}  = [route_survive{4},dd];   %����һ��d-d·��
	dis_cur(8)  = dis_survive(4) + hanmingDis(dd,vector(index:index+2)); %���º�������
	%���²����Ҵ�����
	for i = 1 : 4
		if( dis_cur(2*i-1) <= dis_cur(2*i) )
			route_survive{i} = route{2*i-1};
			dis_survive(i) = dis_cur(2*i-1);
		else
			route_survive{i} = route{2*i};
			dis_survive(i) = dis_cur(2*i);
		end
	end	
end	
%�𰸾��������Ҵ���������
min = realmax();%�������
for i = 1 : 4 
	if( dis_survive(i) < min)
		min = dis_survive(i);
		tar = i;
	end
end
convolution = route_survive{tar};   %�����ҵ�����֮ǰ�ľ�����ˣ�
%������е��Ǿ���������ƻ�M���У����������յĴ�
mse = zeros(1,3);
for index_con = 1 : 3 : length(convolution)
	mse = convolution(index_con:index_con+2);
	if( all( mse(:) == aa(:) ) || all( mse(:) == bc(:) ) || all( mse(:) == ca(:) ) || all( mse(:) == dc(:) ) )
		out(round(index_con/3)+1) = 0;
	else 
		out(round(index_con/3)+1) = 1;
	end
end

%��ֱ������Լ�����������




			