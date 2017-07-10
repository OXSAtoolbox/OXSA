% Matlab GUI to load main spectroscopy GUI running in deployed mode.
% 
% Contains methods to save the scan details to a collection of scans in a
% text file and re run all scans in a collection automatically.
% 
% COMPILE THIS BY RUNNING deployExe.m


% Copyright Chris Rodgers, University of Oxford, 2008-13.
% $Id: PlotCsi.m 7560 2014-04-02 14:09:44Z will $

classdef deployedGUI < dynamicprops

    % Public
    properties
        mainHandle;
        previousLoadDir;
    end
    
    properties(SetAccess = private)
        plotCsiObj;
        currCsihandle;
    end
    
    % GUI-related properties that should not be saved
    properties(Transient)
        menu;
        buttons;
    end

methods    
    function guiObj = deployedGUI()
        % Main GUI function.

        
        %% Create the GUI
        % Associate object with the GUI.
        % Using a handle object means that we never have to call guidata to STORE
        % these values again, only guidata(figNumber) to retrieve a reference.
        guiObj.mainHandle = figure('units','pixels',...
            'position',[500 500 300 150],...
            'menubar','none',...
            'numbertitle','off',...
            'name','31P-MRS Loader',...
            'resize','off');
        
        guidata(guiObj.mainHandle,guiObj);
        
        %% Create the buttons
        guiObj.buttons.load = uicontrol('style','pushbutton',...
            'units','pix',...
            'position',[75 115 150 30],...
            'string','Load',...
            'callback',@guiObj.gui_load);
        
        guiObj.buttons.close = uicontrol('style','pushbutton',...
            'units','pix',...
            'position',[5 45 145 30],...
            'string','Close all',...
            'callback',@guiObj.gui_close);
        
        guiObj.buttons.save = uicontrol('style','pushbutton',...
            'units','pix',...
            'position',[5 5 145 30],...
            'string','Save scan details ',...
            'Enable','off');
        
        guiObj.buttons.saveAndClose = uicontrol('style','pushbutton',...
            'units','pix',...
            'position',[155 5 145 70],...
            'string','Save and close ',...
            'Enable','off');
        
        guiObj.buttons.runMultiple = uicontrol('style','pushbutton',...
            'units','pix',...
            'position',[75 80 150 30],...
            'string','Run multiple',...
            'callback',{@gui_runAllInCollection,guiObj.mainHandle});
        
        %% Create the menue items
        guiObj.menu.settings = uimenu('label','Settings');
        guiObj.menu.setEnvVar = uimenu('Parent',guiObj.menu.settings,'Label','Set enviroment variables','Callback',@guiObj.setEnvVar);
        guiObj.menu.openCollFolder = uimenu('Parent',guiObj.menu.settings,'Label','Open folder containing collections','Callback',@guiObj.openCollFolder);
        guiObj.menu.openResFolder = uimenu('Parent',guiObj.menu.settings,'Label','Open results folder ','Callback',@guiObj.openResFolder);



    end
    
    %% Close all open figures except the main one, disable the callbacks for the save functions
    function gui_close(guiObj,~,~)        
        set(guiObj.mainHandle, 'HandleVisibility', 'off');
        close all;
        set(guiObj.mainHandle, 'HandleVisibility', 'on');
        
        set(guiObj.buttons.save,'enable','off','callback',{});
        set(guiObj.buttons.saveAndClose,'enable','off','callback',{});
    end

    
    function gui_saveAndClose(guiObj,~,~,plotCSIobj)
        
        gui_saveDetails([],[],plotCSIobj);
        
        set(guiObj.mainHandle, 'HandleVisibility', 'off');
        close all;
        set(guiObj.mainHandle, 'HandleVisibility', 'on');
        
        set(guiObj.buttons.save,'enable','off','callback',{});
        set(guiObj.buttons.saveAndClose,'enable','off','callback',{});
    end
    
    function gui_load(guiObj,~,~)
        
        if ~isempty(guiObj.previousLoadDir)
            folder_name = uigetdir(guiObj.previousLoadDir);
            guiObj.previousLoadDir = folder_name;
        else
            folder_name = uigetdir(getenv('userprofile'));
            guiObj.previousLoadDir = folder_name;
        end
        
        try
            ret = guiPromptSpectroPlotCsi(folder_name,'clinicianMode',true);
            
            guiObj.plotCsiObj = ret.obj;
            guiObj.currCsihandle = ret.h;
            
        catch err
            if (strcmp(err.identifier,'MATLAB:exist:firstInputString'))
                disp('Invalid folder choice.')
                return
            else
                return
            end
        end
        
        % Enable the extra buttons
        set(guiObj.buttons.save,'enable','on','callback',{@gui_saveDetails,guiObj.plotCsiObj});
        set(guiObj.buttons.saveAndClose,'enable','on','callback',{@guiObj.gui_saveAndClose,guiObj.plotCsiObj});
        
    end

end % End 

methods(Static)
    % open the folder in explorerr
    function openCollFolder(~,~)
        dir = getenv('31PScanCollections');
        disp(dir)
%         system('set')
        winopen(dir);
    end
    
    function openResFolder(~,~)
        dir = getenv('31PCollectionResults');
        disp(dir)
%         system('set')
        winopen(dir);
    end
    
    function setEnvVar(~,~)
        
        % Collections path
        envName1 = '31PScanCollections';
        startDir = getenv(envName1);
        folder_name1 = uigetdir(startDir,'Select path for the "31PScanCollections" enviroment variable:');
        cmd = sprintf('setx %s "%s"',envName1,folder_name1);
        system(cmd);
%       setenv('31PScanCollections',folder_name1) % Only for current
%       process and subprocesses.
        fprintf('31PScanCollections enviroment variable set to %s.\n',folder_name1)
        
        % Results path
        envName2 = '31PCollectionResults';
        startDir = getenv(envName2);
        folder_name2 = uigetdir(startDir,'Select path for the "31PCollectionResults" enviroment variable:');
        cmd = sprintf('setx %s "%s"',envName2,folder_name2);
        system(cmd);
        fprintf('31PCollectionResults enviroment variable set to %s.\n',folder_name2)
        
        % Ask to restart the system. This is nessecary to get the deployed
        % version to recognise the changes.
        button = questdlg('For the program to recognise these changes the computer must be restarted.','Restart?','Restart now','Later','Restart now');
        switch button
            case 'Restart now'
                system('shutdown -r')
            case 'Later'
                disp('Restart before running any option except "Load" and "Close all"')
                return
        end        
        
    end
    
    %% All other methods defined in external files
    
    gui_saveDetails(h,o,obj);
    gui_runAllInCollection(h,o,mainHandle);
    
end % End static methods

end % End classdef