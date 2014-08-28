function [feat, b] = contactdata2features(data, v0, y0)

for k = 1:numel(data)
    np = numel(data(k).z3d);
    data(k).feat = zeros(np, 12);
    
    valid = (data(k).foot(2)~=data(k).foot(1)); %&& (numel(data(k).z3d)>=10);
    data(k).isvalid = repmat(valid, [np 1]);
    
    if data(k).isvalid(1)
        u = data(k).u;
        v = data(k).v;
        x = data(k).x3d;
        z = data(k).z3d;       
        
        w3d = data(k).foot(2)-data(k).foot(1);
        mind = data(k).foot(3);
        
        data(k).feat(:, 1) = (z-mind) ./ w3d;
        data(k).feat(:, 2) = (v-min(v)) ./ (max(v)-min(v));
        data(k).feat(:, 3) = (u-min(u)) ./ (max(u)-min(u));

        data(k).feat(1, 4) = (min(z(2), z(end)) - z(1))/w3d;
        data(k).feat(2:end-1, 4) = (min(z(1:end-2), z(3:end)) - z(2:end-1))/w3d;        
        data(k).feat(end, 4) = (min(z(1), z(end-1)) - z(end))/w3d;
        
        data(k).feat(1, 5) = (max(z(2), z(end)) - z(1))/w3d;
        data(k).feat(2:end-1, 5) = (max(z(1:end-2), z(3:end)) - z(2:end-1))/w3d; 
        data(k).feat(end, 5) = (max(z(1), z(end-1)) - z(end))/w3d;
        
        data(k).feat(1, 6) = (z(end)-z(1)) ./ abs(x(end)-x(1)+eps);
        data(k).feat(2:end, 6) = (z(2:end)-z(1:end-1)) ./ abs(x(2:end)-x(1:end-1)+eps);
        %data(k).feat(:, 6) = abs(data(k).feat(:, 5));
        data(k).feat(1:end-1, 7) = (z(2:end)-z(1:end-1)) ./ abs(x(2:end)-x(1:end-1)+eps);                        
        data(k).feat(end, 7) = (z(end)-z(1)) ./ abs(x(end)-x(1)+eps);
        %data(k).feat(:, 7) = abs(data(k).feat(:, 6));
        data(k).feat(1, 8) = (v(end)-v(1)) ./ (u(end)-u(1)+eps);
        data(k).feat(2:end, 8) = (v(2:end)-v(1:end-1)) ./ (u(2:end)-u(1:end-1)+eps);
        data(k).feat(1:end-1, 9) = (v(2:end)-v(1:end-1)) ./ (u(2:end)-u(1:end-1)+eps);
        data(k).feat(end, 9) = (v(end)-v(1)) ./ (u(end)-u(1)+eps);

        data(k).feat(1, 10) = atan((v(end)-v(1))./(u(end)-u(1)+eps)) - ...
            atan((v(2)-v(1))./(u(2)-u(1)+eps));
        data(k).feat(2:end-1, 10) = atan((v(3:end)-v(2:end-1))./(u(3:end)-u(2:end-1)+eps)) - ...
            atan((v(1:end-2)-v(2:end-1))./(u(1:end-2)-u(2:end-1)+eps));
        data(k).feat(end, 10) = atan((v(end)-v(1))./(u(end)-u(1)+eps)) - ...
            atan((v(end-1)-v(end))./(u(end-1)-u(end)+eps)); 
        
        ind = convhull(u, v);
        for j = 1:numel(u)
            [tmpval, tmpind] = min(sqrt((u(j)-u(ind)).^2) + (v(j)>v(ind))*100000);
            tmpind = ind(tmpind);
            data(k).feat(j, 11) = -(v(j)-v(tmpind))/(max(v)-min(v));
            %min(sqrt((u(j)-u(ind)).^2 + (v(j)-v(ind)).^2) + (v(j)<v(ind))*10000)/(max(v)-min(v));
        end
        
        data(k).feat(:, 12) = numel(u);
        
%         data(k).feat(2:end-1, 10) = (max(u(1:end-2), u(3:end)) - u(2:end-1))/(max(u)-min(u));
%         data(k).feat(1, 10) = (u(2)-u(1))/(max(u)-min(u));
%         data(k).feat(end, 10) = (u(end-1)-u(end))/(max(u)-min(u));         
    end
end
feat = cat(1, data(:).feat);
isvalid = cat(1, data(:).isvalid);

feat = feat(isvalid, :);

if nargout>1
    b = cat(1, data(:).b);
    b = b(isvalid);
end    

ind = isinf(feat(:));
feat(ind) = 10000;
        
        