function [s] = ensureFieldPresent(s, fieldNames, defaultValue)
% If any of the listed fields are not present, add it.

narginchk(2,3)

if nargin < 3
    defaultValue = '';
end

if ~iscell(fieldNames)
    fieldNames = {fieldNames};
end

for idx=1:numel(fieldNames)
    if ~isfield(s,fieldNames{idx})
        s.(fieldNames{idx}) = defaultValue;
    end
end
