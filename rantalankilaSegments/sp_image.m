function Ic = sp_image(Ic, gt_mask, sp, item1, item2)
% Colors superpixel regions in an image 'Ic' for visualization. 'item1' and 'item2' are sp
% index vectors. Colors are defined manually below. 'gt_mask' is
% optional, supply an empty matrix to ignore it.
    
Ip = reshape(Ic, size(Ic,1)*size(Ic,2), 3); % reshape 2 dim pixel grid into one dimensional vector

% Pixelwise coloring
if ~isempty(gt_mask)
    Ip(gt_mask(:),1) = 225;
    Ip(gt_mask(:),2) = 225;
    Ip(gt_mask(:),3) = 0;
end

% Color 1
for u = item1
    if sp{u}.size == 0
        continue
    end
    x = double(sp{u}.pixels(:,1));
    y = double(sp{u}.pixels(:,2));
    mask = logical(full(sparse(x,y,ones(size(x,1),1), size(Ic,1),size(Ic,2))));
    Ip(mask(:),1) = 0.15*Ip(mask(:),1);
    Ip(mask(:),2) = 0.15*Ip(mask(:),2);
    Ip(mask(:),3) = 0.15*Ip(mask(:),3);
end

% Color 2
for u = item2
    if sp{u}.size == 0
        continue
    end
    x = double(sp{u}.pixels(:,1));
    y = double(sp{u}.pixels(:,2));
    mask = logical(full(sparse(x,y,ones(size(x,1),1), size(Ic,1),size(Ic,2))));
    Ip(mask(:),1) = Ip(mask(:),1);
    Ip(mask(:),2) = 0.2*Ip(mask(:),2);
    Ip(mask(:),3) = 0.2*Ip(mask(:),3);
end

Ic = reshape(Ip,size(Ic,1),size(Ic,2),3);
Ic = uint8(Ic);
Ic = imresize(Ic, 0.5); % reduce pixel amount to 1/4 to save space
