%MemeTao 2017.4.16 
%维特比算法 仅支持(3,1,3)卷积码 
%PS:请在调用前保证序列长度 >= 3*3   为什么? 这不是常识么？！

function [out] = receive(vector)

len = length(vector);   %获取输入序列长度
if(mod(len,3) > 0)
    disp('fuck you!');  %序列长度肯定是3的倍数，因为313卷积码嘛！
end 
%下面我要开始初始化route了
%如果您看不懂下面的路径初始化,
%不用怀疑,绝对是没理解卷积码的逆向推导,请去看书
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
%你还是看不懂？ 那怎么办？下面更看不懂咯！   ^_^   ^_^ 
%按照理论,每一次仅存在8条路径，然后判决出4条幸存路径
%管他呢
route = cell(1,8); 
route_survive = cell(1,4);  
status = cell(1,8);
dis_cur = zeros(1,8);
dis_survive = zeros(1,8);
%--------------------------------8条路径+4条幸存-----------------------------------%
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
	%重新产生八条路径
	%case a    状态A,下同                  
	route  {1}  = [route_survive{1},aa];   %增加一条a-a路径
	dis_cur(1)  = dis_survive(1) + hanmingDis(aa,vector(index:index+2)); %更新汉明距离
	route  {3} 	= [route_survive{1},ab];   %增加一条a-b路径
	dis_cur(3)  = dis_survive(1) + hanmingDis(ab,vector(index:index+2)); %更新汉明距离
	%case b:
	route  {5}  = [route_survive{2},bc];   %增加一条b-c路径
	dis_cur(5)  = dis_survive(2) + hanmingDis(bc,vector(index:index+2)); %更新汉明距离
	route  {7} 	= [route_survive{2},bd];   %增加一条b-d路径
	dis_cur(7)  = dis_survive(2) + hanmingDis(bd,vector(index:index+2));
	%case c:
	route  {2}  = [route_survive{3},ca];   %增加一条c-a路径
	dis_cur(2)  = dis_survive(3) + hanmingDis(ca,vector(index:index+2)); %更新汉明距离
	route  {4}  = [route_survive{3},cb];   %增加一条c-b路径
	dis_cur(4)  = dis_survive(3) + hanmingDis(cb,vector(index:index+2)); %更新汉明距离
	%case d:
	route  {6}  = [route_survive{4},dc];   %增加一条d-c路径
	dis_cur(6)  = dis_survive(4) + hanmingDis(dc,vector(index:index+2)); %更新汉明距离
	route  {8}  = [route_survive{4},dd];   %增加一条d-d路径
	dis_cur(8)  = dis_survive(4) + hanmingDis(dd,vector(index:index+2)); %更新汉明距离
	%重新产生幸存序列
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
%答案就在最后的幸存序列里面
min = realmax();%最大整数
for i = 1 : 4 
	if( dis_survive(i) < min)
		min = dis_survive(i);
		tar = i;
	end
end
convolution = route_survive{tar};   %现在找到噪声之前的卷积码了！
%下面进行的是卷积码逆向推回M序列，即我们最终的答案
mse = zeros(1,3);
for index_con = 1 : 3 : length(convolution)
	mse = convolution(index_con:index_con+2);
	if( all( mse(:) == aa(:) ) || all( mse(:) == bc(:) ) || all( mse(:) == ca(:) ) || all( mse(:) == dc(:) ) )
		out(round(index_con/3)+1) = 0;
	else 
		out(round(index_con/3)+1) = 1;
	end
end

%简直佩服我自己！哈哈哈！




			