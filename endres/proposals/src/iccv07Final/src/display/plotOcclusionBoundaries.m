function plotOcclusionBoundaries(bndinfo, blabels)
% im = drawOcclusionBoundaries(im, bndinfo, blabels)
% blabels(i) = (0, 1, or 2) for off, left, or right
%

if numel(blabels)==bndinfo.ne*2
    blabels = blabels(1:end/2) + 2*blabels(end/2+1:end);
end

hold on
imsize = bndinfo.imsize;

color = [0.01 0.01 0.01];

indices = bndinfo.edges.indices;

arrowdist = ceil(sqrt(imsize(1).^2 + imsize(2).^2)/10);

for k = 1:numel(indices)
    
    if blabels(k)>0
    
        ind = double(indices{k});
        [ey, ex] = ind2sub(bndinfo.imsize(1:2), ind);
        npix = numel(ind);

        narrows = ceil(npix/arrowdist);

        epos = ceil((1:narrows) / (narrows+1) * npix);

        for j = 1:numel(epos)

            [ay, ax] = ind2sub(imsize(1:2), ind(epos(j)));


            if blabels(k)==1
                [y1, x1] = ind2sub(imsize(1:2), ind(max(epos(j)-10,1)));
                [y2, x2] = ind2sub(imsize(1:2), ind(min(epos(j),npix)));
            else % blabels(k)==2;
                [y1, x1] = ind2sub(imsize(1:2), ind(min(epos(j)+10,npix)));
                [y2, x2] = ind2sub(imsize(1:2), ind(min(epos(j),npix)));
            end
            theta = atan2(y2-y1, x2-x1);
%             if blabels(k)==2
%                 theta = mod(theta+pi, 2*pi);
%             end

            asx = ax - cos(theta);
            asy = ay - sin(theta);

            %[ax,ay] = dsxy2figxy(gca, ax, ay);
            %[asx, asy] = dsxy2figxy(gca, asx, asy);
            ax = (ax-1)/(imsize(2)-1);   ay = 1-(ay-1)/(imsize(1)-1);           
            asx = (asx-1)/(imsize(2)-1);   asy = 1-(asy-1)/(imsize(1)-1);
            
            plot(ex, ey, 'Color', 1-color, 'LineWidth', 3);
            plot(ex, ey, 'Color', color, 'LineWidth', 1);
            
            annotation('arrow', [asx ax], [asy ay], 'LineStyle', 'none', ...
                'HeadWidth', 17, 'HeadLength', 10);
        end
    end
end


% arrhsv = ones(5, 3);
% arrhsv(:, 1) = [100 0 135 169 42]/255;  
% 
% colors = max(hsv2rgb(arrhsv), 1/255); % avoid pixel intensity of 0
% 
% [imh, imw] = size(bndinfo.wseg);
% edgeim = zeros([imh imw 3]);
% 
% hasarrow = false(bndinfo.ne*2, 1);
% arrowpos = zeros(1000, 2);
% narrow = 0;
% 
% for k = 1:numel(blabels)
%     if blabels(k) > 0
%         
%         ku = mod(k-1, bndinfo.ne)+1;
%         
%         cols = colors(blabels(k), :);
%         pix = bndinfo.edges.indices{ku};
%         npix = size(edgeim, 1)*size(edgeim, 2);
%         for b = 1:3
%             edgeim(pix + (b-1)*npix) = cols(b);
%         end        
%                 
%         jcts = bndinfo.edges.junctions(ku, :);
%         if k~=ku
%             jcts = jcts([2 1]);
%         end       
%         
%         x = bndinfo.junctions.position(jcts, 1);
%         y = bndinfo.junctions.position(jcts, 2);                                 
%         
%         if ~any(sum((arrowpos(1:narrow, :) - repmat([x(2) y(2)], narrow, 1)).^2, 2) < 20^2) ...
%                 && (numel(pix)>10)
%            
%             narrow = narrow + 1;
%             arrowpos(narrow, :) = [x(2) y(2)];
%                  
%             arrow = struct('x', x(2), 'y', y(2), ...
%                 'angle', atan2(-(y(2)-y(1)), x(2)-x(1)), ...
%                 'radius', 0, 'head_length', round(sqrt(npix)/50), ...
%                 'head_base_angle', 30);
%             arrow.angle = mod(arrow.angle/pi*180, 360);
%             edgeim = draw_arrow_image(edgeim, arrow, cols);
%         end
%         
%     end
% end
% 
% sz = ceil(sqrt(size(im, 1).^2 + size(im,2).^2) / 500);
% 
% for b = 1:3
%     edgeim(:, :, b) = ordfilt2(edgeim(:, :, b), sz*sz, ones(sz, sz));
% end
% 
% if strcmp(class(im), 'uint8')
%     edgeim = im2uint8(edgeim);
% end
% 
% im(edgeim>0) = edgeim(edgeim>0);
% 
% % hold off, clf, imagesc(im), axis image, hold on
% % drawnow;
% 
% % dy = -1;
% % dx = -1;
% %
% % for k = 1:numel(blabels)
% %     if blabels(k) > 0
% %         ku = mod(k-1, bndinfo.ne)+1;
% %         jcts = bndinfo.edges.junctions(ku, :);
% %         if k~=ku
% %             jcts = jcts([2 1]);
% %         end
% % 
% %         x = min(max((bndinfo.junctions.position(jcts, 1)+dx),1), imw);
% %         y = min(max((bndinfo.junctions.position(jcts, 2)+dy), 1), imh);
% %         [arrowx,arrowy] = dsxy2figxy(gca, x, y);        
% %         
% %         if mod(k, 5)==0
% %             annotation('arrow', arrowx, 1-arrowy, ...
% %                 'Color', colors(blabels(k), :), 'HeadStyle', 'vback2', 'LineStyle', 'none');                                    
% %         end
% %             
% %     end
% % end
% 
% 
