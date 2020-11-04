function TrackStep(handles, i)

global Flags Parameters Trace FrameList

if Parameters.MacroID == 4
    Frame1Name = FrameList.FileNames{i};
    Nch1 = str2num(Frame1Name(end-4));
    Frame1 = imread(Frame1Name);
    Frame2Name = [Frame1Name(1:end-5) num2str(Nch1+1) Frame1Name(end-3:end)];
    Frame2 = imread(Frame2Name);
else
    if Parameters.MacroID == 5
        Frame = read(FrameList.FileNames,i);
        RGB = strfind(FrameList.FileNames.VideoFormat, 'RGB');
        if ~isempty(RGB)
            Frame = rgb2gray(Frame);
        end
    elseif Parameters.MacroID == 6
        Frame = FrameList.FileNames(:,:,1,i);
    elseif Parameters.MacroID == 7
        Frame = imread(FrameList.FileNames(1).Filename,i);
    elseif Parameters.MacroID == 8 % dual model
        k = (i-1)*2*Trace.Param.Fields.NumFields + Trace.Param.Fields.FieldID;
        Frame2 = imread(FrameList.FileNames{1},k);
        Frame1 = imread(FrameList.FileNames{1},k+Trace.Param.Fields.NumFields);
    elseif Parameters.MacroID == 9 % AVI two separate channels
        Frame1 = rgb2gray(FrameList.FileNames.Red(i).cdata);
        Frame2 = rgb2gray(FrameList.FileNames.Green(i).cdata);
    elseif Parameters.MacroID == 10 % Zeiss Zen czi file
        % 6D array: series, timepoint, zplane, channel, X, Y
% for now, just one plane and one channel
        Frame = squeeze(FrameList.FileNames(i,:,:));
    else
        Frame = imread(FrameList.FileNames{i});
    end
    if Flags.Mode == 1 % Split
        [Frame1, Frame2] = SplitFrame(Frame); % Split
    end
end
if isfield(Trace.Param, 'BgrndPrcntile')
    BgrndP = Trace.Param.BgrndPrcntile;
else
    BgrndP = 0;
end
if Flags.Run || Flags.EditManual
    if Parameters.ShowFrame
        switch Flags.Mode
            case {1, 3} % Split or Dual
                PlotFrame(handles.axes_frame1, Frame1, 1); % Plot Channel 1
                PlotFrame(handles.axes_frame2, Frame2, 1); % Plot Channel 2
            case 2 % Single
                PlotFrame(handles.axes_single, Frame, 1); % Plot single channel
        end
    end
    if Flags.Manual
        switch Flags.Mode
            case {1, 3} % Split or Dual
                PlotROI(handles.axes_frame1, 1, i)
                PlotROI(handles.axes_frame2, 2, i)
                ManualTrack(handles.axes_frame1, Frame1, 1, i);
            case 2 % Single
                PlotROI(handles.axes_single, 1, i)
                PlotROI(handles.axes_single, 2, i)
                ManualTrack(handles.axes_single, Frame, 1, i);
        end
    else
        switch Flags.Mode
            case {1, 3} % Split or Dual
                AlignCentroids(Frame1, 1, i, Trace.Log.LastGoodRectID);
            case 2 % Single
                AlignCentroids(Frame, 1, i, Trace.Log.LastGoodRectID);
        end
    end
    switch Flags.Mode
        case {1, 3} % Split or Dual
            [Intensity1 bgrnd1 Bgrnd1] = ReadFrame(Frame1, Trace.ROI.Rect(i,:),BgrndP);
            [Intensity2 bgrnd2 Bgrnd2] = ReadFrame(Frame2, Trace.ROI.Rect(i,:) + Trace.ROI.Offset,BgrndP);
        case 2 % Single
            [Intensity1 bgrnd1 Bgrnd1] = ReadFrame(Frame, Trace.ROI.Rect(i,:),BgrndP);
            [Intensity2 bgrnd2 Bgrnd2] = ReadFrame(Frame, Trace.ROI.Rect(i,:) + Trace.ROI.Offset,BgrndP);
    end
    Trace.Data.Fluo(1,i) = Intensity1;
    Trace.Data.Bgrnd(1,i) = Bgrnd1;
    Trace.Data.Fluo(2,i) = Intensity2;
    Trace.Data.Bgrnd(2,i) = Bgrnd2;
    Trace.Param.Bgrnd = [bgrnd1 bgrnd2];
    % compute conditions for loss of track or bad frame
    if Flags.Search
        [CondI CondCM CM1 CM2] = NT_CheckFrame(Frame1, Frame2, i);
    % check whether neuron is tracked, lost or frame is bad
        if (i>1)
            Skipped = 0;
            Found = 0;
            NotFound = 0;
            BadFrame = 0;
            % tracking lost
            if ~CondCM % Pixel intensity at center of mass is closer to backbround than to previous intensity
                Result = NT_NeuronFind(Frame1, 1, i, Trace.Log.LastGoodIntensityID);
                switch Result
                    case 1 % neuron found
                        [Intensity1 bgrnd1 Bgrnd1] = ReadFrame(Frame1, Trace.ROI.Rect(i,:), BgrndP);
                        Trace.Data.Fluo(1,i) = Intensity1;
                        Trace.Data.Bgrnd(1,i) = Bgrnd1;
                        [Intensity2 bgrnd2 Bgrnd2] = ReadFrame(Frame2, Trace.ROI.Rect(i,:) + Trace.ROI.Offset,BgrndP);
                        Trace.Data.Fluo(2,i) = Intensity2;
                        Trace.Data.Bgrnd(2,i) = Bgrnd2;
                        Trace.Log.NeuronFound = [Trace.Log.NeuronFound i];
                        Found = 1;
                        % check, after finding the neuron, if frame is good
                        [CondI CondCM CM1 CM2] = NT_CheckFrame(Frame1, Frame2, i);
                        if ~CondI % intensity too low => bad frame
                            BadFrame = 1;
                        end
                    case 0 % neuron not found
                        Trace.Log.NeuronNotFound = [Trace.Log.NeuronNotFound i];
                        NotFound = 1;
                end
            end
            % bad frame (CM should be good but I not)
            if ((Found==0 && NotFound==0) && CondCM && ~CondI) || BadFrame
                NT_SkipFrame(handles);
                Skipped = 1;
            end
            if ~NotFound
                Trace.Log.LastGoodRectID = i;
                if ~Skipped && ~BadFrame
                    Trace.Log.LastGoodIntensityID = i;
                    Trace.Log.LastGoodCM = [CM1 CM2];
                end
            end
        end
    else
        Trace.Log.LastGoodRectID = i;
    end
    if Parameters.ShowFrame
        switch Flags.Mode
            case {1, 3} % Split or Dual        
                PlotROI(handles.axes_frame1, 1, i)
                PlotROI(handles.axes_frame2, 2, i)
            case 2 % Single
                PlotROI(handles.axes_single, 1, i)
                PlotROI(handles.axes_single, 2, i)
        end
    end
    if Parameters.MacroID ~= 6
        NT_GetAndorTimeStamp(i);
    end
else
    if (Flags.SetROI || Flags.ShowROI) && ~isempty(Trace.ROI.Rect) && Trace.ROI.Rect(i,3) && Trace.ROI.Rect(i,4)
        switch Flags.Mode
            case {1, 3} % Split or Dual
                AlignCentroids(Frame1, 1, i);
                AlignCentroids(Frame2, 2, i);
                if ~isempty(Trace.ROI.Rect) && Trace.ROI.Rect(i,3) && Trace.ROI.Rect(i,4)
                    [Intensity, bgrnd1, Bgrnd, F_ROI_p] = ReadFrame(Frame1, Trace.ROI.Rect(i,:),BgrndP);
                    [Intensity, bgrnd2] = ReadFrame(Frame1, Trace.ROI.Rect(i,:),BgrndP);
                end
            case 2 % Single
                AlignCentroids(Frame, 1, i);
                [Intensity, bgrnd1, Bgrnd, F_ROI_p] = ReadFrame(Frame, Trace.ROI.Rect(i,:),BgrndP);
                [Intensity, bgrnd2] = ReadFrame(Frame, Trace.ROI.Rect(i,:),BgrndP);
        end
        Trace.Param.Bgrnd = [bgrnd1 bgrnd2];
        PlotFrame(handles.axes_ROI, F_ROI_p, 0);
    end
    switch Flags.Mode
        case {1, 3} % Split or Dual
            PlotFrame(handles.axes_frame1, Frame1, 1); % Plot Channel 1
            PlotFrame(handles.axes_frame2, Frame2, 1); % Plot Channel 2
            if ~isempty(Trace.ROI.Rect) && Trace.ROI.Rect(i,3) && Trace.ROI.Rect(i,4)
                [~, ~, ~, F_ROI_p] = ReadFrame(Frame1, Trace.ROI.Rect(i,:),BgrndP);
                PlotFrame(handles.axes_ROI, F_ROI_p, 0);
            end
        case 2 % Single
            PlotFrame(handles.axes_single, Frame, 1);
    end
    if (Flags.SetROI || Flags.ShowROI) && ~isempty(Trace.ROI.Rect) && Trace.ROI.Rect(i,3) && Trace.ROI.Rect(i,4)
        switch Flags.Mode
            case {1, 3} % Split or Dual
                NT_NeuronFeatures(handles.axes_frame1, Frame1, i); % get ROI neuron area, bounding box and centroid as well as BW threshold
            case 2 % Single
                NT_NeuronFeatures(handles.axes_single, Frame, i); % get ROI neuron area, bounding box and centroid as well as BW threshold
        end
    end
    if Flags.ROITight && ~isempty(Trace.ROI.Rect) && Trace.ROI.Rect(i,3) && Trace.ROI.Rect(i,4)
        switch Flags.Mode
            case {1, 3} % Split or Dual
                NT_NeuronFind(Frame1, 1, i);
                NT_NeuronFind(Frame2, 2, i);
            case 2 % Single
                NT_NeuronFind(Frame, 1, i);
        end
    end
    switch Flags.Mode
        case {1, 3} % Split or Dual
            PlotROI(handles.axes_frame1, 1, i)
            PlotROI(handles.axes_frame2, 2, i)
        case 2 % Single
            PlotROI(handles.axes_single, 1, i)
            PlotROI(handles.axes_single, 2, i)
    end
end
if ~isfield(Trace.Param, 'Resolution') || isempty(Trace.Param.Resolution)
    switch Flags.Mode
        case {1, 3} % Split or Dual
            Trace.Param.Resolution = size(Frame1);
        case 2 % Single
            Trace.Param.Resolution = size(Frame);
    end
end

   