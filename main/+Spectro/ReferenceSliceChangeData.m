classdef ReferenceSliceChangeData < event.EventData
% Class for data returned by Spectro.PlotCsi's ReferenceSliceChange event.
  
    properties(SetAccess='private')
        plotCsiObj
        refDx
        sliceDx
    end
    
    methods
        function obj = ReferenceSliceChangeData(plotCsiObj,refDx,sliceDx)
            obj.plotCsiObj = plotCsiObj;
            obj.refDx = refDx;
            obj.sliceDx = sliceDx;
        end
    end
end
