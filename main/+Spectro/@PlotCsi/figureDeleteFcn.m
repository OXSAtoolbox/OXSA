function figureDeleteFcn(obj, hObject, eventdata)
% There is a memory leak in Matlab with Java object callbacks that causes
% a class to be locked in memory if the callbacks are not cleared properly.

try, obj.misc.panes(1).spinner.jhSpinner.StateChangedCallback = []; catch, end
try, obj.misc.panes(2).spinner.jhSpinner.StateChangedCallback = []; catch, end
try, obj.misc.panes(3).spinner.jhSpinner.StateChangedCallback = []; catch, end

