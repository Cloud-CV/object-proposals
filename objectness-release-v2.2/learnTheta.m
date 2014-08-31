function [thetaOpt likelihoodOpt pobj] = learnTheta(cue,params)

fprintf('Learning theta for %s\n',cue);

if nargin < 2 
    params = defaultParams;   
end
    
try 
    struct = load([params.trainingExamples '/posneg.mat'] );
    posneg = struct.posneg;
    clear struct;
catch    
    posneg = generatePosNeg(params);
    save([params.trainingExamples '/posneg.mat'],'posneg');
end

bestValue = -inf;
thetaOpt = 0;

for idx = 1:length(params.(cue).domain)
    
    theta = params.(cue).domain(idx);
    [likelihood  pobj  logTotal] = deriveLikelihood(posneg,theta,params,cue);
    if bestValue < logTotal
        thetaOpt = theta;
        likelihoodOpt = likelihood;
        bestValue = logTotal;
    end  
    fprintf('Best current theta for %s is %f \n',cue,thetaOpt)   
end

end


function posneg = generatePosNeg(params)

struct = load([params.trainingImages 'structGT.mat']);
structGT= struct.structGT;

for idx = 1:length(structGT)    
    img = imread([params.trainingImages structGT(idx).img]);         
    windows = generateWindows(img,'uniform',params);
    posneg(idx).examples =  windows;
    labels = - ones(size(windows,1),1);
    for idx_window = 1:size(windows,1)        
        for bb_id = 1:size(structGT(idx).boxes,1)
            pascalScore = computePascalScore(structGT(idx).boxes(bb_id,:),windows(idx_window,:));
            if (pascalScore >= params.pascalThreshold)
                labels(idx_window) = 1;
                break;
            end
        end
    end
    posneg(idx).labels = labels;
    posneg(idx).img = img;
end

end

function [likelihood pobj logTotal] = deriveLikelihood(posneg,theta_value,params,cue)

params.(cue).theta = theta_value;

examplesPos = zeros(length(posneg) * params.distribution_windows,1);
examplesNeg = zeros(length(posneg) * params.distribution_windows,1);

pos = 0; 
neg = 0;

for idx = 1:length(posneg)        
    
    %idx;
    temp = computeScores(posneg(idx).img,cue,params,posneg(idx).examples);
    posneg(idx).scores = temp(:,end);
    
    indexPositive = find(posneg(idx).labels == 1);
    examplesPos(pos+1:pos+length(indexPositive)) = posneg(idx).scores(indexPositive);
    pos = pos + length(indexPositive);
    
    indexNegative = find(posneg(idx).labels == -1);
    examplesNeg(neg+1:neg+length(indexNegative)) = posneg(idx).scores(indexNegative);
    neg = neg + length(indexNegative);
    
       
end
examplesPos(pos+1:end) = [];
examplesNeg(neg+1:end) = [];

pobj = pos/(pos+neg);
pbg  = 1 - pobj;

posLikelihood = hist(examplesPos,params.(cue).bincenters)/length(examplesPos) + eps;
negLikelihood = hist(examplesNeg,params.(cue).bincenters)/length(examplesNeg) + eps;

logTotal = 0;

for idx = 1:length(examplesPos)                 
    %see what is the corresponding bin center
    for binc = 2:length(params.(cue).bincenters)
        if (examplesPos(idx) <= params.(cue).bincenters(binc))            
            break;            
        end
    end            
    binc = binc - 1;    
    logTotal = logTotal + log((pobj * posLikelihood(binc))/(pobj * posLikelihood(binc) + pbg * negLikelihood(binc) +eps));            
end

likelihood = [posLikelihood;negLikelihood];
end
