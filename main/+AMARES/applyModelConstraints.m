function modelParams = applyModelConstraints(optimVar, func)
% Apply constraints to the optimization variables and transforms them into
% input parameters for makeSyntheticData.
%
% Input:
%
% optimVar is the current vector of variable parameters being varied by lsqcurvefit.
%
% func are each a double constant (fixed parameter) or an anonymous
% function handle (other type of constrained parameter).
%
% Output:
%
% Current values for overall model parameters subject to the current vector
% of variable parameters being varied by lsqcurvefit.

fn = fieldnames(func);

for fnDx = 1:numel(fn)
modelParams.(fn{fnDx}) = applyIt(optimVar,func.(fn{fnDx}));
end

end

function thisOut = applyIt(optimVar,funcs)
thisOut = zeros(size(funcs));

for idx=1:numel(funcs)
    thisFunc = funcs{idx};
    switch thisFunc{1}
        case '@(a)a;'
            thisOut(idx) = thisFunc{2};
        case '@(x,a)x(a);'
            thisOut(idx) = optimVar(thisFunc{2});
        case '@(x,a,b)x(a)+b;'
            thisOut(idx) = optimVar(thisFunc{2})+thisFunc{3};
        case '@(x,a,b)x(a)*b;'
            thisOut(idx) = optimVar(thisFunc{2})*thisFunc{3};
        case '@(x,a,b)x(a)*x(b);'
            thisOut(idx) = optimVar(thisFunc{2})*optimVar(thisFunc{3});
        case '@(x,a,b,c)x(a)+b*x(c);'
            thisOut(idx) = optimVar(thisFunc{2})+thisFunc{3}*optimVar(thisFunc{4});
        otherwise
            error('Unknown type of constraint!')
    end
end
end