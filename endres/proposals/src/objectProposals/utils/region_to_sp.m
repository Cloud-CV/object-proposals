function sps = region_to_sp(bndinfo, regions, type, varargin)

% types: max, min, mean, count, nz_count, index(how??)

dim2 = 1;

if(ismember(type, {'max','min','mean','accum'}))
   values = varargin{1};     
   dim2 = size(values,2);

   switch(type)
      case {'min','max'}
         fun = eval(sprintf('@(a,b)%s(a,b)', type));
      case {'mean','accum'}
         fun = @(a,b)(a + b);
   end

   t_mask = zeros(bndinfo.nseg, dim2);

   for i = 1:numel(regions)
      t_mask(regions{i},:) = fun(t_mask(regions{i},:),repmat(values(i,:), numel(regions{i}), 1));
   end
end

if(ismember(type, {'mean', 'count'}))
   count = zeros(bndinfo.imsize);
   t_c = zeros(bndinfo.nseg, 1);

   for i = 1:numel(regions)
      t_c(regions{i}) = 1 + t_c(regions{i});
   end
%   count = t_c(bndinfo.wseg);
end

if(ismember(type, {'min','max','accum'}))
   sps = t_mask;
elseif(ismember(type, {'mean'}))
   sps = t_mask./repmat(t_c, 1, dim2);
elseif(ismember(type, {'count'}))
   sps = t_c;
end

