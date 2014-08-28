function crfw = crfPLTrain(vlab, hlab, pvSP, phSP, adjlist, pE)

% get f1(y1, y2) = log(P(y1|x)) + log(P(y2|x))
% and f2(y1, y2) = I(y1=y2)*log(P(y1=y2|x)) + I(y1~=y2)*log(P(y1~=y2|x))

npair = 0;
for f = 1:numel(adjlist)
    npair = npair + size(adjlist{f}, 1);
end

f1 = zeros(npair, 49);
f2 = zeros(npair, 49);
lab = zeros(npair, 1);

c = 0;
for f = 1:numel(adjlist)
    
    disp(num2str(f))
    npairf = size(adjlist{f}, 1);
    pg = [pvSP{f}(:, 1)  repmat(pvSP{f}(:, 2), 1, 5).*phSP{f}  pvSP{f}(:, 3)];  
    labf = (vlab{f}==1)*1 + (vlab{f}==2).*(hlab{f}>0).*(hlab{f}+1) + (vlab{f}==3)*7;
    
    s1 = adjlist{f}(:, 1);
    s2 = adjlist{f}(:, 2);
          
    % unary and interaction potentials for s1 and s2 
    for k1 = 1:7
        for k2 = 1:7
            f1(c+1:c+npairf, (k1-1)*7+k2) = log(pg(s1, k1)) + log(pg(s2, k2));
            if k1==k2
                f2(c+1:c+npairf, (k1-1)*7+k2) = log(pE{f});
            else
                f2(c+1:c+npairf, (k1-1)*7+k2) = log((1-pE{f})/6);
            end            
        end
    end
    
    % add potentials for edges going out of s1, s2
    for k = 1:npairf
        n1 = setdiff([find(s1==s1(k)) ; find(s2==s1(k))], k);
        n2 = setdiff([find(s1==s2(k)) ; find(s2==s2(k))], k);
        sn1 = setdiff([s2(find(s1==s1(k))) ; s1(find(s2==s1(k)))], s2(k));
        sn2 = setdiff([s2(find(s1==s2(k))) ; s1(find(s2==s2(k)))], s1(k));        
        
        for n = 1:numel(n1)
            if labf(sn1(n))>0
                tmpf2diff = log((1-pE{f}(n1(n)))/6);
                tmpf2same = log(pE{f}(n1(n)));
                sameind = (labf(sn1(n))-1)*7+[1:7];
                diffind = setdiff(1:49, sameind);
                f2(c+k, sameind) = f2(c+k, sameind) + tmpf2same;
                f2(c+k, diffind) = f2(c+k, diffind) + tmpf2diff;            
            end
        end
        
        for n = 1:numel(n2)
            if labf(sn2(n))>0
                tmpf2diff = log((1-pE{f}(n2(n)))/6);
                tmpf2same = log(pE{f}(n2(n)));
                sameind = ([1:7]-1)*7+labf(sn2(n));
                diffind = setdiff(1:49, sameind);
                f2(c+k, sameind) = f2(c+k, sameind) + tmpf2same;
                f2(c+k, diffind) = f2(c+k, diffind) + tmpf2diff;            
            end
        end

%         for k1 = 1:7
%             for k2 = 1:7
%                 for n = 1:numel(n1)
%                     if k1==labf(sn1(n))
%                         f2(c+k, (k1-1)*7+k2) = f2(c+k, (k1-1)*7+k2) + log(pE{f}(n1(n))/7);
%                     else
%                         f2(c+k, (k1-1)*7+k2) = f2(c+k, (k1-1)*7+k2) + log((1-pE{f}(n1(n)))/42);
%                     end
%                 end
%                 for n = 1:numel(n2)
%                     if k2==labf(sn2(n))
%                         f2(c+k, (k1-1)*7+k2) = f2(c+k, (k1-1)*7+k2) + log(pE{f}(n2(n)));
%                     else
%                         f2(c+k, (k1-1)*7+k2) = f2(c+k, (k1-1)*7+k2) + log((1-pE{f}(n2(n)))/6);
%                     end
%                 end                         
%             end
%         end    
    end
    
    lab(c+1:c+npairf) = (labf(s1)>0 & labf(s2)>0).*((labf(s1)-1)*7 + labf(s2));            
    
    c = c + npairf;
end



ind = find(lab==0);
lab(ind) = [];
f1(ind, :) = [];
f2(ind, :) = [];
%f3(ind, :) = [];

fnc{1} = f1;
fnc{2} = f2;
%fnc{3} = f3;
%disp(numel(lab))

[p, err] = avep([1 0], fnc, lab);
disp(num2str([p err]))


crfw = fminsearch(@(x) objective(x, fnc, lab), [1 1], optimset('Display', 'final')); 

[p, err] = avep(crfw, fnc, lab);
disp(num2str([p err]))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function lpw = objective(w, f, lab)

%disp(num2str(w))

correctind = [1:numel(lab)]' + (lab-1)*numel(lab);

lpw = 0;
tmpz = 0;
for k = 1:numel(f)
    lpw = lpw + w(k)*f{k}(correctind);
    tmpz = tmpz + w(k)*f{k};
end
z = log(sum(exp(tmpz), 2));

lpw = -(sum(lpw - z));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [err] = aveerr(w, f, lab)

tmpz = 0;
for k = 1:numel(f)
    tmpz = tmpz + w(k)*f{k};
end

[tmp, guess] = max(tmpz); %max(w(1)*f1 + w(2)*f2, [], 2);
err = mean(guess~=lab);

disp(num2str([w err]))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [p err] = avep(w, f, lab)

correctind = [1:numel(lab)]' + (lab-1)*numel(lab);

lpw = 0;
tmpz = 0;
for k = 1:numel(f)
    lpw = lpw + w(k)*f{k}(correctind);
    tmpz = tmpz + w(k)*f{k};
end
z = log(sum(exp(tmpz), 2));

p = mean(exp(lpw-z));

[tmp, guess] = max(tmpz, [], 2);
err = mean(guess~=lab);
    

