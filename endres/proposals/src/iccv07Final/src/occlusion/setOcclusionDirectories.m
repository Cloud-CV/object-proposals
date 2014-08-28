% sets directories

dataset = 'labelme';
alg = 'occw';

switch(lower(dataset))

    case 'bsds'
        bsdsdir = '~dhoiem/data/datasets/BSDS300/';
        imdir = fullfile(bsdsdir, 'images/all/');

        basedir = '~/data/occlusion/bsds';
        gtdir = fullfile(basedir, 'gt');
        occdir = fullfile(basedir, 'occlusion');
        pbdir = fullfile(basedir, 'pb');
        pb2dir = fullfile(basedir, 'pb2');
        traindir = fullfile(basedir, 'train');

        
   
    case 'labelme'
        basedir = '~/data/occlusion/labelme';
        imdir_train = fullfile(basedir, 'train/Images');        
        imdir_test = fullfile(basedir, 'test/Images');  
        gtdir = fullfile(basedir, 'labels2');
        occdir = fullfile(basedir, 'occlusion');
        pbdir = fullfile(basedir, 'pb');
        pb2dir = fullfile(basedir, 'pb2');
        traindir = fullfile(basedir, 'train');
    
    otherwise
        error('invalid dataset')
end
