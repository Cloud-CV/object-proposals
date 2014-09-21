function evaluateMetricForProposal(metricName,varargin)
%%
    global configjson;
    proposalNames = fieldnames(configjson);
    
    if(length(varargin)>0)
		proposalsToEvaluate=varargin{1};
		[exists,index]=ismember(proposalsToEvaluate,proposalNames);
        if(exists)
            eval(sprintf('proposalData.%s=configjson.%s',proposalNames{index}, proposalNames{index}))
        end
    else
        proposalsToEvaluate=proposalNames(3:end);	
    	for i=1:length(proposalsToEvaluate)
		eval(sprintf('proposalData.%s=configjson.%s',proposalsToEvaluate{i},proposalsToEvaluate{i}));
        end
       
    end

     %%
    funcName = sprintf('evaluate%s',metricName);
    fh = makeHandle(funcName);
    if(strcmp(metricName, 'RECALL'))
        fh(proposalData,1000,configjson.outputLocation)
    else
        fh(proposalData,'',configjson.outputLocation)
    end
end

function handle = makeHandle(funcName)
    handle = str2func(funcName);
end
