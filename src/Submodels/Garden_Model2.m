function [Q_GA,warn_noexceed] = Garden_Model2(DataSolar, DataRain,Q_GA,irrigation_threshold)
% Converts average daily garden watering flow to yearly pattern
% adapted to for each timepoint in "time" with a maximum in summer

%% New code
DataFitDaily = retime(DataSolar,'daily','sum');

DataRainFit = retime(DataRain,'daily','sum');
DataRainFit.RainyDay = DataRainFit.Q_rain>0;
DataRainFit = retime(DataRainFit,DataRain.Time,'previous');

DataFit = retime(DataFitDaily,DataRain.Time,'previous');
%exceedance_daily = (DataFitDaily.('G(i)')/1000-irrigation_threshold);
Q_GA_tmp = ((DataFit.('G(i)')/1000)-irrigation_threshold).*(1-DataRainFit.RainyDay); % kWh/m²/d

Q_GA_tmp(Q_GA_tmp<0) = 0;
if sum(Q_GA_tmp)~=0
    warn_noexceed = 0;
    Q_GA_tmp = Q_GA_tmp/sum(Q_GA_tmp); % Fraction of insolation 0-1
else
    warn_noexceed = 1;
    Q_GA_tmp = ones([length(Q_GA_tmp) 1])/length(Q_GA_tmp); % uniform, actually Q_GA should be 0 in this case but that's up to the user
end

Q_GA = Q_GA_tmp*Q_GA*days(DataFit.Time(end)-DataFit.Time(1));

end

