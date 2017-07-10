function plotMrSpectra_rephaseHelper_mouseMove(hObject, eventData, originalPoint)

data=guidata(hObject);
currpos = get(data.hAxes(1),'CurrentPoint') - originalPoint;

axisXlim = get(data.hAxes(1),'XLim');
axisXscale = max(axisXlim)-min(axisXlim);
axisYlim = get(data.hAxes(1),'YLim');
axisYscale = max(axisYlim)-min(axisYlim);

% Rephase
% FIXME: This code doesn't leave the correct phases in memory when there
% are several lines which are adjusted separately.
data.zeroOrder = 2*pi*currpos(1,1)/axisXscale;
data.firstOrder = 2*pi*currpos(1,2)/axisYscale/10;

% Display if debugging
if data.options.debug
    disp('Move: data =')
    disp(data)
end

for linedx=1:size(data.hLines,1)
    if data.currLines(linedx)
        ppmaxis = reshape(get(data.hLines(linedx,1),'xdata'),[],1);

        newSpectra=phaseCorrect(ppmaxis, data.spectra(:,linedx), data);

        set(data.hLines(linedx,1),'ydata',real(newSpectra))
        set(data.hLines(linedx,2),'ydata',imag(newSpectra))
    end
end

drawnow expose

guidata(hObject,data);
