function prettyPrint(dicomTree, bShowInWindow)
% List all DICOM files in a tree.
%
% dicomTree - Spectro.dicomTree object containing details of files to display.
% bShowInWindow - display results in a web browser window rather than in
%                 the Matlab command window.

% Copyright Chris Rodgers, University of Oxford, 2008-13.
% $Id: prettyPrint.m 6108 2013-02-04 14:24:21Z crodgers $

error(nargchk(1, 2, nargin, 'struct'))

if nargin < 2
    bShowInWindow = false;
end

strBuffer = [];
if bShowInWindow
    out = @mySprintf;
else
    out = @fprintf;
end

if ~bShowInWindow
    out('\n')
end

if isempty(dicomTree.study)
    out('No DICOM files found.\n')
    if bShowInWindow, showInBrowser(), end;
    return
end

for nStudy=1:numel(dicomTree.study)
    thisStudy = dicomTree.study(nStudy);
    
    try
        thisDir = fileparts(thisStudy.series(1).instance(1).Filename);
    catch ME
        thisDir = '';
    end
    
    out('\nDICOM Study #<a href="matlab:clipboard(''copy'',''%s'')">%s</a>: "%s" [%s]\n', thisStudy.StudyInstanceUID, thisStudy.StudyID, thisStudy.StudyDescription, thisDir);
    
    for nSeries=1:numel(thisStudy.series)
        thisSeries = thisStudy.series(nSeries);
        
        out('DICOM series <a href="matlab:clipboard(''copy'',''%s'')">%d</a> (<a href="matlab:clipboard(''copy'',''%s'')">path</a>): %s:%s:%s on %s/%s/%s, "%s" [',...
        thisSeries.SeriesInstanceUID,...
        thisSeries.SeriesNumber,...
        thisSeries.instance(1).Filename,...
        thisSeries.SeriesTime(1:2),thisSeries.SeriesTime(3:4),thisSeries.SeriesTime(5:6),...
        thisSeries.SeriesDate(7:8),thisSeries.SeriesDate(5:6),thisSeries.SeriesDate(1:4),...
        thisSeries.SeriesDescription)
    
        for nInstance=1:numel(thisSeries.instance)
            if nInstance == 1
                strSep = '';
            else
                strSep = ' ';
            end
            
            out('%s<a href="matlab:clipboard(''copy'',''%s'')">%d</a>',strSep,thisSeries.instance(nInstance).SOPInstanceUID,thisSeries.instance(nInstance).InstanceNumber);
        end
   
        out(']\n');
    end
end

if bShowInWindow
    showInBrowser()
else
    out('\n\n')
end

return

    function mySprintf(varargin)
        strBuffer = [ strBuffer sprintf(varargin{:}) ];
    end

    function showInBrowser()
        %% Pop up DICOM tree
        activeBrowser = com.mathworks.mde.webbrowser.WebBrowser.getActiveBrowser;
        if isempty(activeBrowser)
            % If there is no active browser, create a new one.
            activeBrowser = com.mathworks.mde.webbrowser.WebBrowser.createBrowser(1, 0);
        end
        activeBrowser.setHtmlText(['<html><head><title>' dicomTree.path '</title></head><body><h2>' dicomTree.path '</h2>' regexprep(strBuffer,'\n','<br>\n') '</body></html>']);
    end

end
