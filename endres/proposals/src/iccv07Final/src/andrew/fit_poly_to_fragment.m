function [curve, params, errors] = fit_poly_to_fragment(fragment, order)
%
%[curve, params, errors] = fit_poly_to_fragment(fragment, order)
% 
% Fit a polynomial curve of specified order to an edge fragment.  A
% fragment is simply an Nx2 vector of (x,y) coordinates.
%
% Can also return fit error and the polynomial parameters.
%

% Ensure there are enough points:
if(isempty(fragment))
    error('Supplied fragment contains no points!');
end

N = size(fragment,1);

% Reduce the order if not enough points are provided to fit the requested
% order polynomial (e.g. we need N=4 points to fit a cubic, if only N=3 
% points are provided, this will reduce the order to 2, thereby enabling
% successful fitting of a quadratic)
while( N < (order+1) )
    order = order-1;
end
    
t = linspace(0,1,N)';

fit_normals = false;
% if(nargin==2)
%     order = normal_angles;
%     fit_normals = false;
% end

T = ones(N,1);
for(i_order = 1:order)
    T = [t.^i_order T];
end
    
if(~fit_normals)
    % Fit the polynomial so that it simply tries to pass through the
    % fragment's vertex coordinates.
    params = T \ fragment;
    
%     % Constrained least squares to get the start and end points to exactly
%     % match up to the input coordinates:
%     for(i=1:2)
%         params(:,i) = lsqlin(T(2:end-1,:), fragment(2:end-1,i), ...
%             T([1 end],:), fragment([1 end],i),T([1 end],:), fragment([1 end],i));
%     end
else
    error(['Um, actually, trying to constrain the slopes this way will NOT ' ...
           'work. It is not linear because we do not know the length of the ' ...
           'normal vectors, only the direction.']);
       
%     params = T \ fragment;
%     L = L_helper(params, t, order);
%     
%     % Fit the polynomial so that it tries to pass through the coordinates of the
%     % input fragment AND tries to have slope matching the orientations of
%     % each vertex in the fragment. 
%     T_orient = [ones(N,1) zeros(N,1)];
%     for(i_order = 1:(order-1))
%         T_orient = [(i_order+1)*t.^i_order T_orient];
%     end
%     
%     for(i=1:100)
%         TT = [blkdiag(T,T); blkdiag(-T_orient, T_orient)];
%         
%         params = TT \ [fragment(:); L.*sin(normal_angles); L.*cos(normal_angles)];
%         params = reshape(params, [order+1 2]);
%         
%         L = L_helper(params, t, order);
%     end
    
    
end

curve = T*params;
if(nargout>=3)
    errors = abs(curve - fragment);
end

return;



function L = L_helper(params, t, order)

dx = params(end-1,1);
dy = params(end-1,2);
for(i_order = 2:order)
    dx = dx + i_order*params(end-i_order,1)*t.^(i_order-1);
    dy = dy + i_order*params(end-i_order,2)*t.^(i_order-1);
end

L = sqrt(dx.^2 + dy.^2);
return;