function sp = compute_histograms(sp, words, k, h, w)
% Computes pixel-wise feature histograms for each superpixel.
% Inputs:
%   'sp' the superpixel graph
%   'words' cell array of image-sized [h,w] feature matrices, each pixel
%       value denoting the bin to which it belongs. Bin 0 means no-value.
%   'k' the number of bins in each feature matrix

features_num = length(words);

if features_num == 0 % no features, nothing to do
    return
end

for i = 1:length(sp)
    if size(sp{i}.pixels,1) == 0
        continue % skip empty superpixels
    end
    pix = double(sp{i}.pixels); % using double() here is important. Otherwise sub2ind below caps variable s at 65536, causing integer overflows.
    s = sub2ind([h,w], pix(:,1), pix(:,2)); % linear indices of pixels of current superpixel in the image
    % sub2ind gives indices corresponding to words = words(:); method used
    % for features above.
    
    % Make histograms of the feature matrices
    for fn = 1:features_num
        if size(words{fn},2) == 2 % weighted histogram
            if size(words{fn},1) == 3*h*w % the gradient feature returns feature matrix for each of 3 channels
                sp{i}.hist{fn} = vl_whistc([words{fn}(s,1);words{fn}(s+h*w,1);words{fn}(s+2*h*w,1)], [words{fn}(s,2);words{fn}(s+h*w,2);words{fn}(s+2*h*w,2)], 1:3*k(fn));
            else
                sp{i}.hist{fn} = vl_whistc(words{fn}(s,1), words{fn}(s,2), 1:k(fn));
            end
        else % simple histogram
            sp{i}.hist{fn} = histc(words{fn}(s), 1:k(fn)); % this seems to break for superpixels having size of one pixel, because they do not get transposed like other superpixels at some point(?)
        end
        
        N = sum(sp{i}.hist{fn});
        if N > 0
            sp{i}.hist{fn} = sp{i}.hist{fn}/N; % normalize the histograms
        else
            % If the superpixel is located in the edge, it may not contain
            % any sift descriptors. In this case the histogram is a vector
            % of zeros.
            %fprintf('empty histogram %d %d\n',fn, i)
        end
    end
end