function [testRes,testResStr] = test_createModelConstraints()
% Test AMARES.createModelConstraints. Assumes prior knowledge and
% AMARES.initializeOptimization functions are working correctly.
% Lucian A. B. Purvis 2017

counter = 1;
clear testRes testResStr

params = {'amplitude'; 'chemShift'; 'phase'; 'linewidth'};

%% If bounds are empty, constrain to initial value

pk = AMARES.priorKnowledge.PK_SinglePeak;

for paramDx = 1:numel(params)
    pk.bounds.(params{paramDx}) = [];
end


[~, ~, ~, optimIndex] = AMARES.initializeOptimization(pk);
constraintsCellArray = AMARES.createModelConstraints(pk, optimIndex);

for paramDx = 1:numel(params)
    
    funFn = params{paramDx};
    
    if strcmp(constraintsCellArray.(funFn){1}{1},'@(a)a;')&&constraintsCellArray.(funFn){1}{2}==pk.initialValues.(params{paramDx})
        testResStr{counter} = sprintf('%s no added PK passed', params{paramDx});
        testRes(counter) = 1;
    else
        testResStr{counter} = sprintf('%s no added PK failed', params{paramDx});
        testRes(counter) = 0;
    end
    counter = counter + 1;
    
end

%% If no prior knowledge other than bounds and initial values, default to fitting
pk = AMARES.priorKnowledge.PK_SinglePeak;

[~, ~, ~, optimIndex] = AMARES.initializeOptimization(pk);
constraintsCellArray = AMARES.createModelConstraints(pk, optimIndex);


for paramDx = 1:numel(params)
    
    funFn = params{paramDx};
    
    if strcmp(constraintsCellArray.(funFn){1}{1},'@(x,a)x(a);') % TODO: Check whether this uses the correct fit variables
        testResStr{counter} = sprintf('%s empty bounds passed', params{paramDx});
        testRes(counter) = 1;
    else
        testResStr{counter} = sprintf('%s empty bounds failed', params{paramDx});
        testRes(counter) = 0;
    end
    counter = counter + 1;
    
end


%% Group peaks

pk = AMARES.priorKnowledge.PK_7T_Cardiac_t2;

[~, ~, ~, optimIndex] = AMARES.initializeOptimization(pk);
constraintsCellArray = AMARES.createModelConstraints(pk, optimIndex);

%Additional linewidth

if strcmp(constraintsCellArray.linewidth{1}{1},'@(x,a,b)x(a)+b;')&& constraintsCellArray.linewidth{1}{3}==pk.priorKnowledge(1).base_linewidth
    testResStr{counter} = 'Additional linewidth passed';
    testRes(counter) = 1;
else
    testResStr{counter} = 'Additional linewidth failed';
    testRes(counter) = 0;
end

pk = AMARES.priorKnowledge.PK_3T_Cardiac;

[~, ~, ~, optimIndex] = AMARES.initializeOptimization(pk);
constraintsCellArray = AMARES.createModelConstraints(pk, optimIndex);

% G_linewidth

if strcmp(constraintsCellArray.linewidth{11}{1},'@(x,a)x(a);')&& constraintsCellArray.linewidth{1}{2}==13 %13 is the index for the first DPG peak linewidth
    testResStr{counter} = 'G_linewidth passed';
    testRes(counter) = 1;
else
    testResStr{counter} = 'G_linewidth failed';
    testRes(counter) = 0;
end

% G_amplitude
% Not currently used

% G_phase
%
if strcmp(constraintsCellArray.phase{1}{1},'@(x,a)x(a);')&& constraintsCellArray.phase{1}{2}==21 % 21 is the index of the first peak phase
    testResStr{counter} = 'G_linewidth passed';
    testRes(counter) = 1;
else
    testResStr{counter} = 'G_linewidth failed';
    testRes(counter) = 0;
end

%% Multiplet

%Chemshift
if strcmp(constraintsCellArray.amplitude{2}{1},'@(x,a,b)x(a)+b;')&& constraintsCellArray.amplitude{2}{3}==pk.priorKnowledge(1).chemShiftDelta
    testResStr{counter} = 'Multiplet chemical shift passed';
    testRes(counter) = 1;
else
    testResStr{counter} = 'Multiplet chemical shift failed';
    testRes(counter) = 0;
end


%Amplitudes
if strcmp(constraintsCellArray.amplitude{1}{1},'@(x,a,b)x(a)*b;')&& constraintsCellArray.amplitude{1}{3}==pk.priorKnowledge(1).amplitudeRatio
    testResStr{counter} = 'Multiplet amplitude ratio passed';
    testRes(counter) = 1;
else
    testResStr{counter} = 'Multiplet amplitude ratio  failed';
    testRes(counter) = 0;
end


%% Check that constraint numbering works for each peak

pk = AMARES.priorKnowledge.PK_3T_Cardiac;

[~, ~, ~, optimIndex] = AMARES.initializeOptimization(pk);
constraintsCellArray = AMARES.createModelConstraints(pk, optimIndex);

% 7 peaks including 2 doublets and a triplet = 11

if numel(constraintsCellArray.chemShift) == 11
    testResStr{counter} = 'Constraint numbering passed';
    testRes(counter) = 1;
else
    testResStr{counter} = 'Constraint numbering failed';
    testRes(counter) = 0;
end

%%

if all(testRes==1)
    fprintf('Create model constraints passed!\n')
else
    warning('Create model constraints passed!')
end

