function [CondI CondCM CM1 CM2] = NT_CheckFrame(Frame1, Frame2, i)

% check sharp drops in inensity indicating loss of track or bad frame

global Trace

% center of mass intensity
[m n] = size(Frame1);
x = round(Trace.ROI.C_M(i,1)); y = round(Trace.ROI.C_M(i,2));
CM1 = impixel([1 n],[1 m], Frame1, x, y); % pixel intensity at center of mass
CM1 = CM1(1);
x = x+Trace.ROI.Offset; y = y+Trace.ROI.Offset;
CM2 = impixel([1 n],[1 m], Frame2, x, y); % pixel intensity at center of mass
CM2 = CM2(1);
if i==1
    Trace.Log.LastGoodCM = [CM1 CM2];
    CondI = 1; % Intensity check
    CondCM = 1; % Center of Mass check
else
    % difference between putative neuron and background intensity
    dIB1 = abs(Trace.Data.Fluo(1,i)-Trace.Data.Bgrnd(1,i));
    dIB2 = abs(Trace.Data.Fluo(2,i)-Trace.Data.Bgrnd(2,i));
    % difference between putative neuron and last confirmed neuron intensity
    dIF1 = abs(Trace.Data.Fluo(1,i)-Trace.Data.Fluo(1,Trace.Log.LastGoodIntensityID));
    dIF2 = abs(Trace.Data.Fluo(2,i)-Trace.Data.Fluo(2,Trace.Log.LastGoodIntensityID));
    % difference between putative center of mass and background intensity
    dCM_IB1 = abs(CM1-Trace.Param.Bgrnd(1));
    dCM_IB2 = abs(CM2-Trace.Param.Bgrnd(2));
    % difference between putative center of mass and last confirmed center of mass intensity
    dCM_IF1 = abs(CM1-Trace.Log.LastGoodCM(1));
    dCM_IF2 = abs(CM2-Trace.Log.LastGoodCM(2));
    % Comparisons between background and last confirmed neuron
    CondI = (dIB1>dIF1 && dIB2>dIF2); % Intensity check
    CondCM = (dCM_IB1>dCM_IF1 && dCM_IB2>dCM_IF2); % Center of Mass check
end
