function plotMrSpectra_rephaseHelper_buttonDown(hObject, eventData)

hFig=get(hObject,'Parent');
data = guidata(hFig);

if strcmp(get(hFig,'SelectionType'),'alt')
    % Set the centre for first order phase correction
    if data.options.debug
        disp('Phase CENTRE set')
    end
    
    currpos = get(hObject,'CurrentPoint');
    data.firstOrderCentre = currpos(1);
elseif strcmp(get(hFig,'SelectionType'),'extend')
    if data.options.debug
        disp('RESET')
    end
    
    data.isPhaseActive = 0;
    data.firstOrderCentre = 0;
    data.zeroOrder = 0;
    data.firstOrder = 0;
else
    % Enable phase correction
    if data.options.debug
        disp('Button DOWN')
    end

    data.isPhaseActive = 1;

    if ~isfield(data,'firstOrderCentre')
        data.firstOrderCentre = 0;
    end
    
    currpos = get(data.hAxes(1),'CurrentPoint');
    
    set(hFig,'WindowButtonMotionFcn',@(a,b) plotMrSpectra_rephaseHelper_mouseMove(a,b,currpos),...
        'WindowButtonUpFcn',@(a,b) plotMrSpectra_rephaseHelper_buttonUp(a,b,currpos))

end

guidata(hFig,data);
