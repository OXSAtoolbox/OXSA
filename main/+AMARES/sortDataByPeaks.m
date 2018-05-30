function [results thePeakNames theResTypes] = sortDataByPeaks(results,unsortedData,pk,vdx,varargin)

options = processVarargin(varargin{:});

if isfield(options,'peaks')
    thePeakNames = options.peaks;
else 
    counter = 0;
    for peakDx = 1:size(pk.initialValues,2)
        if ischar(pk.initialValues(1,peakDx).peakName)
            pk.initialValues(1,peakDx).peakName = cellstr(pk.initialValues(1,peakDx).peakName);
        end
        if iscell(pk.initialValues(1,peakDx).peakName)
            for iDx = 1:numel(pk.initialValues(1,peakDx).peakName)
                counter = counter+1;
                thePeakNames{counter} = pk.initialValues(1,peakDx).peakName{iDx};
            end
        else
            counter = counter+1;
            thePeakNames{counter} = pk.initialValues(1,peakDx).peakName;
        end
    end

end

theResTypes = {'ChemicalShifts','Standard_deviation_of_ChemicalShifts'...
    ,'FrequenciesHz','Standard_deviation_of_FrequenciesHz'...
    ,'FrequenciesHzIncOffset','ChemicalShiftsIncOffset'...
    ,'Amplitudes','Standard_deviation_of_Amplitudes'...
    ,'Dampings','Standard_deviation_of_Dampings'...
    ,'Linewidths','Standard_deviation_of_Linewidths'...
    ,'Phases','Standard_deviation_of_Phases'};

if isfield(unsortedData,'GaussianSigma')
    theResTypes(end+1:end+2) = {'GaussianSigma' , 'Standard_deviation_of_GaussianSigma'};
end

   %% Sort AMARES output into expected format.
        % Results are stored by peak name.
        for resdx=1:numel(theResTypes)
            for peakdx=1:numel(thePeakNames)
                results.dataByPeak.( thePeakNames{peakdx} ).( theResTypes{resdx} )(vdx,1) = unsortedData.(theResTypes{resdx})(:,peakdx);
            end
        end