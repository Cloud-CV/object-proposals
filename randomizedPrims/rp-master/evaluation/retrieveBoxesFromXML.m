function [ground_truth_boxes, labels] = retrieveBoxesFromXML(xml_filename,allowed_categories, forbidden_categories, consider_difficult)

v = xml_load(xml_filename);
labels={};
ground_truth_boxes=[];
bad_image=false;
for k=1:length(v)
  names=vertcat(v(k).object.name);
  xmin = str2num(v(k).object(1).bndbox.xmin);
  xmax = str2num(v(k).object(1).bndbox.xmax);
  ymin = str2num(v(k).object(1).bndbox.ymin);
  ymax = str2num(v(k).object(1).bndbox.ymax);
  w=xmax-xmin;
  h=ymax-ymin;
  xc = uint8((xmin+xmax)*0.5);
  yc = uint8((ymin+ymax)*0.5);
  
  %Check if class (and therefore image) are excluded:
  if numel(forbidden_categories)~=0
    for j=1:numel(forbidden_categories)
      if(strcmp(names,forbidden_categories{j}))
        ground_truth_boxes=[];
        labels=[];
        bad_image=true;
        break;
      end
    end
  end
  
  if (bad_image)
    break;
  end
    
  if(~(str2num(v(k).object(1).difficult) && ~consider_difficult))
    
    %Check if class is allowed:
    if(isempty(allowed_categories))
      %All classes allowed
      labels{numel(labels)+1}=names;
      ground_truth_boxes=[ground_truth_boxes; xmin, ymin, xmax, ymax];
    else
      allowed=false;
      for j=1:numel(allowed_categories)
        if(strcmp(names,allowed_categories{j}))
          labels{numel(labels)+1}=names;
          ground_truth_boxes=[ground_truth_boxes; xmin, ymin, xmax, ymax];
          break;
        end
      end
    end
  end
  
  
end
assert(size(ground_truth_boxes,1)==numel(labels));
end















