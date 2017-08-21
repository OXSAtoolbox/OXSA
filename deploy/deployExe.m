% Deploy Spectroscopy Tools v2.1.
clear variables
cd(fileparts(mfilename('fullpath')))


%% Fit a dummy dataset with all desired priorknowledge files to make sure that they will run when deployed
% Get the list of Pk
priorDir = fullfile(RodgersSpectroToolsRoot(),'main','+AMARES','+priorKnowledge');
priorFiles = dir(fullfile(priorDir,'pk*.m'));
listOfPk = arrayfun(@(x) regexprep(x.name,'\.m',''),priorFiles,'uniformoutput',false);

generatePKCache(listOfPk);

%% Dependencies
% Create a list of all the .m files in the \main
% folder and subfolders.

topDir = fullfile(RodgersSpectroToolsRoot(),'main');

mFileList = listFilesRecursive(topDir,'\.m$');
mex64FileList = listFilesRecursive(topDir,'\.mexw64$');

% Add the specific 31P .m files
cd('..');
mfiles31P_name = listFilesRecursive(pwd, '\.m$');
javaFile_name = listFilesRecursive(pwd, '\.java$');
classFile_name = listFilesRecursive(pwd, '\.class$');
cd(fileparts(mfilename('fullpath')));

mFileList = [mFileList; mfiles31P_name]; % Concatenate the two lists


% Automatically pick up external dependencies that are declared within .m
% files using a custom "%#include" pragma modelled on the Matlab
% "%#function" pragma.
extraFileList = cell(0,1);
extraTmp = grepInFiles(mFileList,{'^\s*%#include (.*)$', '^\s*%#include_exec (.*)$'});
for fileDx=1:numel(mFileList)
    if ~isempty(extraTmp{fileDx,1})
        % "include" pragma: 
        
        thisList = cat(1,extraTmp{fileDx,1}{:});
        thisList = cat(1,thisList{:});
        
        for idx=1:numel(thisList)
            % Expand wildcards if present
            if ~isempty(regexp(thisList{idx},'[\?\*]','once'))
                tmp = wildcardexpand('',fullfile(fileparts(mFileList{fileDx}),thisList{idx}),true);
                extraFileList(end+1:end+numel(tmp),1) = tmp;
            else
                extraFileList{end+1,1} = fullfile(fileparts(mFileList{fileDx}),thisList{idx}); %#ok<SAGROW>
            end
        end
    end
    if ~isempty(extraTmp{fileDx,2})
        % "include_exec" pragma:
        
        thisList = cat(1,extraTmp{fileDx,2}{:});
        thisList = cat(1,thisList{:});
        
        for idx=1:numel(thisList)
            extraFileList{end+1,1} = eval(thisList{idx}); %#ok<SAGROW>
        end
        
    % Non-matching files do nothing...
    end
end

extraFileList = unique(extraFileList);

extraFileList{end+1} = fullfile(topDir,'PhiIcon.png');
extraFileList{end+1} = fullfile(topDir,'human.mat');

allFileList = [mFileList; mex64FileList; extraFileList];

% Add an extra '-a' inbetween each file path so that argumentList{:}
% generates a comma seperated list like this "'-a',path,'-a',path,..."
argumentList = {};
for iDx = 1:numel(allFileList)
   argumentList{end+1} = '-a';
   argumentList{end+1} = allFileList{iDx};
end

%%
startTime = clock();
buildTime = datestr(now)

[~,~] = mkdir('deployedGUI');

mcc('-W', 'main', '-T', 'link:exe', 'deployedGUI.m', ...
    '-d', 'deployedGUI', ...
    '-R', ['-startmsg Copyright Chris Rodgers, University of Oxford, 2014. (Built: ' buildTime '.)'], ...
    argumentList{:})

fprintf('Done: elapsed time = %.1fs.\n',etime(clock(),startTime))
datestr(now)

%% Make a folder to distribute
releasesFolderName = fullfile('releases','uncompressed',sprintf('%s_%s','31P_Analysis',datestr(now,'yyyy_mm_dd')));
if ~exist(releasesFolderName,'dir')
    mkdir(releasesFolderName)
end

zipFolderName = fullfile('releases','compressed',sprintf('%s_%s.zip','31P_Analysis',datestr(now,'yyyy_mm_dd')));

copyfile('deployedGUI\deployedGUI.exe',fullfile(releasesFolderName,'31P_Analysis_Tool.exe')) %Copy the main .exe into it