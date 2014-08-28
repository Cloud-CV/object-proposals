function confidences = test_boosted_dt_mc(classifier, features)
% confidences = test_boosted_dt_mc(classifier, features)
% returns a log likelihod ratio for each class in the classifier    
% confidences(ndata, nclasses)

dt = classifier.wcs(1).dt;
if size(features, 2)~=dt.npred
    error('Incorrect number of attributes')
end

wcs = classifier.wcs;  
nclasses = size(wcs, 2);

ntrees = size(wcs, 1);

confidences = zeros(size(features, 1), nclasses);
for c = 1:nclasses    
    for t = 1:ntrees        
        if ~isempty(wcs(t,c).dt)            
            dt = wcs(t,c).dt;
            [var, cut, children, catsplit] = tree_getParameters(dt);
            nodes = treevalc(int32(var), cut, int32(children(:, 1)), ...
                    int32(children(:, 2)), catsplit(:, 1), features');  
            %[class_indices, nodes2, classes] = treeval(wcs(t, c).dt, features);        
            %         if sum(nodes~=nodes2)>0
            %              disp('error')
            % %              disp(num2str([nodes nodes2]))            
            %         end
            confidences(:, c) = confidences(:, c) + wcs(t, c).confidences(nodes);
        end        
    end
    confidences(:, c) = confidences(:, c) + classifier.h0(c);
end

   