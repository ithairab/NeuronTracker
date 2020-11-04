function ManualTrack(h, Frame, Channel, i)

global Flags Trace

k = waitforbuttonpress;
if k % keypad has been pressed
    Flags.Stop = 1;
else % mouse button has been pressed
    [m n] = size(Frame);
    Point = get(h, 'CurrentPoint');
    j = i;
    if i>1 && ~Flags.EditManual
        j = i-1;
    end
    ROI = Trace.ROI.Rect(j,:);
    switch Channel
        case 1
            Trace.ROI.C_M(i,:) = [Point(1,1); Point(1,2)];
            Trace.ROI.Rect(i,1) = Trace.ROI.C_M(i,1) - Trace.ROI.Rect(i,3)/2;
            Trace.ROI.Rect(i,2) = Trace.ROI.C_M(i,2) - Trace.ROI.Rect(i,4)/2;
            ROI = Trace.ROI.Rect(i,:);
        case 2
            ROI = Trace.ROI.Rect(i,:) + Trace.ROI.Displ;
    end
    % Check that ROI is completely within the frame
    % ---------------------------------------------
    if ROI(1)<1
        Out = 1;
        ROI(1) = 1;
    end
    if ROI(2)<1
        Out = 1;
        ROI(2) = 1;
    end
    if ROI(1)+ROI(3)>n
        Out = 1;
        ROI(1) = n-ROI(3);
    end
    if ROI(2)+ROI(4)>m
        Out = 1;
        ROI(2) = m-ROI(4);
    end

end
