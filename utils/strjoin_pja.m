function str = strjoin_pja(sep, varargin)
%STRJOIN_PJA Join strings in a cell array.
% N.B. RENAMED to avoid a name clash with Matlab R2013a.
%
%   STRJOIN(SEP, STR1, STR2, ...) joins the separate strings STR1, STR2, ...
%   into a single string with fields separated by SEP, and returns that new
%   string.

%   Examples:
%
%     strjoin('-by-', '2', '3', '4')
%
%   returns '2-by-3-by-4'.
%
%     list = {'fee', 'fie', 'foe.m'};
%     strjoin('/', list{:}).
%
%   returns 'fee/fie/foe.m'.
%
%   This function is inspired by Perl' function join().

%   Author:      Peter J. Acklam
%   Time-stamp:  2003-10-13 11:13:55 +0200
%   E-mail:      pjacklam@online.no
%   URL:         http://home.online.no/~pjacklam

   % Check number of input arguments.
  narginchk(1, Inf);

   % Quick exit if output will be empty.
   if nargin == 1
      str = '';
      return
   end

   if isempty(sep)
      % special case: empty separator so use simple string concatenation
      str = [ varargin{:} ];
   else
      % varargin is a row vector, so fill second column with separator (using scalar
      % expansion) and concatenate but strip last separator
      varargin(2,:) = { sep };
      str = [ varargin{1:end-1} ];
   end
