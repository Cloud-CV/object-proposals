function runObjectProposal(name)
    global configjson;
    proposalNames = fieldnames(configjson);
  
    for i = 1:length(proposalNames)
        if((strcmp(proposalNames(i), 'imageLocation')==1 || strcmp(proposalNames(i), 'outputLocation')==1 || strcmp(proposalNames(i), 'params')==1))
            continue;
        else    
           fprintf('Coming Here');
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

function handle = makeHandle(funcName)
    handle = str2func(funcName)
end