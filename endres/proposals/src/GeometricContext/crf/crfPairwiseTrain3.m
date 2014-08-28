function [crfw, priors] = crfPairwiseTrain(imsegs, pvSP, phSP, adjlist, pE, params, edgelen)

global itercount;
itercount = 0;

vlab = {imsegs(:).vert_labels};
hlab = {imsegs(:).horz_labels};
spweight = {imsegs(:).npixels};
for f = 1:numel(imsegs)
    spweight{f} = spweight{f} / sum(spweight{f});
end

% get f1(y1, y2) = log(P(y1|x)) + log(P(y2|x))
% and f2(y1, y2) = I(y1=y2)*log(P(y1=y2|x)) + I(y1~=y2)*log(P(y1~=y2|x))

npair = 0;
for f = 1:numel(adjlist)
    npair = npair + size(adjlist{f}, 1);
end


f1 = zeros(npair, 49);
f2 = zeros(npair, 49);
f3 = zeros(npair, 49);
lab = zeros(npair, 1);
w = zeros(npair, 1);
%nbpair = zeros(npair, 2);

c = 0;
for f = 1:numel(adjlist)
    npairf = size(adjlist{f}, 1);
    pg = [pvSP{f}(:, 1)  repmat(pvSP{f}(:, 2), 1, 5).*phSP{f}  pvSP{f}(:, 3)];  
    labf = (vlab{f}==1)*1 + (vlab{f}==2).*(hlab{f}>0).*(hlab{f}+1) + (vlab{f}==3)*7;
    
    s1 = adjlist{f}(:, 1);
    s2 = adjlist{f}(:, 2);

    edgeperc = zeros(numel(s1), 2);
    nb = zeros(size(pg, 1), 1);
    for k = 1:npairf
        nb(s1(k)) = nb(s1(k))+1;
        nb(s2(k)) = nb(s2(k))+1;
        edgeperc(k, 1) = edgelen{f}(s1(k), s2(k)) / (sum(edgelen{f}(s1(k), :))+sum(edgelen{f}(:, s1(k))));
        edgeperc(k, 2) = edgelen{f}(s1(k), s2(k)) / (sum(edgelen{f}(s2(k), :))+sum(edgelen{f}(:, s2(k))));
        w(c+k) = sum(spweight{f}([s1(k) s2(k)]));
    end
    %nbpair(c+1:c+npairf, :) = [nb(s1) nb(s2)];
%    min(1./edgeperc(:, 1) + 1./edgeperc(:, 2))
%    max(1./edgeperc(:, 1) + 1./edgeperc(:, 2))
    % unaries normalize for number of edges, and pairwise normalize for
    % edge length
    for k1 = 1:7
        for k2 = 1:7
            f1(c+1:c+npairf, (k1-1)*7+k2) = log(pg(s1, k1))./nb(s1) + log(pg(s2, k2))./nb(s2);
            kp = params(k1 + (k2-1)*7, :);
            if k1==k2
                f2(c+1:c+npairf, (k1-1)*7+k2) = ...
                    log(kp(3)./(1+exp(-kp(1)-kp(2)*(log(pE{f})-log(1-pE{f}))))).*...
                    (edgeperc(:, 1) + edgeperc(:, 2));
            else
                f3(c+1:c+npairf, (k1-1)*7+k2) = ...
                    log(kp(3)./(1+exp(-kp(1)-kp(2)*(log(pE{f})-log(1-pE{f}))))).*...
                    (edgeperc(:, 1) + edgeperc(:, 2));
            end
        end
    end
    
    lab(c+1:c+npairf) = (labf(s1)>0 & labf(s2)>0).*((labf(s1)-1)*7 + labf(s2));            
    
    c = c + npairf;
end

ind = find(lab==0);
lab(ind) = [];
f1(ind, :) = [];
f2(ind, :) = [];
f3(ind, :) = [];
w(ind, :) = [];

w = w/sum(w);
%nbpair(ind, :) = [];

f2 = f2 - repmat(log(sum(exp(f2), 2)), [1 size(f2, 2)]);
f3 = f3 - repmat(log(sum(exp(f3), 2)), [1 size(f3, 2)]);

fnc{1} = f1;
fnc{2} = f2;
fnc{3} = f3;
%disp(numel(lab))

disp('uniform w')
w = ones(size(w))/numel(w); 

[p, err] = avep([1 0 0 zeros(1,27)], fnc, lab, w);
disp(num2str([p err]))

initval = [3 0 1 3 -1 -1 -1 0 0 -1 2 -1 -1 -1 -1 2 2 -1 -1 -1 2 2 -2 -1 2 1 -1 2 2 1];
crfw = fminunc(@(x) objective(x, fnc, lab, w), initval, optimset('TolFun', 0.01)); 

[p, err] = avep(crfw, fnc, lab, w);
disp(num2str([p err]))

priors = priormat(7, crfw(numel(fnc)+1:end));
crfw = crfw(1:numel(fnc));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function lpw = objective(w, f, lab, weight)
global itercount;
correctind = [1:numel(lab)]' + (lab-1)*numel(lab);

%w(1:3) = max(w(1:3), 0);

pmat = priormat(7, w(numel(f)+1:end));
lpw = pmat(lab);
tmpz = repmat(pmat', [numel(lab) 1]);
for k = 1:numel(f)
    lpw = lpw + w(k)*f{k}(correctind);
    tmpz = tmpz + w(k)*f{k};
end
z = log(sum(exp(tmpz), 2));

lpw = -sum((lpw - z).*weight);

itercount = itercount + 1;
if mod(itercount, 25)==0
    disp(num2str([lpw w pmat(end)]))
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [p err] = avep(w, f, lab, weight)

correctind = [1:numel(lab)]' + (lab-1)*numel(lab);

%w(1:3) = max(w(1:3), 0);

pmat = priormat(7, w(numel(f)+1:end));
lpw = pmat(lab);
tmpz = repmat(pmat', [numel(lab) 1]);
for k = 1:numel(f)
    lpw = lpw + w(k)*f{k}(correctind);
    tmpz = tmpz + w(k)*f{k};
end
z = log(sum(exp(tmpz), 2));

p = sum(exp(lpw-z).*weight);

[tmp, guess] = max(tmpz, [], 2);
err = sum((guess~=lab).*weight);
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pmat = priormat(nlab, param);

param(end+1) = -sum(param); % sum of free params equals zero
pmat = zeros(nlab, nlab);
c=0;
for k1 = 1:nlab
    for k2=k1:nlab
        c = c + 1;
        pmat(k1, k2) = param(c);
        pmat(k2, k1) = param(c);
    end
end
pmat = pmat(:);
pmat(end) = -sum(pmat(1:end-1));