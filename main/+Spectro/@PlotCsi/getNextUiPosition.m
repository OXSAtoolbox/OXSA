function [newPos] = getNextUiPosition(obj, newHeight, bLabel, bMoveDown)
% bLabel: false (default) if this is a button or other control
% bLabel: true if this is a label
%
% bMoveDown: true (default) if we increment position
% bMoveDown: false otherwise

% Check that the corner position has been defined
if ~isfield(obj.misc,'uiNextCorner')
    error('You must define the corner position to start with! E.g. ''obj.misc.uiNextCorner = [0.9 0.96]; % Top Left corner''')
end

if nargin < 4
    bMoveDown = true;
end

% Normally not a label
if nargin < 3
    bLabel = false;
end

% Default button height
if nargin < 2
    newHeight = 0.03;
end

if bLabel == 2
    % Two column
    newWidth = 0.18;
    newHOffset = -0.1;
elseif bLabel == 1
    % Left column
    newWidth = 0.150;
    newHOffset = -0.155;
else
    % Right column
    newWidth = 0.08;
    newHOffset = 0;
end

newPos = [obj.misc.uiNextCorner(1)+newHOffset ...
          obj.misc.uiNextCorner(2)-newHeight ...
          newWidth ...
          newHeight];

if bMoveDown
    obj.misc.uiNextCorner(2) = obj.misc.uiNextCorner(2) - newHeight - 0.01;
end
