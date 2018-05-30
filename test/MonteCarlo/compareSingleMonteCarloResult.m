function res = compareSingleMonteCarloResult(var_a, var_b, type)

percentThresh = 0.01;

analysisFn = fieldnames(var_a);

for aDx = 1:numel(analysisFn)
    
    switch type
        case 'Absolute'
                        diffVal = var_a.(analysisFn{aDx}) - var_b.(analysisFn{aDx});

            res.(analysisFn{aDx}) = diffVal > percentThresh*var_a.(analysisFn{aDx})(end);
            if any(res.(analysisFn{aDx}))
                fprintf('Difference of %0.02f in %s values.\n',mean(diffVal(:)), analysisFn{aDx})
            end
            
        case 'Percentage'
            
            diffVal = var_a.(analysisFn{aDx}) - var_b.(analysisFn{aDx});
            res.(analysisFn{aDx}) = diffVal > percentThresh*100;
            if any(res.(analysisFn{aDx}))
                fprintf('Difference of %0.02f%% in %s values.\n',mean(diffVal(:)), analysisFn{aDx})
            end
    end
    
end