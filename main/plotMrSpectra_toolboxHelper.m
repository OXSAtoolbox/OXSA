function plotMrSpectra_toolboxHelper(hObject, eventData)

% Find the parent figure in which the toolbar button lay
hFig = hObject;
while ~isempty(hFig) && ~strcmp('figure', get(hFig,'type'))
    hFig = get(hFig,'parent');
end

% Retrieve the GUI data
data = guidata(hObject);
if isempty(data)
    data = struct();
end

% Open/construct the spectroscopy panel
if isfield(data,'hPanel') && ~isempty(data.hPanel) && ishandle(data.hPanel)
    figure(data.hPanel);
else
    data.hPanel = figure('IntegerHandle','off','NumberTitle','off','Name',...
        sprintf('Spectroscopy controls for Fig %d',get(hFig,'Number')),...
        'toolbar','none','menubar','none','tag','SpectroscopyPanel',...
        'DeleteFcn',@plotMrSpectra_toolboxHelper_close,'UserData',hFig);
    set(data.hPanel,'units','pixels');
    figPos = get(hFig,'position');
    figPos(1)=figPos(1)+figPos(3)+16;
    figPos([3 4])=[300 400];
    set(data.hPanel,'position',figPos);
    
    % Draw controls
    data.hWhichLine = uitable(...
        'Parent',data.hPanel,...
        'Units','normalize',...
        'ColumnFormat',{  [] [] [] },...
        'ColumnEditable',logical([ 1 1 1 ]),...
        'ColumnName',{  '0th order'; '1st order'; '1st order centre' },...
        'ColumnWidth',{  'auto' 'auto' },...
        'Data', num2cell(zeros(size(data.hLines,1),3)),...
        'Position',[0.01 0.01 0.98 0.98],...
        'CellSelectionCallback',@plotMrSpectra_rephaseHelper,...
        'Tag','hWhichLine');
    %'ButtonDownFcn',@(varargin) disp(varargin),...
    
    % In future, we may wish to use jcontrol to put Java swing objects
    % on this form instead of merely Matlab GUI controls. This gives
    % e.g. better callbacks.
end

% Save the GUI data
guidata(hObject,data);

end

% % --- Set application data first then calling the CreateFcn.
% function local_CreateFcn(hObject, eventdata, createfcn, appdata)
%
% if ~isempty(appdata)
%     names = fieldnames(appdata);
%     for i=1:length(names)
%         name = char(names(i));
%         setappdata(hObject, name, getfield(appdata,name));
%     end
% end
%
% end

