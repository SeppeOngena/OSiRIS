function [DataRain, n, dt]  = WaterInfo(A_roof, eta_rain, csvname, TimeZone, delimiter, decimal,tformat)
% Gives a timetable of the CSV, Metadata of the weather station and the
% number of datapoints

opts = detectImportOptions(csvname, ...
    'Delimiter',delimiter,...
    'DecimalSeparator', decimal,...
    'ReadVariableNames',false, ...
    'EmptyLineRule','read');
opts = setvaropts(opts,opts.VariableNames{1}, ...
                       'Type','datetime',...
                       'InputFormat',tformat,...
                       'TimeZone', TimeZone);
opts.DataLines = [1 inf];
DataRain = readtimetable(csvname,opts);
DataRain.Properties.DimensionNames{1} = 'Time';
varname_ind = find(~isnat(DataRain.Time), 1 )-1;

opts = detectImportOptions(csvname, ...
    'Delimiter',delimiter,...
    'DecimalSeparator', decimal,...
    'ReadVariableNames',false);
opts.DataLines = [varname_ind varname_ind];
opts = setvartype(opts, opts.VariableNames, 'string');

vnames = cellstr(readmatrix(csvname,opts));
DataRain.Properties.VariableNames = vnames(2:end);
DataRain(isnat(DataRain.Time),:) = [];

DataRain  = DataRain(:,strcmp(DataRain.Properties.VariableNames,'Value'));
DataRain.Value(isnan(DataRain.Value))=0;

n = length(DataRain.Value);
dt      = seconds(DataRain.Time(2)-DataRain.Time(1));  % s/tstep

DataRain.Q_rain = DataRain.Value.*A_roof.*eta_rain./1000;

end

