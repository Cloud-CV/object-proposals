function pobjs = APPfitGroundHough(x,y, imsize)
% pobjs = APPfitGroundHough(x,y, imsize)
% Fits the ground-vertical boundary with a set of polylines
%
% Input:
%   x, y: the x and y positions of ground-vertical boundaries
%   imsize: the image size
% Output:
%   pobjs(nplanes, [m b x1 x2 maxy disconnect])
%
% Copyright(C) Derek Hoiem, Carnegie Mellon University, 2005
% Permission granted to non-commercial enterprises for
% modification/redistribution under GNU GPL.  
% Current Version: 1.0  09/30/2005

MAKE_PLOTS = 0; % whether to make displays

[x, inds] =  sort(x);
y = y(inds);

height = imsize(1);
width = imsize(2);
y = height-round(y*(height-1));
x = round(x*(width-1)+1);
%figure(1), hold off, plot(x, y, '.b'), axis equal, hold on

ty =y;
tx =x;
minpts = sqrt(width^2+height^2)/20;
distt = sqrt(width^2+height^2)/100;
mingapt = sqrt(width^2+height^2)/20;
count = 0;

pobjs = {};

% find initial line segments
while length(tx)>minpts        

    % get the hough transform image for the points (tx, ty)
    gim = zeros(imsize);
    inds = round(ty+(tx-1)*height);
    gim(inds) = 1;
    gim = conv2(gim, fspecial('gaussian', 5, 1), 'same');
    theta = [0:179];
    [R, xp] = radon(gim, theta);
    theta = theta';
    
    % get the best line from the hough transform image 
    [maxval, ind] = max(R(:));    

    % get line parameters (ax + by = c)
    [rind,thind] = ind2sub(size(R),ind);
    t = -theta(thind)*pi/180;
    r = xp(rind); 
    lines = [cos(t) sin(t) -r];
    cx = width/2-1;
    cy = height/2-1;
    lines(:,3) = lines(:,3) - lines(:,1)*cx - lines(:,2)*cy;  
    a = lines(1, 1);
    b2 = lines(1, 2);
    c = lines(1, 3);

    % get line parameters in y = mx+b form
    m = -lines(:, 1)/lines(:, 2);
    b = -lines(:, 3)/lines(:, 2);         

    % get the distance of each point from the line
    pdst = abs(a*tx+b2*ty+c)/sqrt(a^2+b2^2);
    inds = find(pdst < distt);

    % while there is a big gap take only the larger side of the gap
    sortx = sort(tx(inds));
    gapt = max((sortx(end)-sortx(1))/5, mingapt);        
    endpoints(count+1, 1:2) = [sortx(1)  sortx(end)];
    %disp(['initlength: ' num2str(length(inds))]) 
    %disp(['gapt: ' num2str(gapt)])
    while (max(abs(sortx(1:end-1)-sortx(2:end))) > gapt)
        [maxval, maxind] = max(abs(sortx(1:end-1)-sortx(2:end)));
        if maxind > length(inds)/2
            inds = inds(1:maxind);
        else
            inds = inds((maxind+1):end);
        end
        sortx = sort(tx(inds));
        endpoints(count+1, 1:2) = [sortx(1)  sortx(end)];
        gapt = max((sortx(end)-sortx(1))/5, mingapt); 
        %disp(['gapt: ' num2str(gapt)])
    end        
    
    %disp(['length: ' num2str(length(inds))])    
    % check that best line has enough points 
    if length(inds) < minpts
        break;
    end    
    
    count = count + 1;
    
    % plot the lines and points on each line
    if MAKE_PLOTS
        figure(1)
        color_chars = ['y'];
        ab = axis; 
        col = color_chars(mod(count-1, length(color_chars))+1);
        if abs(m)<1
             %px = [ab(1:2)];
             px = endpoints(count, 1:2);
             plot(px, height-(m*px+b)+1, ['-' col], 'LineWidth', 5);
        else
             py = ab(3:4);
             plot((height-(py-b)+1)/m,  height-py+1,  ['-' col], 'LineWidth', 5);
        end
        %plot(tx(inds), height-ty(inds)+1, ['.' col])
        drawnow;
        pause(1)
    end            

   
    
    % add assigned points to x and y
    % remove assigned points from tx and ty
    tx(inds) = [];
    ty(inds) = [];

    % store current line
    pobjs{count}(1, :) = [m b 0 0 a b2 c];

end
	
count = length(pobjs);

if ~isempty(pobjs)

    px = cell(count, 1);
    py = cell(count, 1);
    pmedx = zeros(count, 1);
    pmedy = zeros(count, 1);
    oldpinds = cell(count, 1);


    % reassign points to each object and re-estimate lines
    distt2 = distt;
    changed = 1;
    while changed
        changed = 0;
        pdsts = zeros(length(x), count);
        for p1 = 1:length(pobjs)
            a = pobjs{p1}(5);
            b = pobjs{p1}(6);
            c = pobjs{p1}(7);
            pdsts(:, p1) = abs(a*x+b*y+c)/sqrt(a^2+b^2);
            %pobjs{p1}(6:7) = [];
        end
        [mdists, inds] = min(pdsts, [], 2);
        inds2 = find(mdists<=distt2);
        for p1 = 1:length(pobjs)
            pinds = inds2(find(inds(inds2)==p1));
            pinds = pinds(find( (x(pinds)>=(endpoints(p1, 1)-mingapt)) & ...
                (x(pinds)<=(endpoints(p1, 2)+mingapt))));
            if length(setdiff(pinds, oldpinds{p1}))>2
                changed = 1;
                %disp('changed')
                oldpinds{p1} = pinds;
            end
            px{p1} = x(pinds);
            py{p1} = y(pinds);

            if length(pinds) > 0
                endpoints(p1, 1) = min(px{p1});
                endpoints(p1, 2) = max(px{p1});
                

                % re-estimate line params
                p = polyfit(px{p1},py{p1},1);
                pobjs{p1}(1:2) = p;

                pm = p(1);
                pb = p(2);

                a = 1;
                b = -1/pm;
                c = pb/pm;        
                pobjs{p1}(5:7) = [a b c];       

                pmedx(p1) = median(px{p1});    
                pmedy(p1) = median(py{p1});                 
                
            else
                endpoints(p1, 1:2) = 0;
                px{p1} = [];
                py{p1} = [];
            end

        end
    end

    % remove smaller of overlapping segments
    reminds = [];
    for p1 = 1:length(pobjs)
        for p2 = (p1+1):length(pobjs)
            if (endpoints(p1, 1)-endpoints(p2, 1))*...
                    (endpoints(p1, 2)-endpoints(p2, 2)) < 0
                if MAKE_PLOTS, disp('removing overlapping segment'), end;
                if length(px{p1}) < length(px{p2})
                    reminds(end+1) = p1;
                else
                    reminds(end+1) = p2;
                end
            end
        end
        if isempty(px{p1})
            if MAKE_PLOTS, disp('removing empty segment'), end;
            reminds = union(reminds, p1);
        end
    end
    [pobjs, pmedx, pmedy, px, py] = removeIndices(reminds, pobjs, pmedx, pmedy, px, py);
    endpoints(reminds, :) = [];
    

    if MAKE_PLOTS
        figure(2)
        disp(length(pobjs))
        for p1 = 1:length(pobjs)
            color_chars = ['r' 'y' 'g' 'c' 'k'];
            ab = axis; 
            col = color_chars(mod(p1-1, length(color_chars))+1);
            m = pobjs{p1}(1);
            b = pobjs{p1}(2);
            if abs(m)<1
                 tpx = [ab(1:2)];
                 plot(tpx, height-(m*tpx+b)+1, ['-' col], 'LineWidth', 3);
            else
                 tpy = ab(3:4);
                 plot((height-(tpy-b)+1)/m,  height-tpy+1,  ['-' col], 'LineWidth', 3);
            end
            plot(px{p1}, height-py{p1}+1, ['.' col])
            %plot(pmedx(p1), height-pmedy(p1)+1, '+k');
        end
        drawnow;
        pause(5)
    end

    count = length(pobjs);
    
    if length(pobjs) > 0
    
    
    % determine which objects should be merged 
    domerge = zeros(count, count);
    intersectx = zeros(count, count);
    for p1 = 1:length(pobjs)
        for p2 = (p1+1):length(pobjs)
            % if slopes are not same
            if pobjs{p1}(1) ~= pobjs{p2}(1)
                xi = (pobjs{p2}(2)-pobjs{p1}(2))/(pobjs{p1}(1)-pobjs{p2}(1));
                yi = xi*pobjs{p1}(1) + pobjs{p1}(2);
                %plot(xi, height-yi+1, '*k')
                % if med x's appear on opposite sides of intersection 
                if (sign(pmedx(p1)-xi)~=sign(pmedx(p2)-xi))
                    domerge(p1, p2) = 1;
                    domerge(p2, p1) = 1;
                    intersectx(p1, p2) = xi;
                    intersectx(p2, p1) = xi;
                end
            end
        end
    end
    intersectx = round(intersectx);
    if MAKE_PLOTS, disp(['num merges: ' num2str(sum(domerge(:))/2)]), end;

    % merge objects that should be merged
    reminds = [];
    for p1 = 1:length(pobjs)
        mergeinds = find(domerge(p1, :));
        if ~isempty(mergeinds)
            domerge(p1, mergeinds) = 0;
            domerge(mergeinds, p1) = 0;
            oldlength = 0;
            while length(mergeinds)~=oldlength
                oldlength = length(mergeinds);
                for p2 = mergeinds
                    mergeinds = union(mergeinds, find(domerge(p2, :)));
                    domerge(p2, mergeinds) = 0;
                    domerge(mergeinds, p2) = 0;
                end
            end      
            mergeinds = union(mergeinds, p1);
                       
            [tmp, sind] = sort(pmedx(mergeinds));

            % sort mergeinds by their x-medians
            mergeinds = mergeinds(sind);    
            tpx = [];
            tpy = [];
            tobj = [];
            for i = 1:length(mergeinds)

                % if (i) and (i-1) should merge or or (i == 1)
                if (i == 1 || intersectx(mergeinds(i), mergeinds(i-1))~=0)                    
                        
                    if MAKE_PLOTS, disp(['merge: ' num2str(i)]), end;
                    tobj(end+1, :) = pobjs{mergeinds(i)};

                    % set endpoints to intersection points
                    if size(tobj, 1) > 1
                        
                        tobj(end-1, 4) = intersectx(mergeinds(i), mergeinds(i-1));
                        tobj(end, 3) = tobj(end-1, 4);
                                                                   
                    end        

                    % add points from (i) to merged segment
                    tpx = [tpx ; px{mergeinds(i)}];
                    tpy = [tpy ; py{mergeinds(i)}];
                else
                    % effectively remove (i) from merginds
                    mergeinds(i) = mergeinds(i-1);
                end
            end
            pobjs{p1} = tobj;
            [px{p1}, inds] = sort(tpx);
            py{p1} = tpy(inds);
            mergeinds = setdiff(mergeinds, p1);    

            % set indices to remove
            reminds = [reminds(:) ; mergeinds(:)];      
        end
    end
    % remove merged segments
    [pobjs, px, py, pmedx, pmedy] = removeIndices(reminds, pobjs, px, py, pmedx, pmedy);
    endpoints(reminds, :) = [];

    % set endpoints (that were not found by merging)
    for i = 1:length(pobjs) 
        for j = 1:size(pobjs{i}, 1)
            if pobjs{i}(j, 3) == 0
                pobjs{i}(j, 3) = min(px{i});
            end    
            if pobjs{i}(j, 4) == 0
                pobjs{i}(j, 4) = max(px{i});
            end
        end
    end

    % find overlapping segments and resolve
    reminds = [];
    for p1 = 1:length(pobjs)
        for p2 = p1+1:length(pobjs)
            if isempty(intersect(reminds, [p1 p2]))
                overx1 = max([px{p1}(1) px{p2}(1)]);
                overx2 = min([px{p1}(end) px{p2}(end)]);
                if (overx2 > overx1) % then p1 and p2 overlap

                    if MAKE_PLOTS, disp('warning: removing segment'), end;                
                    if length(px{p1}) > length(px{p2})                                  
                        reminds(end+1) = p2;              
                    else
                        reminds(end+1) = p1;
                    end

                end
            end
        end
    end

    [pobjs, px, py, pmedx, pmedy] = removeIndices(reminds, pobjs, px, py, pmedx, pmedy);

    % make sure all ground points belong to one segment
    xstart = zeros(length(pobjs), 1);
    xend = zeros(length(pobjs), 1);
    for p1 = 1:length(pobjs)
        xstart(p1) = pobjs{p1}(1, 3);
        xend(p1) = pobjs{p1}(end, 4);
    end
    [xstart, ind] = sort(xstart);
    xend = xend(ind);
    pobjs = pobjs(ind);
    if xstart(1) ~= x(1)
        pobjs{1}(1, 3) = x(1);    
    end
    for p1 = 1:length(xstart)-1
        if xend(p1)<xstart(p1+1)
            if pmedy(p1) > pmedy(p1+1) % p1 lower than than p2
                pobjs{p1}(end, 4) = xstart(p1+1)-1;
            else
                pobjs{p1+1}(1, 3) = xend(p1)+1;
            end
        end
    end
    [xend, ind] = sort(xend);
    if xend(end) ~= x(end)
        pobjs{ind(end)}(end, 4) = x(end);
    end
    
    end % if at least one object
    
end

if isempty(pobjs)
    
    reminds = [];
    for i =2:length(x)
        if x(i) == x(i-1)
            reminds(end+1) = i;
        end
    end
    x(reminds) = [];
    y(reminds) = [];
    pobjs{1} = piecewise_linear_spline(x, y, 3);
    pobjs{1}(:, 5) = 0;    
end


% reverse height
for i = 1:length(pobjs)
    ind = find(pobjs{i}(:, 5)~=0);
    pobjs{i}(ind, 5) = height - pobjs{i}(ind, 5) + 1;
    pobjs{i}(:, 1) = -pobjs{i}(:, 1);
    pobjs{i}(:, 2) = height- pobjs{i}(:, 2)+1;
end

%figure(1) %, hold off, 
%hold on, plot(oldx, height-oldy+1, '.k');
if MAKE_PLOTS
    figure(3)
    color_chars = ['r' 'g' 'c' 'b' 'm'];
    count = 0;
    for p = 1:length(pobjs)
        rc = mod(p-1, 5)+1;
        for j = 1:size(pobjs{p}, 1)
            count = count + 1;
            m = pobjs{p}(j, 1);
            b = pobjs{p}(j, 2);
            ppx = pobjs{p}(j, 3:4);
            plot(ppx, ppx*m+b, ['-' color_chars(rc)], 'LineWidth', 5);
            if j > 1
                plot([ppx(1) ppx(1)], [ppx(1)*m+b ppx(1)*m+b-50], ...
                    ['-' color_chars(rc)], 'LineWidth', 5);
            end
        end
    end
    drawnow;
end


tp = pobjs;
pobjs = zeros(0, 6);
for i = 1:length(tp)
    for j = 1:size(tp{i},1)  
        pobjs(end+1, 1:5) = tp{i}(j, 1:5);       
    end
    pobjs(end, 6) = 1;
end

pobjs(:, 1) = pobjs(:, 1)*(width-1)/(height-1);
pobjs(:, 2) = (pobjs(:, 2)-1)/(height-1);
pobjs(:, 3:4) = (pobjs(:, 3:4)-1)/(width-1);
pobjs(:, 5) = (pobjs(:, 5)-1)/(height-1);       


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = removeIndices(indices, varargin)

for i = 1:length(varargin)
    varargout(i) = varargin(i);
    varargout{i}(indices) = [];
end

