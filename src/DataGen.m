%% Matlab file for the generation of data for the simulations in R
% The current folder in matlab should be the one containing this file

%% Settings load
ScenList = {'0 - Centralized';
            '1 - Rainwater use';
            '2 - GW treatment for reuse';
            '3 - Dec. treatment and infil.';
            '4 - PW production';
            '5 - GW reuse and PW production';
            '6 - Dec. treatment + PW';
            '7 - Extreme dec.';
            '8 - Extreme dec. + BW reuse'};

Settings = {};

for sceni=1:length(ScenList)
  fid = fopen(['Settings/' ScenList{sceni} '.json']);
    raw = fread(fid,inf);
    str = char(raw');
    fclose(fid); 
  Settings{sceni} = jsondecode2(str);
  %sprintf('Scenario %i done.',sceni)
end

%% Get rain data, solar data, and generated solar
Rain = WaterInfo(1, 1, Settings{1}.Dataset.WaterOptions.RainDataPath,Settings{1}.Dataset.TimeZone,...
    Settings{1}.Dataset.WaterOptions.Delimiter,Settings{1}.Dataset.WaterOptions.Decimalsep,Settings{1}.Dataset.WaterOptions.tformat);

SolarData = SolarInfo(Rain.Time,1,1,1,...
                        ".\Data\SourceData\Solar1H2015-2023Denderbelle.csv", ...
                        Settings{1}.Dataset.TimeZone, ...
                        Settings{1}.Dataset.SolarOptions.SolarFile.DelimiterSolar, ...
                        Settings{1}.Dataset.SolarOptions.SolarFile.DecimalsepSolar, ...
                        Settings{1}.Dataset.SolarOptions.SolarFile.tformatSolar);

CloudTable = Settings{1}.Dataset.SolarOptions.PVModelSettings.ClouddataTable;
    CloudTable.Clear = cell2mat(CloudTable.Clear)';
    CloudTable.Cloudy = cell2mat(CloudTable.Cloudy)';
    CloudTable.Overcast = cell2mat(CloudTable.Overcast)';
    CloudTable = table2array(struct2table(CloudTable));

[SolarGen,CloudsGen] = SolarPower_Model_v4(Rain.Time, CloudTable,Settings{1}.Dataset.lambda, Settings{1}.Dataset.phi,...
                                                    Settings{1}.Dataset.SolarOptions.PVModelSettings.Tlk, ...% kt, Average atmospheric transmissivity/clearness index
                                                    Settings{1}.Dataset.SolarOptions.PVModelSettings.rho, ...% rho, Ground reflectivity https://www.sciencedirect.com/science/article/pii/0038092X94904790);
                                                    Settings{1}.Dataset.SolarOptions.PVModelSettings.beta, Settings{1}.Dataset.SolarOptions.PVModelSettings.alpha,Settings{1}.Dataset.z,...
                                                    1, 1,1,... % take all as 1 to remove influence of pv panels
                                                    true);


%% Application distribution
SolarSim = SolarGen;

Q_appl = Diurnal_Model(Rain.Time, ".\Data\SourceData\FlowDistributionData.csv",1,1,1,1,1,1,1,1);
Q_appl.Q_GA = Garden_Model2(SolarSim, Rain ,1, Settings{2}.Dataset.IrrigationThreshold); % kWh/m²/d, insolation treshold to start irrigating

%% Compile Dataset
varnames = {'Rain_mm','E_insolation','Toilet','Kitchen','BathroomSink','WashingMachine','ShowerBath','Uniform','Irrigation'};
Dataset = array2timetable([Rain.Q_rain*1000 SolarGen.E_solar Q_appl{:,[2:6 9:10]}],'RowTimes',Rain.Time,'VariableNames',varnames); % precipitation in mm

%% Apply application flows for SI

Q_appl.Q_TL = Q_appl.Q_TL*Settings{1}.Scenario.Applications.TL.Q_lpd*Settings{1}.Scenario.Applications.TL.IE/1000;
Q_appl.Q_BT = Q_appl.Q_BT*Settings{1}.Scenario.Applications.BT.Q_lpd*Settings{1}.Scenario.Applications.BT.IE/1000;
Q_appl.Q_SH = Q_appl.Q_SH*Settings{1}.Scenario.Applications.SH.Q_lpd*Settings{1}.Scenario.Applications.SH.IE/1000;
Q_appl.Q_BS = Q_appl.Q_BS*Settings{1}.Scenario.Applications.BS.Q_lpd*Settings{1}.Scenario.Applications.BS.IE/1000;
Q_appl.Q_WM = Q_appl.Q_WM*Settings{1}.Scenario.Applications.WM.Q_lpd*Settings{1}.Scenario.Applications.WM.IE/1000;
Q_appl.Q_DW = Q_appl.Q_DW*Settings{1}.Scenario.Applications.DW.Q_lpd*Settings{1}.Scenario.Applications.DW.IE/1000;
Q_appl.Q_KS = Q_appl.Q_KS*Settings{1}.Scenario.Applications.KS.Q_lpd*Settings{1}.Scenario.Applications.KS.IE/1000;
Q_appl.Q_CL = Q_appl.Q_CL*Settings{1}.Scenario.Applications.CL.Q_ld/1000;
Q_appl.Q_GA = Q_appl.Q_GA*Settings{1}.Scenario.Applications.GA.Q_ld/1000;

Q_appl = table2timetable(Q_appl(:,2:end),"RowTimes",Rain.Time);

%% Write to CSV For R

writetimetable(Dataset,'.\Data\InputDataset.csv')
writetimetable(SolarGen,'.\Data\SolarGen.csv')
writetimetable(SolarData,'.\Data\SolarData.csv')
writetimetable(Rain,'.\Data\Rain.csv')
writetimetable(CloudsGen,'.\Data\CloudsGen.csv')
writetimetable(Q_appl,'.\Data\Q_appl.csv')