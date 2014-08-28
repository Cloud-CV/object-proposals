function [rank, score, fout unary_scores] = greedy_max_score(features, overlaps, w)
% features - feat x proposal, unary features
% overlaps - proposal x proposal 
% w1 - feat x 1
% w2 - 1 x 1 


w1 = w(1:end-4);
w2 = w(end-3);
w3 = w(end-2);
w4 = w(end-1);
w5 = w(end);

w2 = max(w2, 0);
w3 = max(w3, 0);
w4 = max(w4, 0);
w5 = max(w5, 0);

unary_scores = (w1'*features)'; % 1 x proposal

%[scores_sorted, inds]= sort(unary_scores, 'descend');

n_prop = size(features, 2);

f2 = zeros(n_prop, 1);
f3 = zeros(n_prop, 1);

ith_ind = zeros(n_prop, 1);
rank = zeros(n_prop, 1);


fout = zeros(numel(w1)+2*(numel(w2)+numel(w3)),1);

w_norm = sum(weight(1:n_prop));

for i = 1:n_prop
   w_i = weight(i)./w_norm;
   [score(i) ind_i] = max(w_i*(unary_scores - w2*f2 - w3*f3) - w4*f2/n_prop - w5*f3/n_prop);

   fout = fout + [w_i*features(:,ind_i); w_i*f2(ind_i); w_i*f3(ind_i); f2(ind_i)/n_prop; f3(ind_i)/n_prop];

   f2(ind_i) = Inf;

   ith_ind(i) = ind_i;
   rank(ind_i) = i;

   % Update overlap penalty
   f2 = max(f2, overlaps(:, ind_i));
   f3 = f3 + overlaps(:, ind_i)/n_prop;
end

%fout(end) = fout(end)/n_prop;

