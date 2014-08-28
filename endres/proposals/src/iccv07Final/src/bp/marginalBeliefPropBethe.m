function belief_outer = ...
    marginalBeliefPropBethe(factors, factor2var, nvals, ctol)
%
% marginals = marginalBeliefPropBethe(factors, factor2var, nnodes, tol)
%
% Computes the marginals for the given factor graph using the method of
% (Heskes Kees Kappen 2003).  
%
% factors{nf}(ndim1, ndim2 ...): the probability factors
% factor2var{nf}: indicates the subset of variables for each factor
% nvals(nvar): the number of (discrete) values per variable
% tol: convergence tolerance (e.g., 1E-4)


%% Initialize

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

iter_out = 0;
iter_in = 0;

converged_outer = 0;

while ~converged_outer

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

                msgFactorToVar{c} = Qfi ./ msgVarToFactor{c};            

                Qi = Qi .* msgFactorToVar{c}.^(1/nfactors(i));

            end

            belief_inner{i} = Qi .^ (nfactors(i));
            belief_inner{i} = belief_inner{i} ./ sum(belief_inner{i}(:));

            Qi = Qi ./ sum(Qi);
            belief_inner{i} = Qi;
            
            % set var-->factor messages and factor belief
            for f = var2factor{i}            

                c = indexmap(i, f);

                msgVarToFactor{c} = Qi ./ msgFactorToVar{c};

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
            end
        end
        %disp(['Maximum difference: ' num2str(maxdiff)])
        last_belief = belief_inner;        

    end

    converged_outer = 1;
    for i = 1:nvar
        if any(abs(last_belief{i}-belief_outer{i}) > ctol)
            converged_outer = 0;
        end
    end    
    belief_outer = last_belief;

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
%     for f = 1:nf                
%        jointbel = getJoint(belief_outer(factor2var{f}));            
%        expnum = (nfactors(i)-1)/nfactors(i);
%        factor2{f} = factors{f} .* jointbel.^expnum;
%     end    
    
end



