function y = cloudfun_month(Month, ind, clouddata)

clouddata = bsxfun(@rdivide, clouddata, sum(clouddata,2));

%A = params(ind,1);
%B = params(ind,2);
%C = params(ind,3);

%y = A*cos(2*pi/(365*24*3600/dt)*(x-first21dec+B*2628000/dt))+C;
y = clouddata(Month,ind);

end