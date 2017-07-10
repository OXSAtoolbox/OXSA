function identifyDicomFilesInDir(strDir, strWildcard, bShowInWindow)
% Scan all DICOM files and check which sequence they are from.
%
% strDir - folder to scan.
% strWildcard (optional) - restrict to scanning only certain files.
% bShowInWindow - display results in a web browser window rather than in
% the Matlab command window.

% Copyright Chris Rodgers, University of Oxford, 2008-11.
% $Id: identifyDicomFilesInDir.m 6257 2013-03-12 14:24:53Z crodgers $

error(nargchk(1,3,nargin,'struct'))

if nargin < 3
    bShowInWindow = false;
end

if nargin < 2
    strWildcard = '';
end

if ischar(strDir)
    dicomTree = Spectro.dicomTree('dir',strDir,'wildcard',strWildcard);
elseif isa(strDir,'Spectro.dicomTree')
    dicomTree = strDir;
else
    error('Incompatible input format!')
end

dicomTree.prettyPrint(bShowInWindow);
