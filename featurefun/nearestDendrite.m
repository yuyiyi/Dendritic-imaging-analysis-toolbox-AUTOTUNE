function [nearestID, dend_arcloc, dendloc] = nearestDendrite(roi_seed, dendriteROI, handles)

scrsz = handles.scrsz;
im_norm = handles.im_norm;
[d1,d2] = size(im_norm);
r = min(scrsz(3)/3*2/d2, (scrsz(4)-100)/d1)/2;
pos_spine = round([scrsz(3)/3 20 r*d2 r*d1]);
if isempty(findobj('type','figure','number',15))
    pos = pos_spine;    
else
    h1_handles = get(figure(15));
    pos = h1_handles.Position;
end
h1 = figure(15);
cc = colormap(hsv(length(dendriteROI)));
clf('reset')
set(h1,'Name', 'Spine on dendrites','Position', pos);
imshow(im_norm, [quantile(im_norm(:), 0.3), quantile(im_norm(:), 0.99)]);
title('Click on the image to add ROI.')

dend_line_all = []; arc_all = [];
for i = 1:length(dendriteROI)
    if ~isempty(dendriteROI(i).dend_line)
        dend_line = dendriteROI(i).dend_line;
        dC = diff(dend_line,1,1);
        arc = cumsum(sqrt(sum([zeros(1,2); dC].^2,2)));
        dend_line_all = cat(1, dend_line_all, [dend_line, ones(size(dend_line,1),1)*i]);
        arc_all = cat(1, arc_all, arc);
        hold on, plot(dend_line(:,1), dend_line(:,2), 'color', cc(i,:), 'linewidth', 1)
    end
end

nearestID = []; dend_arcloc = []; dendloc = [];
for k = 1:size(roi_seed,1)
    pd = pdist2(roi_seed(k,:), dend_line_all(:,1:2));
    [~, ii] = min(abs(pd));
    id = dend_line_all(ii,3);
    dendloc(k,:) = dend_line_all(ii,1:2);
    dend_arcloc(k) = arc_all(ii);
    nearestID(k) = id;
    hold on, plot(roi_seed(k,1), roi_seed(k,2),'o', 'color', cc(id,:))
    drawnow
end

flag = 0;
while flag == 0
end