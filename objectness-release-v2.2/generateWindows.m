function windows = generateWindows(img,optionGenerate,params,cue)  


[height width ~] = size(img);


switch optionGenerate
    
    case 'uniform'
        
        totalSamples = params.distribution_windows;
        min_width = params.min_window_width;
        min_height = params.min_window_height;
        
        xmin = zeros(totalSamples,1);
        ymin = zeros(totalSamples,1);
        xmax = zeros(totalSamples,1);
        ymax = zeros(totalSamples,1);
        
        for j = 1:totalSamples
            x1 = round(rand(1)*(width-1)+1);
            x2 = round(rand(1)*(width-1)+1);
            while(abs(x1-x2)+1<min_width) %
                x1=round(rand(1)*(width-1)+1);
                x2=round(rand(1)*(width-1)+1);
            end
            
            y1=round(rand(1)*(height-1)+1);
            y2=round(rand(1)*(height-1)+1);
            while(abs(y1-y2)+1<min_height) %
                y1=round(rand(1)*(height-1)+1);
                y2=round(rand(1)*(height-1)+1);
            end
            xmin(j)=min(x1,x2);
            ymin(j)=min(y1,y2);
            xmax(j)=max(x1,x2);
            ymax(j)=max(y1,y2);
        end
                      
        windows = [xmin ymin xmax ymax];
        
    case 'dense' %for SS or ED
        
        pixelDistance = params.(cue).pixelDistance;
        imageBorder = params.(cue).imageBorder;
        
        offsetHeight = floor(imageBorder * height);
        offsetWidth  = floor(imageBorder * width);
        
        height = floor(height * (1 - imageBorder)/pixelDistance);
        width  = floor(width  * (1 - imageBorder)/pixelDistance);
        
        totalWindows = height*width * (height+1) * (width+1)/4;
        
        xmin = zeros(totalWindows,1);
        xmax = zeros(totalWindows,1);
        ymin = zeros(totalWindows,1);
        ymax = zeros(totalWindows,1);
        
        currentWindow = 0;
                
        for x = 1:width
            for y = 1:height
                for w = 1:width - x + 1
                    for h = 1:height - y + 1
                        currentWindow = currentWindow+1;
                        xmin(currentWindow) = x;
                        ymin(currentWindow) = y;
                        xmax(currentWindow) = x + w - 1;
                        ymax(currentWindow) = y + h - 1;
                    end
                end
            end
        end
        
        xmin = xmin * pixelDistance + offsetWidth;
        xmax = xmax * pixelDistance + offsetWidth;
        ymin = ymin * pixelDistance + offsetHeight;
        ymax = ymax * pixelDistance + offsetHeight;
                 
        windows = [xmin ymin xmax ymax];        
        

    otherwise
        error('optionGenerate unknown')
end