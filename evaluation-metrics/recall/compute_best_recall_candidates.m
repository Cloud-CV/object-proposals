function compute_best_recall_candidates(testset, config)
  num_annotations = testset.num_annotations;
  candidates_thresholds = round(10 .^ (0:0.5:4));
  num_candidates_thresholds = numel(candidates_thresholds);
 
  proposalNames = fieldnames(config);
  proposalsToEvaluate=proposalNames(3:end-1);
  
  for i = 1:length(proposalsToEvaluate)
  	method = config.(char(proposalsToEvaluate{i}));
	candidate_dir=[config.outputLocation proposalsToEvaluate{i}];
	fileName=[candidate_dir '/' 'best_recall_candidates.mat']
    	try
   		method=config.(char(proposalsToEvaluate(i)))
      		load(fileName);
    	catch
	    % preallocate
  	  	best_candidates = [];
    		best_candidates(num_candidates_thresholds).candidates_threshold = [];
    		best_candidates(num_candidates_thresholds).best_candidates = [];
    		for i = 1:num_candidates_thresholds
      			best_candidates(i).candidates_threshold = candidates_thresholds(i);
      			best_candidates(i).best_candidates.candidates = zeros(num_annotations, 4);
      			best_candidates(i).best_candidates.iou = zeros(num_annotations, 1);
      			best_candidates(i).image_statistics(numel(testset.impos)).num_candidates = 0;
    		end

    		pos_range_start = 1;
    		for j = 1:numel(testset.impos)
      			pos_range_end = pos_range_start + size(testset.impos(j).boxes, 1) - 1;
      			assert(pos_range_end <= num_annotations);
     			fprintf('sampling candidates for image %d/%d\n', j, numel(testset.impos));
      			img_id = [testset.impos(j).im] ;
      			for i = 1:num_candidates_thresholds
        			[candidates, scores] = get_candidates(candidate_dir,method, img_id,candidates_thresholds(i),true);
        			if isempty(candidates)
          				impos_best_ious = zeros(size(testset.impos(j).boxes, 1), 1);
          				impos_best_boxes = zeros(size(testset.impos(j).boxes, 1), 4);
        			else
          				[impos_best_ious, impos_best_boxes] = closest_candidates(...
            					testset.impos(j).boxes, candidates);
        			end
        			best_candidates(i).best_candidates.candidates(pos_range_start:pos_range_end,:) = impos_best_boxes;
        			best_candidates(i).best_candidates.iou(pos_range_start:pos_range_end) = impos_best_ious;
        			best_candidates(i).image_statistics(j).num_candidates = size(candidates, 1);
      			end
      			pos_range_start = pos_range_end + 1;
      			%save(fileName, 'best_candidates');
    		end
		save(fileName, 'best_candidates');
   	end
  end
end

