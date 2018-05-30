function strRev = getSubversionRevision(strPath,timeout)
% Use TortoiseSVN SubWCRev COM object to query working copy status.
%
% timeout - specifies time to cache previous value. Default 300s.

if ~exist('timeout','var')
    timeout = 300; % Seconds
end

persistent strRev_cache strRev_time

thisTime = clock();

if ~isempty(strRev_time) && etime(thisTime,strRev_time) < timeout
    strRev = strRev_cache;
    return
end

try
    % Query Subversion status
    subwcrev = actxserver('SubWCRev.object');
    subwcrev.GetWCInfo(strPath,true,false);
    minrev = subwcrev.MinRev;
    maxrev = subwcrev.MaxRev;
    hasmod = subwcrev.HasModifications;
    
    if hasmod
        hasmodStr = 'M';
    else
        hasmodStr = '';
    end
    
    if minrev == maxrev
        strRev = sprintf('%d%s',maxrev,hasmodStr);
    else
        strRev = sprintf('%d-%d%s',minrev,maxrev,hasmodStr);
    end
    
    % Tag time in cache if successful
    strRev_cache = strRev;
    strRev_time = thisTime;
catch %#ok<CTCH>
    strRev = 'SVN ERR';
end
