function [winscores]=mvg_windowbec_fast(img, windows)

if size(img,3)==3
  if isinteger(img)
    grayimage=double(rgb2gray(img))/255.0;
    img=double(img)/255.0;
  else
    grayimage=0.2989*img(:,:,1)+0.5879*img(:,:,2)+0.1140*img(:,:,3);
  end
else
  grayimage=img;
end

gmagth=0.02;%0.025;
nsubbox=3;
nbin=4; % 4, 6 or 8
binids=1:nbin;
binbounds=[1:2:2*nbin]/(2*nbin)*180;
binbounds=binbounds/180*pi;
bincenters=[0:2:(2*nbin-1)]/(2*nbin)*180;
bincenters=bincenters/180*pi;
binvects=[cos(bincenters);sin(bincenters)];

nr=size(grayimage,1);
nc=size(grayimage,2);
%edgeim=edge(grayimage,'canny');
[X,Y]=meshgrid(1:nc,1:nr);

[gv,Ngv,gvx,gvy]=gaussianderiv1D_(1);
Gx=zeros(nr,nc);
Gy=zeros(nr,nc);
if size(img,3)>1
  for cdim=1:size(img,3)
    Gxc=conv2(gv,gvx,img(:,:,cdim),'same');
    Gindicator=logical(abs(Gxc)>abs(Gx));
    Gx=Gindicator.*Gxc+~Gindicator.*Gx;
    Gyc=conv2(gvy,gv,img(:,:,cdim),'same');
    Gindicator=logical(abs(Gyc)>abs(Gy));
    Gy=Gindicator.*Gyc+~Gindicator.*Gy;
  end
else
  Gx=conv2(gv,gvx,grayimage,'same');%.*edgeim;
  Gy=conv2(gvy,gv,grayimage,'same');%.*edgeim;
end

Gx(1:Ngv,:)=0;Gx((nr-Ngv+1):nr,:)=0;
Gx(:,1:Ngv)=0;Gx(:,(nc-Ngv+1):nc)=0;
Gy(1:Ngv,:)=0;Gy((nr-Ngv+1):nr,:)=0;
Gy(:,1:Ngv)=0;Gy(:,(nc-Ngv+1):nc)=0;


Gmag=sqrt(Gx.^2+Gy.^2);
Gxu=Gx./(Gmag+eps);
Gyu=Gy./(Gmag+eps);

[cedge,cannyth]=edge(grayimage,'canny');
[cedge,cannyth]=edge(grayimage,'canny',0.5*cannyth);

cedgeint=integralimage(double(cedge));

Gvalid=conv2(gv,gv,double(cedge).*(Gmag>gmagth),'same');

Gxvalid=Gx.*Gvalid;
Gyvalid=Gy.*Gvalid;

Gs(:,:,1)=Gxvalid;
Gs(:,:,2)=Gyvalid;
%keyboard
%figure;sc(Gs,'flow');
%keyboard

oribins=zeros(nr,nc,nbin);
tmp=zeros(nr,nc);
gvs=gaussianderiv1D_(1.5);
oribinintim=zeros(nr,nc,nbin);
for i=1:nbin
  tmp=Gmag.*Gvalid.*reshape(abs([Gxu(:) Gyu(:)]*binvects(:,i)),nr,nc);
  tmp=conv2(gvs,gvs,tmp,'same');
  oribins(:,:,i)=tmp;
  %oribinintim(:,:,i)=integralimage(tmp);
  %figure;sc(tmp);
end
oribinsum=sum(oribins,3);
oribinsummax=max(oribinsum(:));
oribins=oribins/oribinsummax;
oribinsum=oribinsum/oribinsummax;
for i=1:nbin
  oribinintim(:,:,i)=integralimage(oribins(:,:,i));
  %figure;sc(tmp);
end

wincx=0.5*(windows(:,1)+windows(:,3));
wincy=0.5*(windows(:,2)+windows(:,4));
nw=size(windows,1);

%for i=1:4
  winhists=zeros(2*nsubbox,nbin,2*nsubbox);
  winhistsums=zeros(2*nsubbox,2*nsubbox);
%end

winscores=zeros(nw,1);
winareas=zeros(nw,1);
nedgepixels=zeros(nw,1);

onesv=ones(2*nsubbox+1,1);
onesh=ones(1,2*nsubbox+1);

subboxind=1:(2*nsubbox);
intersection=0;
suma=0;sumb=0;

BoxWeights=[ones(1,6); 1 0.5*ones(1,4) 1; 1 0.5 0 0 0.5 1];
BoxWeights=[BoxWeights;flipud(BoxWeights)];
BoxIndices=[2 3*ones(1,4) 4; 1 2 3 3 4 1; 1 1 2 4 1 1;1 1 4 2 1 1; ...
	    1 4 3 3 2 1; 4 3*ones(1,4) 2];

winscores=bescores(windows,oribinintim,nbin,nsubbox,BoxWeights,BoxIndices);
%fprintf('BE scores computed in C \n');
if 0
for i=1:nw
  %fprintf('%d / %d \n',i,nw);
  xa=windows(i,1);ya=windows(i,2);
  xb=windows(i,3);yb=windows(i,4);
  xaa=max(1,xa-1);yaa=max(1,ya-1);
  
  wi=xb-xa+1;
  hi=yb-ya+1;
  winareas(i,1)=wi*hi;
  if wi<(2*nsubbox) | hi<(2*nsubbox)
    continue;
  end
  
  xs=[-0.5:1/(2*nsubbox):0.5]*wi;
  ys=[-0.5:1/(2*nsubbox):0.5]*hi;
  xsr=ceil(xs+wincx(i));
  ysr=ceil(ys+wincy(i))';
  
  Xstart=max(1,onesv*xsr-1);
  Ystart=max(1,ysr*onesh-1);
  
 
  for j=subboxind
    for k=subboxind
      for l=binids
	winhists(j,l,k)=oribinintim(Ystart(j+1,k+1),Xstart(j+1,k+1),l)+oribinintim(Ystart(j,k),Xstart(j,k),l)-oribinintim(Ystart(j+1,k),Xstart(j+1,k),l)-oribinintim(Ystart(j,k+1),Xstart(j,k+1),l);
      end    
      winhistsum(j,k)=sum(winhists(j,:,k));
    end
  end
  
  for j=1:(2*nsubbox)
    for k=1:(2*nsubbox)
      winscores(i,1)=winscores(i,1)+BoxWeights(j,k)*winhists(j,BoxIndices(j,k),k);
    end
  end
  

end
end
winscoremax=max(winscores);
winscores=(winscores./winscoremax);
%winscoremaxtmp=max(winscorestmp);
%winscorestmp=(winscorestmp./winscoremaxtmp);

%keyboard
%%%%%%%%%%%%%%%%%%%%%%%%
% Additional functions %
%%%%%%%%%%%%%%%%%%%%%%%%

function [g,N,gx,gy]=gaussianderiv1D_(sigma,N)

if nargin<2
  N=4*sigma+1;
end

% make sure that N is odd
N=2*floor(N/2)+1;
sigma2=sigma^2;

t=1:N;
mu=(N-1)/2+1;
g=1/(sqrt(2*pi)*sigma)*exp(-0.5*(t-mu).^2/sigma2);
gx=-(t-mu)/sigma2.*g;
gy=gx';

