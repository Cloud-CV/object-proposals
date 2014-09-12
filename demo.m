compile;
configjson.inputLocation = fullfile(pwd, 'demo_img');
if(~exist(fullfile(pwd, 'demo_result')))
    mkdir(fullfile(pwd, 'demo_result'));
end
configjson.outputLocation = fullfile(pwd, 'demo_result');
calcEndres(configjson);