function y = range(x,dim)
%RANGE  Sample range.
%   Y = RANGE(X) returns the range of the values in X.  For a vector input,
%   Y is the difference between the maximum and minimum values.  For a
%   matrix input, Y is a vector containing the range for each column.  For
%   N-D arrays, RANGE operates along the first non-singleton dimension.
%
%   RANGE treats NaNs as missing values, and ignores them.
%
%   Y = RANGE(X,DIM) operates along the dimension DIM.
%
%   See also IQR, MAD, MAX, MIN, STD.

%   Copyright 1993-2004 The MathWorks, Inc.
%   $Revision: 1.1.8.1 $  $Date: 2010/03/16 00:17:06 $

if nargin < 2
    y = max(x) - min(x);
else
    y = max(x,[],dim) - min(x,[],dim);
end
