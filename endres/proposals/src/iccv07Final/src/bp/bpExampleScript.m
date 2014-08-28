% bpExampleScript

ctol = 0.000001;  % convergence tolerance
T = 0.1;       % annealing temperature
maxiter = Inf; % max iter for maxBeliefPropBethe


% factor for P(x1 | x2)
factor2var{1} = [1 2]; % which variables the factor involves
factors{1} = [0.9 0.5 ; ...
              0.1 0.5]; % P(x1=1|x2=1) = 0.9, P(x1=2|x2=1)=0.1
% factor for P(x2 | x3)
factor2var{2} = [2 3]; 
factors{2} = [0.25 0.01 ; ...
              0.75 0.99];
% factor for P(x3)
factor2var{3} = [3]; 
factors{3} = [0.25 ; ...
              0.75];  % P(x1=1)=0.25, P(x1=2)=0.75

nvals = [2 ; 2 ; 2]; % number of states for each node (variable)

[vals_max, bel_max] = maxBeliefPropBethe(factors, factor2var, nvals, ctol, T, maxiter);
bel_max = reshape(cell2mat(bel_max), [nvals(1) numel(nvals)])';

bel_marg = marginalBeliefPropBethe(factors, factor2var, nvals, ctol);
bel_marg = reshape(cell2mat(bel_marg), [nvals(1) numel(nvals)])';

% marginal answer should be:
%   P(x3=1) = 0.25; 
%   P(x2=1) = (0.25)*P(x3=1) + (0.01)*P(x3=2) =  0.07
%   P(x1=1) = (0.9)*P(x2=1) + 0.5*P(x2=2) = 0.528           
bel_marg

% max solution should be:
%   x1 = 2;
%   x2 = 2;
%   x3 = 1 or 2; (equally likely)
bel_max