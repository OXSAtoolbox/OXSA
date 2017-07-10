function savedResultsFile = loadDataGui(obj,strFileMatch,varargin)
% Offer to load saved data, checking both in the source folder and $HOME.
%
% [savedResultsFile] = loadGuiData(obj,strFileMatch,...)
%
% strFileMatch - Names of files to include. E.g. 'cmdFitIrFids_Series*.mat'
%
% Returns:
% savedResultsFile: '' if user aborts or no data is available.
%                   Otherwise, it contains the fully qualified filename.
%
% SEE ALSO:
% makeSaveDir makeLoadDir

% Copyright Chris Rodgers, Univ Oxford, 2012.
% $Id$


options = processVarargin(varargin{:});

if isfield(options,'SelectionMode')
    selectionMode = options.SelectionMode;
else
    selectionMode = 'single';
end

savedResultsFiles = {};
savedResultsDirDx = [];

strSaveDir = obj.makeLoadDir();
for idx=1:numel(strSaveDir)
    tmp = dir(fullfile(strSaveDir{idx},strFileMatch));
    tmp([tmp.isdir]) = [];
    savedResultsFiles = [ savedResultsFiles { tmp.name } ];
    savedResultsDirDx = [ savedResultsDirDx; repmat(idx, numel(tmp), 1) ];
end
clear tmp

savedResultsGuiStr = cell(size(savedResultsFiles));
for idx=1:numel(savedResultsFiles)
    savedResultsGuiStr{idx} = sprintf('%s (from %s)',...
        savedResultsFiles{idx}, ...
        strSaveDir{savedResultsDirDx(idx)});
end

if isempty(savedResultsFiles)
    savedResultsFile = '';
else
    
    if isfield(obj.data.spec.coilInfo,'defaultFID') 
        coilNum = regexp(obj.data.spec.coilInfo.defaultFID,'\d*','match');
        coilStr = sprintf('coil%i',str2num(coilNum{1}));
        initialValue = find(~cellfun(@isempty,cellfun(@(x) logical(regexp(x,coilStr)),savedResultsGuiStr,'UniformOutput',false)), 1, 'last' );
    else
        initialValue = numel(savedResultsGuiStr);
    end
    
    [savedResultsDx,useSavedResults] = listdlg('ListString',savedResultsGuiStr,'SelectionMode',selectionMode,'ListSize',[700 400],...
        'PromptString',[{'Analysis has already completed. Load previous data?';''}; strSaveDir(:); {''}],...
        'InitialValue',initialValue,'OKString','Use selected data [ENTER]','CancelString','Run again [ESC]');
    
    if useSavedResults && numel(savedResultsDx) == 1
        savedResultsFile{1} = fullfile(strSaveDir{savedResultsDirDx(savedResultsDx)},savedResultsFiles{savedResultsDx});
    
    elseif useSavedResults && numel(savedResultsDx) > 1
        for iDx = 1:numel(savedResultsDx)
            savedResultsFile{iDx} = fullfile(strSaveDir{savedResultsDirDx(savedResultsDx(iDx))},savedResultsFiles{savedResultsDx(iDx)});               
        end      
        
    else
        savedResultsFile = '';
    end
end
