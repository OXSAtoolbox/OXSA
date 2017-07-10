function matchedLines = grepInFile(filename,strRegExp)

fid = fopen(filename,'r');
if fid == -1
    error('Cannot open file "%s".',filename)
end
fid_c = onCleanup(@() fclose(fid));

matchedLines = repmat({{}},1,numel(strRegExp));
thisLine = fgetl(fid); % Either -1 (EOF) or a string.
while ischar(thisLine)
    for regExDx = 1:numel(strRegExp)
    thisMatch = regexp(thisLine,strRegExp{regExDx},'tokens');
    
    if ~isempty(thisMatch)
        matchedLines{regExDx}{end+1} = thisMatch;
    end
    end
    
    thisLine = fgetl(fid);
end
