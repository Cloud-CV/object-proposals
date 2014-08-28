function [pair_feats po] = segment_pairing_features_image(th, sind, feat_data)

if(~exist('th','var') | exist('sind', 'var'))
   th = 1;
end

LEFT = 1;
TOP = 2;
RIGHT = 3;
BOTTOM= 4;
PURE = 5;
OBJECT = 6;

   % Features are source x des
%   good = feat_data.pair_labels~=0 & rand(size(feat_data.pair_labels))<th; %Subsampling term
    good = rand(numel(feat_data.regions))<th; %Subsampling term

   if(~exist('sind','var'))
      [sgood dgood] = find(good);
   elseif(isempty(sind))
      [sgood dgood] = find(good);
   else
      dgood = 1:size(feat_data.pair_labels)';
      dgood = dgood(:);
      sgood = repmat(sind, size(dgood));
   end
   
   pred_inds = [LEFT TOP RIGHT BOTTOM PURE]; % no OBJECT
   % 14 + 1 features
%   unary_feats = [feat_data.Xobj(dgood,:), feat_data.pred(dgood, OBJECT)];
   
   pair_inds = sub2ind(size(good), sgood, dgood);

   X1 =1; Y1 = 2; X2 = 3; Y2 = 4;
   bboxes = cat(1,feat_data.Xapp.bbox);

   I1 = max(bboxes(sgood, Y1), bboxes(dgood, Y1));
   I2 = min(bboxes(sgood, Y2), bboxes(dgood, Y2));

   Ls = feat_data.predictions(sgood, LEFT) .* double(bboxes(sgood, X1) > bboxes(dgood, X1)) .* max(0, I2 - I1)./(bboxes(sgood, Y2) - bboxes(sgood,Y1));
   Ld = feat_data.predictions(dgood, LEFT) .* double(bboxes(dgood, X1) > bboxes(sgood, X1)) .* max(0, I2 - I1)./(bboxes(dgood, Y2) - bboxes(dgood,Y1));

   Rs = feat_data.predictions(sgood, RIGHT) .* double(bboxes(sgood, X2) < bboxes(dgood, X2)) .* max(0, I2 - I1)./(bboxes(sgood, Y2) - bboxes(sgood,Y1));
   Rd = feat_data.predictions(dgood, RIGHT) .* double(bboxes(dgood, X2) < bboxes(sgood, X2)) .* max(0, I2 - I1)./(bboxes(dgood, Y2) - bboxes(dgood,Y1));

   J1 = max(bboxes(sgood, X1), bboxes(dgood, X1));
   J2 = min(bboxes(sgood, X2), bboxes(dgood, X2));

   Ts = feat_data.predictions(sgood, TOP) .* double(bboxes(sgood, Y1) > bboxes(dgood, Y1)) .* max(0, J2 - J1)./(bboxes(sgood,X2) - bboxes(sgood,X1));
   Td = feat_data.predictions(dgood, TOP) .* double(bboxes(dgood, Y1) > bboxes(sgood, Y1)) .* max(0, J2 - J1)./(bboxes(dgood,X2) - bboxes(dgood,X1));

   Bs = feat_data.predictions(sgood, BOTTOM) .* double(bboxes(sgood, Y2) < bboxes(dgood, Y2)) .* max(0, J2 - J1)./(bboxes(sgood,X2) - bboxes(sgood,X1));
   Bd = feat_data.predictions(dgood, BOTTOM) .* double(bboxes(dgood, Y2) < bboxes(sgood, Y2)) .* max(0, J2 - J1)./(bboxes(dgood,X2) - bboxes(dgood,X1));

   po = 1 ./ (1+exp(-feat_data.predictions(dgood,OBJECT))) .* 1./(1+exp(-feat_data.predictions(dgood, PURE)));

   pair_feats = [feat_data.pair_feats.c_hint(pair_inds), ... 
                 feat_data.pair_feats.t_hint(pair_inds), ...
                 feat_data.pair_feats.bound_max(pair_inds), ...
                 feat_data.pair_feats.bound_sum(pair_inds), ...
                 feat_data.predictions(sgood,OBJECT)-feat_data.predictions(dgood,OBJECT),...
                 Ls + Ld + Rs + Rd, ...
                 Ts + Td + Bs + Bd, ...
                 Ls + Ld + Rs + Rd + Ts + Td + Bs + Bd];
