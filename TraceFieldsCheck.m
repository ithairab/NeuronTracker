function TraceFieldsCheck

global Trace

% Trace = [];
% Trace.Lost = [];
% Trace.Color = ['y', 'c'];
% Trace.Switch = Switch;
% Trace.Flag = 0;
% Trace.ROI = [];
% Trace.Displ = [0 0 0 0];
% Trace.FMS = 1;
% Trace.TROI = [];

if ~isfield(Trace, 'Axis')
    Trace.Axis.Lim0 = [min(Trace.T) max(Trace.T) min(Trace.Ratio) max(Trace.Ratio)];
    Trace.Axis.Lim = Trace.Axis.Lim0;
end
if ~isfield(Trace, 'Marks')
    Trace.Subgroup.Marks = [];
end
if ~isfield(Trace.ROI, 'Offset')
    Trace.ROI.Offset = Trace.ROI.Displ;
end
% if ~isfield(Trace, 'Skip')
%     Trace.Skip = [];
% end
