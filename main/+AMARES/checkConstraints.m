function checkConstraints(pk)
% Validates and prints a set of prior knowledge for Matlab AMARES.

% check number of peaks
if ~isequal(numel(pk.initialValues),numel(pk.priorKnowledge),numel(pk.bounds))
    error('The peaks listed in the pk.initialValues, pk.priorKnowledge and pk.bounds must be identical.')
end

% check order of peaks and peak names
B_fn = fieldnames(pk.bounds);

for p = 1:numel(pk.initialValues)
    if ~isequal(pk.initialValues(p).peakName,pk.priorKnowledge(p).peakName,pk.bounds(p).peakName)
        error('The peaks listed in the pk.initialValues, pk.priorKnowledge and pk.bounds must be identical.')
    end
    if ischar(pk.initialValues(p).peakName) && size(pk.initialValues(p).peakName,1) > 1
        error('peakName must contain either a single string or a cell array of strings.')
    end
    % check that initial values are in the range defined by lower and upper pk.bounds
    for f = 1:numel(B_fn)
        Bfield = pk.bounds(p).(B_fn{f});
        if ~isempty(Bfield) && isnumeric(Bfield)
            if numel(Bfield) ~= 2
                error('Specify lower and upper pk.bounds for %s', B_fn{f})
            elseif Bfield(1)==Bfield(2) || Bfield(1)>Bfield(2)
                error('Lower and upper pk.bounds for %s cannot be equal', B_fn{f})
            elseif isfield(pk.initialValues, B_fn{f})
                if ~(pk.initialValues(p).(B_fn{f}) >= Bfield(1) && pk.initialValues(p).(B_fn{f}) <= Bfield(2))
                    error('The initial value for %s in {pk.initialValues} is out of pk.bounds', B_fn{f})
                end
            elseif isfield(pk.priorKnowledge, B_fn{f})
                if ~(pk.priorKnowledge(p).(B_fn{f}) >= Bfield(1) && pk.priorKnowledge(p).(B_fn{f}) <= Bfield(2))
                    error('The initial value for %s in {pk.priorKnowledge} is out of pk.bounds', B_fn{f})
                end
            else
                error('structure fieldnames in {pk.bounds} must correspond to fieldnames in {pk.initialValues} or in {pk.priorKnowledge}')
            end
        end
    end
end

%% Check that a group number starts with the first peak in the group
%
 groupNames = {'G_linewidth',   'G_amplitude',    'G_phase'   ,  'G_chemShiftDelta'};
 
 for gnDx = 1:numel(groupNames)
     
    gEmptyArray = cellfun(@isempty,{pk.priorKnowledge(:).(groupNames{gnDx})});
    gArray = {pk.priorKnowledge(:).(groupNames{gnDx})};
    gArray(gEmptyArray) = {0};
    
    groupNumbers = unique([pk.priorKnowledge(:).(groupNames{gnDx})]);
     for iDx = 1:numel(groupNumbers)
         if find(cell2mat(gArray) == groupNumbers(iDx), 1 ) ~= groupNumbers(iDx)
            error('The group number must be the number of the first peak in the group. Failed on: %s, group %d.',groupNames{gnDx},groupNumbers(iDx)) 
         end         
     end    
     
 end


%% Display
% display initial values
IVcell2D = prepForDisp(pk.initialValues);
fprintf('\n\t initial values for %d peaks\n\n', numel(pk.initialValues))
disp(IVcell2D)

% display prior knowledge
PKcell2D = prepForDisp(pk.priorKnowledge);
fprintf('\n\t prior knowledge for %d peaks\n\n', numel(pk.initialValues))
disp(PKcell2D)

%display upper and lower pk.bounds
Bcell2D = prepForDisp(pk.bounds);
fprintf('\n\t upper and lower bounds for %d peaks\n\n', numel(pk.initialValues))
disp(Bcell2D)

end

function ITEMcell2D = prepForDisp(item)
% Pretty print a field from the prior knowledge struct.
ITEM_fn = fieldnames(item);
ITEMcell = struct2cell(item);

ITEMcell2D = cell(numel(ITEM_fn),numel(item));
for p = 1:numel(item)
    for f = 1:numel(ITEM_fn)
        ITEMcell2D(f,1) = ITEM_fn(f);
        if iscellstr(ITEMcell{f,1,p})
            ITEMcell2D{f,p+1} = strjoin_pja(',',ITEMcell{f,1,p}{:});
        elseif ischar(ITEMcell{f,1,p})
            ITEMcell2D{f,p+1} = ITEMcell{f,1,p};
        else
            ITEMstr = mat2str(ITEMcell{f,1,p});
            if isempty(strfind(ITEMstr,'[')) ITEMstr = ['[' ITEMstr ']']; end
            ITEMcell2D{f,p+1} = ITEMstr;
        end
    end
end
end
