function printFigure(obj,varargin)
% Print the localizers from a Spectro.PlotCsi figure.
%
% Works by copying the graphics objects first into another invisible figure
% windows and then calling print(...) on that.

% Copyright Chris Rodgers, Univ Oxford, 2012.
% $Id$

hNew = figure('Visible','off');
c = onCleanup(@() delete(hNew));

obj.copyToFigure(hNew);

set(hNew,'paperpositionmode','auto')
print(hNew,varargin{:});
