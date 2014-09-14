
%%plotting recall


%load sample data
load('methods.mat');
testset=load('data/pascal_gt_data.mat');
compute_best_recall_candidates(testset,methods);


plot_overlap_recall_curve(methods,1000,true, 'NorthEast',true);

plot_num_candidates_auc(methods);


%plot abo

compute_abo_candidates(testset, methods);
 plot_num_candidates_abo( methods);


