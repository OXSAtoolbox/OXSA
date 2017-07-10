function saveFolder = makeSaveDir(obj)
% Generate path for saving analysis results.
%
% saveFolder = makeSaveDir(obj)
%
% By default the directory is a subdirectory "Spectro.PlotCsi.sav" of the
% directory containing the first loaded DICOM file.
%
% When that is not writeable, save into subfolders of
% $HOME/.Spectro.PlotCsi/sav
%
% SEE ALSO:
% makeLoadDir loadDataGui

% TODO: Permit per-user override of these folders via a configuration file.

% Tobias Sjolander and Chris Rodgers, Univ Oxford, 2012.
% $Id$

dicomDir = obj.data.dicomTree.path; % Use this so we handle recursive loading properly.

%% Method 1. Save in Spectro.PlotCsi.sav subfolder...
saveFolder = fullfile(dicomDir,'Spectro.PlotCsi.sav');
if makeSaveDir_check(saveFolder)
    return
end

%% Method 2. Save in user's HOME folder...
% N.B. The Windows "Documents" folder can be obtained with getuserdir (from
% the Windows registry).
strHomeDir = char(java.lang.System.getProperty('user.home'));
% regexptranslate('escape','\/:*?"<>|')
saveFolder = fullfile(strHomeDir,'.Spectro.PlotCsi','sav',regexprep(dicomDir,'[\\/:\*\?"<>\|]','='));
if makeSaveDir_check(saveFolder)
    return
else
    error('Cannot find folder to store results.')
end
end


function bStatus = makeSaveDir_check(strDir)
try
    if ~exist(strDir,'dir')
        mkdir(strDir);
    end
    testFilename = fullfile(strDir,'~$DeleteMe~');
    [fid, fileErrorMsg] = fopen(testFilename,'w');
    if fid == -1
        error('fopen:failed',fileErrorMsg);
    end
    fclose(fid);
    delete(testFilename);
    
    % All is OK if we get to this point.
    bStatus = true;
catch ME
    if ~( ...
          strcmp(ME.identifier,'MATLAB:MKDIR:OSError') ...
          || strcmp(ME.identifier,'fopen:failed') ...
        )
        % Unexpected error.
        rethrow(ME);
    else
        bStatus = false;
    end
end
end
