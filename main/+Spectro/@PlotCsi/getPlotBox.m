% Find where the edge of the axis box ("plotbox") lies...

function [posNew] = getPlotBox(hAxis)
hFig = getParentFigure(hAxis);

thePBAR = get(hAxis,'PlotBoxAspectRatio');
thePos = get(hAxis,'Position');

thePosPix=hgconvertunits(hFig,thePos,get(hAxis,'units'),'Pixels',gcf);

posNew = thePosPix;
if thePosPix(4)/thePosPix(3) > thePBAR(2)/thePBAR(1);
    newHeight = thePosPix(3) * thePBAR(2)/thePBAR(1);
    
    posNew(2) = posNew(2)+0.5*posNew(4)-0.5*newHeight;
    posNew(4) = newHeight;
else
    newWidth = thePosPix(4) * thePBAR(1)/thePBAR(2);
    
    posNew(1) = posNew(1)+0.5*posNew(3)-0.5*newWidth;
    posNew(3) = newWidth;
end
end


function fig = getParentFigure(fig)
% if the object is a figure or figure descendent, return the
% figure.  Otherwise return [].
while ~isempty(fig) && ~strcmp('figure', get(fig,'type'))
    fig = get(fig,'parent');
end
end
