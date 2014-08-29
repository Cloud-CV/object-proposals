function AdaptVOC2007Data(originalTopDirectory,imgListDir,outputDir,params)

omitImagesWithClasses=params.omitImagesWithClasses;
includeBoxesWithClasses=params.includeBoxesWithClasses;
considerDifficult=params.considerDifficult;

if(exist(outputDir,'dir')~=0)
  disp(['The parsed dir: ' outputDir ' already exists. Press any key to use it (or delete it to parse it again)...']);
  pause;
  return;
end
mkdir(outputDir);

assert((numel(includeBoxesWithClasses)+numel(omitImagesWithClasses))==20);

annotationsDir=[originalTopDirectory '/VOC2007/Annotations/'];

assert(exist(imgListDir,'file')~=0);

fid=fopen(imgListDir);
i=0;
nFilesWithGT=0;
nObjects=0;
while ~feof(fid)
  disp(['Adapting image...' num2str(i)]);
  tline = fgets(fid);
  tline=tline(1:(end-1));
  
  %% Load groundtruth
  gtXmlFile=[annotationsDir '/' tline '.xml'];
  assert(exist(gtXmlFile,'file')~=0);
  [gt.boxes,gt.labels] = retrieveBoxesFromXML(gtXmlFile,includeBoxesWithClasses, omitImagesWithClasses, considerDifficult);
  if(size(gt.boxes,1)>0)
    i=i+1;
    disp(['    ' num2str(size(gt.boxes,1)) ' groundtruth boxes extracted']);
    outGT=[outputDir '/gt_' num2str(i) '.mat']; %New index is given to the image!
    save(outGT,'gt');
    if(size(gt.boxes,1)>0)
      nFilesWithGT=nFilesWithGT+1;
      nObjects=nObjects+size(gt.boxes,1);
    end
    
    jpegFile=[originalTopDirectory '/VOC2007/JPEGImages/' tline '.jpg'];
    assert(exist(jpegFile,'file')~=0);
    iData.RGB=imread(jpegFile);
    iData.origId=tline;
    outRGB=[outputDir '/rgb_' num2str(i) '.mat'];
    save(outRGB,'iData');
  end
  
  clear iData gt
end
info.nFilesWithGT=nFilesWithGT;
info.nObjects=nObjects;
save([outputDir '/info.dat'],'info');
fclose(fid);

fid=fopen([outputDir '/img_formats.dat'],'a+t');
fwrite(fid,[outputDir '/rgb_%d.mat']);
fprintf(fid,'\n');
fwrite(fid,num2str(i));
fclose(fid);
end
  
