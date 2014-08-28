function pball = pbCGTG_nonmax(im,radius,norient)
% function [pb,theta] = pbCGTG(im,radius,norient)
% 
% Compute probability of boundary using CG and TG.
%
% David R. Martin <dmartin@eecs.berkeley.edu>
% April 2003
%
% Edited by Derek Hoiem, Jan 2006: reduce radius size for large images,
% do not apply non-maxima suppression, 4 orientations


if nargin<2, radius=[0.01 0.02 0.02 0.02]; end
if nargin<3, norient=4; end % was 8
if numel(radius)==1, radius=radius*ones(1,4); end

% beta from logistic fits (trainCGTG.m)
if all(radius==[0.01 0.02 0.02 0.02]), % 64 textons
  beta = [-4.5015774e+00 6.6845040e-01 1.3588346e-01 1.9537985e-01 5.3922927e-01];
  fstd = [ 1.0000000e+00 3.9505238e-01 1.4210176e-01 1.9449891e-01 1.9178634e-01];
  beta = beta ./ fstd;
else
  error(sprintf('no parameters for radius=[%g %g]\n',radius(1),radius(2)));
end

[imh, imw, unused] = size(im);
radius = norm([320 240]) / norm([imh imw]) * radius; % make radius equivalent to [240 320] case

% get gradients
[cg,tg,gtheta] = detCGTG(im,radius,norient);

% compute oriented pb
[h,w,unused] = size(im);
pball = zeros(h,w,norient);
for i = 1:norient,
  l = cg(:,:,1,i); l = l(:);
  a = cg(:,:,2,i); a = a(:);
  b = cg(:,:,3,i); b = b(:);
  t = tg(:,:,i); t = t(:);
  x = [ones(size(b)) l a b t];
  pbi = 1 ./ (1 + (exp(-x*beta')));
  pball(:,:,i) = reshape(pbi,[h w]);
end

% mask out 1-pixel border where nonmax suppression fails
% pb(1,:) = 0;
% pb(end,:) = 0;
% pb(:,1) = 0;
% pb(:,end) = 0;
