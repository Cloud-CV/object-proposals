function [windows]=mvg_makeSuperpixelsWindows(superPix,maxNumConnectedSuperpix)

%% Default settings
if nargin<2
    maxNumConnectedSuperpix=3; % Defaults to triplets
end

%% Make sure superpxels are in labeled format
if size(superPix,3)>1
    superPix=mvg_numerizeLabels(superPix);    
end
superPix=double(superPix);

%% Make single superpixel windows
superpixLabels=unique(superPix(:));
windows=zeros(length(superpixLabels),4);
for i=1:length(superpixLabels)
    [rw,cl]=find(superPix==superpixLabels(i));
    windows(i,:)=[min(cl),min(rw),max(cl),max(rw)];
end

%% Make tuplets if needed
if maxNumConnectedSuperpix>1
    
    %% Find neighboring superpixels (4-neighbors)
    neighborLabels=zeros(size(superPix,1),size(superPix,2),4);
    neighborLabels(:,:,1)=[superPix(:,1),superPix(:,1:end-1)]; % left
    neighborLabels(:,:,2)=[superPix(:,2:end),superPix(:,end)]; % right
    neighborLabels(:,:,3)=[superPix(1,:);superPix(1:end-1,:)]; % top
    neighborLabels(:,:,4)=[superPix(2:end,:);superPix(end,:)]; % bottom
    
    %% Find superpixel border pixels
    borderPairs=[neighborLabels(:),repmat(superPix(:),[4,1])];
    superPixNeighbors=unique(sort(borderPairs,2),'rows');
    
    %% Remove single superpixels
    superPixNeighbors(superPixNeighbors(:,1)==superPixNeighbors(:,2),:)=[];
    
    %% Make bounding boxes for all pairs
    numWindowsTuplets=size(superPixNeighbors,1);
    windowsAdd=zeros(numWindowsTuplets,4);
    for i=1:numWindowsTuplets
        [rw,cl]=find(superPix==superPixNeighbors(i,1) | superPix==superPixNeighbors(i,2));
        windowsAdd(i,:)=[min(cl),min(rw),max(cl),max(rw)];
    end
    
    %% Remove multiple windows
    windowsAdd=unique(windowsAdd,'rows');
    
    %% Add windows to existing ones
    windows=[windows;windowsAdd];
    
end

%% Add more connected components if needed
if maxNumConnectedSuperpix>2
    % Make superpixel pair matrix
    superpixelPairsMatrix=zeros(length(superpixLabels),length(superpixLabels));
    superpixelPairsMatrix(superPixNeighbors(:,1)+(superPixNeighbors(:,2)-1)*length(superpixLabels))=1;
    superpixelPairsMatrix=superpixelPairsMatrix+superpixelPairsMatrix';

    % Initialize
    superpixComb=superPixNeighbors;
    
    % Continue to add windows
    for i=3:maxNumConnectedSuperpix
        % Extend combination by one
        superpixComb=extendSupepixComb_(superpixelPairsMatrix,superpixComb);
        
        % Make new windows
        windowsAdd=zeros(size(superpixComb,1),4);
        for j=1:size(superpixComb,1)
            [rw,cl]=find(ismember(superPix,superpixComb(j,:)));
            windowsAdd(j,:)=[min(cl),min(rw),max(cl),max(rw)];
        end
        
        % Remove multiple windows
        windowsAdd=unique(windowsAdd,'rows');
        
        % Add windows to existing ones
        windows=[windows;windowsAdd];
        
    end
    
end

%% Remove any dublicate windows
windows=unique(windows,'rows');








%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Additional functions %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Add new superpixel combination to the existing ones %%%
function [superpixExtComb]=extendSupepixComb_(superpixelPairsMatrix,superpixComb)

%% Initialize
superpixExtComb=[];

%% Loop over existing combination and extend
for i=1:size(superpixComb,1)
    % Find connected superpixels
    connSuperpix=superpixelPairsMatrix(:,superpixComb(i,:));
    connSuperpix=find(sum(connSuperpix,2)>eps);
    connSuperpix=setdiff(connSuperpix,superpixComb(i,:));
    
    % Add connected components to 
    if ~isempty(connSuperpix)
        superpixExtComb=[superpixExtComb; [repmat(superpixComb(i,:),[length(connSuperpix),1]), connSuperpix(:)]];
    end
    
end

%% Remove possible duplicates
superpixExtComb=unique(sort(superpixExtComb,2),'rows');




%%% Numerize superpixel labels %%%
function N = numerizeSuperpixLabels_(S)

% converts the segmentation image S from true-color
% to ordered integer labels
%

N = zeros(size(S,1),size(S,2),'uint16');
col2n = zeros(256,256,256);
totcol = 0;
for x = 1:size(S,2)
    for y = 1:size(S,1)
        p = reshape(S(y,x,:),1,3)+1;
        cix = col2n(p(1),p(2),p(3));
        if cix > 0
          N(y,x) = cix;
        else
          totcol = totcol+1;
          col2n(p(1),p(2),p(3)) = totcol;
          N(y,x) = totcol;
        end
    end
end

% MVG version (faster)
% S=double(S);
% temp=S(:,:,1)+S(:,:,2)*256+S(:,:,3)*256^2;
% lbl=unique(temp(:));
% %lblCode=[lbl,(1:length(lbl))'];
% N=zeros(size(S,1),size(S,2),'uint16');
% for i=1:length(lbl)
%     N(temp==lbl(i))=i;
% end




