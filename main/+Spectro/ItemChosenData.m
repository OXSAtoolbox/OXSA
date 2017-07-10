classdef ItemChosenData < event.EventData
% Class for data returned by Spectro.FileOpenGui's ItemChosen event.
  
    properties(SetAccess='private')
        fileOpenGuiObj
        thisData
    end
    
    methods
        function obj = ItemChosenData(fileOpenGuiObj,thisData)
            obj.fileOpenGuiObj = fileOpenGuiObj;
            obj.thisData = thisData;
        end
    end
end
