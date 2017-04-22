function hanmingDis = input(src,cur)

len_src = length(src);
len_cur = length(cur);
if(len_src ~= len_cur)
    disp('error input: len_cur not equal len_src');
end
dis = 0;
for i = 1 : len_cur
    if(cur(i) ~= src(i))
       dis = dis + 1;
    end
end
hanmingDis = dis;
