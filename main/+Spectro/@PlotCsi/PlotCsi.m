% Matlab GUI to view Siemens CSI (2d or 3d) data, with the localisation
% displayed using 2d slices and marker lines.
%
% Options may be passed as name, value pairs or as a struct.

% Copyright Chris Rodgers, University of Oxford, 2008-14.
% $Id: PlotCsi.m 11600 2017-07-10 14:19:07Z lucian $

classdef PlotCsi < dynamicprops
    
    % Public properties
    properties
        debug = false;
        showSliceLines = 1; % This should probably become a dependent property.
    end
    
    % Read-only property with the data
    properties(SetAccess=protected)
        data;
        overlay;
    end
    
    % GUI-related properties that should not be saved
    properties(Transient)
        handles;
        menu;

        % Extra data is stored here during development. Once the code is
        % stable, a class property should be created.
        misc = struct();
    end
    
    % See "Avoiding Property Initialization Order Dependency" in the Matlab
    % help for explanation of this next code.
    properties(Access=private)
        privateVoxel = 1;
        privateCsiSlice = 1;
        privateTitle = 'Main Window';
    end
    properties(Dependent)
        voxel;
        csiSlice;
        csiInterpolated;
        title;
        csiShift;
    end
    
    methods
        function obj = PlotCsi(theDicomPathOrTree, spectraUid, varargin)
            % Constructor
            
            %% Check input arguments
            narginchk(2, Inf)
            
            % If no options argument, set a default value
            options = processVarargin(varargin{:});
            
            % Scan through options setting essential fields
            optionsDefaults = {'debug',0;
                'referenceImages',NaN;
                'loadedData',{};
                'referenceImagesDefaultSlices',[];
                'voxel',[]};
            for idx=1:size(optionsDefaults,1)
                if ~isfield(options,optionsDefaults{idx,1})
                    options.(optionsDefaults{idx,1}) = optionsDefaults{idx,2};
                end
            end
            
            %% Debug flag
            if options.debug
                obj.debug = true;
            end
            
            %% Create GUI and allocated main stored memory
            % Associate object with the GUI.
            % Using a handle object means that we never have to call guidata to STORE
            % these values again, only guidata(figNumber) to retrieve a reference.
            scrsz = get(0,'ScreenSize');
            obj.handles.mainWindow=figure('IntegerHandle','off','HandleVisibility','on','Tag','Spectro.PlotCsi','Name','PlotCsi V2 [Main Window]','NumberTitle','off','Position',[scrsz(3)/2-350 scrsz(4)/2-300 700 600],'PaperPositionMode','auto','Color',[1 1 1],'DeleteFcn',@obj.figureDeleteFcn);
            clf;
            guidata(gcf,obj);
            
            %% Load data unless it has been provided already (for debugging)
            if isempty(options.loadedData)
                obj.data=obj.preLoadData(theDicomPathOrTree, spectraUid, options);
            else
                obj.data=options.loadedData;
            end
            
            % Set default slice
            if numel(options.referenceImagesDefaultSlices) ~= obj.data.numRefs
                for refdx=1:obj.data.numRefs
                    options.referenceImagesDefaultSlices(refdx) = obj.data.pathRef{refdx}.instanceDx;
                end
            end
            
            %% Set the opening voxel selection
            if numel(options.voxel) == 0
                % Set the default voxel to the central voxel with CSI interpolation on
                obj.voxel = obj.data.spec.colRowSliceToVoxel(ceil(obj.data.spec.size / 2));
            else
                obj.voxel = options.voxel;
            end
            
            %% Plot the localisers in 3D code
            figure(obj.handles.mainWindow)
            set(gcf,'Toolbar','none')
            
            % Plot reference image axes separately
            % The "main" view goes along the top and is biggest.
            % Remaining views are tiled along the bottom.
            
            obj.misc.panes = [];
            
            % Axis colour scheme
            [obj.misc.axisColours.active, obj.misc.axisColours.inactive] = obj.calcColours(obj.data.numRefs);
            
            for refdx=1:obj.data.numRefs
                if refdx == obj.data.numRefs
                    obj.misc.panes(refdx).hCsiAxis = subplot('position',[0 0.3 0.8 0.7]);
                else
                    obj.misc.panes(refdx).hCsiAxis = subplot('position',[(refdx-1)*0.8/(obj.data.numRefs-1) 0 0.8/(obj.data.numRefs-1) 0.3]);
                end
                
                obj.misc.panes(refdx).nSlice = options.referenceImagesDefaultSlices(refdx); % Default
                
                for refdx2=1:numel(obj.data.imgRef{refdx})
                    obj.misc.panes(refdx).hImages(refdx2) = ...
                        obj.impatch2d(obj.data.imgRef{refdx}{refdx2},...
                        obj.data.infoRef{refdx}{refdx2}.PixelSpacing);
                    
                    if refdx2~=options.referenceImagesDefaultSlices(refdx)
                        set(obj.misc.panes(refdx).hImages(refdx2),'Visible','off')
                    end
                    
                    set(obj.misc.panes(refdx).hImages(refdx2),'HitTest','off');
                    hold on
                end
                
                set(obj.misc.panes(refdx).hCsiAxis,'ydir','rev','color',obj.misc.axisColours.active(refdx,:),'xcolor',obj.misc.axisColours.active(refdx,:),'ycolor',obj.misc.axisColours.active(refdx,:),'xtick',[],'ytick',[],'visible','on');
                axis tight
                
                % Add a coloured margin to the LHS of localizer
                oldXlim=get(obj.misc.panes(refdx).hCsiAxis,'xlim');
                set(obj.misc.panes(refdx).hCsiAxis,'xlim',oldXlim+[-2 0])
                
                obj.projectVector_Prepare(refdx);
            end
            
            % TODO: There is a bug when the first slice of a stack doesn't intersect
            % another reference image but other slices do. Needs to be handled better.
            
            % Mark intersection with other reference images a la Syngo
            for refdx=1:obj.data.numRefs
                axes(obj.misc.panes(refdx).hCsiAxis);
                for refdxOther=1:obj.data.numRefs
                    obj.misc.panes(refdx).hIntersectLines{refdxOther} = [];
                    if refdx ~= refdxOther % Don't intersect with self
                        for refdxOther2=1:numel(obj.data.imgRef{refdxOther})
                            try
                            obj.misc.panes(refdx).hIntersectLines{refdxOther}(refdxOther2) ...
                                = obj.calcPlaneIntersect(obj.data.infoRef{refdx}{1},obj.data.infoRef{refdxOther}{refdxOther2});
                            catch
                                obj.misc.panes(refdx).hIntersectLines{refdxOther}(refdxOther2) = NaN;
                            end
                        end
                    end
                end
            end
            
            obj.updatePlaneIntersect()
            
            %% Add menu items
            obj.menu.sep = uimenu('Label','|','Enable','off');
            obj.menu.plotCsi = uimenu('Label','&PlotCsi');
            obj.menu.quickFit = uimenu('Parent',obj.menu.plotCsi,'Label','&Quick Fit','Callback',@obj.quickFit_Callback,'Accelerator','J');
            
            obj.menu.showSliceLines = uimenu('Parent',obj.menu.plotCsi,'Label','Show Slice &Lines','Callback',@obj.showSliceLines_Callback,'Accelerator','L','Separator','on','Checked','on');
            
            set(findall(obj.handles.mainWindow,'type','uimenu','label','&Save'),'Accelerator','') % Remove CTRL-S for SAVE
            obj.menu.showSatBands = uimenu('Parent',obj.menu.plotCsi,'Label','Show &Saturation Bands','Callback',@(o,e) obj.drawSatBands(),'Accelerator','S');
            
            % # --> END
            % ' --> RIGHT-ARROW
            % What else is possible??
            obj.menu.showScanSummary = uimenu('Parent',obj.menu.plotCsi,'Label','Show scan summary &info','Callback',@(o,evt) obj.showScanSummary,'Accelerator','#');

            obj.menu.identifyDicomFilesInDir = uimenu('Parent',obj.menu.plotCsi,'Label','&Dicom files in directory','Callback',@(o,evt) identifyDicomFilesInDir(obj.data.dicomTree),'Accelerator','D','Separator','on');
            
            obj.menu.halfVoxelShift = uimenu('Parent',obj.menu.plotCsi,'Label','&Half Voxel Shift','Callback',@obj.halfVoxShift_Callback,'Accelerator','H','Separator','on','Checked','off');

            obj.menu.about = uimenu('Parent',obj.menu.plotCsi,'Label','&About...','Callback',@(obj,evt) web('http://rodgers.org.uk/','-browser'),'Separator','on');
            
            % Add sliders
            obj.misc.uiNextCorner = [0.9 0.98]; % Top Left corner of first button.
            
            %% Add UI controls along RHS
            % (The function obj.getNextUiPosition handles stacking these.)
            
            % Version information
            svnRevision = regexp('$Revision: 11600 $',['\$' 'Revision: ([0-9]+) \$'],'tokens','once');
            svnDate = regexp('$Date: 2017-07-10 15:19:07 +0100 (Mon, 10 Jul 2017) $',['^\$' 'Date: ([0-9-]+ [0-9]+:[0-9]+)'],'tokens','once');
            
            % "Inactive" tweak documented at: http://www.mathworks.com/support/solutions/en/data/1-158CEG/index.html?product=ML&solution=1-158CEG
            obj.handles.versionLabel=uicontrol('Parent',gcf,'Style','text',...
                'string',{['Spectro.PlotCsi (Ver ' svnRevision{1} ' ' svnDate{1} ')'];
                '© Chris Rodgers, University of Oxford, 2008-14.'},...
                'BackgroundColor',get(obj.handles.mainWindow,'Color'),...
                'ForegroundColor',[0 0 0.8],...
                'Enable','inactive',...
                'ButtonDownFcn',@(obj,evt) web('http://rodgers.org.uk/','-browser'),...
                'horiz','center','units','norm','position',obj.getNextUiPosition(0.03,2,true));
            
            % CSI slice
            obj.handles.sliderCsiSlice=sliderEx(obj.csiSlice,1,obj.data.spec.slices,1,...
                @obj.sliderCsiSlice_Callback,...
                'Parent',gcf,'units','norm','pos',obj.getNextUiPosition(0.02,false,false));
            obj.handles.sliderCsiSlice.timeout = 0.1; % 0.1s timeout so GUI doesn't redraw at every step as the slider is dragged.
            if obj.debug, obj.handles.sliderCsiSlice.debug = true; end
            
            obj.handles.sliderCsiSliceLabel=uicontrol('Parent',gcf,'Style','text','string',sprintf('CSI Slice: %d ',obj.csiSlice),...
                'horiz','right','units','norm','BackgroundColor',[1 1 1],...
                'position',obj.getNextUiPosition(0.02,true,true));
            
            % Voxel number
            obj.handles.sliderNVoxel=sliderEx(obj.voxel,1,prod(obj.data.spec.size),1,...
                @obj.voxelNumberCallback,...
                'Parent',gcf,'units','norm','pos',obj.getNextUiPosition(0.02,false,false));
            
            obj.handles.sliderNVoxelLabel=uicontrol('Parent',gcf,'Style','text','string',sprintf('Voxel Number: %d ',obj.voxel), ...
                'horiz','right','units','norm','BackgroundColor',[1 1 1],...
                'position',obj.getNextUiPosition(0.02,true,true));
            
            % jMRUI export
            obj.handles.quickFit = uicontrol('Parent',gcf,'Style','pushbutton','units','norm','pos',obj.getNextUiPosition(),...
                'String','Quick Fit','Callback',@obj.quickFit_Callback);
            
            obj.handles.quickPlotSpec = uicontrol('Parent',gcf,'Style','pushbutton','units','norm','pos',obj.getNextUiPosition(),...
                'String','Quick plot spectrum','Callback',@obj.quickPlotSpectrum_Callback);
            
            obj.handles.quickPlotFid = uicontrol('Parent',gcf,'Style','pushbutton','units','norm','pos',obj.getNextUiPosition(),...
                'String','Quick plot FID','Callback',@obj.quickPlotFid_Callback);
            
            obj.handles.quickPlotAllSpec = uicontrol('Parent',gcf,'Style','pushbutton','units','norm','pos',obj.getNextUiPosition(),...
                'String','ALL spectra','Callback',@obj.quickPlotAllSpectra_Callback);
            
            obj.handles.interpolated = uicontrol('Parent',gcf,'Style','togglebutton','units','norm','pos',obj.getNextUiPosition(),...
                'String','CSI Interpolation','value',1,'Callback',@obj.csiInterpolation_Callback);
            
            obj.handles.debugBreak = uicontrol('Parent',gcf,'Style','pushbutton','units','norm','pos',obj.getNextUiPosition(),...
                'String','Debug break','Callback',@obj.debugBreak);
            
            obj.handles.showSliceLines = uicontrol('Parent',gcf,'Style','togglebutton','Value',1,'units','norm','pos',obj.getNextUiPosition(),...
                'String','Show Slice Lines','Callback',@obj.showSliceLines_Callback);
            
            obj.misc.TA = obj.data.spec.info{1}.csa.SliceMeasurementDuration/1000; % In seconds
            
            obj.handles.textTA=uicontrol('Parent',gcf,'Style','text','string',sprintf('TA=%d:%0.2d',floor(obj.misc.TA/60),floor(mod(obj.misc.TA,60))), ...
                'horiz','center','units','norm', ...
                'position',obj.getNextUiPosition(0.02));
            
            obj.csiInterpolated = 1; % TODO: Is this needed?
            obj.csiShift = [0 0 0];
            
            for refdx=1:obj.data.numRefs
                % Create out of view. Will be shifted by figure's ResizeFcn.
                %
                % N.B. MUST add corresponding clean-up of the callback function to the
                % figure's DeleteFcn. Otherwise, this class will be locked in memory
                % until Matlab is restarted with a warning:
                %
                % Warning: Objects of 'Spectro.PlotCsi' class exist. Cannot clear this
                % class or any of its super-classes.
                %
                % N.B. MUST store reference to this Java control in a
                % Transient property. Otherwise Matlab R2010b crashes and
                % takes down the whole computer when the object is passed
                % to save(...).
                
                [obj.misc.panes(refdx).spinner.jhSpinner, ...
                    obj.misc.panes(refdx).spinner.jhSpinnerComponent] = ...
                    Spectro.PlotCsi.addSliceSelector(obj.handles.mainWindow, ...    % hFig
                    options.referenceImagesDefaultSlices(refdx), ...           % default
                    1, numel(obj.data.infoRef{refdx}), ...             % min, max
                    [-10 -10 1 1], ...                                         % position
                    {@obj.refCallback, refdx},... % callback
                    sprintf('Study %s, Series %d "%s"',... % tooltip
                    obj.data.dicomTree.study(obj.data.pathRef{refdx}.studyDx).StudyID,...
                    obj.data.dicomTree.study(obj.data.pathRef{refdx}.studyDx).series(obj.data.pathRef{refdx}.seriesDx).SeriesNumber,...
                    obj.data.dicomTree.study(obj.data.pathRef{refdx}.studyDx).series(obj.data.pathRef{refdx}.seriesDx).SeriesDescription)...
                    );
                
                obj.misc.panes(refdx).spinner.cmdButton = ...
                    uicontrol('Parent',obj.handles.mainWindow,...
                    'Style','pushbutton',...
                    'FontName','Consolas','FontSize',16,...
                    'String','<html>&#x25BA;</html>',...
                    'Position',[-10 10 1 1],...
                    'Callback',{@obj.refCmdButtonCallback, refdx});
                
                %Add the contrast spinners
                % Add contrast controls
                [obj.misc.panes(refdx).contrast_spinnerA.jhSpinner, ...
                    obj.misc.panes(refdx).contrast_spinnerA.jhSpinnerComponent] = ...
                    Spectro.util.addSpinner(obj.handles.mainWindow, ...
                    140, ...           % default
                    1, 4096, ...             % min, max
                    [-10 -10 1 1], ...       % position
                    {@obj.plotCSI_contrastCallback,refdx}, ... % callback
                    'Mid-grey level',...
                    'step',10);
                set(obj.misc.panes(refdx).contrast_spinnerA.jhSpinnerComponent,'visible','off')
                
                [obj.misc.panes(refdx).contrast_spinnerB.jhSpinner, ...
                    obj.misc.panes(refdx).contrast_spinnerB.jhSpinnerComponent] = ...
                    Spectro.util.addSpinner(obj.handles.mainWindow, ...
                    270, ...           % default
                    1, 4096, ...             % min, max
                    [-10 -10 1 1], ...                                         % position
                    {@obj.plotCSI_contrastCallback,refdx}, ... % callback
                    'Window width',...
                    'step',10);
                set(obj.misc.panes(refdx).contrast_spinnerB.jhSpinnerComponent,'visible','off')

                
                obj.misc.panes(refdx).refMenu.menu = uicontextmenu();
                
                % Define the context menu items and install their callbacks
                obj.misc.panes(refdx).refMenu.adjContrast = uimenu(obj.misc.panes(refdx).refMenu.menu, 'Label', 'Adjust &contrast', 'Callback', @(o,e) obj.refCmdButton_AdjContrast(o,e,refdx), 'Checked', 'off');
                
                obj.misc.panes(refdx).refMenu.loadImg = uimenu(obj.misc.panes(refdx).refMenu.menu, 'Label', '&Load', 'Callback', @(o,e) obj.refCmdButton_Load(o,e,refdx),'Separator', 'on');
                
                obj.misc.panes(refdx).refMenu.autoCsiSlice = uimenu(obj.misc.panes(refdx).refMenu.menu, 'Label', '&Auto CSI slice', 'Callback', @(o,e) obj.refCmdButton_AutoCsiSlice(o,e,refdx), 'Separator', 'on', 'Checked', 'off');
                % This may be an inappropriate place for this.
                obj.misc.panes(refdx).autoUpdate = false;
                                
                %     obj.misc.panes(refdx).refMenu.reset = uimenu(obj.misc.panes(refdx).refMenu.menu, 'Label', '&Reset', 'Callback', @Zoom_Reset_Callback, 'Separator', 'on');
                %     obj.misc.panes(refdx).refMenu.markOverflow = uimenu(obj.misc.panes(refdx).refMenu.menu, 'Label', '&Mark overflow', 'Callback', @Zoom_MarkOverflow_Callback, 'Separator', 'on');
            end
            
            % Set window title
            obj.title = sprintf('%s, Study %s, Series %d "%s"',...
                obj.data.dicomTree.path,...
                obj.data.dicomTree.study(obj.data.specPath.studyDx).StudyID,...
                obj.data.dicomTree.study(obj.data.specPath.studyDx).series(obj.data.specPath.seriesDx).SeriesNumber,...
                obj.data.dicomTree.study(obj.data.specPath.studyDx).series(obj.data.specPath.seriesDx).SeriesDescription);
            
            % Set arrow key handler
            set(obj.handles.mainWindow,'WindowKeyPressFcn',@obj.arrowKey_Callback);
            
            % Set the resize handler and call once to initialise
            set(obj.handles.mainWindow,'ResizeFcn',@obj.resizeFcn)
            obj.resizeFcn(obj.handles.mainWindow)
            
            %% Draw voxels
            obj.drawVoxels();          
                        
            disp('Done plotting')
        end
        
        % For debugging, override "whos" to dump the size of the class members
        function whos(h)
            origWarn = warning();
            warning off 'MATLAB:structOnObject'
            try
                s = builtin('struct', h); % use 'builtin' in case struct() is overridden
                vsize(s);
            catch
            end
            warning(origWarn);
        end

        %% Get/Set methods
        function set.showSliceLines(obj,newVal)
            if newVal == obj.showSliceLines
                return
            end
            
            if newVal
                obj.showSliceLines = 1;
                set(obj.handles.showSliceLines,'Value',1);
                set(obj.menu.showSliceLines,'Checked','on');
            else
                obj.showSliceLines = 0;
                set(obj.handles.showSliceLines,'Value',0);
                set(obj.menu.showSliceLines,'Checked','off');
            end
            
            % Redraw GUI
            obj.updatePlaneIntersect();
        end
        
        function retval = get.voxel(obj)
            retval = obj.privateVoxel;
        end
        
        function retval = get.csiSlice(obj)
            retval = obj.privateCsiSlice;
        end
        
        function retval = get.csiShift(obj)
            retval = obj.data.spec.csiShift;
        end
        
        function set.csiShift(obj,newVal)
            oldVal = obj.data.spec.csiShift;
            obj.data.spec.csiShift = newVal;
            
            if ~isequal(oldVal, newVal)
                % Force redraw of CSI grid.
                obj.csiSlice = obj.csiSlice;
            end
        end
        
        function retval = get.csiInterpolated(obj)
            retval = obj.data.spec.csiInterpolated;
        end
        
        function set.csiInterpolated(obj,newVal)
            oldVal = obj.data.spec.csiInterpolated;
            obj.data.spec.csiInterpolated = newVal;
            
            if oldVal ~= newVal
                % Set max CSI slice
                if ~obj.csiInterpolated && ...
                        (obj.csiSlice > obj.data.spec.slices ...
                         || obj.voxel > prod(obj.data.spec.size))
                    obj.voxel = prod(obj.data.spec.size);
                end
        
                % Force redraw of CSI grid. Deal with cases where CSI slice
                % has changed or not to force full redraw.
                oldCsiSlice = obj.csiSlice;
                
                obj.voxel = obj.voxel;
                
                if obj.csiSlice == oldCsiSlice               
                    obj.csiSlice = obj.csiSlice;
                end
                
                obj.handles.sliderCsiSlice.max = obj.data.spec.slices;
                obj.handles.sliderNVoxel.max = prod(obj.data.spec.size);
            end
        end
        
        function set.voxel(obj,newVal)
            if newVal < 1 || newVal > prod(obj.data.spec.size) || isnan(newVal)
                error('Voxel number out of range. Not changed.')
            else
                obj.privateVoxel = newVal;
            end
            
            % If the option to automatically select a reference image is
            % selected, then do so here.
            try
                for refDx = 1:obj.data.numRefs
                    if obj.misc.panes(refDx).autoUpdate
                        obj.autoRefOnVoxSelect(refDx,newVal);                
                    end
                end
            catch
            end
            % Calculate the in-plane voxel number (i.e. the index to the
            % handle of the patch on screen) and the slice number.
            [idxInSlice, slice] = obj.data.spec.voxelToIdxInSliceAndSlice(newVal);
            
            try
                obj.handles.sliderNVoxel.value = newVal;
                
                for refdx=1:numel(obj.misc.panes)
                    set(obj.misc.panes(refdx).hVoxels,'FaceAlpha',0);
                    set(obj.misc.panes(refdx).hVoxels(idxInSlice),'FaceAlpha',0.2)
                end
                
                if isequal(obj.csiShift,[0 0 0])
                    voxTag = '';
                else
                    voxTag = '+';
                end
                set(obj.handles.sliderNVoxelLabel,'string',sprintf('Voxel Number: %d%s ',obj.voxel,voxTag));
            catch
            end
            
            if obj.csiSlice ~= slice
                obj.csiSlice = slice;
            end
            
            notify(obj,'VoxelChange')
        end
        
        function set.csiSlice(obj,newVal)
            if newVal < 1 || newVal > obj.data.spec.slices
                error('CSI slice number out of range. Not changed.')
            else
                obj.privateCsiSlice = newVal;
            end
            
            try
                obj.handles.sliderCsiSlice.value = newVal;
                set(obj.handles.sliderCsiSliceLabel,'string',sprintf('CSI Slice: %d ',obj.csiSlice));
                obj.drawVoxels();
            catch
            end
            
            % Choose corresponding voxel in the current slice if necessary.
            % Decode current voxel number
            [idxInSlice, slice] = obj.data.spec.voxelToIdxInSliceAndSlice(obj.privateVoxel);
            
            % Ensure we are in the correct slice
            newVoxel = obj.data.spec.idxInSliceAndSliceToVoxel(idxInSlice, obj.privateCsiSlice);
            
            % Update voxel number if necessary
            if obj.voxel ~= newVoxel
                obj.voxel = newVoxel;
            end
        end
        
        function [retval] = get.title(obj)
            retval = obj.privateTitle;
        end
        
        function set.title(obj,newVal)
            if ~ischar(newVal)
                error('title must be a string.')
            end
            
            obj.privateTitle = newVal;
            
            set(obj.handles.mainWindow,'Name',['Spectro.PlotCsi [' newVal ']']);
        end
        

        %% All other methods defined in external files
        autoRefOnVoxSelect(obj,refdx1,newVoxel);
        autoCSISliceOnRefSelect(obj,refdx1,refdx2);
        arrowKey_Callback(obj,hObject,eventData);
        csiInterpolation_Callback(obj,hObject,eventdata);
        csiInterpolation_Deinterpolate(obj);
        debugBreak(obj,hObject,eventdata);
        drawSatBands(obj);
        drawVoxels(obj);
        figureDeleteFcn(obj, hObject, eventdata);
        quickFit_Callback(obj,hObject,eventdata);
        [projVec, projVecInPlane, projVecPerp] = projectVector(obj,refdx,refdx2,inputVec,strType);
        projectVector_Prepare(obj,refdx);
        quickPlotAllSpectra_Callback(obj,hObject,eventdata);
        quickPlotFid_Callback(obj,hObject,eventdata);
        quickPlotSpectrum_Callback(obj,hObject,eventdata);
        refCallback(obj,hObject,eventdata,refdx);
        refCmdButton_AdjContrast(obj,hObject,eventdata,refdx);
        refCmdButton_AutoCsiSlice(obj,hObject,eventdata,refdx);
        refCmdButton_Load(obj,hObject,eventdata,refdx);
        refCmdButtonCallback(obj,hObject,eventdata,refdx);
        refPane_reload(obj,newFileData_Data,refdx);
        resizeFcn(obj,hObject,eventdata);
        setOverlay(obj,varargin);
        setCustomReconSpec(obj,newSpec);
        showSliceLines_Callback(obj,hObject,eventData);
        sliderCsiSlice_Callback(obj,sliderCsiSlice);
        updatePlaneIntersect(obj);
        voxelClicked_Callback(obj,hObject,eventdata);
        voxelNumberCallback(obj,hObject,eventdata);
        saveFolder = makeLoadDir(obj);
        saveFolder = makeSaveDir(obj);
        savedResultsFile = loadDataGui(obj,strFileMatch,varargin);
        position = calcVoxelCentreCoords(obj,nVoxel);
        printFigure(obj,varargin);
        plotCSI_contrastCallback(obj,hObject,eventdata,refdx);
        [hNew] = copyToFigure(obj, hNew, paneDxToCopy);
        strOut = showScanSummary(obj,bPopupWindow);
        halfVoxShift_Callback(obj,hObject,eventdata);
    end
    
    methods(Static)
        [jhSpinner, jhSpinnerComponent] ...
            = addSliceSelector(hFig, startSlice, minSlice, maxSlice, pos, callback, tooltip);
        [active, inactive] ...
            = calcColours(num);
        [hLine, pointOnLine, directionVector] ...
            = calcPlaneIntersect(infoRef,info2);
        [posNew] ...
            = getPlotBox(hAxis);
        [data] ...
            = preLoadData(dicomPathOrTree, spectraUid, options);
        [h] ...
            = impatch2d(img,pixelSpacing);
        [isect] ...
            = intersectLineAndLineSegment(x0,xL,rA,rB);
        [projVec, projVecInPlane, projVecPerp] ...
            = projectVector_Raw(infoRef,inputVec,strType);
    end
    
    events
        ReferenceSliceChange
        VoxelChange
    end
end
