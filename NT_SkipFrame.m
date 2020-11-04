function NT_SkipFrame(handles)

global Trace FrameList

i = get(handles.listbox_Frames, 'Value');
ID = Trace.Subgroup.ID(i);
[check ind] = ismember(ID, Trace.Subgroup.ID);
if check
    Trace.Subgroup.ID = setdiff(Trace.Subgroup.ID, ID);
    Trace.Subgroup.IDSkipped = [Trace.Subgroup.IDSkipped ID];
    Trace.Subgroup.IDSkipped = sort(Trace.Subgroup.IDSkipped);
    FrameList.ID = Trace.Subgroup.ID;
    FrameList.IDSkipped = Trace.Subgroup.IDSkipped;
    Trace.Param.LastFrame = Trace.Param.LastFrame-1;
    iskp = find(Trace.Subgroup.IDSkipped == ID);
    set(handles.listbox_Frames, 'String', FrameList.Display(FrameList.ID));
    set(handles.listbox_Frames, 'Value', min(length(FrameList.ID), i));
    set(handles.listbox_FramesSkipped, 'String', FrameList.Display(FrameList.IDSkipped));
    set(handles.listbox_FramesSkipped, 'Value', iskp);
end
