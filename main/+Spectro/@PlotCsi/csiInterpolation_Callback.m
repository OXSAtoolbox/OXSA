function csiInterpolation_Callback(obj,hObject,eventdata)
% Set whether the CSI voxels are interpolated.

% Copyright Chris Rodgers, University of Oxford, 2010-11.
% $Id: csiInterpolation_Callback.m 4072 2011-04-08 13:30:59Z crodgers $

newVal = get(hObject,'Value');

fprintf('DEBUG: csiInterpolation_Callback %d --> %d.\n',...
    obj.csiInterpolated,...
    newVal);

if obj.csiInterpolated ~= newVal
    obj.csiInterpolated = newVal;
end
