function [summaryRes, analysis] = createSummaryStructure(analysis, varargin)
%summaryRes = createSummaryStructure(analysis)
%Creates a summary array for Monte Carlo SNR simulations.
%
%1. Removes top and bottom 0.1 percentile data for each variance and additional dimension.
%2. Sorts by SNR.
%3. Separates into 12 bins.
%
%Input structure fields:
%- SNR array of size # variance by # Monte Carlo runs
%- Time array of size # variance by # Monte Carlo runs
%-- 'Absolute' and 'Percentage' fields
%-- 'Value', 'Bias' and 'CRLB' fields
%--- Any further fieldnames that are required e.g. 'Amplitudes' and 'Linewidths'
%These should be arrays of size (# variance, # number Monte Carlo runs, additional dimension for e.g. peaks)
%
%Output structure fields:
%- SNR by bin
%- Average time by bin
%- # Points per bin
%- 'Absolute' and 'Percentage' fields
%-- 'Value', 'Bias', 'SD', and 'RMSE'
%--- Futher fieldnames of arrays of size (# bins, # additional dimensions)
%
%Lucian A. B. Purvis 2017
%

if nargin>1 && ~isempty(varargin{1})
    numBins = varargin{1};
else
    numBins = 12;
end

if nargin>2 && ~isempty(varargin{2})
    percentileThresholds = varargin{2};
else
    percentileThresholds = [0.1 99.9];
end

%% Get fieldnames

if isfield(analysis,'Percentage')
    resFn = {'Absolute', 'Percentage'};
else
    resFn = {'Absolute'};
    
end
subFn = fieldnames(analysis.(resFn{1}));
analysisFn = fieldnames(analysis.(resFn{1}).(subFn{1}));

%% Get dimensions

dataDims = size(analysis.(resFn{1}).(subFn{1}).(analysisFn{1}));

numVariance = dataDims(1);
numRuns = dataDims(2);

if numel(size(analysis.SNR)) == numel(dataDims) && all(size(analysis.SNR)== dataDims)
    shapedSNR = 1;
else
    shapedSNR = 0;
end


if numel(dataDims)>2
    
    extraDims = prod(dataDims(3:end));
    sizeExtraDims = dataDims(3:end);
else
    extraDims = 1;
    sizeExtraDims = 1;
end


%Reshape structure
for resDx = 1:numel(resFn)
    for sDx = 1:numel(subFn)
        for aDx = 1:numel(analysisFn)
            analysis.(resFn{resDx}).(subFn{sDx}).(analysisFn{aDx}) = permute(reshape(analysis.(resFn{resDx}).(subFn{sDx}).(analysisFn{aDx}),[numVariance, numRuns, extraDims]), [3,1,2]);
        end
    end
end

if shapedSNR
    analysis.Time = permute(reshape(analysis.Time,[numVariance, numRuns, extraDims]), [3,1,2]);
    analysis.SNR = permute(reshape(analysis.SNR,[numVariance, numRuns, extraDims]), [3,1,2]);
end


%% Remove top and bottom 0.1 percentile according to Absolute Values by extra dimensions

for eDx = 1:extraDims
    for aDx = 1:numel(analysisFn)
        
        threshVals = squeeze(analysis.Absolute.Value.(analysisFn{aDx})(eDx,:));
        percentileVals= prctile(threshVals, percentileThresholds);
        inclDx = threshVals>percentileVals(1) & threshVals<percentileVals(2);
        
        for resDx = 1:numel(resFn)
            for sDx = 1:numel(subFn)
                for a2Dx = 1:numel(analysisFn)
                    
                    analysis.(resFn{resDx}).(subFn{sDx}).(analysisFn{a2Dx}) = analysis.(resFn{resDx}).(subFn{sDx}).(analysisFn{a2Dx})(:,inclDx);
                end
            end
        end
        
        if shapedSNR
            analysis.Time = analysis.Time(:,inclDx);
            analysis.SNR = analysis.SNR(:,inclDx);
            
        else
            analysis.Time = analysis.Time(inclDx);
            analysis.SNR = analysis.SNR(inclDx);
        end
    end
end

%% Remove top 1 percentile according to Absolute CRLB

for eDx = 1:extraDims
    for aDx = 1:numel(analysisFn)
        
        threshVals = abs(squeeze(analysis.Absolute.CRLB.(analysisFn{aDx})(eDx,:)));
        percentileVals= abs(prctile(threshVals, [0 100-10*percentileThresholds(1)]));
        inclDx = threshVals>percentileVals(1) & threshVals<percentileVals(2);
        
        for resDx = 1:numel(resFn)
            for sDx = 1:numel(subFn)
                for a2Dx = 1:numel(analysisFn)
                    
                    analysis.(resFn{resDx}).(subFn{sDx}).(analysisFn{a2Dx}) = analysis.(resFn{resDx}).(subFn{sDx}).(analysisFn{a2Dx})(:,inclDx);
                end
            end
        end
        
        if shapedSNR
            analysis.Time = analysis.Time(:,inclDx);
            analysis.SNR = analysis.SNR(:,inclDx);
            
        else
            analysis.Time = analysis.Time(inclDx);
            analysis.SNR = analysis.SNR(inclDx);
        end
    end
end

%% Sort by SNR

if shapedSNR
    for eDx = 1:extraDims
        [analysis.SNR(eDx,:), sortDx ] = sort(analysis.SNR(eDx,:));
        analysis.Time(eDx,:) = analysis.Time(eDx,sortDx);
        
        for resDx = 1:numel(resFn)
            for sDx = 1:numel(subFn)
                for aDx = 1:numel(analysisFn)
                    analysis.(resFn{resDx}).(subFn{sDx}).(analysisFn{aDx})(eDx,:) = analysis.(resFn{resDx}).(subFn{sDx}).(analysisFn{aDx})(eDx,sortDx);
                end
            end
        end
    end
else
    
    
    [analysis.SNR, sortDx ] = sort(analysis.SNR);
    analysis.Time = analysis.Time(sortDx);
    
    for resDx = 1:numel(resFn)
        for sDx = 1:numel(subFn)
            for aDx = 1:numel(analysisFn)
                analysis.(resFn{resDx}).(subFn{sDx}).(analysisFn{aDx}) = analysis.(resFn{resDx}).(subFn{sDx}).(analysisFn{aDx})(:,sortDx);
            end
        end
    end
end

%% Bin


if shapedSNR
    numInc = numel(analysis.SNR(1,:));
else
    numInc = numel(analysis.SNR);
end

bin = floor( numInc/numBins);
summaryRes.numPoints = bin;

for binDx = 1:numBins
    binInclDx = ((binDx - 1)*bin + 1):binDx*bin;
    
    if shapedSNR
        summaryRes.SNR(binDx,:) = mean(analysis.SNR(:,binInclDx),2);
        summaryRes.Time(binDx,:) = mean(analysis.Time(:,binInclDx),2);
    else
        summaryRes.SNR(binDx) = mean(analysis.SNR(binInclDx));
        summaryRes.Time(binDx) = mean(analysis.Time(binInclDx));
    end
    for resDx = 1:numel(resFn)
        
        for aDx = 1:numel(analysisFn)
            for sDx = 1:numel(subFn)
                
                summaryRes.(resFn{resDx}).(subFn{sDx}).(analysisFn{aDx})(binDx,:) = mean(analysis.(resFn{resDx}).(subFn{sDx}).(analysisFn{aDx})(:,binInclDx),2);
            end
            
            summaryRes.(resFn{resDx}).SD.(analysisFn{aDx})(binDx,:) = std(analysis.(resFn{resDx}).Value.(analysisFn{aDx})(:,binInclDx),[],2);
            
            if isfield(summaryRes.(resFn{resDx}), 'Bias')
                summaryRes.(resFn{resDx}).RMSE.(analysisFn{aDx})(binDx,:) = sqrt(summaryRes.(resFn{resDx}).Bias.(analysisFn{aDx})(binDx,:).^2 + summaryRes.(resFn{resDx}).SD.(analysisFn{aDx})(binDx,:).^2);
            end
        end
        
    end
    
    
end

%% Reshape
subFn2 = fieldnames(summaryRes.(resFn{1}));
finalSize = [numBins, sizeExtraDims];

for resDx = 1:numel(resFn)
    
    for aDx = 1:numel(analysisFn)
        for sDx = 1:numel(subFn2)
            
            summaryRes.(resFn{resDx}).(subFn2{sDx}).(analysisFn{aDx}) = reshape(summaryRes.(resFn{resDx}).(subFn2{sDx}).(analysisFn{aDx}),finalSize);
        end
    end
end

if shapedSNR
    summaryRes.SNR = reshape(summaryRes.SNR,finalSize);
    summaryRes.Time = reshape(summaryRes.Time,finalSize);
end
