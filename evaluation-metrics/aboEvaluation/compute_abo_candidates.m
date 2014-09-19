function compute_abo_candidates(testset, methods)

  num_images = numel(testset.impos);
  candidates_thresholds = round(10 .^ (0:0.5:4))
  num_candidates_thresholds = numel(candidates_thresholds);

  for method_idx = 1:numel(methods)
    fileName=[ methods(method_idx).opts.outputLocation 'abo_candidates.mat']; 
    try
      load(fileName, 'abo_candidates');
      continue;

    catch

       abo_candidates = [];
       abo_candidates(num_candidates_thresholds).candidates_threshold = [];
       abo_candidates(num_candidates_thresholds).candidates = [];
       for i = 1:num_candidates_thresholds
                abo_candidates(i).candidates_threshold = candidates_thresholds(i);
                abo_candidates(i).candidates = cell(num_images, 1);
       end

        for i=1:num_images
                img_id =testset.impos(i).im;
                for j=1:num_candidates_thresholds
                        [candidates, scores] = get_candidates(methods(method_idx), img_id, ...
                                                candidates_thresholds(j));
                         abo_candidates(j).candidates{i}=candidates;
                end
                r=rem(i,1000);
                if(r==0)
                        fprintf('done with image :%s,%s\n',img_id,methods(method_idx).opts.name);
                end
       end
     parsave(fileName, abo_candidates);
   end

  end
end

function parsave(fileName, data)

 var_name=genvarname(inputname(2));
 eval([var_name '=data'])
 save(fileName,var_name,'-v7.3');

end

