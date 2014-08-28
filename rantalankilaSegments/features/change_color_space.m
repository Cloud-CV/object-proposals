function [sp_new, scores_new] = change_color_space(color_space, I_rgb, sp, K, im_num, h, w, sph, opts)
% Updates the histograms in the 'sp' variable by recalculating them using
% image transformed into another color space, and color space -specific
% features. This function is not used with default settings.

scores_new = [];

switch color_space
    case 'nrgb'
        I_nrgb = uint8(rgb_to_nrgb(I_rgb));
        [words, k] = compute_features(I_nrgb, I_rgb, 'nrgb', opts, im_num);
        sp_new = compute_histograms(sp, words, k, h, w);
        scores_new = similarity_scores(sp_new, K, opts, 0, sph);
    case 'opp'
        I_opp = uint8(rgb_to_opp(I_rgb));
        [words, k] = compute_features(I_opp, I_rgb, 'opp', opts, im_num);
        sp_new = compute_histograms(sp, words, k, h, w);
        scores_new = similarity_scores(sp_new, K, opts, 0, sph);
    case 'hsv'
        I_hsv = uint8(rgb_to_hsv(I_rgb));
        [words, k] = compute_features(I_hsv, I_rgb, 'hsv', opts, im_num);
        sp_new = compute_histograms(sp, words, k, h, w);
        scores_new = similarity_scores(sp_new, K, opts, 0, sph);
    otherwise
        error('bad image type argument')
        
end





