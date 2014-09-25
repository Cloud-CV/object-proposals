initialize;
configjson.imageLocation = fullfile(pwd, 'demo_img');
if(~exist(fullfile(pwd, 'demo_result')))
    mkdir(fullfile(pwd, 'demo_result'));
end
configjson.outputLocation = fullfile(pwd, 'demo_result');

%%% proposals for al images in the imageLocation
runObjectProposal('randomPrim');

%%%proposals for one image
%1)
proposals=runObjectProposal('randomPrim','demo_img/2007_009084.jpg');

%2)
im=imread('demo_img/2007_009084.jpg');
proposals=runObjectProposal('randomPrim',im);

%%% certain number of proposals

proposals=runObjectProposal('randomPrim',im,100);
