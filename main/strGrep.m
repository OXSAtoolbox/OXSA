% [strMatches] = strGrep(strSearchRE,strIn,<options>)
%
% strSearchRE - regular expression to be matched
% strIn       - string to search
%
% Display matching lines.
%
% Example:
%
% strGrep('ab',sprintf('This line contains ab\nbut this does not\nnor does this\nHow about this line?'))
%
% prints output for two matching lines:
%
% This line contains ab
% How about this line?

%% Add this if options are defined
% Options may be passed as name, value pairs or as a struct.

% Copyright Chris Rodgers, University of Oxford, 2009
% $Id: strGrep.m 11600 2017-07-10 14:19:07Z lucian $

function [strMatches] = strGrep(strSearchRE,strIn,varargin)

%% Check input arguments
narginchk(2, Inf)

% If no options argument, set a default value
options = processVarargin(varargin{:});

% Scan through options setting essential fields
optionsDefaults = {'matchcase', 0;
                   'not',0};
for idx=1:size(optionsDefaults,1)
    if ~isfield(options,optionsDefaults{idx,1})
        options.(optionsDefaults{idx,1}) = optionsDefaults{idx,2};
    end
end

% Strings are split on newline. Cell arrays are treated "as is".
if ischar(strIn)
    tmp = regexp(strIn,'\r?\n','split');
elseif iscellstr(strIn)
    tmp = strIn;
else
    error('Incompatible type: You must pass in a string, or a cell array of strings')
end

if options.matchcase
    tmp_match = cellfun(@(x) ~isempty(x), regexp(tmp,strSearchRE));
else
    tmp_match = cellfun(@(x) ~isempty(x),regexpi(tmp,strSearchRE));
end

if options.not
    tmp_match = ~tmp_match;
end

if nargout<1
    fprintf('%s\n',tmp{tmp_match})
else
    strMatches = tmp(tmp_match);
end
