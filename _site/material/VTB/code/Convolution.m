function [out] = conv(vector)
len = length(vector);
b1 = vector(1);
b2 = 0;
b3 = 0;
for i = 1 : len 
    c1 = b1;
    c2 = xor(b1,b3);
    c3 = xor(xor(b1,b2),b3);
    out(3*(i-1) + 1) = c1;
    out(3*(i-1) + 2) = c2;
    out(3*(i-1) + 3) = c3;
    b3 = b2 ;
    b2 = b1 ;
    if(i<len)
        b1 = vector(i+1);
    end
end