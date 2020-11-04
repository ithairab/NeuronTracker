function AnalyzeTrace(handles)

global Trace Flags

if Trace.Flag
    Ind = Trace.Subgroup.ID;
    Fluo = Trace.Data.Fluo;
    Bgrnd = zeros(size(Fluo));
    if isfield(Trace.Data, 'Bgrnd') && Flags.BackgroundSubtract
        Bgrnd = Trace.Data.BgrndRaw;
        if Flags.BackgroundCorrect
            [Bgrnd(1,:) FlickInd1a] = NT_CorrectBgrndFlicker(Bgrnd(1,:),Trace.Param.BackgroundCorrectNBins);
            [Bgrnd(1,:) FlickInd1b] = NT_CorrectBgrndFlicker(Bgrnd(1,:),Trace.Param.BackgroundCorrectNBins);
            FlickInd1 = [FlickInd1a FlickInd1b];
            FlickInd2 = [];
            if Flags.Mode == 1 | Flags.Mode == 3 % Split or Dual
                [Bgrnd(2,:) FlickInd2a] = NT_CorrectBgrndFlicker(Bgrnd(2,:),Trace.Param.BackgroundCorrectNBins);
                [Bgrnd(2,:) FlickInd2b] = NT_CorrectBgrndFlicker(Bgrnd(2,:),Trace.Param.BackgroundCorrectNBins);
                FlickInd2 = [FlickInd2a FlickInd2b];
            end
            if ~isempty(FlickInd1) || ((Flags.Mode == 1 | Flags.Mode == 3) & ~isempty(FlickInd2))
                Trace.Data.Bgrnd = Bgrnd;
                Trace.Data.FlickInd{1} = FlickInd1;
                if Flags.Mode == 1 | Flags.Mode == 3
                    Trace.Data.FlickInd{2} = FlickInd2;
                end
            end
        else
            Trace.Data.Bgrnd = Trace.Data.BgrndRaw;
        end
    else
        Trace.Data.Bgrnd = Bgrnd;
    end
    Fluo = Fluo - Bgrnd;
    switch Flags.Mode
        case {1, 3} % Split or Dual
            Ind1 = Trace.Param.Switch+1;
            Ind2 = 2-Trace.Param.Switch;
            Bleed = Trace.Param.Bleed;
            Fluo(Ind1,:) = Fluo(Ind1,:) - Bleed/100*Fluo(Ind2,:);
            Fluo(Ind2, Fluo(Ind2,:)==0) = NaN;
            Trace.Analyzed.Ratio = Fluo(Ind1,:)./Fluo(Ind2,:);
        case 2 % Single
            Trace.Analyzed.Ratio = Fluo(1,:);% - Fluo(2,:);
    end
    Trace.Analyzed.Ratio = (Trace.Analyzed.Ratio-min(Trace.Analyzed.Ratio))/min(Trace.Analyzed.Ratio)*100;
    dT = 1/Trace.Param.FMS;
    N = Trace.Param.NumFrames;
    Trace.Data.Tmean = 0:dT:(N-1)*dT;
    if isfield(Trace.Param, 'TimeType') && strcmp(Trace.Param.TimeType, 'Stamp')
        Trace.Data.T = Trace.Data.Tstamp;
    else
        Trace.Data.T = Trace.Data.Tmean;
    end
    if isempty(Trace.Axis.Lim0) || Flags.FMS_change || Flags.TimeType_Change || Flags.BackgroundSubtract_Change || Flags.BackgroundCorrect_Change
        Trace.Axis.Lim0 = [min(Trace.Data.T) Trace.Data.T(Trace.Param.LastFrame) min(Trace.Analyzed.Ratio(Ind)) max(Trace.Analyzed.Ratio(Ind))];
        Trace.Axis.Lim = Trace.Axis.Lim0;
    end
    % Find maxima
    Trace.Analyzed.MaximaInd = TraceExtrema(Trace.Analyzed.Ratio);
    % Euclidian displacement
    Trace.Analyzed.Motion = sqrt(diff(Trace.ROI.C_M(:,1)).^2 + diff(Trace.ROI.C_M(:,2)).^2);
    Trace.Analyzed.Motion = [0; Trace.Analyzed.Motion];
    % PCA - first component
    [~, SCORE] = pca(Trace.ROI.C_M);
    Trace.Analyzed.PCA1 = SCORE(:,1);
end

% --------------------------------------------------------------
function extrema = TraceExtrema(y)

Diff1 = diff(y);
pos = find(Diff1 >=0);
pos2 = intersect(pos, pos+1);
pos3 = intersect(pos2, pos2+1);
neg = find(Diff1 < 0);
neg2 = intersect(neg, neg-1);
neg3 = intersect(neg2, neg2-1);
extrema = intersect(neg3, pos3+1) + 1;

% --------------------------------------------------------------
function TraceBaseline(y)



