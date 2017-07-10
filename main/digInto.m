% [strOut, bFound] = digInto(target, strSearchRE, <options>)
%
% target - struct to search.
% strSearchRE - regular expression for field name matching.
%               DEFAULT is '.' which matches (displays) all fields.
%
% Search recursively through nested structs or cell arrays
% matching field names against a supplied regular expression.
%
% Display data and parents for any match.
%
% Options may be passed as name, value pairs or as a struct.
%
% "searchcontent" : if true, search the content of fields in addition to
%                   their names
%
% Example:
%
% xx = struct('NameOne',1,'AnotherName',2);
% xx.Three.Four.NameOne = { 7 };
% xx.Three.Four.AnotherName = 1;
% digInto(xx,'[Nn]ame')
% digInto(xx,'[Oo]ne')

% Copyright Chris Rodgers, University of Oxford, 2008-13
% $Id: digInto.m 6814 2013-07-31 12:57:40Z crodgers $

% Inspired by code from: http://code.activestate.com/recipes/576489/
%                Fri, 5 Sep 2008 by kaushik.ghose

function [strOut, bFound] = digInto(target, strSearchRE, varargin)

%% Check input arguments
error(nargchk(1, Inf, nargin, 'struct')) %#ok<NCHKN>

if nargin < 2
    strSearchRE = '.';
end

% If no options argument, set a default value
options = processVarargin(varargin{:});

% Scan through options for unknown fields and set defaults
optionsDefaults = {'debug', 0; 'level', 0; 'searchcontent', 0};

fn = fieldnames(options);
for idx=1:numel(fn)
    if ~any(strcmp(fn{idx},optionsDefaults(:,1)))
        error('Unknown option "%s"!', fn{idx});
    end
end
for idx=1:size(optionsDefaults,1)
    if ~isfield(options,optionsDefaults{idx,1})
        options.(optionsDefaults{idx,1}) = optionsDefaults{idx,2};
    end
end

newOptions = options;
newOptions.level = newOptions.level + 1;

bFound = 0;
strOut = '';

tabs = repmat(' ',1,4*options.level);

if iscell(target)
    fn=cell(numel(target),1);
    for idx=1:numel(target)
        fn{idx} = ['{' num2str(idx) '}'];
    end
elseif isstruct(target)
    if numel(target) == 1
        % Normal struct field
        fn = fieldnames(target);
    else
        % Struct array field
        fn = cell(numel(target),1);
        for idx=1:numel(target)
            fn{idx} = ['(' num2str(idx) ')'];
        end
    end
elseif isa(target, 'function_handle')
    fn = {func2str(target)};
elseif isa(target, 'handle')
    target = builtin('struct',target);
    fn = fieldnames(target);
else
    error('First input must be a cell array, stuct, struct array, function handle or handle object.')
end

matches = regexpi(fn, strSearchRE); % Which fieldnames match?

for n = 1:length(fn)
    if iscell(target)
        fn2 = target{n};
    elseif isstruct(target) && numel(target) > 1
        fn2 = target(n);
    elseif isa(target, 'function_handle')
        % Decode the variables stored in workspace #1 of a function handle.
        tmp_f = functions(target);
        if isfield(tmp_f,'workspace')
            fn2 = tmp_f.workspace{1};
        else
            fn2 = [];
        end
        clear tmp_f
    else
        fn2 = target.(fn{n});
    end
    
    if iscell(fn2) || isstruct(fn2) || isa(fn2, 'function_handle')
        [strOutInner, bFoundInner] = digInto(fn2, strSearchRE, newOptions);
        strFoundData = '';
    else
        strOutInner = '';
        % Check this isn't a massive chunk of data!
        fn2_stats = whos('fn2');
        if fn2_stats.bytes < 1024
            strFoundData = [' = ' evalc('disp(fn2)')];
            strFoundData(end) = [];
            
            % Tidy up
            if regexp(strFoundData,'\n')
                % Multi-line output needs an initial LF
                strFoundData = [' =' char(10) strFoundData(3:end)]; %#ok<AGROW>
            else
                % Remove leading spaces from single line output
                strFoundData = regexprep(strFoundData,'^ =[\t ]+',' = ');
            end
        else
            strFoundDataTmp = evalc('disp(reshape(fn2(1:20),1,[]))');
            strFoundDataTmp(end) = [];
            
            strFoundData = sprintf(' = %d x %s [%s ...]',prod(fn2_stats.size),fn2_stats.class,strFoundDataTmp);
        end
        
        bFoundInner = 0;
        if options.searchcontent && ischar(fn2)
            matchesContent = regexpi(fn2, strSearchRE);
            
            if ~isempty(matchesContent)
                bFoundInner = 1;
                
                if ischar(fn2)
                    % Print any matching lines of text in their entirety
                    
                    tmp_fn2 = regexp(fn2,'\r?\n','split');
                    tmp_match = cellfun(@(x) ~isempty(x),regexpi(tmp_fn2,strSearchRE));
                    strFoundData = [strFoundData sprintf('\n***** MATCHES *****\n') sprintf('%s\n',tmp_fn2{tmp_match}) sprintf('\n*****---------*****\n')]; %#ok<AGROW>
                end
            end
        end
    end

    if any(matches{n}) || bFoundInner
        bFound = 1;
        
        strOut = sprintf('%s%s%s%s\n%s',strOut,tabs,fn{n},strFoundData,strOutInner);
    end
end

if nargout<1
    disp(strOut)
    clear strOut
end

end
