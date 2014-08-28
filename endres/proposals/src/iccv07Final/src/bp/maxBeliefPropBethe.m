function [vals, belief_outer] = ...
    maxBeliefPropBethe(factors, factor2var, nvals, ctol, T, maxiter)
%
% [mlvals, bel] = marginalBeliefPropBethe(factors, factor2var, nnodes, tol)
%
% Computes the most likely solution for the given factor graph using the
% method of (Heskes Kees Kappen 2003) and the annealing approach suggested 
% by (Yuille 2001).  
%
% factors{nf}(ndim1, ndim2 ...): the probability factors
% factor2var{nf}: indicates the subset of variables for each factor
% nnodes(nvar): the number of (discrete) values per variable
% tol: convergence tolerance (e.g., 1E-4)
% T: the annealing schedule (each temperature)
%

%% Initialize

if ~exist('maxiter', 'var') || isempty(maxiter)
    maxiter = Inf;
end

nvar = numel(nvals);

nf = numel(factors);

% get factors that contain each variable
nfx = 0;
var2factor = cell(nvar);
for f = 1:nf
    for i = factor2var{f}
        var2factor{i}(end+1) = f;
        nfx = nfx + 1;
    end
end

% get number of factors per variable
nfactors = zeros(nvar, 1);
for k = 1:nvar
    nfactors(k) = numel(var2factor{k});
end

% initialize and index messages
indexmap = spalloc(nf, nvar, nfx);
msgVarToFactor = cell(nfx, 1);
msgFactorToVar = cell(nfx, 1);
c = 0;
for i = (1:nvar)
  for f = var2factor{i}  
      c = c + 1;
      indexmap(i,f) = c;
      msgVarToFactor{c} = ones(nvals(i), 1); %ones(size(factors{f}));
      msgFactorToVar{c} = ones(nvals(i), 1);
  end
end

% initialize belief
Q_factor_joint = factors;
factor2 = factors;

for f = 1:numel(factors)
    Q_factor_joint{f} = ones(size(factors{f}));
end

belief_inner = cell(nvar, 1);
for k = 1:nvar
    belief_inner{k} = ones(nvals(k), 1);
end
last_belief = belief_inner;
belief_outer = last_belief;



%% Do belief propagation by minimizing Beth free energy

origfactors = factors;


for t = T  

    %disp(['T = ' num2str(t)]);
    
    for f = 1:numel(factors)
        factors{f} = origfactors{f} .^ (1/t);
        factors{f} = factors{f} / sum(factors{f}(:));
    end

    iter_out = 0;    
    
    converged_outer = 0;

    while ~converged_outer

        iter_in = 0;
        iter_out = iter_out + 1;
        %disp(num2str(['outer loop: ' num2str(iter_out)]));
        
        converged = 0;    

        while ~converged        

            iter_in = iter_in + 1;
            %disp(num2str(['inner loop: ' num2str(iter_in)]));            
            
            for i = 1:nvar            

                % set factor-->var messages and variable belief
                Qi = ones(nvals(i),1);
                for f = var2factor{i}                   
                    
                    c = indexmap(i, f);        
                    ti = find(factor2var{f}==i);

                    Qfi = getMarginals(Q_factor_joint{f}, ti);            

%                     if any(msgVarToFactor{c}<eps)
%                         disp('flag 1');
%                     end
                    msgFactorToVar{c} = Qfi ./ (max(msgVarToFactor{c},eps));            

                    Qi = Qi .* msgFactorToVar{c}.^(1/nfactors(i));

                end

                belief_inner{i} = Qi .^ (nfactors(i));
                belief_inner{i} = belief_inner{i} / sum(belief_inner{i});

                Qi = Qi ./ sum(Qi);
                belief_inner{i} = Qi;

                % set var-->factor messages and factor belief
                for f = var2factor{i}            

                    c = indexmap(i, f);

%                     if any(msgFactorToVar{c}<eps)
%                         disp('flag 2');
%                     end                    
                    msgVarToFactor{c} = Qi ./ (max(msgFactorToVar{c},eps));
                    
%                     if any(msgVarToFactor{c} < 0.00001)
%                         disp('flag 3')
%                     end
                    
                    v2fIndAll = indexmap(factor2var{f}, f);
                    jointv2f = getJoint(msgVarToFactor(v2fIndAll));            
                    Q_factor_joint{f} = factor2{f} .* jointv2f; 
                    Q_factor_joint{f} = Q_factor_joint{f} ./ sum(Q_factor_joint{f}(:));
                end                


            end

            % check convergence
            converged = 1;
            maxdiff = 0;
            for i = 1:nvar
                maxdiff = max(maxdiff, max(abs(last_belief{i}-belief_inner{i})));
                if any(abs(last_belief{i}-belief_inner{i}) > ctol)
                    converged = 0;
                    break;
                end
            end
            %disp(['Maximum difference: ' num2str(maxdiff)])
            last_belief = belief_inner;        
            
            if iter_in >= maxiter
                disp('Quitting inner loop early');
                converged = 1;
            end
            
        end % end inner loop

        converged_outer = 1;
        for i = 1:nvar
            if any(abs(last_belief{i}-belief_outer{i}) > ctol)
                converged_outer = 0;
                break;
            end
        end    
        belief_outer = last_belief;

        if iter_out >= maxiter
            disp('Quitting outer loop early');
            converged_outer = 1;
        end
        
        for f = 1:nf                
            tmp = cell(size(factor2var{f}));
            for i = 1:numel(tmp)
                vari = factor2var{f}(i);
                expnum = (nfactors(vari)-1)/nfactors(vari);
                tmp{i} = belief_outer{vari}.^expnum;
            end
            % expnum = (nfactors(i)-1)/nfactors(i);
            %jointbel = getJoint(belief_outer(factor2var{f}));                       
            %factor2{f} = factors{f} .* jointbel.^expnum;
            jointbel = getJoint(tmp);
            factor2{f} = factors{f} .* jointbel;
        end    

    end

end

vals = zeros(nvar, 1);
conf = zeros(nvar, 1);
for k = 1:nvar
    [conf(k), vals(k)] = max(belief_outer{k});
end