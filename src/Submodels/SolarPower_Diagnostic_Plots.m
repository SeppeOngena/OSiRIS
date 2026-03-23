function [totalyear, totalyear2] = SolarPower_Diagnostic_Plots(DataSolar, DataSolar2, DataClouds,dt_sun,dt,plotcloud, plotsolar)
% Just some diagnostic plots and prints

close all
if plotcloud
figure(1)
DataClouds2 = retime(DataClouds,'daily','mean');
bar(DataClouds2.Time, DataClouds2.ClearDay,1.044,'FaceColor',[252, 182, 28]/255);
hold on
bar(DataClouds2.Time, DataClouds2.CloudyDay,1.044,'FaceColor',[64, 115, 191]/255);
bar(DataClouds2.Time, DataClouds2.OvercastDay,1.044,'FaceColor',[74/255 76/255 79/255]);
hold off
legend('Clear','Cloudy','Overcast')
set(gca,'YColor','none')
set(gca,'XTick', datetime(2014:2024,1,1,0,0,0,'TimeZone',DataClouds.Time.TimeZone))
set(gcf().Children,'FontSize',16)

figure(2)
subplot(3,1,1)
plot(DataClouds.Time,DataClouds.CloudProb)
ylabel('Cloud probability')
subplot(3,1,2)
plot(DataClouds.Time,DataClouds.Cloud)
ylabel('Cloud occurrence')
subplot(3,1,3)
plot(retime(DataClouds,'daily','mean').Time,retime(DataClouds,'daily','mean').Cloud*100)
ylabel('Daily cloud coverage (% of sky)')
set(gcf().Children,'FontSize',16)

DataClouds2 = retime(DataClouds,'daily','max');
DataClouds2 = retime(DataClouds2,'monthly','sum');
DataClouds2 = groupsummary(DataClouds2,"Time",'monthofyear','mean');
y = [DataClouds2.mean_OvercastDay, DataClouds2.mean_CloudyDay,DataClouds2.mean_ClearDay];
y = y./sum(y,2);
figure(3)
bar(DataClouds2.monthofyear_Time,y,'stacked')
set(gcf().Children,'FontSize',16)
end

if plotsolar

figure(4)
subplot(2,1,1)
plot(DataSolar.Time, DataSolar.E_solar,'Color',[0.6 0 .0])
ylabel('E_{solar,data} (kWh\cdot dt^{-1})')
subplot(2,1,2)
hold on 
DataSolar5 = retime(DataSolar2,'regular',"sum",'TimeStep',seconds(dt_sun));
DataSolar5 = retime(DataSolar5,DataSolar.Time,"linear");
DataSolar5.E_solar = DataSolar5.E_solar/dt_sun*dt;
plot(DataSolar5.Time, DataSolar5.E_solar,'Color',[0.6 0 .0])
ylabel('E_{solar,sim} (kWh\cdot dt^{-1})')
hold off
set(gcf().Children,'FontSize',16)

figure(5)
DataSolar3 = retime(DataSolar,'monthly','sum');
DataSolar3 = groupsummary(DataSolar3(DataSolar3.E_solar>0,:),"Time",'monthofyear',{'mean','std'});
DataSolar4 = retime(DataSolar2,'monthly','sum');
DataSolar4 = groupsummary(DataSolar4(DataSolar4.E_solar>0,:),"Time",'monthofyear',{'mean','std'});

errorbar(DataSolar3.monthofyear_Time, DataSolar3.mean_E_solar,DataSolar3.std_E_solar,linewidth=2)
hold on
errorbar(DataSolar4.monthofyear_Time, DataSolar4.mean_E_solar,DataSolar4.std_E_solar,linewidth=2)
hold off
legend('Data','Simulations')
ylabel('Harvested solar energy (kWh/m²)')
xlabel('Month of the year')
set(gcf().Children,'FontSize',16)

figure(6)
subplot(4,1,1)
plot(DataSolar2.Time, DataSolar2.G0,'Color',[0.6 0 .0])
ylabel('G_0 (Wh/m²)')
ylim([0 300])
subplot(4,1,2)
plot(DataSolar2.Time, DataSolar2.G,'Color',[0.6 0 .0])
ylabel('G (Wh/m²)')
ylim([0 300])
subplot(4,1,3)
plot(DataSolar2.Time, DataSolar2.Gc,'Color',[0.6 0 .0])
ylabel('G_c (Wh/m²)')
ylim([0 300])
subplot(4,1,4)
plot(DataSolar2.Time, DataSolar2.('G(i)'),'Color',[0.6 0 .0])
ylabel('G_p (Wh/m²)')
ylim([0 300])
set(gcf().Children,'FontSize',16)


end

totalyear = retime(DataSolar, 'yearly', 'sum');
totalyear2 = retime(DataSolar2, 'yearly', 'sum');

end

%set(gcf().Children(4),'FontSize',16)
%set(gcf().Children(3),'FontSize',16)
%set(gcf().Children(2),'FontSize',16)
%set(gcf().Children(1),'FontSize',16)
%exportgraphics(gcf,'SolarModel.pdf','Resolution',300)