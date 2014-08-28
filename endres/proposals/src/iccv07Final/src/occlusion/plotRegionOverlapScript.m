function plotRegionOverlapScript

load('~/data/occlusion/labelme/results/result_LM_region_mean_covering.mat');

%% Plot by area
area_vals = [0.0025 0.005 0.01 0.2 0.4 1];

areas = cat(2, cover_occ1.area)';

% assign index for largest area_vals that area is less than or equal to
area_ind = zeros(size(areas));
for k = 1:numel(area_vals)
    area_ind = area_ind + (areas > area_vals(k));
end
area_ind = area_ind+1;

names = {'Pb+ucm', 'globalPb+ucm', 'occ_1', 'occ_{final}'};
area_hist = zeros(numel(area_vals), 4);
ovmax{1} = cat(1, cover_ucm1.maxov);
ovmax{2} = cat(1, cover_ucm2.maxov);
ovmax{3} = cat(1, cover_occ1.maxov);
ovmax{4} = cat(1, cover_occave.maxov);

area_hist = zeros(numel(area_vals), numel(ovmax));
for k = 1:numel(ovmax)
    for k2 = 1:numel(area_vals)
        area_hist(k2, k) = mean(ovmax{k}(area_ind==k2));
    end        
end

na = numel(area_vals);
nl = numel(ovmax);
figure(1), hold off;
style = {'--', '--', '-', '-' ,'-'};
markers = {'+', 'x', 'o', '+', 'x'};
for k = 1:numel(ovmax)
    plot(area_hist(:, k), 'LineStyle', style{k}, 'MarkerSize', 12, 'Marker', markers{k}, 'LineWidth', mod(k,3)+2, 'Color', hsv2rgb(k/nl, 1, k/nl)); hold on;
end
xlabels = strtokAll(num2str(area_vals), ' ');  
xlabels = [[{'0'} ; xlabels(1:end-1)] repmat({'-'}, na, 1)   xlabels(:) [repmat({'|'}, na-1, 1) ; {' '}]]';
axis([1 6 0 1]); set(gca, 'XTick', 1:na, 'XTickLabel', cat(2, xlabels{:}), 'FontSize', 16); 
legend(names, 'Location', 'NorthWest')
xlabel('Region Area', 'FontSize', 18); ylabel('Average Overlap', 'FontSize', 18)
print -f1 -depsc ~/data/occlusion/labelme/figs/plots/overlap_comparison_by_area.eps

%% Cumulative overlap
figure(2), hold off, 
ind = true(size(areas));
for k = 1:numel(ovmax)
    y = sort(ovmax{k}(ind), 'descend');
    plot((1:numel(y))/numel(y), y, 'LineStyle', style{k}, 'LineWidth', mod(k,3)+2, 'Color', hsv2rgb(k/nl, 1, k/nl)); hold on;
end
axis([0 1 0 1]); set(gca, 'XTick', 0:0.1:1, 'FontSize', 16); 
legend(names, 'Location', 'NorthEast')
xlabel('Recall', 'FontSize', 18); ylabel('Overlap', 'FontSize', 18)
print -f2 -depsc ~/data/occlusion/labelme/figs/plots/overlap_overall_comparison.eps

%% Cumulative overlap by area
figure(3), hold off, 
for k = 1:na-1
    ind = areas>=area_vals(k);
    y = sort(ovmax{end}(ind), 'descend');
    plot((1:numel(y))/numel(y),y, 'LineStyle', style{k}, 'LineWidth', mod(k,3)+2, 'Color', hsv2rgb(k/(na-1), 1, k/(na-1))); hold on;
end
axis([0 1 0 1]); set(gca, 'XTick', 0:0.1:1, 'FontSize', 16); 
for k = 1:na-1, lstr{k} = [' >' num2str(area_vals(k))]; end
legend(lstr, 'Location', 'SouthWest')
xlabel('Recall', 'FontSize', 18); ylabel('Overlap', 'FontSize', 18);
print -f3 -depsc  ~/data/occlusion/labelme/figs/plots/overlap_occlusion.eps