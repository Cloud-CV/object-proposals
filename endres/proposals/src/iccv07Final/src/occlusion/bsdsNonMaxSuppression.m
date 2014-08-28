function pb = bsdsNonMaxSuppression(pbnew, pbold)

if size(pbold)~=size(pbnew)
    pbold = imresize(pbold, size(pbnew), 'nearest');
end
pb = pbnew.*double(pbold>0);


% [h, w] = size(pbnew);
% norient = size(pball, 3);
% theta = (0:norient-1)/norient*pi;
% 
% [h2, w2, tmp] = size(pball);
% if h2~=h || w~=w2
%     pball = imresize(pball, [h w], 'nearest');
% end
% 
% % nonmax suppression and max over orientations
% [unused,maxo] = max(pball,[],3);
% pb = zeros(h,w);
% %theta = zeros(h,w);
% r = 2.5;
% for i = 1:norient,
%   mask = (maxo == i);
%   %a = fitparab(pball(:,:,i),r,r,theta(i));
%   %pbi = nonmax(max(0,a),gtheta(i));
%   pbi = nonmax(pbnew,theta(i));
%   pb = max(pb,pbi.*mask);
% end
% pb = max(0,min(1,pb));
% 
% % mask out 1-pixel border where nonmax suppression fails
% pb(1,:) = 0;
% pb(end,:) = 0;
% pb(:,1) = 0;
% pb(:,end) = 0;
