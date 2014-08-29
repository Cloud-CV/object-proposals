function [superpixelLabels]=mvg_computeSuperpixels(img)

%% Compute Felzenswalb superpixels
superPix=computeSuperpixels_(img);

%% Numerize labels
superpixelLabels=numerizeSuperpixLabels_(superPix);

%% Ensure double format
superpixelLabels=double(superpixelLabels);



%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Additional functions %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Compute Felzenswalb superpixels %%%
function [superPix]=computeSuperpixels_(img)

% Initialize parameters
basis_sigma = 0.5;
basis_k = 450;
basis_min_area = 200;

Iarea = size(img,1)*size(img,2);
sf = sqrt(Iarea/(300*200));

sigma = basis_sigma*sf;
min_area = basis_min_area*sf;
k = basis_k;

% Run segmentation algorithm
superPix=mvg_FelzenswalbSuperpixelWrapper(img,sigma,min_area,k);


%%% Numerize superpixel labels %%%
function N = numerizeSuperpixLabels_(S)

% converts the segmentation image S from true-color
% to ordered integer labels
%

N = zeros(size(S,1),size(S,2),'uint16');
col2n = zeros(256,256,256);
totcol = 0;
for x = 1:size(S,2)
    for y = 1:size(S,1)
        p = reshape(S(y,x,:),1,3)+1;
        cix = col2n(p(1),p(2),p(3));
        if cix > 0
          N(y,x) = cix;
        else
          totcol = totcol+1;
          col2n(p(1),p(2),p(3)) = totcol;
          N(y,x) = totcol;
        end
    end
end

% MVG version (faster)
% S=double(S);
% temp=S(:,:,1)+S(:,:,2)*256+S(:,:,3)*256^2;
% lbl=unique(temp(:));
% %lblCode=[lbl,(1:length(lbl))'];
% N=zeros(size(S,1),size(S,2),'uint16');
% for i=1:length(lbl)
%     N(temp==lbl(i))=i;
% end
