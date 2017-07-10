function output_txt = dicomCursorUpdateFcn(obj,event_obj,rawData)
% Display the position of the data cursor
% obj          Currently not used (empty)
% event_obj    Handle to event object
% rawData      Unmapped data values
% output_txt   Data cursor text string (string or cell array of strings).

% This function is designed to work with "image" objects, whose XData and
% YData have the default values.

% Sanity checks
target = get(event_obj,'Target');

if ~strcmp(get(target,'type'),'image')
    error('Unsuitable object type.')
end

% position of the data point to label
pos = get(event_obj,'Position');
% catch
%     disp('!!!')
%     keyboard
% end

% read the x and y data
xvals = get(get(event_obj,'Target'),'XData');
yvals = get(get(event_obj,'Target'),'YData');

if numel(xvals) ~= 2 || ~all(xvals == [1 size(rawData,2)]) ...
   numel(yvals) ~= 2 || ~all(yvals == [1 size(rawData,1)])
error('Wrong size XData or YData')
end

% create the text to be displayed
output_txt = { sprintf('Val = %d', rawData(pos(2),pos(1)));...
    ['X: ',num2str(pos(1),4)];...
    ['Y: ',num2str(pos(2),4)] };

% If there is a Z-coordinate in the position, display it as well
if length(pos) > 2
    output_txt{end+1} = ['Z: ',num2str(pos(3),4)];
end
end
