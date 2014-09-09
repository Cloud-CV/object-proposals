function methods = getMethods( configjson )
    proposalNames = fieldnames(configjson)
    
    for i = 1:length(configjson)
        methods(i).name = proposalNames(i);
        methods(i).candidate_dir = ...
        configjson(proposalNames(i)).outputLocation;
        methods(i).isBaseline = configjson(proposalNames(i)).opts.isbaseline;
        methods(i).order = configjson(proposalNames(i)).opts.order;    
    end
end

