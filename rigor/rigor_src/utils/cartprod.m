% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function [xy_i, xy_j] = cartprod(xgv, ygv)
%  [xy_i xy_j] = cartprod_mex(xgv, ygv);
    [temp2, temp1] = meshgrid(ygv, xgv);
    xy_i = temp1(:);
    xy_j = temp2(:);
end

