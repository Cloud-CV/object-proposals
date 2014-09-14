function methods = getMethods( configjson )
    proposalNames = fieldnames(configjson);

    for i = 1:length(configjson)
        if(strcmp(proposalNames(i), 'imageLocation')~=0 || strcmp(proposalNames(i), 'outputLocation')~=0)
        methods(i).name = char(proposalNames(i));
        eval(sprintf('methods(i).candidate_dir = fullfile(configjson.outputLocation, %s)', char(proposalNames(i))));
        eval(sprintf('methods(i).is_baseline = configjson.%s.opts.isbaseline', char(proposalNames(i))));
        eval(sprintf('methods(i).order = configjson.%s.opts.order',char(proposalNames(i))));    
    end
    
  sort_keys = [num2cell([methods.is_baseline])', {methods.name}'];
  for i = 1:numel(methods)
    sort_keys{i,1} = sprintf('%d', sort_keys{i,1});
  end
  [~,idx] = sortrows(sort_keys);
  for i = 1:numel(methods)
    methods(idx(i)).sort_key = i;
  end
  
end

