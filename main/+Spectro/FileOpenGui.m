classdef FileOpenGui < handle
% Select DICOM file interactively.

% Copyright Chris Rodgers, University of Oxford, 2010-11.
% $Id: FileOpenGui.m 4004 2011-03-16 16:42:26Z crodgers $

properties(SetAccess='protected')
    hFig
    contrast
    current
    hAutoContrast
    hDataCursor
    hDebug
    hFigAxis
    hFigImage
    hLabelCommand
    hMenu
    hMenuExit
    hResetContrast
    hTree % Spectro.dicomUiTree object.
    hZoom
    multipleSelectionEnabled
end
    
properties(Access='private')
    waitState_thisData = [];
end
    
events
    ItemChosen % Event when an item has been chosen from the right-click menu.
end

methods
    function h = FileOpenGui(strTopdirOrDicomTree,bMultipleSelectionEnabled,strTitle,bRecursive)
    % Select DICOM file interactively.
    %
    % strTopDirOrDicomTree - Starting folder OR Spectro.dicomTree object.
    % bMultipleSelectionEnabled - Allow multiple selection.
    % strTitle - Title for the selection window.
    % bRecursive - Set Spectro.dicomTree to recursively scan each folder.
    %
    % EXAMPLES:
    %
    % Selecting a single item:
    % itemData = Spectro.FileOpenGui(pwd).waitForItemChosenAndClose();
    %
    % Selecting items asynchronously:
    % h = Spectro.FileOpenGui(pwd);
    % addlistener(h, 'ItemChosen', @(varargin) disp(varargin))
    
    %% Process input arguments
    if nargin < 1
        strTopdirOrDicomTree = uigetdir(pwd(),'Choose top level folder');
        
        if ~ischar(strTopdirOrDicomTree) && strTopdirOrDicomTree == 0
            error('Aborted by user'); % Cancel was pressed.
        end
    end
    
    if nargin < 2 || isempty(bMultipleSelectionEnabled)
        bMultipleSelectionEnabled = false;
    end
    
    if nargin < 3 || isempty(strTitle)
        strTitle = 'Select DICOM data';
    end
    
    if nargin < 4 || isempty(bRecursive)
        bRecursive = false;
    end
    
    %% Detect primary monitor to put file dialog in the middle
    primaryMon = getPrimaryMonitor();
    windowPos = [primaryMon.x+primaryMon.width*0.10 primaryMon.y+primaryMon.height*0.10 primaryMon.width*0.80 primaryMon.height*0.80];

    %% Create figure
    h.hFig = figure('NumberTitle','off',...
        'Menubar','none',...
        'Toolbar','none',...
        'Name', strTitle, ...
        'IntegerHandle', 'off', ...
        'Position',windowPos, ...
        'DeleteFcn',@(o,e) delete(h), ...
        'KeyPressFcn',@(o,e) h.keyPressFcn(o,e) );
    
    % Store the figure data object into the figure's guidata
    guidata(h.hFig, h);
    
    %% Create tree on certain position
    tmpPosFig=get(h.hFig,'Position');
    tmpPosTree=[2, 2, tmpPosFig(1,3)/2, tmpPosFig(1,4)-4];
    
    h.hTree = Spectro.dicomUiTree(strTopdirOrDicomTree,h.hFig,tmpPosTree,bRecursive);
    
    addlistener(h.hTree, 'ItemSelected', @(varargin) h.SelectFcn(varargin{:}));
    
    h.hTree.contextMenuCallback = @(varargin) h.contextMenuCallback(varargin{:});
    h.hTree.keyPressEnterCallback = @(varargin) h.keyPressEnterCallback(varargin{:});
    h.hTree.keyPressEscCallback = @(varargin) delete(h);
    
    if bMultipleSelectionEnabled
        h.hTree.setMultipleSelectionEnabled(true);
        multipleSelectionEnabled = true;
    end
    
    %% Create other elements of the user interface
    % Create command label
    h.hLabelCommand  = uicontrol('Style','edit', 'Fontsize', 10, 'String', 'Command:', 'HorizontalAlignment','left');
    
    % Create row of command buttons
    h.hDebug  = uicontrol('Style','pushbutton', 'Fontsize', 10, 'String', 'Debug','Callback',@(o,e) h.DebugCommand);
    
    % Add contrast controls
    [h.contrast.spinnerA.jhSpinner, ...
        h.contrast.spinnerA.jhSpinnerComponent] = ...
        Spectro.util.addSpinner(h.hFig, ...
        2048, ...           % default
        1, 4096, ...             % min, max
        [-10 -10 1 1], ...                                         % position
        @(o,e) h.contrastCallback, ... % callback
        'Mid-grey level');
    
    [h.contrast.spinnerB.jhSpinner, ...
        h.contrast.spinnerB.jhSpinnerComponent] = ...
        Spectro.util.addSpinner(h.hFig, ...
        4096, ...           % default
        1, 4096, ...             % min, max
        [-10 -10 1 1], ...                                         % position
        @(o,e) h.contrastCallback, ... % callback
        'Window width');
    
    h.hResetContrast = uicontrol('Style','pushbutton', 'Fontsize', 10, 'String', 'Reset Contrast','Callback',@(o,e) h.ResetContrast_Callback);
    h.hAutoContrast = uicontrol('Style','togglebutton', 'Fontsize', 10, 'String', 'Auto Contrast', 'Min', 0, 'Max', 1, 'Value', 1, 'Callback',@(o,e) h.AutoContrast_Callback);
    h.hDataCursor = uicontrol('Style','togglebutton', 'Fontsize', 10, 'String', 'Data Cursor', 'Min', 0, 'Max', 1, 'Value', 0, 'Callback',@(o,e) h.DataCursor_Callback);
    
    % Create axis in which the images will be displayed
    h.hFigAxis  = axes('Parent',h.hFig,'Units','pixels','ActivePositionProperty','OuterPosition','Visible','off');
    
    %% Zoom control
        h.hZoom.button = uicontrol('Style', 'pushbutton', 'Fontsize', 10, 'String', 'Zoom', 'Callback', @(o,e) h.Zoom_Button_Callback);
    h.hZoom.menu = uicontextmenu();
    
    % Define the context menu items and install their callbacks
        h.hZoom.zoom = uimenu(h.hZoom.menu, 'Label', '&Zoom', 'Callback', @(o,e) h.Zoom_Zoom_Callback);
        h.hZoom.pan = uimenu(h.hZoom.menu, 'Label', '&Pan', 'Callback', @(o,e) h.Zoom_Pan_Callback);
        h.hZoom.reset = uimenu(h.hZoom.menu, 'Label', '&Reset', 'Callback', @(o,e) h.Zoom_Reset_Callback, 'Separator', 'on');
        h.hZoom.markOverflow = uimenu(h.hZoom.menu, 'Label', '&Mark overflow', 'Callback', @(o,e) h.Zoom_MarkOverflow_Callback, 'Separator', 'on');
    
    h.hZoom.initXlim = [];
    h.hZoom.initYlim = [];
    
    set(h.hFig,'ResizeFcn',@(o,e) h.ResizeFcn);
    h.ResizeFcn();
    end
    % End of figure creation code.

    %% Action when treenode selected
    function SelectFcn(h,hTree,eventdata)
        % Only deal with the last selected item
        if isempty(hTree.current)
            tmpCurrent = [];
        else
            tmpCurrent = hTree.current(end);
        end
                
        if tmpCurrent.treenodeId == 1
            % ROOT node
            set(h.hLabelCommand,'String','<< Root item selected >>')
            return
        end

        % Copy "current" so that we can update it with extra information
        h.current = tmpCurrent;
        
		if strcmp(h.current.treenode.Type,'Instance')
            [h.current.img, h.current.map] = dicomread(h.current.filename);
            
            % Store current zoom if already loaded at least one image.
            if ishandle(h.hFigImage)
                oldXlim = get(h.hFigAxis,'xlim');
                oldYlim = get(h.hFigAxis,'ylim');

                if isequal(oldXlim,h.hZoom.initXlim) && isequal(oldYlim,h.hZoom.initYlim)
                    oldXlim = [];
                end
            else
                oldXlim = [];
            end
            
            % Remove old image if it's defined.
            try
                if isvalid(h)
                    delete(h.hFigImage)
                end
            catch ME
                disp(ME)
            end
            
            % Avoid colormap conflicts - converts mapped image to true colour before display.
            if isempty(h.current.map)
                valA = double(h.contrast.spinnerA.jhSpinner.getValue());
                valB = double(h.contrast.spinnerB.jhSpinner.getValue());
            
                if valB == 0
                    valB = 1; % Avoid 0 - 0 window map which will crash in mySubimage below.
                end
            
                h.hFigImage = Spectro.util.mySubimage(h.hFigAxis,h.current.img,valA+[-0.5 0.5]*valB);
                
                h.AutoContrast_Callback();
            else
                h.hFigImage = Spectro.util.mySubimage(h.hFigAxis,h.current.img,h.current.map);
            end
            
            % Save full view of the image as zoom default
            zoom(h.hFig,'reset')
            
            h.hZoom.initXlim = get(h.hFigAxis,'Xlim');
            h.hZoom.initYlim = get(h.hFigAxis,'Ylim');
            if ~isempty(oldXlim)
                set(h.hFigAxis,'Xlim',oldXlim,'Ylim',oldYlim);
            end
            
            hold(h.hFigAxis,'on')
            
            % Find the handle for the data cursor; set the update function
            dcmH = datacursormode(gcf);
            set(dcmH,'UpdateFcn',@(aa,ab) Spectro.util.dicomCursorUpdateFcn(aa,ab,h.current.img))
            
            if ~isfield(h.current.thisInfo,'ImageComments')
                h.current.thisInfo.ImageComments = '(No ImageComments)';
            end
            if ~isfield(h.current.thisInfo,'SliceLocation')
                h.current.thisInfo.SliceLocation = '(No SliceLocation)';
            end
            strtodisp = strcat([h.current.thisInfo.ImageComments, ' Slice location: ', num2str(h.current.thisInfo.SliceLocation)]);
            set(h.hLabelCommand,'String',strtodisp);
        else
            set(h.hLabelCommand,'String',h.current.treenode.Description);
        end
    end

    function ResizeFcn(h)
        % Executes when figure is resized.
    
        posFig=get(h.hFig,'Position');
        posTree=[2, 2, posFig(1,3)/2, posFig(1,4)-4];
        posZoom          = [posFig(1,3)/2+5,   posFig(1,4)-24, 40,  20];
        posDataCursor    = [posFig(1,3)/2+50,  posFig(1,4)-24, 85,  20];

        posContrastA     = [posFig(1,3)/2+140, posFig(1,4)-24, 60,  20];
        posContrastB     = [posFig(1,3)/2+205, posFig(1,4)-24, 60,  20];
        posResetContrast = [posFig(1,3)/2+270, posFig(1,4)-24, 100, 20];
        posAutoContrast  = [posFig(1,3)/2+375, posFig(1,4)-24, 100, 20];

        posDebug         = [posFig(1,3)/2+480, posFig(1,4)-24, 50,  20];
       
        posLabelCommand  = [posFig(1,3)/2+5,   posFig(1,4)-48, posFig(1,3)/2-10, 20];
        posFigAxis       = [posFig(1,3)/2+5,   2,              posFig(1,3)/2-10, posFig(1,4)-74];
        
        try
        set(h.hTree.hTree,'Position',posTree);
        catch
        end
        
        set(h.hDebug,'Position',posDebug);
        set(h.contrast.spinnerA.jhSpinnerComponent,'Position',posContrastA);
        set(h.contrast.spinnerB.jhSpinnerComponent,'Position',posContrastB);
        set(h.hResetContrast,'Position',posResetContrast);
        set(h.hAutoContrast,'Position',posAutoContrast);
        set(h.hDataCursor,'Position',posDataCursor);
        set(h.hZoom.button,'Position',posZoom);
        
        set(h.hFigAxis,'OuterPosition',posFigAxis);
        
        set(h.hLabelCommand,'Position',posLabelCommand);
    end

    function Zoom_Button_Callback(h)
        figPoint = get(h.hZoom.button,'Position');
        new_pt = hgconvertunits(h.hFig,figPoint,get(h.hZoom.button,'Units'),'pixels',h.hFig);
        set(h.hZoom.menu,'Position',new_pt([1 2]),'Visible','on');
        
%         figPoint = get(h.hFig,'CurrentPoint');
%         new_pt = hgconvertunits(h.hFig,[0 0 figPoint],get(h.hFig,'Units'),'pixels',h.hFig);
%         set(h.hZoom.menu,'Visible','on','Position',new_pt([3 4]));
    end
    
    function Zoom_Zoom_Callback(h)
        if strcmp(get(h.hZoom.zoom,'Checked'),'on')
            zoom off
            set(h.hZoom.zoom,'Checked','off');
        else
            zoom on
            set(h.hZoom.zoom,'Checked','on');
        end
    end

    function Zoom_Pan_Callback(h)
        if strcmp(get(h.hZoom.pan,'Checked'),'on')
            pan off
            set(h.hZoom.pan,'Checked','off');
        else
            pan on
            set(h.hZoom.pan,'Checked','on');
        end
    end

    function Zoom_Reset_Callback(h)
        zoom off
        
        axis tight
        zoom reset
        
        set(h.hZoom.zoom,'Checked','off');
    end

%% Functions connected to buttons
    function ResetContrast_Callback(h)
        % Reset the contrast to default values
        h.contrast.spinnerA.jhSpinner.setValue(2048);
        h.contrast.spinnerB.jhSpinner.setValue(4096);
    end

    function AutoContrast_Callback(h)
        if get(h.hAutoContrast,'Value')
            if isfield(h.current.thisInfo,'ImageComments') && strcmp(h.current.thisInfo.ImageComments,'Rsquare*4000 Map')
                % Special case for Rsquare*4000 Map to give it sensible range
                clim = [3930 4010];
            else
                % Reset the contrast to default values
                try
                clim(1) = double(min(h.current.img(:).'));
                clim(2) = double(max(h.current.img(:).'));
                catch
                    % There is no current image, so set default values
                    % manually
                    clim = [0 4096];
                end

            end
            
            h.contrast.spinnerA.jhSpinner.setValue((clim(1)+clim(2))/2);
            h.contrast.spinnerB.jhSpinner.setValue(clim(2)-clim(1));
        end
    end

    function DataCursor_Callback(h)
        if get(h.hDataCursor,'Value')
            datacursormode(h.hFig,'on');
        else
            datacursormode(h.hFig,'off');
        end
    end

    function DebugCommand(h)
        disp('Break in DebugCommand - type "dbcont" to resume')
        keyboard
    end

    function contrastCallback(h)
        if isfield(h.current,'map') && isempty(h.current.map)
            valA = double(h.contrast.spinnerA.jhSpinner.getValue());
            valB = double(h.contrast.spinnerB.jhSpinner.getValue());
            
            % Originally plotted with
            %h.hFigImage = subimage(h.current.img,valA+[-0.5 0.5]*valB);
            % But if we call that again we'll duplicate the image object.

            clim = valA+[-0.5 0.5]*valB;
            
            cdata = double(cat(3, h.current.img, h.current.img, h.current.img));
            cdata = (cdata - clim(1)) / (clim(2) - clim(1));
            cdata = min(max(cdata,0),1);
            
            set(h.hFigImage,'CData',cdata);

% TODO: Allow some form of contrast adjustment with a colour map.

%         else
%             h.hFigImage = subimage(h.current.img,h.current.map);
        end
    end

    function Zoom_MarkOverflow_Callback(h)
        if strcmp(get(h.hZoom.markOverflow,'Checked'),'on')
            set(h.hZoom.markOverflow,'Checked','off')
            set(h.hFigImage,'AlphaData',1)
        else
            set(h.hZoom.markOverflow,'Checked','on')
            set(h.hFigAxis,'Color',[1 0 0]);
            set(h.hFigImage,'AlphaData',~(h.current.img>=4095))
        end
    end

    function returnItem(h,selectedNode)
        treedata = h.hTree.evalin('treedata');
        thisData = treedata(selectedNode.getLastPathComponent.getValue);
        h.fireItemChosen(thisData);
    end

    function delete(h)
        disp('Deleting FileOpenGui')
        
        try
            set(h.hFig,'DeleteFcn','');
            delete(h.hFig);
        catch
        end
    end
        
    function fireItemChosen(h,thisData)
        % Fire event for client code that wants to know about item
        % selection asynchronously e.g. to update a figure.
        notify(h,'ItemChosen',Spectro.ItemChosenData(h,thisData));
        
        % Trigger return to client code that wants to know about item
        % selection synchronously. Setting this property will make
        % waitForItemChosen return.
        h.waitState_thisData = thisData;
    end
    
    function [thisData] = waitForItemChosen(h)
    % Block execution until an item has been selected.
    %
    % Returns the data struct associated with the selected node.
    
        h.waitState_thisData = [];
        
        while isvalid(h) && isempty(h.waitState_thisData)
            drawnow
            pause(0.1)
        end
        
        if isvalid(h)
            thisData = h.waitState_thisData;
        else
            thisData = [];
        end
    end
    
    function [thisData] = waitForItemChosenAndClose(h)
    % Block execution until an item has been selected and then close dialog.
    %
    % Returns the data struct associated with the selected node.
        thisData = h.waitForItemChosen();
        delete(h);
    end
    
    function contextMenuCallback(h,hTree,jMenu,treePath)
        item = javax.swing.JMenuItem('<html><b>Select this item</b>');
        hItem = handle(item,'CallbackProperties');
        set(hItem,'ActionPerformedCallback',@(a,b) h.returnItem(treePath));
        jMenu.insert(item,0);
        
        jMenu.insert(javax.swing.JSeparator(),1);
    end
    
    function keyPressEnterCallback(h,hTree,treePath)
        h.returnItem(treePath);
    end
    
    function keyPressFcn(h,hObj,evt)
        if evt.Character == 27 % ESC
            delete(h);
        end
    end
end
end
