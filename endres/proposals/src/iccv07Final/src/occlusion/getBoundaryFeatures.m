function [x, featDescription] = getBoundaryFeatures(ind, occ, pb, pb2)
% [x, featDescription] = getBoundaryFeatures(ind, occ, pb, pb2)

if islogical(ind)
    ind = find(ind);
end

featDescription = cell(1, 7);
x = zeros(numel(ind), 7);

[imh, imw, no] = size(occ.po_all);
npix = imh*imw;
%n = zeros(numel(ind), 1);
for f = 1:4
    ind2 = ind + npix*(f-1);
    x(:, f) = occ.po_all(ind2);
    featDescription{f} = ['pocc' num2str(f)];
    %n = n + double(x(:, f)>0);
end
f = f+1;
x(:, f) = max(x(:, 1:f-1), [], 2); % occ.po(ind);
featDescription{f} = 'pocc_max';
%f = f+1;
%x(:, f) = n;
if exist('pb', 'var') && ~isempty(pb)
    f = f+1;
    pb_soft = max(pb.pb_soft, [], 3); 
    x(:, f) = pb_soft(ind);
    featDescription{f} = 'pb1';
end
if exist('pb2', 'var') && ~isempty(pb2)
    f = f+1;
    x(:, f) = pb2.pb_soft(ind);
    featDescription{f} = 'pb2';
end
