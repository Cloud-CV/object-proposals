function iccv07PlotResults

if 0
%% Stage 1 low-level
load('./results/initialClassifierComparisonResult3.mat');
figure(1), hold off
plot(pr_pb.r, pr_pb.p, 'b:', 'LineWidth', 4);
hold on
plot(pr_im.r, pr_im.p, 'g--', 'LineWidth', 3);
plot(pr_all.r, pr_all.p, 'r', 'LineWidth', 3);
legend({'Pb Only', 'Pb+Edge/Region Cues', 'Pb+Edge/Region+3D Cues'}, ...
    'Location', 'NorthEast', 'FontSize', 12);
title('Boundary Classification', 'FontSize', 20);
xlabel('Recall', 'FontSize', 18);
ylabel('Precision', 'FontSize', 18);
axis([0 1 0 1])
set(gca, 'FontSize', 14);
disp(num2str([fgacc_im fgacc_all]));
    

%% Stage 2 low-level
load('./results/classifierComparisonResult_stage2.mat');
load('./results/classifierComparisonResult_stage2mrf2.mat');
figure(2), hold off
plot(pr_pb.r, pr_pb.p, 'b:', 'LineWidth', 4);
hold on
plot(pr_im.r, pr_im.p, 'g--', 'LineWidth', 3);
plot(pr_all.r, pr_all.p, 'r', 'LineWidth', 3);
plot(pr_mrf2.r, pr_mrf2.p, '--m', 'LineWidth', 3);
legend({'Pb Only', 'Pb+Edge/Region Cues', 'Pb+Edge/Region+3D Cues', 'All Cues + MRF'}, ...
    'Location', 'SouthWest', 'FontSize', 12);
title('Boundary Classification', 'FontSize', 20);
xlabel('Recall', 'FontSize', 18);
ylabel('Precision', 'FontSize', 18);
axis([0 1 0 1])
set(gca, 'FontSize', 14);
disp(num2str([fgacc_im fgacc_all fgacc_mrf2]));

%% Stage 3 low-level
load('./results/classifierComparisonResult_stage3.mat');
load('./results/classifierComparisonResult_stage3mrfg3.mat');
figure(3), hold off
plot(pr_pb.r, pr_pb.p, 'b:', 'LineWidth', 4);
hold on
plot(pr_im.r, pr_im.p, 'g--', 'LineWidth', 3);
plot(pr_all.r, pr_all.p, 'r', 'LineWidth', 3);
plot(pr_mrfg3.r, pr_mrfg3.p, '--m', 'LineWidth', 3);
legend({'Pb Only', 'Pb+Edge/Region Cues', 'Pb+Edge/Region+3D Cues', 'All Cues + MRF'}, ...
    'Location', 'SouthWest', 'FontSize', 12);
title('Boundary Classification', 'FontSize', 20);
xlabel('Recall', 'FontSize', 18);
ylabel('Precision', 'FontSize', 18);
axis([0 1 0 1])
set(gca, 'FontSize', 14);
disp(num2str([fgacc_im fgacc_all fgacc_mrfg3]));
end

%% Scatter segmentation results
 load('/usr1/projects/dhoiem/iccv07/data4/segresults.mat');
 figure(4), hold off
 plot([results_test1.efficiency], [results_test1.conservation], 'b+', 'MarkerSize', 8, 'LineWidth', 2);
 hold on
 plot([results_test2.efficiency], [results_test2.conservation], 'gx', 'MarkerSize', 8,  'LineWidth', 2);
 plot([results_test3.efficiency], [results_test3.conservation], 'r^', 'MarkerSize', 8,  'LineWidth', 2);
 legend({'Iter 1', 'Iter 2', 'Final'}, ...
    'Location', 'SouthWest', 'FontSize', 12);
title('Segmentation Accuracy', 'FontSize', 20);
xlabel('Efficiency (Log nObjects / nRegions)', 'FontSize', 18);
ylabel('Conservation (Pixel Accuracy)', 'FontSize', 18);
set(gca, 'FontSize', 14);
disp(num2str([median([results_test1.efficiency]) median([results_test2.efficiency]) ...
    median([results_test3.efficiency])]));
disp(num2str([median([results_test1.conservation]) median([results_test2.conservation]) ...
    median([results_test3.conservation])])); 
disp(num2str([median([results_test1.nregions]) median([results_test2.nregions]) ...
    median([results_test3.nregions])])); 
axis([-8 0 0 1])

