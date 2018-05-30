function dicomData = processDicomDirRecursive(strPath, parallelRecursion, strWildcard, bIgnoreCache, bDisplayProgress, bDetailedHdrInfo)
% Return dicomData structure for all DICOM files in a folder recursively.
%
% strPath - folder to search or cell array of folders to search.
%
% Any further arguments (e.g. wildcard) are passed unchanged to
% processDicomDir().
%
% Example:
% dicomData = processDicomDirRecursive(pwd)

% Copyright Chris Rodgers, University of Oxford, 2011.
% $Id$

if ~exist('parallelRecursion','var')
    parallelRecursion = false;
end

if ~exist('strWildcard','var')
    strWildcard = '';
end

if ~exist('bIgnoreCache','var')
    bIgnoreCache = false;
end

if ~exist('bDisplayProgress','var')
    bDisplayProgress = true;
end

if ~exist('bDetailedHdrInfo','var')
    bDetailedHdrInfo = false;
end

% Perform a depth-first traversal of folders under strPath
if iscell(strPath)
    dirList = strPath(:);
else
    dirList{1} = strPath;
end

idx = 1;
while idx <= numel(dirList)
    d = dir(dirList{idx});
    
    d(strcmp({d.name},'.')) = [];
    d(strcmp({d.name},'..')) = [];
    
    newDirs = {d([d.isdir]).name}.';
    
    for jdx=1:numel(newDirs)
       newDirs{jdx} = fullfile(dirList{idx},newDirs{jdx}); 
    end
    
    dirList = [dirList(1:idx); newDirs; dirList((idx+1):end)];
    
    idx = idx+1;
end

% Process each individual folder
dicom = cell(size(dirList));
if parallelRecursion
    parfor idx=1:numel(dirList)
        dicom{idx} = processDicomDir(dirList{idx},strWildcard, bIgnoreCache, false, bDetailedHdrInfo);
    end
else
    if bDisplayProgress
        progressbar(0);
        % Force progress bar to close when this function returns if it hasn't already
        pbCleanup = onCleanup(@() progressbar(1));
    end

    for idx=1:numel(dirList)
        dicom{idx} = processDicomDir(dirList{idx},strWildcard, bIgnoreCache, false, bDetailedHdrInfo);
        if bDisplayProgress
            progressbar(idx/numel(dirList));
        end
    end
    
    clear pbCleanup
end

% Merge the results into a single dicomData struct
dicomData = dicomDataMerge(dicom{:});
