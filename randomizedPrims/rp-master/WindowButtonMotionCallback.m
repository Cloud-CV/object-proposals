function WindowButtonMotionCallback(a, b)

global h I pcs proposals selections current

%% Ask for center:
p = get(h, 'currentPoint');
H = size(I, 1);
W = size(I, 2);
i = round(H-p(2));
j = round(p(1));
id = 1;

%% Find closest proposal:
d = sqrt((pcs(:, 1) - j) .^ 2 + (pcs(:, 2) - i) .^ 2);
[~, ids] = min(d);
current = proposals(ids(id), :);

%% Display results:
%clf;
imshow(I, 'Border', 'tight');
hold on;
plotBoxes(selections, 'b', [], '-');
plotBoxes(current, 'y', [], '-');
plot([pcs(ids(id), 1) j], [pcs(ids(id), 2) i], 'g-.');
plot(pcs(ids(id), 1),pcs(ids(id), 2), 'yx', 'LineWidth', 5);
plot(j, i, 'bx', 'LineWidth', 5);

end