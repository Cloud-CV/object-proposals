function drawBoxes(boxes,base_color,linewidth)
% boxes=[xmin ymin xmax ymax scoreObjectness]

if nargin < 3
    linewidth = 3;
end

if nargin < 2
    base_color = [1 0 0];%red
end

boxes = sortrows(boxes,5);
    
maxscore = max(boxes(:,5));
for idx = 1:size(boxes,1)
    xmin = boxes(idx,1);
    ymin = boxes(idx,2);
    xmax = boxes(idx,3);
    ymax = boxes(idx,4);
    score = boxes(idx,5);
    %score = min(score*5,1);
    
    color = base_color*score/maxscore;
    
    %draw left line
    line([xmin xmin],[ymin ymax],'Color',color,'Linewidth',linewidth);
    
    %draw right line
    line([xmax xmax],[ymin ymax],'Color',color,'Linewidth',linewidth);
    
    %draw top line
    line([xmin xmax],[ymin ymin],'Color',color,'Linewidth',linewidth);
    
    %draw bottom line
    line([xmin xmax],[ymax ymax],'Color',color,'Linewidth',linewidth);
end
