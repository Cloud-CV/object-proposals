function scores = scores_against_sp_group(sp, in_list, out_list, opts)
% Temporarily combines sp listed by in_list as a single sp. Then returns
% score of every out_list sp against this special sp.

if isempty(in_list)
    error('You need to give non-empty list of sp indices to combine.');
end

sp_amount = length(sp);

% create the special background sp
in_sp = [];
in_sp.size = 0;
for l = in_list % add all 'in_list' superpixels
    in_sp.size = in_sp.size + sp{l}.size;
end
in_sp.hist = merge_histograms(sp, in_list);

sp{sp_amount+1} = in_sp; % add the special superpixel into the 'sp' variable

K_all = [(sp_amount+1)*ones(length(out_list),1),out_list'];
scores = similarity_scores(sp, K_all, opts); % get scores of inside sp against the special sp
sp(sp_amount+1) = []; % delete the special sp. Not required as 'sp' is not returned by this function
