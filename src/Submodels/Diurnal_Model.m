function Q_appliances = Diurnal_Model(time, flow_csvname, Q_TL, Q_BT, Q_SH, Q_BS, Q_WM, Q_DW, Q_KS, Q_CL)
% Converts daily average flow values to the correct diurnal patterns
% matching the time steps in the "time"

n = length(time);
dt = time(2)-time(1);  % s/tstep

if dt < days(1) % Diurnal pattern
    Usage = readtable(flow_csvname); % Reads flow patterns from the given csv
        Usage.Time = datetime(Usage.Time,'InputFormat','HH:mm');
        Usage = table2timetable(Usage);
        if dt>=minutes(15)
            Usage = retime(Usage,'regular','sum','TimeStep',dt);
        else
            Usage = retime(Usage,'regular','nearest','TimeStep',dt);
            Usage.Variables = Usage.Variables/(minutes(15)/dt);
        end
  
    firsttime = timeofday(time(1));
        selecttime = find(firsttime == timeofday(Usage.Time)); clear firsttime
        nrep = (height(time)-height(Usage(selecttime:end,:)))/height(Usage);
    if rem(nrep,1)==0
        Usage = [Usage(selecttime:end,:);
                repmat(Usage,nrep,1)];
    else
        Usage = [Usage(selecttime:end,:);
                 repmat(Usage,floor(nrep),1);
                 Usage(1:(n-height(Usage(selecttime:end,:))-floor(nrep)*height(Usage)),:)];
    end
    %clear nrep selecttime
    Usage.Time = time;
    
else % Uniform distribution per day
    Usage = (ones(n,9)/24/3600*seconds(dt)); % m3/d --> m3/tstep
    Usage = array2timetable(Usage, 'Rowtimes',time);
    Usage = renamevars(Usage, Usage.Properties.VariableNames, {'TL','BT','SH','BS','WM','DW','KS','CL','GA'});
    
end
    
% Now to multiply with the daily values (m3/d --> m3 per time step)
Q_appliances = table((1:n)',Q_TL*Usage.TL, ...
                            Q_BT*Usage.BT,...
                            Q_SH*Usage.SH,...
                            Q_BS*Usage.BS,...
                            Q_WM*Usage.WM,...
                            Q_DW*Usage.DW,...
                            Q_KS*Usage.KS,...
                            Q_CL*Usage.CL,...
                'VariableNames',{'Time', ...
                            'Q_TL', ...
                            'Q_BT', ...
                            'Q_SH', ...
                            'Q_BS', ...
                            'Q_WM', ...
                            'Q_DW', ...
                            'Q_KS', ...
                            'Q_CL'});

end

