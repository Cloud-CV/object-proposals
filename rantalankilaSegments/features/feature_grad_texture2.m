function [words, k] = feature_grad_texture2(I, opts)
% Gradient texture feature, that should be the same as van de Sande used in
% 'Segmentation as Selective Search for Object Recognition'.

I = double(I);

k = 8;

xang = cos((pi/k)*(0:k-1));
yang = sin((pi/k)*(0:k-1));


words = zeros(size(I,1)*size(I,2), 2, 3);

% for each color channel
for cchan = 1:3
    dx = I(2:end-1, 3:end, cchan) - I(2:end-1, 1:end-2, cchan); % x column index
    dy = I(3:end, 2:end-1, cchan) - I(1:end-2, 2:end-1, cchan); % y row index
    
    % Gradient magnitude
    m_mid = sqrt(dx.^2 + dy.^2);

    R = zeros(size(I,1)-2, size(I,2)-2, k);
    for i = 1:k
       R(:,:,i) = abs(xang(i)*dx + yang(i)*dy); % calculate score for each angle
    end
    
    [~, directions_mid] = max(R,[],3); % pick the directions with maximum score (categorize directions into bins)
    
    % Add one pixel zero padding to m and directions
    m = zeros(size(I,1), size(I,2));
    m(2:end - 1, 2:end - 1) = m_mid;
    
    directions = zeros(size(I,1), size(I,2));
    directions(2:end - 1, 2:end - 1) = directions_mid + k*(cchan-1);
    
    % Something like this can be used to verify correct indexing - original image can be seen in the image
    %image(directions*4)
    
    words(:,:,cchan) = [directions(:), m(:)];  
end

words = [words(:,:,1); words(:,:,2); words(:,:,3)];






    