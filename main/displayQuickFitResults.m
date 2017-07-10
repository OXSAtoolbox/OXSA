function displayQuickFitResults(obj)

%% Create the table

% headers 

htmlTableParts{1} = '<TABLE border="1">';


peaks = fieldnames(obj.misc.fittingResults{1}.dataByPeak);
fitMagFields = {'Amplitudes','ChemicalShifts','FrequenciesHz','Dampings','Linewidths','Phases'};
fitSDFields = {'Standard_deviation_of_Amplitudes','Standard_deviation_of_ChemicalShifts','Standard_deviation_of_FrequenciesHz','Standard_deviation_of_Dampings','Standard_deviation_of_Linewidths','Standard_deviation_of_Phases'};

htmlTableParts{2} = '<TR><TH>';
for ffDx = 1:numel(fitMagFields)
    htmlTableParts{2} = [htmlTableParts{2} '<TH>' fitMagFields{ffDx}];
end

for pDx = 1:numel(peaks)
    dataFields = [];
    
    for ffDx = 1:numel(fitMagFields)
        dataFields = [dataFields '<TD>' num2str( obj.misc.fittingResults{1}.dataByPeak.(peaks{pDx}).(fitMagFields{ffDx})) '+-' num2str(obj.misc.fittingResults{1}.dataByPeak.(peaks{pDx}).(fitSDFields{ffDx}))];
    end
        htmlTableParts{pDx+2} = sprintf('<TR><TH>%s%s',...
                                peaks{pDx}, dataFields);
    
    
end


%% Additional info

% Offset
addInfoStr{1} = sprintf('<p>Offset = %0.1f Hz = %0.1f ppm </p>',obj.misc.fittingResults{1}.offsetHz,obj.misc.fittingResults{1}.offsetHz/obj.data.spec.imagingFrequency);

% Norm
addInfoStr{2}= sprintf('<p>Relative Norm = %d </p>',obj.misc.fittingResults{1}.relativeNorm);

% Exit message

addInfoStr{3} =  ['<p>' obj.misc.fittingResults{1}.fitStatus{1}.OUTPUT.message '</p>'];


web(['text://<html><head><title>Matlab AMARES fit of voxel ' num2str(obj.voxel) '</title></head><body><h1>Raw fit results of voxel ' num2str(obj.voxel) '</a></h1>' htmlTableParts{:} '</TABLE>' addInfoStr{:} '</body></html>']);