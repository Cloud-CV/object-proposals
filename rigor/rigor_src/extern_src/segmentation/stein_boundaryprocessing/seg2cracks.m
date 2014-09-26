function [crack_img] = seg2cracks(seg)
%
% [crack_img] = seg2cracks(seg)
% 
%  Converts a segmentation image into a crack-coded image.
%

% Bits:
%       |
%       | 1
% 4 ----+---- 2
%       | 
%       | 3

% Values:
% tic
UP    = 1;
RIGHT = 2;
DOWN  = 3;
LEFT  = 4;

JUNCTION = 5;

% dx = uint8(seg ~= image_right(seg));
% dy = uint8(seg ~= image_down(seg) );
% crack_img = dx + bitshift(dy,LEFT-1) + ...
%     bitshift(image_right(dy),RIGHT-1) + bitshift(image_down(dx),DOWN-1);

% Removed dependency on image_down and image_right, to make this more
% easily packaged:
dx = uint8(seg ~= seg(:,[2:end end]));
dy = uint8(seg ~= seg([2:end end],:));
crack_img = dx + bitshift(dy,LEFT-1) + ...
    bitshift(dy(:,[2:end end]),RIGHT-1) + bitshift(dx([2:end end],:),DOWN-1);

% Find interior junctions:
junction_map = (crack_img==11 | crack_img==7 | crack_img==14 | ...
    crack_img==13 | crack_img==15);

% Find the junctions along the borders:
junction_map([1 end],:) = junction_map([1 end],:) | bitget(crack_img([1 end],:),UP);
junction_map(:,[1 end]) = junction_map(:,[1 end]) | bitget(crack_img(:,[1 end]),LEFT);

% set the junction bit for all these junctions in the crack_img
crack_img(junction_map) = bitset(crack_img(junction_map), JUNCTION);
   

% % Also set all borders of the image to be seen as junctions (all bits set
% % == a value of 15) so that we will know to stop in the fragment chaining 
% % process later
% crack_img(:,[1 end]) = 15;
% crack_img([1 end],:) = 15;

% fprintf('New method: %.3f seconds\n', toc);
% 
% %% Old Method %%
% tic
% [nrows, ncols ] = size(seg);
% crack_img2 = zeros(nrows, ncols, 'uint8');
% % Bits:
% UP    = 1;
% RIGHT = 2;
% DOWN  = 3;
% LEFT  = 4;
% 
% index = find(seg ~= image_right(seg));
% crack_img2(index) = bitset(crack_img2(index), UP);
% 
% index = find(image_right(seg) ~= image_downright(seg));
% crack_img2(index) = bitset(crack_img2(index), RIGHT);
% 
% index = find(image_down(seg) ~= image_downright(seg));
% crack_img2(index) = bitset(crack_img2(index), DOWN);
% 
% index = find(seg ~= image_down(seg));
% crack_img2(index) = bitset(crack_img2(index), LEFT);
% 
% fprintf('Old method: %.3f seconds\n', toc);
% 
% if(all(crack_img(:)==crack_img2(:)))
%     disp('Results agree.')
% end
% 
