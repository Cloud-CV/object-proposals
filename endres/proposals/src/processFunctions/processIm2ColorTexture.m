function [textonim, colorim] = processIm2ColorTexture(im, varargin)

%% Set parameters

colorNodes = varargin{1};
textonNodes = varargin{2};

%% Classify surfaces

textonim = uint16(getTextonImage(im, textonNodes));

if(size(im,3)==3)
   colorim = uint16(getColorImage(im, colorNodes));
else
   colorim = [];
end
