function [P] = compute_P_Matrix(optimVar, func)
% Compute P matrix for CRB determination.
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

% The P matrix has dp_i / dp'_j entries linking independent and full
% (including constrained) parameter list.

% Combine into canonical ordering...
params = AMARES.getCanonicalOrdering();

for fDx =1:numel(params)
    
    funcs(fDx,:) = func.(params{fDx}); %#ok<AGROW>
    
end

P = applyIt(optimVar,funcs);

end

% Compute derivatives...
function thisOut = applyIt(optimVar,funcs)
thisOut = spalloc(numel(funcs),numel(optimVar),2*numel(funcs));

for idx=1:numel(funcs)
    thisFunc = funcs{idx};
    switch thisFunc{1}
        case '@(a)a;'
            % All zeros. Nothing to change. % da/dx(z) = 0 where a = const.
        case '@(x,a)x(a);'
            thisOut(idx,thisFunc{2}) = 1; %#ok<*SPRIX> % dx(a)/dx(z) = delta_az
        case '@(x,a,b)x(a)+b;'
            thisOut(idx,thisFunc{2}) = 1; % dx(a)/dx(z) = delta_az
        case '@(x,a,b)x(a)*b;'
            thisOut(idx,thisFunc{2}) = thisFunc{3}; % d(x(a)*b)/dx(z) = delta_az * b
        case '@(x,a,b)x(a)*x(b);'
            thisOut(idx,thisFunc{2}) = optim(thisFunc{3}); % d(x(a)*x(b))/dx(z) = delta_ax * x(b) + x(a) * delta_bx
            thisOut(idx,thisFunc{3}) = thisOut(idx,thisFunc{3}) + optim(thisFunc{2}); % + catches cases where {2} == {3}.
        case '@(x,a,b,c)x(a)+b*x(c);' % d(x(a)+b*x(c))/dx(z) = delta_az + b*delta_cz
            thisOut(idx,thisFunc{2}) = 1;
            thisOut(idx,thisFunc{4}) = thisOut(idx,thisFunc{4}) + thisFunc{3};
        otherwise
            error('Unknown type of constraint!')
    end
end
end