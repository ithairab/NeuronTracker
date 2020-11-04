function CutOff = AreaIntensityThreshold(Frame, Area)

% sort pixels and choose threshold to be the Area before last intensity

[m n] = size(Frame);
VFrame = reshape(Frame, m*n, 1);
VFrameSrt = sort(VFrame);
CutOff = double(VFrameSrt(end-round(Area)));
CutOff = CutOff/65535;



% % computes the histogram of Frame and returns the cutoff value of intensity
% % that includes at least the top Area number of pixels
% 
% CutOff = 0;
% CutOffID = [];
% MaxPix = max(max(Frame));
% [counts x] = imhist(Frame);
% TopID = find(x>MaxPix, 1, 'first');
% if ~isempty(TopID)
%     CumCounts = cumsum(counts(TopID:-1:1));
%     CutOffID = find(CumCounts<=Area, 1, 'last');
% end
% if ~isempty(CutOffID)
%     xID = TopID-CutOffID+1;
%     if xID>0
%         CutOff = double(x(TopID-CutOffID+1));
%         CutOff = CutOff/x(end);
%     end
% end
% 
