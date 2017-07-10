function h = subplotSetBorder(rows,cols,border,overall,idx,varargin)
% Variant on "subplot" that leaves a specified gap between subplots.
%
% h = subplotSetBorder(rows,cols,border,overall,idx,...)
% OR
% h = subplotSetBorder(hAxis,rows,cols,border,overall,idx,...)
%
% border has the offsets in each element [left right bottom top]
% overall has the offsets overall [left right bottom top]
%
% EXAMPLE:
% 
% figure
% subplotSetBorder(2,2,[.01 .01 0 .03],[0 0.05 0 0],3);
% plot(1:20,1:20,'r.-')

% Copyright Chris Rodgers, University of Oxford, 2011.
% $Id$

if isscalar(rows) && ishandle(rows) && strcmp(get(rows,'type'),'axes')
    % Second form of command line. Relabel arguments.
    hAxis = rows;
    rows = cols;
    cols = border;
    border = overall;
    overall = idx;
    idx = varargin{1};
    varargin(1) = [];
else
    hAxis = [];
end

posX = mod(idx - 1, cols);
posY = floor((idx - 1) / cols);

colWidth = (1-overall(1)-overall(2))/cols;
rowHeight = (1-overall(3)-overall(4))/rows;

offset = [border(1)+overall(1) border(3)+overall(3) -border(1)-border(2) -border(3)-border(4)];

if numel(idx) == 1
    newPos = [posX*colWidth (rows-posY-1)*rowHeight colWidth rowHeight]+offset;
else
    newPosTmp = zeros(numel(idx),4);
    for c = 1:numel(idx)
        newPosTmp(c,:) = [posX(c)*colWidth (rows-posY(c)-1)*rowHeight colWidth rowHeight]+offset;
    end
    
    % POS is left bottom width height
    
    % Which is left-most?
    newLeft = min(newPosTmp(:,1));
    
    % Which is right-most?
    newRight = max(newPosTmp(:,1)+newPosTmp(:,3));
    
    % Which is bottom-most?
    newBottom = min(newPosTmp(:,2));
    
    % Which is top-most?
    newTop = max(newPosTmp(:,2)+newPosTmp(:,4));
    
    % POS is left bottom width height
    newPos = [newLeft newBottom (newRight-newLeft) (newTop-newBottom)];
end

if isempty(hAxis)
    hh = axes('Position',newPos,varargin{:});
else
    axes(hAxis);
    set(hAxis,'Position',newPos,varargin{:});
    hh = hAxis;
end

if nargout > 0
    h = hh;
end
