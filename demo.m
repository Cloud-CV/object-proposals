initialize;
configjson.imageLocation = fullfile(pwd, 'demo_img');
if(~exist(fullfile(pwd, 'demo_result')))
    mkdir(fullfile(pwd, 'demo_result'));
end
configjson.outputLocation = fullfile(pwd, 'demo_result');

imageFile='demo_img/2007_009084.jpg';
objectProposal='randomPrim';

%%% Proposals for all images in imageLocation

runObjectProposals(objectProposal);

% Proposals for one image
% 1)

proposals=runObjectProposals(objectProposal,imageFile);

% 2)

im=imread(imageFile);
proposals=runObjectProposals(objectProposal,im);

%%% Certain number of proposals

proposals=runObjectProposals(objectProposal,im,100);