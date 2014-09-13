function [gb_thin_CSG, gb_thin_CS, gb_fat_CS, texton] = simpleGPb(I)

% place the current directory on the top of paths (so rgb2lab in this
% directory will get called when needed)
curr_dir = fileparts(which(mfilename));
rmpath(curr_dir);
addpath(curr_dir);

[gb_thin_CSG, gb_thin_CS, gb_fat_CS] = Gb_CSG(I);
texton = genTexton(I);
gb_thin_CSG = uint8(round(255*gb_thin_CSG));
gb_thin_CS = uint8(round(255*gb_thin_CS));
gb_fat_CS = 255*gb_fat_CS;
texton = uint8(texton);

end