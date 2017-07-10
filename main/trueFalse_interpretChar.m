function out = trueFalse_interpretChar(in)
% Interpret a "true" or "false" string --> logical value.
% Use built-in conversion for other input types.

if ischar(in)
    switch lower(in)
        case {'false','off','no'}
            out = false;
            return
        case {'true','on','yes'}
            out = true;
            return
        otherwise
            error('Expect true/on/yes or false/off/no but got "%s".',in)
    end
end

out = logical(in);
