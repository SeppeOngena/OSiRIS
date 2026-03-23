function [SolarDistroData, dt_sun] = SolarInfo(Time_rain, kWp_panels, eta_inverter,eta_heat, csvname, TimeZone, delimiter, decimal,tformat)
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
SolarDistroData = readtimetable(csvname,opts);
SolarDistroData.Properties.DimensionNames{1} = 'Time';
varname_ind = find(~isnat(SolarDistroData.Time), 1 )-1;

opts = detectImportOptions(csvname, ...
    'Delimiter',delimiter,...
    'DecimalSeparator', decimal,...
    'ReadVariableNames',false);
opts.DataLines = [varname_ind varname_ind];
opts = setvartype(opts, opts.VariableNames, 'string');

vnames = cellstr(readmatrix(csvname,opts));
SolarDistroData.Properties.VariableNames = vnames(2:end);
SolarDistroData(isnat(SolarDistroData.Time),:) = [];

dt_sun      = seconds(SolarDistroData.Time(2)-SolarDistroData.Time(1));  % s/tstep
dt          = seconds(Time_rain(2)-Time_rain(1));  % s/tstep

SolarDistroData = retime(SolarDistroData,Time_rain,'linear');
SolarDistroData.("G(i)") = SolarDistroData.('Gb(i)')+SolarDistroData.('Gd(i)')+SolarDistroData.('Gr(i)');
SolarDistroData.("G(i)")(isnan(SolarDistroData.("G(i)")))=0;
SolarDistroData.('G(i)') = SolarDistroData.('G(i)')*dt/dt_sun; % Wh/kWp
SolarDistroData.('Gb(i)') = SolarDistroData.('Gb(i)')*dt/dt_sun; % Wh/kWp
SolarDistroData.('Gd(i)') = SolarDistroData.('Gd(i)')*dt/dt_sun; % Wh/kWp
SolarDistroData.('Gr(i)') = SolarDistroData.('Gr(i)')*dt/dt_sun; % Wh/kWp
SolarDistroData.E_solar = SolarDistroData.('G(i)')*kWp_panels/1e3*eta_inverter*eta_heat; % kWh/tstep;

end

