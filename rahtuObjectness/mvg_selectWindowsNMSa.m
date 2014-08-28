function [indexSamples]=mvg_selectWindowsNMSa(windows,scores,imageSize,numberSamples,NMSthreshold)

% Initialize
nw=size(windows,1);

scv=sort(scores(:),1,'ascend');
if NMSthreshold==0
  scoreth=0;
else
  scoreth=scv(min(floor(NMSthreshold*nw)+1,nw));
end
dx=imageSize(2);
dy=imageSize(1);

indexSamples=selectwinsdensemultireso_(windows,scores,dx,dy,numberSamples,scoreth);



%%%%%%%%%%%%%%%%%%%%%%%%
% Additional functions %
%%%%%%%%%%%%%%%%%%%%%%%%

%%% Selected windows densely in multiple resolutions%%%
function [winids,gridbins]=selectwinsdensemultireso_(windows,scores,dx,dy,nsample,scoreth)%,startbincount)

%if nargin<7
%  startbincount=5;
%end
nlevels=3;
levelfactor=2;
wbins=[];

scores=scores(:);
%rlevels=[5 10 20 40 80];
nw=size(windows,1);

windowsnorm=windows./(ones(nw,1)*[dx dy dx dy]);
nbins=zeros(1,nlevels);
levelids=nlevels:-1:1;

[gridbins2,reslevels2]=winstogridmultireso_(windows,scores,dx,dy,nlevels,2,scoreth);
[gridbins3,reslevels3]=winstogridmultireso_(windows,scores,dx,dy,nlevels,3,scoreth);
[gridbins5,reslevels5]=winstogridmultireso_(windows,scores,dx,dy,nlevels,5,scoreth);

allgrids{1}=gridbins2;allgrids{2}=gridbins3;allgrids{3}=gridbins5;
allresos=[reslevels2;reslevels3;reslevels5];
[sres,sresid]=sort(allresos(:),1,'ascend');
sresidb=floor((sresid-1)/3)+1;
sresida=sresid-(sresidb-1)*3;
%[sres sresida sresidb]
%keyboard

sampleindicator=zeros(nw,1);
winids=zeros(nsample,1);
counter=0;
for i=1:length(sres)
  if counter>=nsample
    break;
  end
  counteri=nsample-counter;
  if i==1
    validlocalmaxima=allgrids{sresida(i)}{sresidb(i)}.localmaxima;
  else
    validlocalmaxima=allgrids{sresida(i)}{sresidb(i)}.localmaxima;
    validlocalmaxima=(sampleindicator(allgrids{sresida(i)}{sresidb(i)}.maxscorewins)==0) ...
	& validlocalmaxima;
  end
  [sc,ssid]=sort(allgrids{sresida(i)}{sresidb(i)}.maxscores(validlocalmaxima),1,'descend');
  newid=ssid(1:min(sum(validlocalmaxima),counteri));
  idi=find(validlocalmaxima);
  %idi=idi(1:min(sum(validlocalmaxima),counteri));
  winids((counter+1):(counter+length(newid)))= ...
      allgrids{sresida(i)}{sresidb(i)}.maxscorewins(idi(newid));
  sampleindicator(allgrids{sresida(i)}{sresidb(i)}.maxscorewins(idi(newid)))=1;
  counter=counter+length(newid);

  gridstep=sres(i);
  %fprintf('Level: %d / %d, gridstep: %d, counter=%d\n',i,nlevels,gridstep,counter);
  
end

if counter<nsample
  counteri=nsample-counter;
  validids=(sampleindicator==0);
  [sc,ssid]=sort(scores(validids),1,'descend');
  newid=ssid(1:min(sum(validids),counteri));
  winids((counter+1):(counter+length(newid)))=newid;
end


%%% Windows to grid %%%
function [gridbins,reslevels]=winstogridmultireso_(windows,scores,dx,dy,nlevels,startbincount,scoreth)%,nsample,scoreth,startbincount)

if nargin<7 || isempty(scoreth)
  scoreth=0;
end
if nargin<6 || isempty(startbincount)
  startbincount=5;
end
if nargin<5 || isempty(nlevels)
  nlevels=3;
end
levelfactor=2;
wbins=[];

scores=scores(:);
%rlevels=[5 10 20 40 80];
nw=size(windows,1);

windowsnorm=windows./(ones(nw,1)*[dx dy dx dy]);
nbins=zeros(1,nlevels);
levelids=nlevels:-1:1;

gridbins=cell(1,nlevels);
%wbins=cell(1,nlevels);
reslevels=zeros(1,nlevels);
%objwins=scores>scoreth;

for i=levelids
  bincount=levelfactor^(i-1)*startbincount;
  bincount2=bincount^2;
  reslevels(i)=bincount;
  
  if i==nlevels
    wini=floor(bincount*(windowsnorm-eps))+1;
    ai=(wini(:,1)-1)*bincount+wini(:,2);
    bi=(wini(:,3)-1)*bincount+wini(:,4);
    Bsi=sparse(ai,bi,1,bincount2,bincount2);
  else
    nextbincount=levelfactor^(i+1-1)*startbincount;
    nextlevelbincoords=floor((gridbins{i+1}.bincoords+levelfactor-1)/levelfactor);
    ai=(nextlevelbincoords(:,1)-1)*bincount+nextlevelbincoords(:,2);
    bi=(nextlevelbincoords(:,3)-1)*bincount+nextlevelbincoords(:,4);
    Bsi=sparse(ai,bi,1,bincount2,bincount2);
  end
  
  [iba,ibb]=find(Bsi);
  nbins(i)=length(iba);
  Bids=sparse(iba,ibb,1:nbins(i),bincount2,bincount2);
  %wbins{i}=Bids((bi-1)*bincount2+ai);
  
  xa=floor((iba-1)/bincount)+1;
  ya=iba-(xa-1)*bincount;
  xb=floor((ibb-1)/bincount)+1;
  yb=ibb-(xb-1)*bincount;
  
  %parentcoords
  clear gb;
  %gb.parentids=zeros(1,nbins(i));
  gb.nbin=nbins(i);
  gb.bincoords=[xa ya xb yb];
  

  if i==nlevels
    wins=sparse(Bids((bi-1)*bincount2+ai),1:nw,scores,nbins(i),nw);
    %checksum=sum(sparse(Bids((bi-1)*bincount2+ai),1:nw,1,nbins(i),nw));
    if 0
    if min(checksum)==1 & max(checksum)==1
    else
      disp('checksum incorrect');
      keyboard
    end
    end
    %gb.nobjwins=sum(gb.wins>scoreth,2)';
    [maxscores,maxscorewins]=(max(wins,[],2));
    gb.maxscores=full(maxscores);
    gb.maxscorewins=full(maxscorewins);
    %keyboard
    %gb.childids=[];
  else
    wins=sparse(Bids((bi-1)*bincount2+ai),1:gridbins{i+1}.nbin,gridbins{i+1}.maxscores,nbins(i),gridbins{i+1}.nbin);
    [maxscores,nlmaxids]=max(wins,[],2);
    gb.maxscores=full(maxscores);
    gb.maxscorewins=gridbins{i+1}.maxscorewins(nlmaxids);
    %gb.wins=[];
    %nextbincount=levelfactor^(i+1-1)*startbincount;
    %nextlevelbincoords=floor((gridbins{i+1}.bincoords+levelfactor-1)/levelfactor)';
    %nlai=(nextlevelbincoords(:,1)-1)*bincount+nextlevelbincoords(:,2);
    %nlbi=(nextlevelbincoords(:,3)-1)*bincount+nextlevelbincoords(:,4);
    %gridbins{i+1}.parentids=full(Bids((nlbi-1)*bincount2+nlai))';

  end

  neighbors=ones(nbins(i),8);
  validneighbors=logical(ones(nbins(i),1));
  neighborj=zeros(nbins(i),4);
  abj=ones(nbins(i),1);
  shift=[-1 0 0 0; 1 0 0 0; 0 -1 0 0; 0 1 0 0; 0 0 -1 0; 0 0 1 0; 0 ...
	0 0 -1; 0 0 0 1];
  xaj=zeros(nbins(i),8);yaj=xaj;xbj=xaj;ybj=xaj;
  tmpxaj=xaj;tmpyaj=xaj;tmpxbj=xaj;tmpybj=xaj;
  zeroids=logical(ones(nbins(i),1));
  for j=1:8
    xaj=xa+shift(j,1);
    yaj=ya+shift(j,2);
    xbj=xb+shift(j,3);
    ybj=yb+shift(j,4);
    neighborj(:,1)=min(xaj,xbj);
    neighborj(:,2)=max(xaj,xbj);
    neighborj(:,3)=min(yaj,ybj);
    neighborj(:,4)=max(yaj,ybj);
    aj=(neighborj(:,1)-1)*bincount+neighborj(:,2);
    bj=(neighborj(:,3)-1)*bincount+neighborj(:,4);
    validneighbors=logical(min((neighborj>0 & neighborj<=bincount),[],2));
    abj(validneighbors)=(bj(validneighbors)-1)*bincount2+aj(validneighbors);
    Njids=full(Bids(abj));
    [nonzeroids,tmp,nonzeros]=find(Njids);
    zeroids(nonzeroids)=0;%find(Njids==0);
    validneighbors(zeroids)=0;
    neighbors(nonzeroids,j)=nonzeros;
    neighbors(:,j)=gb.maxscores(neighbors(:,j)).*validneighbors;
  end
  gb.localmaxima=(max(neighbors,[],2)<gb.maxscores) & (gb.maxscores>scoreth);
  
  gridbins{i}=gb;
  %Bidsnext=Bids;
end



