function LogParams = cloudfit(Okta1,Okta2,Okta3)%DataSolar,DataRain,clouddata,lambda,phi,Tlk,rho,beta,alpha,A_panel,Wp_panel,eta_inverter,eta_heat)

fit = @(b,x) b(1)/(1+exp(-b(2)*(x-b(3))));
fcn = @(b) fit(b,0)^2+(fit(b,1)-Okta1)^2+(fit(b,2)-Okta2)^2+(fit(b,3)-Okta3)^2;
s = fminsearch(fcn,[1,3,1.5]);%,optimset('Display','iter','PlotFcns',@optimplotfval));
LogParams = s;
end