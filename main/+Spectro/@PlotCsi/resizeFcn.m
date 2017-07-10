function resizeFcn(obj,hObject,eventdata)

%% Move the localizer slice selection and contrast spinner controls
for refdx=1:obj.data.numRefs
    axisPos = Spectro.PlotCsi.getPlotBox(obj.misc.panes(refdx).hCsiAxis);
    
    if ismac
        width = 40;
    else
        width = 35;
    end
    
    
    %Slice selection
    newPos(1)=axisPos(1) + axisPos(3); % On right edge
    newPos(2)=axisPos(2) + 40;
    newPos(3)=width;
    newPos(4)=axisPos(4) - 40;

    set(obj.misc.panes(refdx).spinner.jhSpinnerComponent,'position',newPos)
    
    set(obj.misc.panes(refdx).spinner.cmdButton,...
        'Position',[axisPos(1)+axisPos(3) axisPos(2) width 40])
    
    %Contrast
    % A
    newPos(1)=axisPos(1) - width*1.2; % On left edge
    newPos(2)=axisPos(2) + axisPos(4)/2;
    newPos(3)=width*1.2;
    newPos(4)=axisPos(4)/2;

    set(obj.misc.panes(refdx).contrast_spinnerA.jhSpinnerComponent,'position',newPos)
    
    % B
    newPos(1)=axisPos(1) - width*1.2; % On left edge
    newPos(2)=axisPos(2);
    newPos(3)=width*1.2;
    newPos(4)=axisPos(4)/2;

    set(obj.misc.panes(refdx).contrast_spinnerB.jhSpinnerComponent,'position',newPos)

end
