function AlignCentroids(Frame, Channel, i, iprev)

global Trace Parameters

if nargin==3
    iprev=i;
end
cont = 1;
Out = 0;
[m n] = size(Frame);
ROI = Trace.ROI.Rect(iprev,:);
if Channel == 2
    ROI = ROI + Trace.ROI.Offset;
end

while cont

    % Centre of Mass
    % --------------
    F_ROIraw = imcrop(Frame, ROI);
%     F_ROI = double(imadjust(F_ROIraw)); % just for tracking, actual intensity is based on raw values
F_ROI = F_ROIraw;
    D = sum(sum(F_ROI));
    if (size(F_ROI') == ROI(3:4)+1) & D~=0
        switch Parameters.TrackModeID
            case 1 % center of mass
                x = 1:ROI(3)+1;
                X = repmat(x, ROI(4)+1, 1);
                C_Mx = ROI(1) + sum(sum(X.*F_ROI))/D; % ROI horizontal centre of mass
                y = 1:ROI(4)+1;
                Y = repmat(y', 1, ROI(3)+1);
                C_My = ROI(2) + sum(sum(Y.*F_ROI))/D; % ROI vertical centre of mass
                C_M = [C_Mx C_My];
            case 2 % maximum
                [mxcol mxcoli] = max(F_ROIraw);
                [mxrow mxrowi] = max(mxcol);
                C_M = [ROI(1)+mxrowi ROI(2)+mxcoli(mxrowi)];
        end
        % Centre of Mass and ROI Centroid Displacement
        % --------------------------------------------
        switch Channel
            case 1
                Trace.ROI.C_M(i,:) = C_M;
                C_Rect = [ROI(1)+ROI(3)/2 ROI(2)+ROI(4)/2];
%                 dC = Trace.ROI.C_M(i,:) - Trace.ROI.C_Rect;
                dC = Trace.ROI.C_M(i,:) - C_Rect;
            case 2
                dC = C_M - (Trace.ROI.C_Rect + Trace.ROI.Offset(1:2));
        end

        % Align ROI Centroid to Centre of Mass
        % ------------------------------------
        ROI(1:2) = ROI(1:2) + dC;
%         ROI(1:2) = ROI(1:2) + SIGN*dC;

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
        switch Channel
            case 1
                Trace.ROI.Rect(i,:) = ROI;
                if ~Out
%                     Trace.ROI.C_Rect = Trace.ROI.C_Rect + dC;
                    Trace.ROI.C_Rect = C_Rect + dC;
                else
                    Trace.ROI.C_Rect = [Trace.ROI.Rect(i,1)+Trace.ROI.Rect(i,3)/2 Trace.ROI.Rect(i,2)+Trace.ROI.Rect(i,4)/2];
                end
            case 2
                if ~Out
                    Trace.ROI.Offset(1:2) = Trace.ROI.Offset(1:2) + dC;
                else
                    Trace.ROI.Offset = ROI - Trace.ROI.Rect(i,:);
                end
        end
        if dC < Parameters.Epsilon | Out
            cont = 0;
        end
    else
        if i>1
            Trace.ROI.C_M(i,:) = Trace.ROI.C_M(iprev,:);
            Trace.ROI.Rect(i,:) = ROI;
        end
        cont = 0;
    end
end

if size(F_ROI') ~= ROI(3:4)+1
    disp(sprintf('i=%g ROI size (AlignCentroids)',i))
end
