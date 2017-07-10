function [strFullName] = wildcardexpand(strDir,strWildcard,bAllowMultiple)
% [strFullName] = wildcardexpand([strDir], strWildcard, [bAllowMultiple])
%
% Expand a wildcard to give a unique filename
%
% If strDir is empty, then extract the path from the wildcard
%
% If bAllowMultiple is true, return multiple matches as a cell array.

% $Id: wildcardexpand.m 3352 2010-06-04 10:46:14Z crodgers $

if nargin<3
    bAllowMultiple = 0;
end

if numel(strDir) == 0
    dirIdx=strfind(strWildcard,filesep);
    
    if numel(dirIdx) == 0
        dirIdx=0;
    end
    
    strDir=strWildcard(1:dirIdx(end));
    strWildcard=strWildcard((dirIdx(end)+1):end);
elseif strDir(end)~=filesep
    strDir = [strDir filesep];
end

files = dir([strDir strWildcard]);

if bAllowMultiple
    % Return a cell array
    strFullName = cell(numel(files),1);
    for idx = 1:numel(files)
       strFullName{idx} = [strDir files(idx).name];
    end
else
    if numel(files) ~= 1
        error('CTR:wildcardexpand','Wildcard matched %d files when 1 expected',numel(files))
    end
    
    % Return a simple string
    strFullName = [strDir files(1).name];
end

