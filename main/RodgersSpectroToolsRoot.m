% Return the root directory in the RodgersSpectroToolsRoot codebase
%
% [strOut] = RodgersSpectroToolsRoot()

% Copyright Chris Rodgers, University of Oxford, 2008.
% $Id: RodgersSpectroToolsRoot.m 257 2008-08-07 17:20:38Z crodgers $

function [strOut] = RodgersSpectroToolsRoot()
    
strOut = fileparts(fileparts(mfilename('fullpath')));

