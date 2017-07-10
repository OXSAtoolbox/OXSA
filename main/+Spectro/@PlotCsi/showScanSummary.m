function showScanSummary(obj, bPopupWindow)
% Dump information about this data set.
%
% If bPopupWindow is true (default), display a pop-up window with the
% details.
% If bPopupWindow is false, print to the command window instead.

% Copyright Chris Rodgers, Univ Oxford, 2013.
% $Id$

if ~exist('bPopupWindow','var')
    bPopupWindow = true;
end

if ~bPopupWindow
    obj.data.spec.printScanSummary(false);
else
    strBuffer = evalc('obj.data.spec.printScanSummary(true)');
    
    activeBrowser = com.mathworks.mde.webbrowser.WebBrowser.getActiveBrowser;
    if isempty(activeBrowser)
        % If there is no active browser, create a new one.
        activeBrowser = com.mathworks.mde.webbrowser.WebBrowser.createBrowser(1, 0);
    end
    activeBrowser.setHtmlText(['<html><head><title>showScanSummary</title></head><body><h2>showScanSummary</h2>' regexprep(strBuffer,'\n','<br>\n') '</body></html>']);
end
