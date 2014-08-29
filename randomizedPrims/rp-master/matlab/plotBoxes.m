function plotBoxes(boxes, color, scores, lineStyle)
hold on;
if(strcmp(color,'random'))
 hues=rand(size(boxes,1));
end
for i=1:size(boxes,1)
    
    xmin=boxes(i,1);
    ymin=boxes(i,2);
    xmax=boxes(i,3);
    ymax=boxes(i,4);
    
    if(strcmp(color,'random'))
      c=hsv2rgb(hues(i),1,1);
    else
      c=color;
    end
    plot([xmin xmax xmax xmin xmin],[ymin ymin ymax ymax ymin],'Color',color,'LineWidth',3,'LineStyle',lineStyle);
    
    if(size(scores))
        text(xmin,ymin,num2str(scores(i)),'BackgroundColor',color);
    end
end

end
