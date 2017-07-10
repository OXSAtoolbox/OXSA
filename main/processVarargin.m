% Allow varargin to hold either a struct or a list of field/value pairs
% or a mixture of structs and field/value pairs.
%
% If parameters are specified more than once, the last value is used.
%
% [options] = processVarargin(varargin)
%
% Example 1:
%
% To use this in a function, add code as follows:
%
% function [ ... ] = myfunction(param1, param2, ... , varargin)
% ...
% % Read options from varargin
% options = processVarargin(varargin{:});
%
%
% Example 2:
%
% inputStruct = struct('abc',1);
% inputStruct.def = {23};
% options = processVarargin(inputStruct);
% options2 = processVarargin('abc',1,'def',{23});
% isequal(options,options2)
%
% After running this code, inputStruct, options and options2 will all be
% the same.

% Copyright Chris Rodgers, University of Oxford, 2008-13.
% $Id: processVarargin.m 6515 2013-05-14 10:57:39Z crodgers $

function [opt] = processVarargin(varargin)

full_f = cell(0,1);
full_v = cell(0,1);

idx = 1;
while idx <= numel(varargin)
    if isstruct(varargin{idx}) && numel(varargin{idx}) == 1
        f = fieldnames(varargin{idx});
        v = struct2cell(varargin{idx});
        idx = idx+1;
    elseif ischar(varargin{idx}) && numel(varargin) > idx
        f = varargin(idx);
        v = varargin(idx+1);
        idx = idx+2;
    else
        error('Bad input format! Expected a struct or field/value pair.')
    end

    % Now append to the main list
    full_f(end+1:end+numel(f),1) = f;
    full_v(end+1:end+numel(f),1) = v;
end

% Sort fields and catch duplicate field names
[full_f, fnDx] = myUnique(full_f);
full_v = full_v(fnDx);

opt = cell2struct(full_v,full_f);
end

function [out,dx] = myUnique(in)
% unique is changing in R2012a so roll our own

[tmpSort, tmpSortDx] = sort(in);
mask = true(size(tmpSort));
for idx=numel(tmpSort)-1:-1:1
    if isequal(tmpSort(idx+1),tmpSort(idx))
        mask(idx) = false;
    end
end

out = tmpSort(mask);
dx = tmpSortDx(mask);

end
