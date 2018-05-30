function identifyDicomFilesInDir(strDir, strWildcard, bShowInWindow, bRecursive)
% Scan all DICOM files and check which sequence they are from.
%
% strDir - folder to scan.
% strWildcard (optional) - restrict to scanning only certain files.
% bShowInWindow (optional) - display results in a web browser window rather
%                            than in the Matlab command window.
% bRecursive (optional) - process folder recursively.

% Copyright Chris Rodgers, University of Oxford, 2008-11.
% $Id: identifyDicomFilesInDir.m 8072 2014-11-05 17:23:03Z crodgers $

error(nargchk(1,4,nargin,'struct'))

if nargin < 4
    bRecursive = false;
end

if nargin < 3
    bShowInWindow = false;
end

if nargin < 2
    strWildcard = '';
end

if ischar(strDir)
    dicomTree = Spectro.dicomTree('dir',strDir,'wildcard',strWildcard,'recursive',bRecursive);
elseif isa(strDir,'Spectro.dicomTree')
    dicomTree = strDir;
else
    error('Incompatible input format!')
end

dicomTree.prettyPrint(bShowInWindow);
