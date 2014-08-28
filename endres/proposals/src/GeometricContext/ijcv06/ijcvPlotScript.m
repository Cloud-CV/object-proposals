
medFS = 18;
bigFS = 20;

indir = '/IUS/vmr20/dhoiem/data/ijcv06';
outdir = '/IUS/vmr20/dhoiem/data/ijcv06/results';

DO_TREES = 1;
DO_NODES = 1;
DO_SEGMENTATIONS = 1;
DO_SEGMENTS = 1;
DO_PR = 0;
DO_DATA = 1;
% PR Curves
if DO_PR 
    tmp = load([indir '/multisegResults2.mat']);
    if ~exist('imsegs')
        load '../data/allimsegs2.mat';
    end
    load '../data/rand_indices.mat';
    [prv, prh] = pg2prcurve(tmp.pg2, imsegs(cv_images));
    figure(6), hold off
    colors = ['grb'];
    patterns = [{'-', '--', ':'}];
    for v = 1:numel(prv)
        plot(prv(v).r, prv(v).p, [colors(v) patterns{v}], 'LineWidth', 3)
        hold on
    end
    legend(gca, {'Support', 'Vertical', 'Sky'}, 'FontSize', medFS, 'Location', 'SouthWest')
    set(gca, 'FontSize', medFS) 
    axis([0 1 0.5 1])        
    set(gca, 'XTick', [0:0.1:1]);  
    xlabel('Recall')
    ylabel('Precision')
    print('-f6', '-dpsc2', [outdir '/prvplot.ps'])    
    figure(7), hold off
    colors = ['rgcyk'];
    patterns = {'--', ':', '--', '-', '-'};
    for h = 1:numel(prh)
        plot(prh(h).r, prh(h).p, [colors(h) patterns{h}], 'LineWidth', 3)
        hold on
    end
    legend(gca, {'Left', 'Center', 'Right', 'Porous', 'Solid'}, 'FontSize', medFS, 'Location', 'SouthWest')
    set(gca, 'FontSize', medFS) 
    axis([0 1 0 1])        
    xlabel('Recall')
    ylabel('Precision')
    print('-f7', '-dpsc2', [outdir '/prhplot.ps'])      
end


% Number of Trees
if DO_TREES;
    tmp = load([indir '/classifierParams2.mat']);
    ntrees = [1 2 5 10 20 50 100];
    figure(1), hold off, semilogx(ntrees, tmp.vacc_t, '-r+', 'LineWidth', 3, 'MarkerSize', 7)
    hold on, semilogx(ntrees, tmp.hacc_t, '--b+', 'LineWidth', 3, 'MarkerSize', 7)
    legend(gca, {'Main', 'Sub'}, 'FontSize', medFS, 'Location', 'NorthWest')
    set(gca, 'FontSize', medFS)
    set(gca, 'XTick', ntrees);   
    set(gca,'XTickLabel', ntrees);  
    set(gca, 'XMinorTick', 'off')    
    axis([1 100 0.5 1])        
    xlabel('Number of Weak Learners (8-Node DT)')
    ylabel('Accuracy')
    print('-f1', '-dpsc2', [outdir '/ntreesplot.ps'])
end

% Number of Nodes
if DO_NODES;
    tmp = load([indir '/classifierParamsNodes.mat']);
    nnodes = [2 4 8 16 32];
    figure(2), hold off, semilogx(nnodes, tmp.vacc_n, '-r+', 'LineWidth', 3, 'MarkerSize', 7)
    hold on, semilogx(nnodes, tmp.hacc_n, '--b+', 'LineWidth', 3, 'MarkerSize', 7)
    legend(gca, {'Main', 'Sub'}, 'FontSize', medFS, 'Location', 'NorthWest')
    set(gca, 'FontSize', medFS)
    set(gca, 'XTick', nnodes);   
    set(gca,'XTickLabel', nnodes);     
    set(gca, 'XMinorTick', 'off')    
    axis([2 32 0.5 1])        
    xlabel('Number of Leaf Nodes per Tree')
    ylabel('Accuracy')
    print('-f2', '-dpsc2', [outdir '/nnodesplot.ps'])
end

% Number of Segmentations
if DO_SEGMENTATIONS
    tmp = load([indir '/numSegmentationsResults.mat']);
    nseg = [1 2 4 8 15 30 60];
    tmp.vacc = tmp.vacc([6:7 1:5]);
    tmp.hacc = tmp.hacc([6:7 1:5]);
    figure(3), hold off, semilogx(nseg, tmp.vacc, '-r+', 'LineWidth', 3, 'MarkerSize', 7)
    hold on, semilogx(nseg, tmp.hacc, '--b+', 'LineWidth', 3, 'MarkerSize', 7)
    legend(gca, {'Main', 'Sub'}, 'FontSize', medFS, 'Location', 'NorthWest')
    set(gca, 'FontSize', medFS)
    set(gca, 'XTick', nseg);
    set(gca,'XTickLabel', nseg); 
    set(gca, 'XMinorTick', 'off')    
    axis([1 60 0.5 1])       
    xlabel('Number of Segmentations')
    ylabel('Accuracy')
    print('-f3', '-dpsc2', [outdir '/nsegmentationsplot.ps'])
end

% Number of Segments
if DO_SEGMENTS
    % standard error = [.98%, 0.70%, 0.85%, 0.89%, 0.72%, 0.75%, 0.77%]
    tmp = load([indir '/singleSegResults.mat']);
    tmp2 = load([indir '/spSegResults2.mat']);
    nsegments = [3 6 12 25 50 100 200 400];
    meanv = [mean(tmp.vacc,2) ; tmp2.vacc];
    figure(4), hold off, semilogx(nsegments, meanv, '-r+', 'LineWidth', 3, 'MarkerSize', 7)
    meanh = [mean(tmp.hacc,2) ; tmp2.hacc];
    hold on, semilogx(nsegments, meanh, '--b+', 'LineWidth', 3, 'MarkerSize', 7)
    
%     stdv = [tmp.stderrv' tmp2.stderrv];
%     stdh = [tmp.stderrh' tmp2.stderrh];
%     for k = 1:numel(nsegments)
%         plot([nsegments(k) nsegments(k)], [meanv(k)-stdv(k)/2 meanv(k)+stdv(k)/2], 'r', 'Linewidth', 3);
%         plot([nsegments(k) nsegments(k)], [meanh(k)-stdh(k)/2 meanh(k)+stdh(k)/2], 'b', 'Linewidth', 3);   
%     end
    set(gca, 'XTick', [3 6 12 25 50 100 200 400]);
    set(gca,'XTickLabel',{'3','6','12','25','50','100', '200', 'sp'})
    set(gca, 'XMinorTick', 'off')    
    axis([3 400 0.3 1])    
    legend(gca, {'Main', 'Sub'}, 'FontSize', medFS, 'Location', 'NorthWest')
    set(gca, 'FontSize', medFS)
    xlabel('Number of Segments')
    ylabel('Accuracy')
    print('-f4', '-dpsc2', [outdir '/nsegmentsplot.ps'])
end

% Number of Data
if DO_DATA
    tmp = load([indir '/ndataResults1.mat']);
    tmp2 = load([indir '/ndataResults2.mat']);
    tmp.vacc = (tmp.vacc + tmp2.vacc)/2;
    tmp.hacc = (tmp.hacc + tmp2.hacc)/2;
    ndata = [5 10 25 50 75 100 150 200];
    figure(5), hold off, semilogx(ndata, tmp.vacc, '-r+', 'LineWidth', 3, 'MarkerSize', 7)
    hold on, semilogx(ndata, tmp.hacc, '--b+', 'LineWidth', 3, 'MarkerSize', 7)
    set(gca, 'XTick', [5 10 25 50 100 200]);
    set(gca,'XTickLabel',{'5','10','25','50','100', '200'})
    set(gca, 'XMinorTick', 'off')    
    axis([5 200 0.3 1])    
    legend(gca, {'Main', 'Sub'}, 'FontSize', medFS, 'Location', 'NorthWest')
    set(gca, 'FontSize', medFS)
    xlabel('Number of Training Images')
    ylabel('Accuracy')
    print('-f5', '-dpsc2', [outdir '/ndataplot.ps'])
end
