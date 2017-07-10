function [hNew] = copyToFigure(obj, hNew, paneDxToCopy)
% Copy the localizers from a Spectro.PlotCsi figure into the specified figure.
%
% hNew: Target figure handle.
% paneDx: (optional) Specify which reference panes should be copied.

% Copyright Chris Rodgers, Univ Oxford, 2012.
% $Id$

if ~exist('hNew','var')
    hNew = figure();
end

if ~exist('paneDxToCopy','var')
    paneDxToCopy = 1:numel(obj.misc.panes);
end

set(hNew,'colormap',get(obj.handles.mainWindow,'colormap'))
set(hNew,'position',get(obj.handles.mainWindow,'position'))

new_handle = copyobj([obj.misc.panes(paneDxToCopy).hCsiAxis],hNew);

% Remove callbacks to prevent odd behaviour - e.g. clicking in the copy
% would have updated the main GUI window but not the copy plot!
set(findobj(new_handle,'-not','ButtonDownFcn',[]),'ButtonDownFcn',[])

hTextAx = axes('parent',hNew,'units','norm','position',[0 0 1 1],'Visible','off');
set(hTextAx,'units',get(obj.handles.mainWindow,'units'))

for panedx = paneDxToCopy
    posn = get(obj.misc.panes(panedx).spinner.jhSpinnerComponent,'position');
    posn = [posn(1)+posn(3)/2 posn(2)+posn(4)/2 0];
    text('parent',hTextAx,...
        'units',get(obj.handles.mainWindow,'units'),...
        'position',posn,...
        'string',sprintf('%d',obj.misc.panes(panedx).spinner.jhSpinner.Value),...
        'fontsize',20)
end
