function PlotROI(h, Channel, i)

global Trace

axes(h)
% plot ROI and Centre of Mass
if size(Trace.ROI.Rect,1)>=i && Trace.ROI.Rect(i,3) && Trace.ROI.Rect(i,4)
    % No displacement for Channel 1
    Offset = [0 0 0 0];
    Cstr = 'y';
%     if nargin>3 && Channel == 2
    if Channel == 2
        Offset = Trace.ROI.Offset;
        Cstr = 'c';
    end
    rectangle('Position', Trace.ROI.Rect(i,:) + Offset, 'EdgeColor', Cstr);
    plot(Trace.ROI.C_M(i,1) + Offset(1), Trace.ROI.C_M(i,2) + Offset(2), 'r+')
end

