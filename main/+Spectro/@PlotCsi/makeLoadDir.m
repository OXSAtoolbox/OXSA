function saveFolder = makeLoadDir(obj)
% Generate path for loading analysis results.
%
% saveFolder = makeLoadDir(obj)
%
% saveFolder is a cell array comprising:
%
% 1) A subdirectory "Spectro.PlotCsi.sav" of the directory containing the
% first loaded DICOM file.
%
% 2) A subfolders of $HOME/.Spectro.PlotCsi/sav
%
% SEE ALSO:
% makeSaveDir loadDataGui

% TODO: Permit per-user override of these folders via a configuration file.

% Tobias Sjolander and Chris Rodgers, Univ Oxford, 2012.
% $Id$

saveFolder = cell(0,1);

dicomDir = obj.data.dicomTree.path; % Use this so we handle recursive loading properly.

%% Method 1. Saved in Spectro.PlotCsi.sav subfolder...
saveFolderTmp = fullfile(dicomDir,'Spectro.PlotCsi.sav');
if exist(saveFolderTmp,'dir')
    saveFolder{end+1,1} = saveFolderTmp;
end

%% Method 2. Saved in user's HOME folder...
strHomeDir = char(java.lang.System.getProperty('user.home'));
% regexptranslate('escape','\/:*?"<>|')
saveFolderTmp = fullfile(strHomeDir,'.Spectro.PlotCsi','sav',regexprep(dicomDir,'[\\/:\*\?"<>\|]','='));
if exist(saveFolderTmp,'dir')
    saveFolder{end+1,1} = saveFolderTmp;
end