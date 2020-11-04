function NT_TraceStamp

% special function for updating existing computed traces with a time stamp
% user should open the relevant tiff directory and load the trace

global Trace FrameList

if isfield(Trace.Data, 'Tstamp')
    errordlg('Trace already contains a time stamp');
else
    for i = 1:numel(FrameList.FileNames)
        NT_GetAndorTimeStamp(i);
    end
    Trace.Data.Tmean = Trace.Data.T;
    if strcmp(Trace.Param.TimeType, 'stamp')
        Trace.Data.T = Trace.Data.Tstamp;
    else
        Trace.Data.T = Trace.Data.Tmean;
    end
end
