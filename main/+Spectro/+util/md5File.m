function [md5] = md5File(strFilename)

fid = fopen(strFilename,'r');
data = fread(fid, Inf, '*uint8');
fclose(fid);

md5 = hash(data,'MD5');
