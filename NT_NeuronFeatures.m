function NT_NeuronFeatures(h, Frame, i)

global Trace

% look for the neuron within the ROI (so that closeby background noise is avoided)
F_ROI = imadjust(imcrop(Frame, Trace.ROI.Rect(i,:)));
BWThresh = graythresh(F_ROI);
BW_ROI = im2bw(F_ROI, BWThresh);
[L_ROI,NUM] = bwlabel(BW_ROI);
if NUM>0
    Trace.Features.Flag = 1;
    STATS = regionprops(L_ROI); % Area, Centroid and BoundingBox
    % find the element that is closest to the ROI center of mass
    Centroid = zeros(NUM,2);
    for j=1:NUM
        Centroid(j,:) = STATS(j).Centroid;
    end
    Dist = (Centroid - repmat(0.5*Trace.ROI.Rect(1,3:4), NUM, 1)).^2;
    Dist = sum(Dist,2);
    [minDist NeuronInd] = min(Dist);
    Trace.Features.Area = STATS(NeuronInd).Area;
    Width = STATS(NeuronInd).BoundingBox(3);
    Height = STATS(NeuronInd).BoundingBox(4);
    Trace.Features.Width = Width;
    Trace.Features.Height = Height;
    BBox = [Trace.ROI.C_M(1,1)-Width/2 Trace.ROI.C_M(1,2)-Height/2 Width Height];
    axes(h)
    rectangle('Position', BBox, 'EdgeColor', 'g');

    % check other possible objects in frame (for finding this specific neuron during run)
    F = imadjust(Frame);
    BW = im2bw(F, BWThresh); % use the same threshold used to find the neuron within the ROI
    [L,NUM] = bwlabel(BW);
    STATS = regionprops(L);
%     NeuronInd = 1;
    SumFrameAreas = 0;
    k = 0;
    for j=1:NUM
        area = STATS(j).Area;
        if (area>0.6*Trace.Features.Area) % exclude stray pixels
            k = k+1;
            InInd(k) = j;
            SumFrameAreas = SumFrameAreas+area;
        end
    end
    Trace.Features.SumFrameAreas = SumFrameAreas;
    Centroid = zeros(k,2);
    AllWidths = zeros(k,1);
    AllHeights = zeros(k,1);
    AllAreas = zeros(k,1);
    for j=1:k
        Centroid(j,:) = STATS(InInd(j)).Centroid;
        AllWidths(j) = STATS(InInd(j)).BoundingBox(3);
        AllHeights(j) = STATS(InInd(j)).BoundingBox(4);
        AllAreas(j) = STATS(InInd(j)).Area;
    end
    % find which object is the neuron and determine the order of its
    % dimensions out of all objects in frame
    dCENTROID = sum((Centroid - repmat(Trace.ROI.C_M(1,:), k, 1)).^2,2);
    [mindist neuronind] = min(dCENTROID);
    [AWSrt AWSrtInd] = sort(AllWidths,1,'descend');
    [AHSrt AHSrtInd] = sort(AllHeights,1,'descend');
    [AASrt AASrtInd] = sort(AllAreas,1,'descend');
    AWID = find(AWSrtInd==neuronind); 
    AHID = find(AHSrtInd==neuronind); 
    AAID = find(AASrtInd==neuronind);
    Trace.Features.OrderWHA = [AWID AHID AAID];
    Trace.Features.NumObjects = k;
%     Ind = 1:k; Ind(1) = neuronind; Ind(neuronind) = 1;
%     Trace.Features.AllWidths = Trace.Features.AllWidths(Ind);
%     Trace.Features.AllHeights = Trace.Features.AllHeights(Ind);
%     Trace.Features.AllAreas = Trace.Features.AllAreas(Ind);
else
    Trace.Features.Flag = 0;
end
