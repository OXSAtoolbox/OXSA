classdef dicomUiTree < handle
% Select DICOM file interactively.
%
% The dicomUiTree object can be retrieved from the GUI by:
% obj=getappdata(findobj(gcf,'Tag','dicomUiTree'),'dicomUiTree');

% Copyright Chris Rodgers, University of Oxford, 2010-11.
% $Id: FileOpenGui.m 4004 2011-03-16 16:42:26Z crodgers $

    properties
        evalin      % Evaluate code with access to treedata.
        hTree       % Java tree object handle.
        contextMenuCallback % Allow customisation of the right-click menu.
        keyPressEnterCallback % Allow customisation of the ENTER keypress.
        keyPressEscCallback % Allow customisation of the ESC keypress.
    end
    
    properties(SetAccess='protected')
        current     % Formatted copy of data for most recently selected node.
        hFig        % Handle of parent figure.
        setSelection % Set the item selected in the GUI.
        multipleSelectionEnabled = 0; % Whether multiple items may be selected. Default FALSE.
        strTopdir   % Top of the tree
        bRecursive  % Set Spectro.dicomTree to scan folders recursively.
    end
    
    methods 
    function [h] = dicomUiTree(strTopdirOrDicomTree,hFig,position,bRecursive)
        % Construct (and draw) a dicomUiTree object.
        
        %% Process input arguments
        if nargin < 1 || isempty(strTopdirOrDicomTree)
            strTopdirOrDicomTree = uigetdir(pwd(),'Choose top level folder');
            
            if ~ischar(strTopdirOrDicomTree) && strTopdirOrDicomTree == 0
                return; % Cancel was pressed.
            end
        end
        
        if isa(strTopdirOrDicomTree,'Spectro.dicomTree')
            h.strTopdir = strTopdirOrDicomTree.path;
        else
            h.strTopdir = strTopdirOrDicomTree;
        end
        
        if nargin < 2 || isempty(hFig)
            h.hFig = gcf;
        else
            h.hFig = hFig;
            clear hFig;
        end
        
        if nargin < 3 || isempty(position)
            tmpPosFig=get(h.hFig,'Position');
            position=[2, 2, tmpPosFig(3)-4, tmpPosFig(4)-4];
        end
        
        if nargin < 4 || isempty(bRecursive)
            h.bRecursive = false;
        else
            h.bRecursive = bRecursive;
        end

        %% Set up variable used to store data associated with each tree node.
        % A nested variable is used for performance reasons to avoid the
        % (severe) performance penalty of repeated access to class member
        % variables.
        
        % Node types:
        % 'Root'
        % 'Folder'
        % DICOM 'Study'
        % DICOM 'Series'
        % DICOM 'Instance'
        %
        % The nodes in the tree at each level are sorted.
        %
        % There is no guarantee that neighbouring nodes in the GUI
        % have neighbouring treedata indices but they WILL be in the same
        % order.

        treedata = struct('ParentId',{},...
            'Type',{},...
            'Description',{},...
            'Path',{});
        
        h.current = struct('treenodeId',{},'treenode',{},'filename',{},'thisInfo',{});

        % Create tree GUI control with (hidden) root node with value "1"
        root = uitreenode('v0', 1, 'DICOM', [], false);
        treedata(1).ParentId = 0;
        treedata(1).Type = 'Root';
        h.hTree = uitree('v0', 'Parent', h.hFig, ...
            'Position', position, ...
            'Root', root, ...
            'ExpandFcn', @ExpandFcn );
        set(h.hTree,'NodeSelectedCallback', @SelectFcn);
        h.hTree.getTree.setRootVisible(false);
        setappdata(h.hTree.UIContainer,'dicomUiTree',h);
        origDeleteFcn = get(h.hTree.UIContainer,'DeleteFcn');
        set(h.hTree.UIContainer,...
            'DeleteFcn',@(obj,evt) myDeleteFcn(obj,evt,origDeleteFcn),...
            'Tag','dicomUiTree');
        clear origDeleteFcn

        % Add context menu
        jTree = handle(h.hTree.getTree,'CallbackProperties');
        jMenu = javax.swing.JPopupMenu;
        set(jTree,'MousePressedCallback',{@JTree_MousePressedCallback, jMenu});
        set(jTree,'KeyPressedCallback',{@JTree_KeyPressedCallback, jMenu});
%         set(jTree,'KeyTypedCallback',@tmpFcn);
%         set(jTree,'KeyReleasedCallback',@tmpFcn);

        % Add the first visible nodes
        if isa(strTopdirOrDicomTree,'Spectro.dicomTree')
            addItemToTree(1,'Folder',h.strTopdir,strTopdirOrDicomTree);
        else
            if iscellstr(h.strTopdir)
                for idx=1:numel(h.strTopdir)
                    addItemToTree(1,'Folder',h.strTopdir{idx});
                end
            else
                addItemToTree(1,'Folder',h.strTopdir);
            end
        end
        h.hTree.expand(root);
        drawnow
        drawnow
        
        % Allow access with TAB key
        jTree.setFocusable(true);
        jTree.requestDefaultFocus;

        % Select and expand first visible node
        h.hTree.setSelectedNode(root.getChildAt(0));
        h.hTree.expand(root.getChildAt(0));
        h.hTree.getTree.scrollPathToVisible(javax.swing.tree.TreePath(root.getChildAt(0).getPath()));

        % "Method" for external code to access treedata
        h.evalin = @evalin;
        
        % "Method" to programatically set active node
        h.setSelection = @(varargin) setSelection_Private(h,varargin{:});

        return
        % End of figure creation code.

    %% Action when treenode selected
    function SelectFcn(tree, ~)
        nodes = tree.SelectedNodes;
    
        % TODO: Accelerate this function by only updating nodes that have changed.
        h.current = struct('treenodeId',{},'treenode',{},'filename',{},'thisInfo',{});
        
        for nodeDx = 1:numel(nodes)
            h.current(nodeDx).treenodeId=nodes(nodeDx).getValue;
            h.current(nodeDx).treenode=treedata(h.current(nodeDx).treenodeId);
        end
        
        % For efficiency reasons, only load the last node to be selected
        if numel(nodes) > 0 && strcmp(h.current(numel(nodes)).treenode.Type,'Instance')
            % Parse DICOM info and store for later use
            h.current(numel(nodes)).filename = h.current(numel(nodes)).treenode.Data.Filename;
            h.current(numel(nodes)).thisInfo = SiemensCsaParse(dicominfo(h.current(numel(nodes)).filename));
        end
        
        notify(h,'ItemSelected');
    end

    %% Action when treenode is Expanded
    function nodes = ExpandFcn(~, ParentId)
        % onCleanup to restore the cursor
        currCursor = get(h.hFig,'Pointer');
        c = onCleanup(@() set(h.hFig,'Pointer',currCursor));
        % Now show "wait" cursor
        set(h.hFig,'Pointer','watch');
        drawnow expose
        
        % Decide how to expand depending on what type of node this is
        parentnode = treedata(ParentId);
        
        % For speed (accessing dynamicprops properties is slow), gather
        % together a whole batch of child nodes and store them together
        % when this function finishes.
        
        % The node ID corresponds to an index into a struct array. This is
        % the quickest method available (see testSpeedOfDynamicProps.m).
        
        if strcmp(parentnode.Type,'Folder')
            % In recursive mode, don't show the file structure again
            if ~h.bRecursive
            
                % Folder - expand by searching on disk
                files = dir(parentnode.Path);
                
                for idxB = 1:numel(files)
                    if files(idxB).isdir && ~strcmp(files(idxB).name,'.') && ~strcmp(files(idxB).name,'..')
                        addItemToTree(ParentId,'Folder',files(idxB).name);
                    end
                end
            
            end
            
            if isfield(parentnode,'dicomTree') && isa(parentnode.dicomTree,'Spectro.dicomTree')
                % Spectro.dicomTree was supplied when loading - use it
                dicomData = parentnode.dicomTree;
            else
                % Scan folder for DICOM files
                dicomData = Spectro.dicomTree('dir',parentnode.Path,'recursive',h.bRecursive);
            end
            
            % Add appropriate nodes to the tree data in memory
            for StudyDx=1:numel(dicomData.study)
                thisStudyId = addItemToTree(ParentId, 'Study', dicomData.study(StudyDx), dicomData);
                
                for SeriesDx=1:numel(dicomData.study(StudyDx).series)
                    thisSeriesId = addItemToTree(thisStudyId, 'Series', dicomData.study(StudyDx).series(SeriesDx), dicomData);
                    
                    for InstanceDx=1:numel(dicomData.study(StudyDx).series(SeriesDx).instance)
                        %thisInstanceId = % Not used
                        addItemToTree(thisSeriesId, 'Instance', dicomData.study(StudyDx).series(SeriesDx).instance(InstanceDx), dicomData);
                    end
                end
            end
        end
        
        % Take all children
        treenodesDx = find([treedata.ParentId]==ParentId);
        
        for idxB = 1:numel(treenodesDx)
            if strcmp(treedata(treenodesDx(idxB)).Type,'Folder')
                % Matlab compiler script include:
                %#include_exec [matlabroot,'\toolbox\matlab\icons\foldericon.gif']
                iconpath = [matlabroot,'/toolbox/matlab/icons/foldericon.gif'];
                leaf = false;
            elseif strcmp(treedata(treenodesDx(idxB)).Type,'Study')
                % Matlab compiler script include:
                %#include_exec [matlabroot,'\toolbox\matlab\icons\HDF_pointfieldset.gif']
                iconpath = [matlabroot,'/toolbox/matlab/icons/HDF_pointfieldset.gif'];
                leaf = false;
            elseif strcmp(treedata(treenodesDx(idxB)).Type,'Series')
                % Check for ShMOLLI colour maps
                isShmolli = 0;
                try
                    if regexp(treedata(treenodesDx(idxB)).Data.instance(1).ImageComments,'^(ShMOLLI color |ShMOLLI2 T1 color)','once')
                        isShmolli = 1;
                    end
                catch
                end
                try
                    if regexp(treedata(treenodesDx(idxB)).Data.instance(1).ImageComments,'^MOLLI2 T1 color','once')
                        isShmolli = 2;
                    end
                catch
                end
                try
                    if regexp(treedata(treenodesDx(idxB)).Data.instance(1).ImageComments,'^SATREC T1 color','once')
                        isShmolli = 3;
                    end
                catch
                end
                
                if isShmolli == 1
                    % Matlab compiler script include:
                    %#include_exec [matlabroot,'\toolbox\matlab\icons\greencircleicon.gif']
                    iconpath = [matlabroot,'/toolbox/matlab/icons/greencircleicon.gif'];
                elseif isShmolli == 2
                    % Matlab compiler script include:
                    %#include darkgreencircleicon.png
                    iconpath = fullfile(fileparts(mfilename('fullpath')),'darkgreencircleicon.png');
                elseif isShmolli == 3
                    % Matlab compiler script include:
                    %#include darkgreencircleicon.png
                    iconpath = fullfile(fileparts(mfilename('fullpath')),'darkgreencircleicon.png');
                else
                    % Matlab compiler script include:
                    %#include_exec [matlabroot,'\toolbox\matlab\icons\file_open.png']
                    iconpath = [matlabroot,'/toolbox/matlab/icons/file_open.png'];
                end
                leaf = false;
            elseif strcmp(treedata(treenodesDx(idxB)).Type,'Instance')
                % Matlab compiler script include:
                %#include_exec [matlabroot,'\toolbox\matlab\icons\pageicon.gif']
                iconpath = [matlabroot,'/toolbox/matlab/icons/pageicon.gif'];
                leaf = true;
            else
                warning('Unknown item type')
                iconpath = [];
                leaf = true;
            end
            
            % TODO: Provide callback that executes here to permit
            % customisation of the tree icons.
            %
            % E.g. Spectroscopy code can mark spectroscopy data, ShMOLLI
            % code could mark ShMOLLI data sets.
            
            nodes(idxB) = uitreenode('v0',treenodesDx(idxB),treedata(treenodesDx(idxB)).Description, iconpath, leaf); %#ok<AGROW>
        end
        
        if numel(treenodesDx) == 0
            nodes = [];
        end
    end

    function [newId] = addItemToTree(ParentId,Type,data,dicomTree)
        % Type = 'Folder': FOLDER. Pass in the folder name.
        % TYPE = 'Study': DICOM STUDY.
        % TYPE = 'Series': DICOM SERIES.
        % TYPE = 'Instance': DICOM INSTANCE (e.g. image or spectrum).
        
        newId = numel(treedata)+1;
        
        theparent = treedata(ParentId);
        
        % Process the different types appropriately
        switch Type
            case 'Folder'
                if strcmp(theparent.Type, 'Folder')
                    ParentPath = theparent.Path;
                else
                    ParentPath = '';
                end
                treedata(newId).Description = data;
                treedata(newId).Path = fullfile(ParentPath, data);
                
                if exist('dicomTree','var') % For recursive dicomTree initialisation.
                    treedata(newId).dicomTree = dicomTree;
                end
                
            case 'Study'
                treedata(newId).Description = sprintf('%s: %s (%d)',data.StudyID,...
                    data.StudyDescription,numel(data.series));
                treedata(newId).StudyID = data.StudyID;
                treedata(newId).Data = data;
                treedata(newId).dicomTree = dicomTree;
                
            case 'Series'
                treedata(newId).Description = sprintf('%d: %s (%d)',data.SeriesNumber,...
                    data.SeriesDescription,numel(data.instance));
                treedata(newId).SeriesNumber = data.SeriesNumber;
                treedata(newId).Data = data;
                treedata(newId).dicomTree = dicomTree;
                
            case 'Instance'
                treedata(newId).Description = sprintf('%d: %s [%s]',data.InstanceNumber,...
                    data.ImageComments, data.Filename);
                treedata(newId).InstanceNumber = data.InstanceNumber;
                treedata(newId).Data = data;
                treedata(newId).dicomTree = dicomTree;
                
            otherwise
                error('Unknown tree node type')
                % N.B. Must not set any part of treedata before this to
                % guarantee that we remain self-consistent.
        end
        
        treedata(newId).ParentId = ParentId;
        treedata(newId).Type = Type;
    end

    function JTree_MousePressedCallback(~, eventData, jMenu)
        if eventData.isMetaDown  % Right-click is like a Meta-button
            % Get the clicked node
            clickX = eventData.getX;
            clickY = eventData.getY;
            jtree = eventData.getSource;
            treePath = jtree.getPathForLocation(clickX, clickY);
            
            if isempty(treePath)
                return
            end
            
            JTree_MousePressedCallback_doWork(jMenu, jtree, treePath, clickX, clickY);
        end
    end
    
    function JTree_MousePressedCallback_doWork(jMenu, jtree, treePath, ptX, ptY)
        % Reset the Java menu to show a summary of important information
        % about the selected item.
        
        jMenu.removeAll
        
        node = treePath.getLastPathComponent;
        item = javax.swing.JMenuItem(['Right-click on ' char(node.getName)]);
        jMenu.add(item);
        
        if ~isempty(h.current)
            selectedNodeDx = find(node.getValue() == [h.current.treenodeId],1,'last');
            
            if ~isempty(selectedNodeDx) && strcmp(h.current(selectedNodeDx).treenode.Type,'Instance') && ~isempty(h.current(selectedNodeDx).thisInfo)
                % This is the selected node. Query DICOM information
                try
                    txt = sprintf('SeriesDate: %s, SeriesTime: %s, AcquisitionTime: %s',h.current(selectedNodeDx).thisInfo.SeriesDate,h.current(selectedNodeDx).thisInfo.SeriesTime,h.current(selectedNodeDx).thisInfo.AcquisitionTime);
                    jMenu.add(txt);
                    
                    txt = regexprep(evalc('disp(h.current(selectedNodeDx).thisInfo.PatientName)'),'^ *','');
                    jMenu.add(txt);
                    
                    dcm = Spectro.dicom(h.current(selectedNodeDx).thisInfo);
                    coilInfo = dcm.getCoilInfo();
                    if isfield(coilInfo,'name')
                        jMenu.add(sprintf('Coil: "%s"',coilInfo.name));
                    end
                catch
                    txt = sprintf('Unexpected DICOM information format');
                    jMenu.add(txt);
                end
            end
        end
        
        % Allow customisation of the menu
        if isa(h.contextMenuCallback,'function_handle')
            h.contextMenuCallback(h,jMenu,treePath);
        end
        
        % Display the (possibly-modified) context menu
        jMenu.show(jtree, ptX, ptY); % Displays the popup menu at the position x,y in the coordinate space of the component invoker.
        jMenu.repaint;
    end
    
    function JTree_KeyPressedCallback(~, eventData, jMenu)
        % ENTER: Select item.
        % "/" or "?": Display right-click menu.
        
%         eventData.getKeyCode()
        
        if eventData.getKeyCode() == 10
            % ENTER: Select item.
            disp('SELECT...')

            % Get the clicked node
            jtree = eventData.getSource;
            treePath = jtree.getSelectionPath();
            
            if isempty(treePath)
                return
            end
            
            if isa(h.keyPressEnterCallback,'function_handle')
                h.keyPressEnterCallback(h,treePath);
            end

        elseif eventData.getKeyCode() == 47
            % "/" or "?": Display right-click menu.
            disp('RIGHT CLICK MENU')
           
            % Get the clicked node
            jtree = eventData.getSource;
            treePath = jtree.getSelectionPath();
            
            if isempty(treePath)
                return
            end
            
            pT = jtree.getRowBounds(jtree.getRowForPath(jtree.getSelectionPath)).getLocation();
            
            % Nudge down +20 so as to not hide item that was chosen.
            JTree_MousePressedCallback_doWork(jMenu, jtree, treePath, pT.x, pT.y + 20);
            
        elseif eventData.getKeyCode() == 27 % ESC
            if isa(h.keyPressEscCallback,'function_handle')
                h.keyPressEscCallback(h);
            end
        end
    end

    function [varargout] = evalin(varargin)
        varargout = cell(1,nargout);
        
        [varargout{:}] = eval(varargin{:});
    end

    function str = forceEndFilesep(str)
        if numel(str) < 1 || str(end) ~= filesep()
            str(end+1) = filesep();
        end
    end
    
    function setSelection_Private(h, strPath, uid)
        % Select the requested folder or DICOM study/series/instance in the
        % tree. Expands nodes as required.
        
        % Ensure strPath ends in a separator
        strPath = forceEndFilesep(strPath);
        
        % Set up comparison function
        if ispc
            compFunc = @(testPath) strncmpi(strPath, testPath, numel(testPath));
        else
            compFunc = @(testPath) strncmp(strPath, testPath, numel(testPath));
        end
        
        % Walk the tree searching for a matching folder first.
        path = 1;
        thisNode = root;
        h.hTree.expand(thisNode);
        drawnow
        
        bMatchPart = true;
        bMatchFull = false;
        
        while bMatchPart
            thisLevelDx = find([treedata.ParentId] == path(end));
            thisLevelDx(~strcmp('Folder',{treedata(thisLevelDx).Type})) = [];
        
            bMatchPart = false;
            for idxC=1:numel(thisLevelDx)
                testPath = forceEndFilesep(treedata(thisLevelDx(idxC)).Path);
            
                if compFunc(testPath)
                    %disp('MATCH')
                    %treedata(thisLevelDx(idxC))
                    path(end+1) = thisLevelDx(idxC); %#ok<AGROW>
                    bMatchPart = true;
                    
                    % Find tree node
                    [thisNode] = findTreeNode(h, thisNode, thisLevelDx(idxC));
                    
                    if numel(strPath) == numel(testPath)
                        % Exact match
                        bMatchFull = true;
                    end
                    break
                end
            end
        end
        
        if ~bMatchFull
            error('No such item in the tree.')
        end

        if nargin >= 3
            % Then search for a matching UID therein.
            
            % thisLevelDx contains the treedata IDs for all Dicom "STUDY"
            % object in this folder. I.e. it excludes subfolders.
            thisLevelDx = find([treedata.ParentId] == path(end));
            thisLevelDx(~strcmp('Study',{treedata(thisLevelDx).Type})) = [];
            
            for studyDx = thisLevelDx % Set studyDx to treedata ID for each study in turn.
                dicomPath = searchForUid(Spectro.dicomTree(struct('study',treedata(studyDx).Data)),uid);
                
                if ~isempty(dicomPath)
                    % There is a matching series/instance in this study, so
                    % we must walk through Java tree of GUI node objects in
                    % order to select it.
                    
                    thisNode = findTreeNode(h, thisNode, studyDx); % Find corresponding JAVA tree node object.
                    
                    if isfield(dicomPath,'seriesDx')
                        seriesLevel = find([treedata.ParentId] == studyDx); % List of treedata IDs for series in the current study.
                        seriesDx = seriesLevel(dicomPath.seriesDx); % Pick out the correct series. This relies on the fact that the ordering of nodes in the Java tree and in treenode are identical.
                        
                        if ~isempty(seriesDx)
                            thisNode = findTreeNode(h, thisNode, seriesDx); % Find corresponding JAVA tree node object.
                            
                            if isfield(dicomPath,'instanceDx')
                                instanceLevel = find([treedata.ParentId] == seriesDx); % List of treedata IDs for instances in the current series.
                                instanceDx = instanceLevel(dicomPath.instanceDx); % Pick out the correct instance. This relies on the fact that the ordering of nodes in the Java tree and in treenode are identical.
                                
                                if ~isempty(instanceDx)
                                    thisNode = findTreeNode(h, thisNode, instanceDx); % Find corresponding JAVA tree node object.
                                end
                            end
                        end
                    end
                end
            end
        end
        
        % Mark the selected node in the user interface.
        h.hTree.setSelectedNode(thisNode);
        try
            h.hTree.getTree.scrollPathToVisible(javax.swing.tree.TreePath(thisNode.getPath()));
        catch
            warning('Exception while scrolling dicomUiTree control.')
        end
        h.hTree.repaint;
    end
    
    function [thisNode] = findTreeNode(h, thisNode, targetDx)
        % Find tree node
        bFoundChild = false;
        for chDx=1:thisNode.getChildCount
            testNode = thisNode.getChildAt(chDx-1);
%             fprintf('Searching node %d, saw %d.\n',targetDx,testNode.getValue);
            if testNode.getValue == targetDx
                thisNode = testNode;
                h.hTree.expand(thisNode);
                drawnow
                bFoundChild = true;
                break
            end
        end
        
        if ~bFoundChild
            error('Error expanding nodes.')
        end
    end
    
    function myDeleteFcn(obj,evt,origDeleteFcn)
        disp('Cleaning up dicomUiTree')
        % Chain original DeleteFcn that removed java object
        if ~isempty(origDeleteFcn) % CTR: Matlab R2014b fix. Perhaps origDeleteFcn generating code should be changed instead?
            feval(origDeleteFcn{1},obj,evt,origDeleteFcn{2:end});
        end
        % Delete Matlab dicomUiTree object
        if isvalid(h)
            delete(h);
        end
    end
    
    end % End of the constructor (and its nested functions).
    
    function delete(h)
    % dicomUiTree destructor (which deletes GUI object too)
        disp('dicomUiTree delete(...):')
        
        try
            if ishandle(h.hTree)
                delete(h.hTree)
            end
        catch ME
            disp(ME)
        end
    end
    
    function setMultipleSelectionEnabled(h,newVal)
        warning('setMultipleSelectionEnabled is currently very much in BETA state. Expect errors!')
        h.multipleSelectionEnabled = newVal;
        h.hTree.setMultipleSelectionEnabled(newVal)
    end
    end % End of the methods
    
    events
        ItemSelected % Fired when a node has been selected.
    end
end % End of the class
