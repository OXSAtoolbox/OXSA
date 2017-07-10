function pk = preparePriorKnowledge(fields,values)

%% Loop through and assemble structs
for peakDx = 1:size(values.boundsCellArray,1)
    for fieldsDx = 1:size(fields.Bounds,2)
        pk.bounds(1,peakDx).(fields.Bounds{fieldsDx}) = values.boundsCellArray{peakDx,fieldsDx};
    end
end

for peakDx = 1:size(values.IVCellArray,1)
    for fieldsDx = 1:size(fields.IV,2)
        pk.initialValues(1,peakDx).(fields.IV{fieldsDx}) = values.IVCellArray{peakDx,fieldsDx};
    end
end

for peakDx = 1:size(values.PKCellArray,1)
    for fieldsDx = 1:size(fields.PK,2)
        pk.priorKnowledge(1,peakDx).(fields.PK{fieldsDx}) = values.PKCellArray{peakDx,fieldsDx};
    end
end

%% Check the prior knowledge for consistency.
AMARES.checkConstraints(pk);
