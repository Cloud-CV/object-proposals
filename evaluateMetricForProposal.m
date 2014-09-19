function evaluateMetricForProposal(metricName,varargin)

    global configjson;
    proposalNames = fieldnames(configjson);
    if(length(varargin)>0)
		proposalsToEvaluate=varargin{1};
		[exists,index]=ismember(proposalsToEvaluateName,proposalNames);
                eval(sprintf('proposalData=configjson.%s',proposalNames{index})
    
    else
	proposalsToEvaluate=proposalNames(3:end);	
	for i=1:length(proposalsToEvaluate)
		eval(sprintf('proposalData(i)=configjson.%s',proposalsToEvaluate{i}));
	end	
end

 
funcName = sprintf('eval%s',metricName);
fh = makeHandle(funcName);
fh(proposalData);
end
function handle = makeHandle(funcName)
    handle = str2func(funcName)
end
