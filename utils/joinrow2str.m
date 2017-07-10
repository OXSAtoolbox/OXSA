function [out]=joinrow2str(varargin)
% [out] = joinrow2str(data,...,format,sep)
%
% Utility function for prety-printing one or more vectors (rows), using a
% given format string (format or '%g' by default) and a separator between
% each entry (sep or ',' by default).
%
% The data arguments may be either a numeric vector, or a cell array
% vector containing e.g. strings. Each element of data will be flattened
% before being used. Data elements are fed into sprintf in the order that
% they are given.
%
% Example:
%
% Build a SQL string:
% joinrow2str({'abc','def','ghi','jkl'},[1 2 3 4],'%s=%g',' or ')
%
% See: SPRINTF for details of the format string.

% $Id: joinrow2str.m 106 2008-07-21 11:13:21Z crodgers $

if nargin<=0 || numel(varargin{1})==0
  out='';
  return
end

if nargin>1 && ischar(varargin{end})
  sep=varargin{end};
  if nargin>2 && ischar(varargin{end-1})
    format=varargin{end-1};
    varargin=varargin(1:(end-2));
  else
    varargin=varargin(1:(end-1));
    format='%g';
  end
else
  sep=',';
  format='%g';
end

row=cell(numel(varargin),numel(varargin{1}));

for idx=1:numel(varargin)
  if iscell(varargin{idx})
    row(idx,:)=reshape(varargin{idx},1,[]);
  else
    row(idx,:)=num2cell(reshape(varargin{idx},1,[]));
  end
end

out=sprintf(format,row{:,1});
for idx=2:size(row,2)
  out=[out sep sprintf(format,row{:,idx})];
end

