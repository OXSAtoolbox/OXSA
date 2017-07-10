function plotMrSpectra_rephaseHelper_buttonUp(hObject, eventData, originalPoint)

data=guidata(hObject);

set(hObject,'WindowButtonMotionFcn','','WindowButtonUpFcn','');
data.isPhaseActive = 0;

% Set the parameters into the spectroscopy helper panel
oldData = get(data.hWhichLine,'Data');

for linedx=1:size(oldData,1);
    if data.currLines(linedx)
        oldData{linedx,1}=data.zeroOrder;
        oldData{linedx,2}=data.firstOrder;
        oldData{linedx,3}=data.firstOrderCentre;
    end
end

set(data.hWhichLine,'Data',oldData);

guidata(hObject,data);

if data.options.debug
    disp('Button UP')
end
