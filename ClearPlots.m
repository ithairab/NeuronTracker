function ClearPlots(handles)

axes(handles.axes_Motion)
axis off
cla
axes(handles.axes_Trace1)
axis off
cla
axes(handles.axes_Trace2)
axis off
cla
axes(handles.axes_Ratio)
% axis off
% cla
% axes(handles.axes_ScaleBar)
% axis off
cla
axes(handles.axes_ROI)
axis off
cla
set(handles.text_axes_Ratio, 'String', '');
set(handles.text_axes_Motion, 'String', '');
