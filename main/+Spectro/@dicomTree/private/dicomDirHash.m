function [theHash] = dicomDirHash(strDir, strWildcard)
% Create a hash of the file names, sizes and modification dates.
% Additionally, hash the full content of any DICOMDIR files.
%
% This hash is highly likely to be unique for a folder or CD/DVD containing
% DICOM files. It can be used to cache parsed forms of this DICOM data.
%
% Stale cache files will need to be deleted manually from time to time.

% Copyright Chris Rodgers, University of Oxford, 2011.
% $Id: dicomDirHash.m 5540 2012-06-22 11:08:10Z crodgers $

% Canonicalise the directory case (for windows)
if ispc()
    strDir = GetLongPathName(strDir);
    
    if isempty(strDir)
        error('Directory not found.')
    end
end

% Append wildcard if it was supplied
if nargin < 2 || isempty(strWildcard)
    strDirWithWildcard = strDir;
else
    strDirWithWildcard = fullfile(strDir,strWildcard);
end

% Get directory listing early so we abort early if there is an error.
theFiles = dir(strDirWithWildcard);

% Create Java hash object
x=java.security.MessageDigest.getInstance('MD5');

x.update(uint8(strDirWithWildcard));
x.update(uint8(10)); % \n

for idx=1:numel(theFiles)
    if theFiles(idx).isdir
        continue
    end
    
    x.update(uint8(sprintf('%s,%d,%.16f\n',theFiles(idx).name,theFiles(idx).bytes,theFiles(idx).datenum)));
    
    if strcmpi(theFiles(idx).name,'dicomdir')
        fid = fopen(fullfile(strDir,theFiles(idx).name));
        x.update(fread(fid,'uint8'));
        fclose(fid);
    end
end

theHash=sprintf('%.2x',typecast(x.digest,'uint8'));
