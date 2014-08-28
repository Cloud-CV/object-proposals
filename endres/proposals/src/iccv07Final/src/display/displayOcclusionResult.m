function displayOcclusionResult(im, bndinfo, objlab, edgelab, contact, fignum)
% lim = displayOcclusionResult(im, bndinfo, objlab, edgelab, contact, fignum)
%
% Displays occlusion result
%
% Input:
%   im:      double RGB image
%   bndinfo: structure that stores region and boundary info (and labels)
%   objlab:  not used (set to empty)
%   edgelab: (0, 1, 2) for off, left/right occludes (empty if result is
%            stored in bndinfo)
%   contact: set if vertical-ground contact lines are to be drawn
%   fignum:  number of figure to display in


if isempty(edgelab)
    try
        edgelab = bndinfo.edges.boundaryType;
        edgelab = edgelab(1:end/2) + 2*edgelab(end/2+1:end);    
    catch
        edgelab = [];
    end
end
  
try close(fignum); catch end;   
iptsetpref('ImshowBorder', 'tight');    
mag = min(640/max(bndinfo.imsize)*100, 100);
iptsetpref('ImshowInitialMagnification', mag)
figure(fignum), imshow(im)
plotOcclusionBoundariesWithContact(bndinfo, edgelab, contact);



