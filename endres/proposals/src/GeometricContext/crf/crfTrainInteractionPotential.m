function params = crfTrainInteractionPotential(imsegs, adjlist, pE)

nlab = numel(imsegs(1).label_names);

% get label priors
pLab = zeros(1, nlab);
for f = 1:numel(imsegs)
    npix = imsegs(f).npixels / sum(imsegs(f).npixels);
    for k = 1:imsegs(f).nseg
        if imsegs(f).labels(k)~=0
            pLab(imsegs(f).labels(k)) = pLab(imsegs(f).labels(k)) + npix(k);
        end
    end
end
pLab = pLab / sum(pLab);

% get number of edges
nedge = 0;
for f = 1:numel(imsegs)
    for k = 1:size(pE{f}, 1)
        if all(imsegs(f).labels(adjlist{f}(k, :))>0)
            nedge = nedge + 1;
        end
    end
end

% get ground truth labels and data
yPair = zeros(nedge, 1); % label
xSim = zeros(nedge, 1); % similarity potential
params = zeros(nlab*nlab, 2);

nedge = 0;
for f = 1:numel(imsegs)
    lab = imsegs(f).labels;
    for k = 1:size(pE{f}, 1)
        if all(lab(adjlist{f}(k, :))>0)
            nedge = nedge + 1;
            klab = lab(adjlist{f}(k, :));
            klab = [min(klab) max(klab)]; % enforce symmetry
            yPair(nedge) = klab(1) +nlab*(klab(2)-1);
            xSim(nedge) = log(pE{f}(k))-log(1-pE{f}(k));
        end
    end
end
% get P(y1,y2 | xSim)/P(y1)/P(y2) = theta3/(1+exp(-(theta1 + theta2*x)))
for y1 = 1:nlab
    for y2 = y1:nlab
        y = y1 + (y2-1)*nlab;
        tmplab = (yPair==y);       
        initParam = [log(mean(tmplab))-log(1-mean(tmplab)) 0.5*(y1==y2)-0.5*(y1~=y2)];
        params(y, 1:2) = fminsearch(@(x) objective(x, xSim, tmplab), initParam); 
        params(y, 3) = 1/pLab(y1)/pLab(y2);
        params(y2+(y1-1)*nlab, :) = params(y, :);
        val = objective(params(y, 1:2), xSim, tmplab)/numel(tmplab);
        %disp(num2str([y1 y2 mean(tmplab) val params(y, :)]))
    end
end

  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function val = objective(param, x, y)
pY = 1./(1+exp(-(param(1)+param(2)*x)));
val = -sum(y.*log(pY) + (1-y).*log(1-pY));
%disp(num2str([mean(y) sum(y.*pY)/sum(y) sum((1-y).*(1-pY))/sum(1-y) sum(y.*log(pY)) sum((1-y).*log(1-pY))]))


    



