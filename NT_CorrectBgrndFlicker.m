function [CorrectedBgrnd FlickInd] = NT_CorrectBgrndFlicker(Bgrnd, NBins)

CorrectedBgrnd = Bgrnd;
FlickInd = [];
DiffBgrnd = diff(Bgrnd);
AbsDiffBgrnd = abs(DiffBgrnd);
[Count BinCntrs] = hist(AbsDiffBgrnd, NBins);
% check if background trace flickers (there should be a clear separation
% between small differences from frame to frame and huge ones, the latter
% being a very small fraction of frame differences)
% Mid = (max(AbsDiffBgrnd) + min(AbsDiffBgrnd))/2;
Mid = BinCntrs(2);
if Count(2)==0
    if Count(1)>Count(NBins)
        FlickInd = find(AbsDiffBgrnd>Mid);
    else
        FlickInd = find(AbsDiffBgrnd<Mid);
    end
    for i = FlickInd
        CorrectedBgrnd(i+1:end) = CorrectedBgrnd(i+1:end) - DiffBgrnd(i);
    end
    
    
%     figure(1)
%     hold off
%     plot(Bgrnd)
%     hold on
%     plot(CorrectedBgrnd, 'r')
%     plot(FlickInd, CorrectedBgrnd(FlickInd), 'g.')
    
    
end
