% MYDICOMREAD Load DICOM images without swapping row/col so that the pixel
% ordering remains the same as in the original images
%
% [...] = myDicomRead(...)
%
% Parameters are the same as for dicomread

% Copyright Chris Rodgers, University of Oxford, 2008.
% $Id: myDicomRead.m 3402 2010-06-22 15:48:24Z crodgers $

function [varargout] = myDicomRead(varargin)

varargout = cell(1,nargout);

[varargout{:}] = dicomread(varargin{:});

for paramdx=1:numel(varargout)
    origDims = 1:numel(size(varargout{paramdx}));

    if numel(origDims)>=2
        newDims = origDims;
        newDims = origDims([2 1]);

        varargout{paramdx} = permute(varargout{paramdx},newDims);
    end
end
