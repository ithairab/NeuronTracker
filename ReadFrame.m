function [Intensity, bgrnd, Bgrnd, F_ROI_p] = ReadFrame(Frame, ROI, BgrndP)

F_ROI = imcrop(Frame, ROI);
Intensity = sum(sum(F_ROI));
F_ROI_p = F_ROI;
Bgrnd = 0;
bgrnd = [];
if BgrndP>0 && BgrndP<=50
    [ROIm ROIn] = size(F_ROI);
    NumPix = ROIm*ROIn;
    V_F_ROI = reshape(F_ROI, NumPix, 1);
    bgrnd = prctile(V_F_ROI, BgrndP);
    F_ROI_p = F_ROI -bgrnd ;
    Bgrnd = Intensity-sum(sum(F_ROI_p));
    F_ROI_p(F_ROI<=bgrnd) = max(max(F_ROI_p)); % for display purposes
end

