function ResetTrace

global Trace Flags Parameters

% if isempty(Trace)
%     Switch = 1;
% else
%     Switch = Trace.Param.Switch;
% end
if Flags.Run
    if Parameters.MacroID ~= 6 & Parameters.MacroID ~= 7 & Parameters.MacroID ~= 8
        Trace.Data.T = [];
        Trace.Data.Tmean = zeros(1, Trace.Param.NumFrames);
        Trace.Data.Tstamp = zeros(1, Trace.Param.NumFrames);
    end
    Trace.Data.Fluo = zeros(2, Trace.Param.NumFrames);
    Trace.Data.Bgrnd = [];
    Trace.Data.BgrndRaw = [];
%     if isfield(Trace.Data, 'BgrndRaw')
%         Trace.Data = rmfield(Trace.Data,'BgrndRaw');
%     end
    Trace.Log.NeuronFound = [];
    Trace.Log.NeuronNotFound = [];
    Trace.Log.LastGoodIntensityID = 1;
    Trace.Log.LastGoodRectID = 1;
    Trace.ROI.Rect = [Trace.ROI.Rect(1,:); zeros(Trace.Param.NumFrames-1, 2) repmat(Trace.ROI.Rect(1,3:4),Trace.Param.NumFrames-1,1)];
    Trace.ROI.C_M = [Trace.ROI.C_M(1,:); zeros(Trace.Param.NumFrames-1, 2)];
    Trace.Analyzed.Ratio = zeros(1, Trace.Param.NumFrames);
    Trace.Analyzed.Motion = zeros(1, Trace.Param.NumFrames);
    Trace.Subgroup.ID = 1:Trace.Param.NumFrames;
    Trace.Subgroup.IDSkipped = [];
    Trace.Param.TrackMode = Parameters.TrackModeList{Parameters.TrackModeID};
else
    Trace = [];
    Trace.Compat = 3; % Minimum version of compatibility
    Trace.Flag = 0;
    Trace.Mode = 'Single'; % 1 = Split, 2 = Single, 3= Dual
    Trace.Param.NumFrames = 0;
    Trace.Param.LastFrame = 0;
    Trace.Param.FMS = Parameters.FMS;
    Trace.Param.NumAvgFrames = 1;
    Trace.Param.Bleed = Parameters.Bleed;
    Trace.Param.Switch = Flags.Switch;
    Trace.Param.Color = Parameters.TraceColor;
    Trace.Param.BgrndPrcntile = 10;
    Trace.Param.BackgroundCorrect = Flags.BackgroundCorrect;
    Trace.Param.BackgroundCorrectNBins = Parameters.BackgroundCorrectNBins;
    Trace.Param.TimeType = 'Mean';
    Trace.ROI.Rect = [];
    Trace.ROI.C_M = [];
    Trace.ROI.Offset = [0 0 0 0];
    Trace.Subgroup.Lost = [];
    Trace.Param.Comment = '';
end
Trace.Axis.Lim0 = [];
Trace.Axis.Lim = [];
Trace.Axis.Rect = [];
Trace.Subgroup.Marks = [];
Trace.Subgroup.IDSkipped = [];