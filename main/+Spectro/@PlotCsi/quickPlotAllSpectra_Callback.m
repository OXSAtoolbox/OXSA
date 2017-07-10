function quickPlotAllSpectra_Callback(obj,hObject,eventdata,amaresOutputFilename)  %#ok<INUSD>
% Callback that plots the current voxel spectrum in a new window
%
% Takes care not to make the main GUI lose focus.

% Copyright Chris Rodgers, University of Oxford, 2010-11.
% $Id: quickPlotAllSpectra_Callback.m 5803 2012-09-26 14:42:58Z crodgers $

% If there is already an open window, just refresh it...
try delete(get(4,'UserData')); catch end

if ~ishandle(4)
    oldFig = gcf;
    figure(4);
    figure(oldFig);
    
    % Add menu for selection of display mode
    hMenu = findobj(4,'type','uimenu','tag','QuickPlot');
    if isempty(hMenu) || ~ishandle(hMenu)
        hMenu = uimenu('Label','QuickPlot','tag','QuickPlot','Parent',4);
        hPhaseMode(1) = uimenu('Label','Abs','Accelerator','A','Callback',@(o,e) setPhaseMode(o,'abs'),'Parent',hMenu,'Checked','on');
        strMode = 'abs';
        hPhaseMode(2) = uimenu('Label','Real','Accelerator','R','Callback',@(o,e) setPhaseMode(o,'real'),'Parent',hMenu);
        hPhaseMode(3) = uimenu('Label','Imag','Accelerator','I','Callback',@(o,e) setPhaseMode(o,'imag'),'Parent',hMenu);
    end
end

quickPlotAllSpectra_Helper;

myListener = addlistener(obj,'VoxelChange',@(e,o) quickPlotAllSpectra_Helper());
% Make sure references to the main PlotCsi object are removed by a "close
% all". Otherwise we would have to restart Matlab.
set(4,'DeleteFcn',@(varargin) delete(myListener),'UserData',myListener);

% Pop up the drawn figure before finishing since the user has explicitly clicked it this time.
figure(4)


    function quickPlotAllSpectra_Helper()
        selectedVoxel = obj.voxel;
        selectedSpectra = obj.data.spec.spectra;
        
        %% Plot all absolute spectra
        yMax = 0;
        for coilDx=1:numel(selectedSpectra)
            if max(abs(selectedSpectra{coilDx}(:,selectedVoxel))) > yMax
                yMax = max(abs(selectedSpectra{coilDx}(:,selectedVoxel)));
            end
        end
        
        hFig = 4;
        delete(findobj(hFig,'type','axes'))
        
        subplotRows = ceil(obj.data.spec.coils / 5);
        subplotCols = min(obj.data.spec.coils, 5);
        
        for coilDx=1:obj.data.spec.coils
            newAx = subplot(subplotRows,subplotCols,coilDx,'Parent',hFig);
            
            apodSpec = specApodize(obj.data.spec.dwellTime*(0:size(selectedSpectra{1},1)-1).',selectedSpectra{coilDx}(:,selectedVoxel),50);
            
            % plot(stored.misc.data.ppmaxis{coilDx},abs(selectedSpectra{coilDx}(:,selectedVoxel)));
            
            % TODO: Figure out how strMode can end up being blank.
            if ~exist('strMode','var')
                strMode = 'abs';
            end
            
            if strcmp(strMode,'abs')
                plot(newAx,obj.data.spec.ppmAxis,abs(apodSpec),'b-');
                ylim(newAx,[0 yMax])
            elseif strcmp(strMode,'real')
                plot(newAx,obj.data.spec.ppmAxis,real(apodSpec),'r-');
                ylim(newAx,[-yMax yMax])
            elseif strcmp(strMode,'imag')
                plot(newAx,obj.data.spec.ppmAxis,imag(apodSpec),'g-');
                ylim(newAx,[-yMax yMax])
            else
                error('Unknown plot mode.')
            end
                
            title(newAx,obj.data.spec.coilStrings{coilDx},'interpreter','none')
            set(newAx,'XDir','rev')
            xlim(newAx,minmax(obj.data.spec.ppmAxis.'))
        end
        
        set(hFig,'name',sprintf('Quick plot of voxel #%d',selectedVoxel))
    end

    function setPhaseMode(hObj,newMode)
        set(hPhaseMode,'Checked','off')
        set(hObj,'Checked','on')
        
        strMode = newMode;
        
        quickPlotAllSpectra_Helper();
    end
end
