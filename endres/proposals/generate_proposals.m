function [ranked_regions superpixels image_data] = generate_proposals(input)
% Generate a list of proposals ordered by their likelihood of containing an object
% regions - a cell array of proposals
%           proposals are encoded the list of superpixels that belong to that region
% superpixels - a pixel map indicating which superpixel each pixel belongs to
%
% To get the pixelmask for the ith region:
%    mask = ismember(superpixels, regions{i});
%
% Additional image data is stored in the optional image_data field:
%
% image_data.occ - Occlusion boundary information
% image_data.occ.bndinfo{,_all} - Main occlusion boundary structures
% image_data.occ.pbim - pb output
%
% image_data.gconf - Geometric context confidences
% image_data.textonim - quantized texton index map for the image
% image_data.colorim - quantized color index map for the image
% image_data.bg - predicted probability of background map


function_root = which('generate_proposals.m');
function_root = function_root(1:end-length('generate_proposals.m'));

if(isstr(input))
   im = im2double(imread(input));
else
   im = im2double(input); % Just to make input consistent
end

start = tic;
start_image = start;
fprintf('***Extracting image level features******\n');

%%%% Occlusion and Geometric context
fprintf('------Occlusion boundaries + Geometric context------\n')
start_ob = tic;
[occ.bndinfo, occ.pbim, image_data.gconf, occ.bndinfo_all] = ...
   processIm2Occlusion(im);
[occ.pb1, occ.pb2, occ.theta] = getOrientedOcclusionProbs(occ.bndinfo_all);
bmaps = getOcclusionMaps(occ.bndinfo_all); 
occ.bmap = mean(bmaps,3); 


image_data.occ = occ;

fprintf('Done (%f)\n', toc(start_ob));

%%%% Color + Texture codewords
start_ct = tic;
fprintf('------Quantize color/texture------\n');

col = load(fullfile(function_root, 'classifiers', 'colorClusters.mat'));
tex = load(fullfile(function_root, 'classifiers', 'textonClusters.mat'));
[image_data.textonim, image_data.colorim] = processIm2ColorTexture(im, col, tex);
fprintf('Done (%f)\n', toc(start_ct));

%%%% Probability of BG
fprintf('------Probability of BG------\n');
start_bg = tic;
msclassifiers = load(fullfile(function_root, 'classifiers', 'msBgClassifiers.mat'));
[image_data.bg] = processIm2MsObjects(im, msclassifiers);
fprintf('Done (%f)\n', toc(start_bg));
fprintf('\nTotal time: %f\n', toc(start_image));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Segment level features %%%%%%%%%%%
fprintf('\n***Extracting Segment Features******\n');
start_seg = tic;
load(fullfile(function_root, 'classifiers', 'bboxClassifier2.mat'), 'classifier_bbox');
load(fullfile(function_root, 'classifiers', 'subregionClassifier_mix.mat'), 'classifier');

[region_data] = processData2RegionFeatures(image_data, classifier_bbox, classifier);
fprintf('Done (%f)\n', toc(start_seg));


fprintf('\n***Proposing Regions******\n');
start_prop = tic;
[proposals proposal_data] = proposeRegions(image_data, region_data);

fprintf('Done (%f)\n', toc(start_prop))

fprintf('\n***Extracting Proposal Appearance Features******\n');
start_app = tic;
proposal_features = getRegionAppearance(image_data, proposals);
fprintf('Done (%f)\n', toc(start_app));


fprintf('\n***Ranking Proposals******\n');
start_rank = tic;
load(fullfile(function_root, 'classifiers', 'ranker_final.mat'), 'w');
[ranking overlaps] = rankProposals(image_data, proposals, proposal_features, w);

fprintf('Done (%f)\n', toc(start_rank));

stop = toc(start);
fprintf('\n\n Proposal process complete: Total Time: %f (%dm, %ds)\n', stop, floor(stop/60), mod(ceil(stop),60));

[dk ordering] = sort(ranking);
ranked_regions = proposals(ordering);
superpixels = image_data.occ.bndinfo_all{1}.wseg;
