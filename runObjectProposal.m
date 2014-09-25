function varargout = runObjectProposal(varargin)
	%if not inputs are provided, this will run for all images in the imageLocation of configjson
	%first input should be the proposal name. If
    global configjson;
    varargout={};    
    if(~isempty(varargin))
	if(nargin==1)
        	proposalName = varargin{1};
		funcName = sprintf('calc%s', char(proposalName));
		try
            		fh = makeHandle(funcName);
            		fh(configjson);
        	catch exc
            		fprintf('***************Error running %s*****************\n', funcName);
			msgString = getReport(exc);
			fprintf(msgString);
        	end

	elseif(nargin==2)
		proposalName = varargin{1};
		imageInput=varargin{2};
		funcName = sprintf('calc%sForIm', char(proposalName));
		try
                        fh = makeHandle(funcName);
                    	varargout{1} = fh( imageInput, configjson.(char(proposalName)));
                catch exc
                        fprintf('***************Error running %s********************\n', funcName);
			msgString = getReport(exc);
                        fprintf(msgString);
                end

	elseif(nargin==3)
 		proposalName = varargin{1};
                imageInput=varargin{2};
		numProposals=varargin{3};
		%set numProposals in opts
		configjson.(char(proposalName)).opts.numProposals=numProposals;
		funcName = sprintf('calc%sForIm', char(proposalName));
                try
                        fh = makeHandle(funcName);
                        varargout{1} = fh( imageInput, configjson.(char(proposalName)));
                catch exc
                        fprintf('****Error running %s ********\n', funcName);
			msgString = getReport(exc);
                        fprintf(msgString);
                end
	end
    else
	% if varargin is empty, run all proposals on all images in the image location with default proposals
        proposalNames = fieldnames(configjson);
        for i = 1:length(proposalNames)
            if((strcmp(proposalNames(i), 'imageLocation')==1 || strcmp(proposalNames(i), 'outputLocation')==1 || strcmp(proposalNames(i), 'params')==1))
                continue;
            else    
                try
                    funcName = sprintf('calc%s', char(proposalNames(i)));
                    fh = makeHandle(funcName);
                    fh(configjson);
                catch
                    fprintf('Error running %s\n', funcName);
                end
            end
        end
        
    end
end

function handle = makeHandle(funcName)
    handle = str2func(funcName);
end
