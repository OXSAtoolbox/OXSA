function hHumanAxis = addHumanPositionMarker(hAxes)
% Add a 3D graphic of a human body to indicate DICOM orientations.
%
% If a human body has already been drawn, update the listeners to
% synchronise the view with the specified axis/axes.
%
% hAXes: Axis handle(s) to be associated with the human figure.
%
% SEE ALSO:
% Spectro.dicomImage.plot()

% Copyright Chris Rodgers, University of Oxford, 2008-12.
% $Id$

if nargin < 1
    hAxes = gca;
end

hFig = get(hAxes,'Parent');

if iscell(hFig)
    if isequal(hFig{:})
        hFig = hFig{1};
    else
        error('Axes must be children of the same figure.')
    end
end

% Store original axis
origAxis = get(get(0,'CurrentFigure'),'CurrentAxes');

% Check if human figure already drawn.
hHumanAxis = findobj(hFig,'tag','humanPositionMarker','type','axes');

if isempty(hHumanAxis) || ~ishandle(hHumanAxis)
    % Plot a human figure
    hHumanAxis = axes('position',[0.8 0 0.2 0.5]);
    plotHuman(hHumanAxis);
end

% Set axes to equal vis3d mode to ensure consistent rotation
axis(hAxes,'equal','vis3d')

% Add/update view and listeners
set([hHumanAxis; hAxes(:)],'CameraUpVector',[0 -1 0])
set(hHumanAxis,'CameraPosition',[-3 -3 -3])

for idx=1:numel(hAxes)
    view(hAxes(idx),45,45)
end

cameratoolbar(hFig,'SetCoordsys','y')
cameratoolbar(hFig,'SetMode','orbit')
cameratoolbar(hFig,'Show')

% Synchronise rotations of the master / legend images
set(hHumanAxis,'UserData',[]);
stored = [];

allAxes = [hAxes(:);hHumanAxis];

for axisDx = 1:numel(allAxes)
    % R2014b fix. Not sure if this code will work in earlier versions too.
    % hAxisObj = handle(allAxes(axisDx)); % Fetch associated handle OBJECT.
    % stored.hListener(1,axisDx) = handle.listener(hAxisObj,findprop(hAxisObj,'CameraPosition'),'PropertyPostSet',{@(h,e) linkplot_helper(h,e,allAxes,hHumanAxis)});
    % stored.hListener(2,axisDx) = handle.listener(hAxisObj,findprop(hAxisObj,'CameraUpVector'),'PropertyPostSet',{@(h,e) linkplot_helper(h,e,allAxes,hHumanAxis)});
stored.hListener{1,axisDx} = addlistener(allAxes(axisDx),'CameraPosition','PostSet',@(h,e) linkplot_helper(h,e,allAxes,hHumanAxis));
stored.hListener{2,axisDx} = addlistener(allAxes(axisDx),'CameraUpVector','PostSet',@(h,e) linkplot_helper(h,e,allAxes,hHumanAxis));
end

stored.timer = timer('BusyMode','drop','ExecutionMode','singleShot',...
                     'Name','addHumanPositionMarker_Timer');

set(hHumanAxis,'UserData',stored)

% Restore axis
if ~isempty(origAxis) && ishandle(origAxis)
    axes(origAxis);
end
end

function linkplot_helper(hProp,evt,hAxes,hHumanAxis)
stored = get(hHumanAxis,'UserData');

if ~strcmp(stored.timer.Running,'off')
	stop(stored.timer);
end

% Exclude axis that triggered event from synchronisation
hAxes(evt.AffectedObject.eq(hAxes))=[];

stored.timer.StartDelay = 0.3; % Units s
stored.timer.TimerFcn = {@linkplot_helper_timeout,evt.AffectedObject,hAxes,hHumanAxis};
start(stored.timer);
end

function linkplot_helper_timeout(hTimer, evt, hObj, hAxes, hHumanAxis)
% Link plots by synchronising CameraPosition and CameraTarget properties

% See "Defining Scenes with Camera Graphics" for details of the properties
% that are set in this function.

theCameraVec = normalise(hObj.CameraPosition - hObj.CameraTarget);
theCameraUpVector = hObj.CameraUpVector;

for idx=1:numel(hAxes)
    set(hAxes(idx),'CameraUpVector',theCameraUpVector);
    set(hAxes(idx),'CameraTarget',[0 0 0]);
    set(hAxes(idx),'CameraPosition',theCameraVec*norm(get(hAxes(idx),'CameraPosition')));
end
end
