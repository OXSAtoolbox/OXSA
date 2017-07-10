function fileList = listFilesRecursive(currentBaseDir,strRegExp,fileList)
% Fetch list of all .m files below a certain folder recursively.
%
% Example:
% fileList = listFilesRecursive(baseDir,strRegExp)

% Match all files if no regexp specified
if ~exist('strRegExp','var')
    strRegExp = '.*';
end

% Initialise fileList at the top level of recursion.
if ~exist('fileList','var')
    fileList = cell(0,1);
end

dirContents = dir(currentBaseDir);

for iDx=1:numel(dirContents)
    if any(strcmp(dirContents(iDx).name,{'.','..'}))
        % Skip . and ..
        continue
    elseif dirContents(iDx).isdir
            fileList = listFilesRecursive(fullfile(currentBaseDir,dirContents(iDx).name),strRegExp,fileList);
    else
        if isempty(regexp(dirContents(iDx).name,strRegExp,'once'))
            continue
        else
            % Combine the file name with the current dir.
            fileList{end+1,1} = fullfile(currentBaseDir,dirContents(iDx).name);
            
            % If you have to deal with . notation.
            %                     packageFolders = regexp(currentBaseDir,'(?<=\\\+).+?(?=\\|$)','match');
            %                     if isempty(packageFolders)
            %                        fileList{end+1} =dirContents(iDx).name;
            %                     else
            %                         fileList{end+1} = [strjoin(packageFolders,'.') '.' strrep(dirContents(iDx).name,'.m','')];
            %                     end
        end
    end
end
