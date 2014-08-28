function featvec = MRS4fast(im)

[featvec] = MR8fast(im);
featvec = featvec';

featvec = cat(2, featvec(:, 1:2), max(featvec(:, 3:5), [], 2), max(featvec(:, 6:8), [], 2));
