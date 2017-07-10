function matches = grepInFiles(fileNames, strRegExp)

if ischar(strRegExp)
    strRegExp = {strRegExp};
end

matches = cell(numel(fileNames),numel(strRegExp));
for fileDx=1:numel(fileNames)
    matches(fileDx,:) = grepInFile(fileNames{fileDx}, strRegExp);
end
