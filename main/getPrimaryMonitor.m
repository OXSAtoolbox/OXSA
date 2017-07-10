function mon = getPrimaryMonitor()
% Returns struct with primary monitor x,y,width,height coordinates.
%
% EXAMPLE:
% priMon = getPrimaryMonitor();
% figure('Position',[priMon.x + 0.1*priMon.width ...
%                    priMon.y + 0.1*priMon.height ...
%                    0.8*priMon.width ...
%                    0.8*priMon.height])

monitorPositions = get(0,'MonitorPositions');

if ismac
    % the left monitor is always highest row.
    % Q: Is this also primary monitor??
    mon.x = monitorPositions(end,1);
    mon.y = monitorPositions(end,2);
    mon.width = monitorPositions(end,3);
    mon.height = monitorPositions(end,4);
    
else
    % the primary monitor is always at position [1 1 ... ...]
    primaryMonitorIdx = find(monitorPositions(:,1)==1 & monitorPositions(:,2)==1,1,'first');
    
    if isempty(primaryMonitorIdx), error('Cannot identify primary monitor.'), end
    
    mon.x = monitorPositions(primaryMonitorIdx,1);
    mon.y = monitorPositions(primaryMonitorIdx,2);
    mon.width = monitorPositions(primaryMonitorIdx,3) - monitorPositions(primaryMonitorIdx,1) + 1; % Matlab BUG workaround.
    mon.height = monitorPositions(primaryMonitorIdx,4) - monitorPositions(primaryMonitorIdx,2) + 1; % Matlab BUG workaround.
    
end
