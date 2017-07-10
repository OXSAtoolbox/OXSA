function cleanupObj = autoWaitCursor(hFig)
% Display a wait cursor in the current figure or a specified figure and
% then automatically restore the original cursor.
%
% EXAMPLE
% cleanupObj = autoWaitCursor();
% or
% cleanupObj = autoWaitCursor(gcf);
%
% When the cleanupObj goes out of scope, the cursor is restored.

% Copyright Chris Rodgers, University of Oxford, 2011.
% $Id: autoWaitCursor.m 4235 2011-05-19 15:57:51Z crodgers $

if nargout < 1
    error('autoWaitCursor() won''t work unless you store the returned onCleanup object.')
end

if nargin < 1
    hFig = gcf;
end

% Create onCleanup object to restore the cursor
currCursor = get(hFig,'Pointer');
cleanupObj = onCleanup(@() set(hFig,'Pointer',currCursor));

% Now show "wait" cursor
set(hFig,'Pointer','watch');
drawnow expose
