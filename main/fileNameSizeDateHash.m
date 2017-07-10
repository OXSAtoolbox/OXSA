function [theHash] = fileNameSizeDateHash(strDir,files)
% Create a hash of the file names, sizes and modification dates.

% Copyright Chris Rodgers, University of Oxford, 2011-12.
% $Id: dirHash.m 4527 2011-09-21 13:32:51Z crodgers $

theHash = cell(size(files));

for idx=1:numel(files)
    if files(idx).isdir
        continue
    end
    
    % Create Java hash object
    x=java.security.MessageDigest.getInstance('MD5');

    x.update(uint8(fullfile(strDir,files(idx).name)));
    x.update(uint8(10)); % \n
    
    x.update(uint8(sprintf('%d,%.16f\n',files(idx).bytes,files(idx).datenum)));
    
    theHash{idx}=sprintf('%.2x',typecast(x.digest,'uint8'));
end
