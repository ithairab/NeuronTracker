function Result = NT_NeuronFind(Frame, Channel, i, iprev)

global Trace FrameList

Result = 0;
if isfield(Trace, 'Features')
%     if nargin==3
%         iprev=i;
%     end
%     if Channel==1
%         FramePrev = imread(FrameList.FileNames{iprev});
%         FramePrev1 = SplitFrame(FramePrev);
%     else
%         FramePrev1 = Frame;
%     end
    [m, n] = size(Frame);
    AREA = Trace.Features.Area; 
    SUMFRAMEAREA = Trace.Features.SumFrameAreas;
%     WIDTH = Trace.Features.Width; 
%     HEIGHT = Trace.Features.Height; 
%     BWThresh = AreaIntensityThreshold(FramePrev1, SUMFRAMEAREA);
    BWThresh = AreaIntensityThreshold(Frame, SUMFRAMEAREA);
    if BWThresh~=0
        BW = im2bw(Frame, BWThresh);
        if ~all(all(BW)) && any(any(BW)) % BW is not a uniform 0 or 1 (no element, no background)
            [L,NUM] = bwlabel(BW);
            if NUM>0
                STATS = regionprops(L); % Area, Centroid and BoundingBox
                k = 0;
                for j=1:NUM
                    area = STATS(j).Area;
                    if area>0.6*AREA % discard possible stray pixels
                        k=k+1;
                        InInd(k) = j;
                    end
                end
                if k>0
                    Area = zeros(k,1);
                    Box = zeros(k,4);
                    Centroid = zeros(k,2);
                    for j=1:k
                        Area(j) = STATS(InInd(j)).Area;
                        Box(j,:) = STATS(InInd(j)).BoundingBox;
                        Centroid(j,:) = STATS(InInd(j)).Centroid;
                    end
                    NeuronInd = 1;
                    % since everything is moving, dimensions may change, try to
                    % find the object that matches the best with the original
                    % neuron
                    if k>1
                        HCut = find(Box(:,1)<=0 | Box(:,1)+Box(:,3)>=n); % look for objects cut horizontally out of frame
                        VCut = find(Box(:,2)<=0 | Box(:,2)+Box(:,4)>=m); % look for objects cut vertically out of frame
                        [WSrt WSrtInd] = sort(Box(:,3),1,'descend'); % Width
                        [HSrt HSrtInd] = sort(Box(:,4),1,'descend'); % Height
                        [ASrt ASrtInd] = sort(Area,1,'descend'); % Area
                        WHA = Trace.Features.OrderWHA; % dimension order of original neuron (e.g. second widest)
                        WID = WSrtInd(WHA(1)); 
                        HID = HSrtInd(WHA(2)); 
                        AID = ASrtInd(WHA(3));
                        if ~isempty(VCut) % at least one object is out of the frame (top or bottom)
                            NeuronInd = WID; % choose only according to horizontal axis
                        elseif ~isempty(HCut) % at least one object is out of the frame (left or right)
                            NeuronInd = HID; % choose only according to vertical axis
                        elseif WID==HID && HID==AID % the same order for every measure
                            NeuronInd = AID;
                        elseif AID==HID && AID~=WID % something wrong with width
                            NeuronInd = HID; % choose according to height
                        elseif AID==WID && AID~=HID % something wrong with height
                            NeuronInd = WID; % choose according to width
                        end
                    end
                    CENTROID = Centroid(NeuronInd,:);
                    if Channel==1
                        Trace.ROI.C_M(i,:) = CENTROID;
                        Trace.ROI.C_Rect = CENTROID;
                        Trace.ROI.Rect(i,1:2) = [CENTROID(1)-Trace.ROI.Rect(i,3)/2 CENTROID(2)-Trace.ROI.Rect(i,4)/2];
                    else
                        Trace.Offset = CENTROID - Trace.ROI.C_M(i,:);
                    end
                    Result = 1;
                end
            end
        end
    end
end
