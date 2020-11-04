function varargout = NeuronTracker3(varargin)
% Last Modified by GUIDE v2.5 28-Nov-2017 12:50:16

% ***********************************************************************
% transition between directories and traces being loaded (make sure all is
% cleared so that a new image list can be loaded

% Quit function

% baseline extraction for percentage calculation and bleaching correction

% add isfield(Trace, '') checks so that loaded traces missing a field will
% not return errors

% add a structure called Parameters and save it so that parameters are
% maintained when application is opened

% finish the frames/fps component
% ***********************************************************************

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @NeuronTracker3_OpeningFcn, ...
                   'gui_OutputFcn',  @NeuronTracker3_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before NeuronTracker3 is made visible.
function NeuronTracker3_OpeningFcn(hObject, eventdata, handles, varargin)
global DefaultPath HomePath
global Flags Parameters
global Trace GUI_ROI ScaleBar
global GuiHandle
GuiHandle = hObject;
DefaultPath = '/Users/ithairabinowitch/Data/Imaging/';
HomePath = fileparts(get(hObject, 'FileName'));
Flags = [];
Flags.MovieStop = 0;
Flags.Run = 0;
Flags.Stop = 0;
Flags.Search = 0;
Flags.EditManual = 0;
Flags.SetROI = 0;
Flags.ShowROI = 0;
Flags.DataCursorMode = 0;
Flags.FMS_change = 0;
Flags.TimeType_Change=0;
Flags.Manual = 0;
Flags.ROITight = 0;
Flags.Mode = 2; % 1 = Split (one frame split in two), 2 = Single, 3 = dual (two cameras)
Flags.BackgroundSubtract = 0;
Flags.BackgroundSubtract_Change = 0;
Flags.BackgroundCorrect = 0;
Flags.BackgroundCorrect_Change = 0;
Flags.ManualContrast = 0;
Flags.Switch = 1; % switch red and green (or yellow and cyan)
Parameters = [];
Parameters.ShowFrame = 0;
Parameters.Epsilon = 1;
Parameters.ROITight = 200;
% Parameters.FileFilter = '*.tif';
Parameters.FileFilter = '*.*';
Parameters.ImageMode = {'Split', 'Single', 'Dual'};
Parameters.TrackModeID = 1;
Parameters.TrackModeList = {'MassCenter', 'Maximum'};
Parameters.Contrast.Top = 255;
Parameters.Contrast.Bottom = 0;
Parameters.BackgroundCorrectNBins = 5;
Parameters.Bleed = 0;%0.8;
Parameters.FMS = 1;% 5
Parameters.TraceColor = ['g', 'r'];
Parameters.MacroID = 10;
Parameters.MacroList = {'single tifs', '3 Folder','Fast LZ', '2 photon', 'AVI', 'Mat', 'tif sequence', 'tiff Z dual', 'AVI r/G', 'ZEN'};
% Parameters.Experiment.Prompts = {'Objective (e.g. 63X W)', 'ND Filter (e.g. 2.0)',...
%     'Intensity (e.g. -2 notches)', 'Orientation (e.g. head/tail first)', 'Num Eggs (e.g. 9+1, ?)',...
%     'Previous Trace same worm (time)'};
Parameters.Experiment.Prompts = {'Objective (e.g. 63X W)', 'ND Filter (e.g. 2.0)',...
    'Intensity (e.g. 10%)', 'Orientation (e.g. head/tail first)', 'Num Eggs (e.g. 9+1, ?)',...
    'Previous Trace same worm (time)'};
Parameters.Experiment.ParamList = {'Objective', 'NDFilter', 'Intensity', 'Orientation', 'NumEggs', 'PrevTrace'};
Parameters.Experiment.Defaults = {'63X Oil', 'NA', '60/255', 'Head', '-', ''};
Parameters.Experiment.Values = [];
Parameters.PathName = DefaultPath;
Trace = [];
ResetTrace;
Mode_Reconfigure(handles);
GUI_ROI = [];
GUI_ROI.Flag1 = 0;
GUI_ROI.hrect1 = 0;
GUI_ROI.API1 = 0;
GUI_ROI.Flag2 = 0;
GUI_ROI.hrect2 = 0;
GUI_ROI.API2 = 0;
set(handles.pushbutton_Stop, 'Enable', 'off');
set(handles.text_Ch1, 'ForegroundColor', Parameters.TraceColor(Flags.Switch+1))
set(handles.text_Ch2, 'ForegroundColor', Trace.Param.Color(2-Flags.Switch))
set(handles.listbox_Frames, 'Value', 1);
set(handles.listbox_Macros, 'Value', Parameters.MacroID);
set(handles.listbox_Macros, 'String', Parameters.MacroList);
set(handles.popupmenu_TrackMode, 'Value', Parameters.TrackModeID);
set(handles.popupmenu_TrackMode, 'String', Parameters.TrackModeList);
set(handles.popupmenu_Mode, 'String', Parameters.ImageMode, 'Value', Flags.Mode);
set(handles.edit_Filter, 'String', Parameters.FileFilter);
set(handles.edit_Epsilon, 'String', num2str(Parameters.Epsilon));
set(handles.edit_ROITight, 'String', num2str(Parameters.ROITight));
set(handles.radiobutton_ShowFrame, 'Value', Parameters.ShowFrame);
set(handles.radiobutton_Manual, 'Value', Flags.Manual);
set(handles.radiobutton_TrackSearch, 'Value', Flags.Search);
set(handles.pushbutton_PlotTrace, 'Enable', 'off');
set(handles.radiobutton_BackgroundSubtract, 'Value', Flags.BackgroundSubtract);
set(handles.radiobutton_BackgroundCorrect, 'Value', Flags.BackgroundCorrect);
% set(handles.edit_BackgroundPercentile, 'Enable', 'off');
set(handles.edit_NumFields, 'String', '1');
set(handles.popupmenu_FieldID, 'String', '1');
set(handles.axes_frame1, 'ButtonDownFcn',...
    {@Mouse_axes_frame1_Callback, handles.axes_frame1, eventdata})
% set(handles.popupmenu_TimeType, 'String', {'Stamp' 'Mean'});
set(handles.popupmenu_TimeType, 'String', {'Mean' 'Stamp'});
set(handles.popupmenu_TimeType, 'Value', 2);
set(handles.slider_ContrastTop, 'Min', 0, 'Max', 255, 'Value', Parameters.Contrast.Top)
set(handles.slider_ContrastBottom, 'Min', 0, 'Max', 255, 'Value', Parameters.Contrast.Bottom)
set(handles.togglebutton_ManualContrast, 'Value', Flags.ManualContrast);
set(handles.edit_BackgroundCorrectNBins, 'String', num2str(Parameters.BackgroundCorrectNBins));
set(handles.edit_Bleed, 'String', num2str(Parameters.Bleed));
if Flags.ManualContrast
    set(handles.slider_ContrastTop, 'Enable', 'on')
    set(handles.slider_ContrastBottom, 'Enable', 'on')
else
    set(handles.slider_ContrastTop, 'Enable', 'off')
    set(handles.slider_ContrastBottom, 'Enable', 'off')
end
linkaxes([handles.axes_frame1; handles.axes_frame2]);
axes(handles.axes_frame1)
axis off
axes(handles.axes_frame2)
axis off
axes(handles.axes_single)
axis off
axes(handles.axes_ROI)
axis off
axes(handles.axes_Motion)
axis off
axes(handles.axes_Trace1)
axis off
axes(handles.axes_Trace2)
axis off
axes(handles.axes_Ratio)
% axis off
% axes(handles.axes_ScaleBar)
% axis off
% ScaleBar = [];
% ScaleBar.X = 50;
% set(handles.axes_ScaleBar, 'Units', 'points');
set(handles.axes_Ratio, 'Units', 'points');
% ScaleBar.Position = get(handles.axes_ScaleBar, 'Position');
% ScaleBar.Ratio_Position = get(handles.axes_Ratio, 'Position');
% ScaleBar.XFactor = ScaleBar.Position(3)/ScaleBar.Ratio_Position(3);
% ScaleBar.YFactor = ScaleBar.Position(4)/ScaleBar.Ratio_Position(4);
set(handles.edit_FMS, 'String', num2str(Trace.Param.FMS));
% OpenDir_Callback(handles.OpenMovie, eventdata, handles);

% Choose default command line output for NeuronTracker3
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes NeuronTracker3 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = NeuronTracker3_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% ========================================================================


% Mode (Dual or Single)
% ---------------------

function popupmenu_Mode_Callback(hObject, eventdata, handles)
global Flags Trace
if ~Trace.Flag
    Flags.Mode = get(hObject, 'Value');
    Mode_Reconfigure(handles);
end
function popupmenu_Mode_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Mode: 1 = split, 2 = single, 3 = dual
function Mode_Reconfigure(handles)
global Flags Trace
switch Flags.Mode
    case 1
        Trace.Mode = 'Ratio';
        axes(handles.axes_single); cla;
        set(handles.pushbutton_Switch, 'visible', 'on')
        set(handles.text_Ch1, 'visible', 'on')
        set(handles.text_Ch2, 'visible', 'on')
    case 2
        Trace.Mode = 'Difference';
        axes(handles.axes_frame1); cla;
        axes(handles.axes_frame2); cla;
        set(handles.pushbutton_Switch, 'visible', 'off')
        set(handles.text_Ch1, 'visible', 'off')
        set(handles.text_Ch2, 'visible', 'off')
    case 3
        Trace.Mode = 'Ratio';
        axes(handles.axes_single); cla;
        set(handles.pushbutton_Switch, 'visible', 'on')
        set(handles.text_Ch1, 'visible', 'on')
        set(handles.text_Ch2, 'visible', 'on')
end
if Trace.Param.NumFrames > 0
    TrackStep(handles, Trace.Subgroup.ID(1));
end

% ========================================================================

% File Selection
% --------------

function File_Callback(hObject, eventdata, handles)
function Open_Callback(hObject, eventdata, handles)

function OpenFile_Callback(hObject, eventdata, handles)

function OpenMovie_Callback(hObject, eventdata, handles)
global Parameters Trace Flags
% Parameters.PathName = uigetdir(Parameters.PathName, 'Select Movie Directory');
if Parameters.MacroID==5
    [Parameters.FileName Parameters.PathName] = uigetfile('*.avi', 'Select movie avi file');
elseif Parameters.MacroID==6
    [Parameters.FileName Parameters.PathName] = uigetfile('*.mat', 'Select movie mat file');
elseif Parameters.MacroID==7
    [Parameters.FileName Parameters.PathName] = uigetfile('*.tif*', 'Select tiff stack file');
elseif Parameters.MacroID==8
    [Parameters.FileName Parameters.PathName] = uigetfile('*.tif*', 'Select tiff stack file');
    Flags.Mode = 3;
    set(handles.popupmenu_Mode,'Value',Flags.Mode);
elseif Parameters.MacroID==9
    [Parameters.FileName Parameters.PathName] = uigetfile('*.avi', 'Select red AVI file');
    Flags.Mode = 3;
    set(handles.popupmenu_Mode,'Value',Flags.Mode);
elseif Parameters.MacroID==10
    [Parameters.FileName Parameters.PathName] = uigetfile('*.czi', 'Select ZEN czi file');
else
    Parameters.PathName = uigetdir('Select Movie Directory');
    Parameters.FileName = [];
end
if Parameters.PathName ~= 0
    set(handles.listbox_Frames, 'String', {});
    Flags.BackgroundCorrect = 0;
    set(handles.radiobutton_BackgroundCorrect, 'Value', Flags.BackgroundCorrect);
    cd(Parameters.PathName);
    Parameters.SubName = '';
    Parameters.ResultPath = '';
    IndSubName = findstr(filesep, Parameters.PathName);
    if ~isempty(IndSubName)
        SubName = Parameters.PathName(IndSubName(end)+1:end);
        Parameters.SubName = SubName;
        Parameters.ResultPath = fullfile(Parameters.PathName(1:IndSubName(end)-1),'Results');
        if ~isdir(Parameters.ResultPath)
            mkdir(Parameters.ResultPath);
        end
    end
    ResetTrace;
    Mode_Reconfigure(handles);
    ClearPlots(handles);
    set(handles.listbox_Frames, 'Value', 1);
    % Check how many simultaneous fields were recorded
    Trace.Param.Fields.NumFields = 1;
    Trace.Param.Fields.FieldID = 0;
    % previous Andor-specific information
    NumFieldsXY = AndorRecord('RepeatXY', '\t%f');
    NumFieldsZ = AndorRecord('RepeatZ', '\t%f');
    if ~isempty(NumFieldsXY)
        Trace.Param.Fields.NumFields = NumFieldsXY{1};
        Trace.Param.Fields.Type = 'xy';
    elseif ~isempty(NumFieldsZ)
        Trace.Param.Fields.NumFields = NumFieldsZ{1};
        Trace.Param.Fields.Type = 'z';
    end
    % new tiff Z information is extracted here:
    if Parameters.MacroID==8
        Trace.Param.imfinfo = imfinfo(Parameters.FileName);
        TIFFz = NT_ExtractTIFFinfo(Trace.Param.imfinfo);
        Trace.Param.TIFFz = TIFFz;
        Trace.Param.Fields.NumFields = TIFFz.Znum;
        Trace.Param.Fields.Type = 'z';
        set(handles.popupmenu_FieldID, 'String', cellstr(num2str(1:TIFFz.Znum)));
    end
    set(handles.edit_NumFields, 'String', Trace.Param.Fields.NumFields);
    edit_NumFields_Callback(handles.edit_NumFields, eventdata, handles);
    popupmenu_FieldID_Callback(handles.popupmenu_FieldID, eventdata, handles);
    set(handles.text_Pathname, 'String', [Parameters.PathName Parameters.FileName]);
    pushbutton_ResetFMS_Callback(handles.pushbutton_ResetFMS, eventdata, handles);
    NumAvgFrames = 1;
    FramesAveraged = AndorRecord('Use Frame averaging', '=%s');
    if ~isempty(FramesAveraged) && ~isempty(strmatch('Checked',FramesAveraged{1}))
        NumAvgFrames = AndorRecord('Frames to be averaged', '=%f');
        Trace.Param.NumAvgFrames = NumAvgFrames{1};
    end
    EMGain = AndorRecord('Gains - EMGain', '=%f');
    if ~isempty(EMGain)
        Trace.Param.EMGain = EMGain{1};
    end
    set(handles.text_NumAvgFrames,'String', sprintf('%.0f frame(s) averaged', NumAvgFrames));
    set(handles.edit_BackgroundPercentile, 'String', num2str(Trace.Param.BgrndPrcntile));
    set(handles.edit_Comment, 'String', '');
%     load gong.mat
%     sound(y,Fs)
    if Parameters.MacroID~=10
        ExpParam_Callback(handles.ExpParam, eventdata, handles);
    end
end

function ExpParam_Callback(hObject, eventdata, handles)
global Parameters Trace
Parameters.Experiment.Values = inputdlg(Parameters.Experiment.Prompts, 'Experiment Parameters', 1, ...
    Parameters.Experiment.Defaults);
NumExpParam = numel(Parameters.Experiment.Values);
for i=1:NumExpParam
    eval(sprintf('Trace.Param.Experiment.%s = Parameters.Experiment.Values{i};', Parameters.Experiment.ParamList{i}));
    Parameters.Experiment.Defaults{i} = Parameters.Experiment.Values{i};
end

% find the files that match the filter and recognize their type
function edit_Filter_Callback(hObject, eventdata, handles)
global Trace Parameters FrameList Flags
Parameters.FileFilter = get(hObject, 'String');
FrameList.FileNames = MacroRead;
FrameList.Display = [];
if Parameters.MacroID == 5
    NumFrame0 = FrameList.FileNames.NumberOfFrames; % for AVI files
    for i=1:NumFrame0
        FrameList.Display{i} = sprintf('Frame %g', i);
    end
elseif Parameters.MacroID == 6 % mat file
    NumFrame0 = size(FrameList.FileNames, 4);
    MaxNumDigits = ceil(log10(NumFrame0+1));
    MaxTimeDigits = ceil(log10(Trace.Data.Tstamp(end)+1));
    for i=1:NumFrame0
        FrameList.Display{i} = sprintf('Frame %1$0*2$g - %3$0*4$.2f sec', i, MaxNumDigits, Trace.Data.Tstamp(i), MaxTimeDigits);
    end
elseif Parameters.MacroID == 7 % tiff stack
    NumFrame0 = numel(FrameList.FileNames);
    [~,fname] = fileparts(Parameters.FileName);
    for i=1:NumFrame0
        FrameList.Display{i} = sprintf('%s_%g', fname, i);
    end
elseif Parameters.MacroID == 8 % tiff Z stack
    NumFrame0 = Trace.Param.TIFFz.Fnum;
    [~,fname] = fileparts(Parameters.FileNames);
    for i=1:NumFrame0
        FrameList.Display{i} = sprintf('%s_%g', fname, i);
    end
elseif Parameters.MacroID == 9 % AVI g/r
    NumFrame0 = numel(FrameList.FileNames.Red);
    [~,fname] = fileparts(Parameters.FileName);
    for i=1:NumFrame0
        FrameList.Display{i} = sprintf('%s_%g', fname, i);
    end
elseif Parameters.MacroID == 10 % ZEN zci file
    NumFrame0 = size(FrameList.FileNames,1);
    [~,fname] = fileparts(Parameters.FileName);
    for i=1:NumFrame0
        FrameList.Display{i} = sprintf('%s_%g', fname, i);
    end
else
    FrameList.Display = FrameList.FileNames;
end
%------------------------------------------------------------
% adjust time index so that they are all of equal length
% otherwise frames do not show up in order (e.g. 10000 < 9999)
TimeLen = 0;
flag_hetero = 0;
NumFrame0 = numel(FrameList.Display);
ind_t = zeros(NumFrame0,1);
timelen = zeros(NumFrame0,1);
if flag_hetero
    for i=1:NumFrame0
        dTimeLen = TimeLen-timelen(i);
        if dTimeLen>0
            Zpad = [];
            for j=1:dTimeLen
                Zpad = [Zpad '0'];
            end
            FrameList.Display{i} = [FrameList.Display{i}(1:(ind_t(i)+1)), Zpad, FrameList.Display{i}((ind_t(i)+2):end)];
        end
    end
    [FrameList.Display srtind] = sort(FrameList.Display);
    FrameList.FileNames = FrameList.FileNames(srtind);
end
%------------------------------------------------------------
FrameList.ID = 1:NumFrame0;
FrameList.IDSkipped = [];
set(handles.listbox_FramesSkipped, 'String', FrameList.Display(FrameList.IDSkipped));
FrameNum = length(FrameList.ID);
if FrameNum > 1
    set(handles.listbox_Frames, 'String', FrameList.Display(FrameList.ID));
    Trace.Param.NumFrames = FrameNum;
    Trace.Subgroup.ID = FrameList.ID;
    set(handles.listbox_Frames, 'Value',1);
    TrackStep(handles, Trace.Subgroup.ID(1));
    if isfield(Trace.Param, 'Fields') && Trace.Param.Fields.NumFields > 1
        if ~isfield(Trace.Param, 'TIFFz')
            FieldIDInd = strfind(FrameList.FileNames{1}, '.tif')-1;
            if FieldIDInd>0
                FieldID = str2num(FrameList.FileNames{1}(FieldIDInd))+1;
            end
            Trace.Param.Fields.FieldID = FieldID;
            set(handles.popupmenu_FieldID, 'Value', FieldID);
            Parameters.TraceName = [Parameters.SubName sprintf('_Field%1.0f_',FieldID)];
        end
    else
        Parameters.TraceName = Parameters.SubName;
    end
end
function edit_Filter_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_NumFields_Callback(hObject, eventdata, handles)
global Trace
NF = str2num(get(hObject, 'String'));
if NF>0 && isfield(Trace.Param, 'Fields') && NF>=Trace.Param.Fields.FieldID
    Trace.Param.Fields.NumFields = NF;
    set(handles.popupmenu_FieldID, 'Value', 1, 'String', num2str((1:NF)'));
else
    set(hObject, 'String', num2str(Trace.Param.Fields.NumFields));
end
if NF == 1
    Parameters.FileFilter = '*.tif';
    set(handles.edit_Filter, 'String', Parameters.FileFilter);
end
function edit_NumFields_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function popupmenu_FieldID_Callback(hObject, eventdata, handles)
global Trace Parameters
FID = get(hObject, 'Value');
Trace.Param.Fields.FieldID = FID;
if Trace.Param.Fields.NumFields > 1
    Parameters.FileFilter = sprintf('*%1.0f.tif', FID-1);
    set(handles.edit_Filter, 'String', Parameters.FileFilter);
end    
edit_Filter_Callback(handles.edit_Filter, eventdata, handles)
function popupmenu_FieldID_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function listbox_Frames_Callback(hObject, eventdata, handles)
global Trace
i = get(handles.listbox_Frames, 'Value');
if i<=length(Trace.Subgroup.ID)
    ID = Trace.Subgroup.ID(i);
    if Trace.Flag
        pushbutton_PlotTrace_Callback(handles.pushbutton_PlotTrace, eventdata, handles);
        axes(handles.axes_Ratio)
        hold on
        plot(Trace.Data.T(ID),Trace.Analyzed.Ratio(ID),'.r');
        axes(handles.axes_Trace1)
        hold on
        plot(Trace.Data.T(ID),Trace.Data.Fluo(1,ID),'.r');
        axes(handles.axes_Trace2)
        hold on
        plot(Trace.Data.T(ID),Trace.Data.Fluo(2,ID),'.r');
    end
else
    Ind = setdiff(1:Trace.Param.NumFrames, Trace.Subgroup.IDSkipped);
    ID = Ind(i);
end    
TrackStep(handles, ID);
function listbox_Frames_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function SavePanel_Callback(hObject, eventdata, handles)
% global GuiHandle
global Trace
[FileName, PathName] = uiputfile({'*.ai';'*.tif';'*.jpg'}, 'Save Panel', 'Panel');
FullFileName = [PathName, FileName];
if FileName ~= 0
%     h = guihandles;
%     h = gcf;
%     saveas(h.figure1, FullFileName);
%    hgsave(GuiHandle, FullFileName);
%     hgsave(FullFileName);
    ExpFigH = figure;
%     set(ExpFigH, 'HandleVisibility', 'off');
    plot(Trace.Ratio);
    saveas(ExpFigH, FullFileName);
    close(ExpFigH)
end

function SaveParameters
global Parameters
save([HomePath, 'Parameters'], '-struct', 'Parameters');

function Quit_Callback(hObject, eventdata, handles)
Confirm = questdlg('Exit Matlab?');
if strcmp(upper(Confirm), 'YES')
    exit
end
% ========================================================================

% User Neuron Select
% ------------------

function Mouse_axes_frame1_Callback(hObject, eventdata)
disp('OK')


function pushbutton_Zoom_Callback(hObject, eventdata, handles)
global Flags
if ~Flags.Run
    zoom;
end

function pushbutton_ROI1_Callback(hObject, eventdata, handles)
global Flags GUI_ROI Trace
if ~Flags.Run
    zoom off
    if ~GUI_ROI.Flag1
        if isempty(Trace.ROI.Rect)
            rect0 = [];
        else
            rect0 = Trace.ROI.Rect(1,:);
        end
        if Flags.Mode == 1 | Flags.Mode == 3 % Split or dual
            haxes = handles.axes_frame1;
        elseif Flags.Mode == 2 % Single
            haxes = handles.axes_single;
        end
        GUI_ROI.hrect1 = imrect(haxes, rect0);
        GUI_ROI.API1 = iptgetapi(GUI_ROI.hrect1);
        GUI_ROI.Flag1 = 1;
        fcn = makeConstrainToRectFcn('imrect',...
             get(haxes,'XLim'),get(haxes,'YLim'));
        GUI_ROI.API1.setDragConstraintFcn(fcn);
    end
end


function pushbutton_ROI2_Callback(hObject, eventdata, handles)
global Flags GUI_ROI Trace
if ~Flags.Run && ~GUI_ROI.Flag2
    if isempty(Trace.ROI.Rect)
        errordlg('Please select ROI1 before ROI2', 'ROI1 not selected');
    else
        rect0 = Trace.ROI.Rect(1,:) + Trace.ROI.Offset;
        if Flags.Mode == 1 | Flags.Mode == 3 % Split or Dual
            haxes = handles.axes_frame2;
        elseif Flags.Mode == 2 % Single
            haxes = handles.axes_single;
        end
        GUI_ROI.hrect2 = imrect(haxes, rect0);
        GUI_ROI.API2 = iptgetapi(GUI_ROI.hrect2);
        GUI_ROI.API2.setResizable(0);
        GUI_ROI.Flag2 = 1;
        fcn = makeConstrainToRectFcn('imrect',...
             get(haxes,'XLim'),get(haxes,'YLim'));
        GUI_ROI.API2.setDragConstraintFcn(fcn);
    end
end


function pushbutton_Set_Callback(hObject, eventdata, handles)
global Flags Trace GUI_ROI FrameList
if ~Flags.Run
    if GUI_ROI.Flag1
        Trace.ROI.Rect(1,:) = GUI_ROI.API1.getPosition();
        GUI_ROI.API1.delete();
        GUI_ROI.Flag1 = 0;
        Trace.ROI.C_Rect = [Trace.ROI.Rect(1,1)+Trace.ROI.Rect(1,3)/2 Trace.ROI.Rect(1,2)+Trace.ROI.Rect(1,4)/2];
        Trace.ROI.Rect(1,:) = round(Trace.ROI.Rect(1,:));
        Trace.ROI.C_Rect = round(Trace.ROI.C_Rect);

        Flags.SetROI = 1;
    end
    if GUI_ROI.Flag2
        ROI2 = GUI_ROI.API2.getPosition();
        Trace.ROI.Offset = ROI2 - Trace.ROI.Rect(1,:);
        GUI_ROI.API2.delete();
        GUI_ROI.Flag2 = 0;  
    end
    i = get(handles.listbox_Frames, 'Value');
    ID = Trace.Subgroup.ID(i);
    TrackStep(handles, ID);
    Flags.SetROI = 0;
    FrameList.ID = 1:Trace.Param.NumFrames;
    FrameList.IDSkipped = [];
    Trace.Subgroup.ID = FrameList.ID;
    Trace.Subgroup.IDSkipped = FrameList.IDSkipped;
    set(handles.listbox_Frames, 'Value', 1);
    set(handles.listbox_Frames, 'String', FrameList.Display);
    set(handles.listbox_FramesSkipped, 'Value', 1);
    set(handles.listbox_FramesSkipped, 'String', FrameList.Display(FrameList.IDSkipped));
end


function pushbutton_ROITight_Callback(hObject, eventdata, handles)
global Trace Flags Parameters
if isfield(Trace, 'Features')
    Trace.ROI.Rect(1,3) = round(Trace.Features.Width * Parameters.ROITight/100);
    Trace.ROI.Rect(1,4) = round(Trace.Features.Height * Parameters.ROITight/100);
    i = get(handles.listbox_Frames, 'Value');
    ID = Trace.Subgroup.ID(i);
    Flags.ROITight = 1;
    TrackStep(handles, ID);
    Flags.ROITight = 0;
end

function edit_ROITight_Callback(hObject, eventdata, handles)
global Trace Flags Parameters
v = str2num(get(hObject, 'String'));
if v>=100 && v==round(v)
    Parameters.ROITight = v;
    pushbutton_ROITight_Callback(handles.pushbutton_ROITight, eventdata, handles);
else
    set(hObject, 'String', num2str(Parameters.ROITight));
end
function edit_ROITight_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_Epsilon_Callback(hObject, eventdata, handles)
global Flags Parameters
if ~Flags.Run
    Epsilon = str2num(get(hObject, 'String'));
    if Epsilon > 0
        Parameters.Epsilon = Epsilon;
    end
end
function edit_Epsilon_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_BackgroundPercentile_Callback(hObject, eventdata, handles)
global Trace FrameList Flags
Bgrnd = str2num(get(hObject, 'String'));
if Bgrnd>=0 && Bgrnd<=50
    Trace.Param.BgrndPrcntile = Bgrnd;
    Flags.ShowROI = 1;
    i = get(handles.listbox_Frames, 'Value');
    ID = Trace.Subgroup.ID(i);
    TrackStep(handles, ID);
    Flags.ShowROI = 0;
else
    if isfield(Trace, 'Param') && isfield(Trace.Param, 'BgrndPrcntile')
        set(hObject, 'String', Trace.Param.BgrndPrcntile);
    else
        set(hObject, 'String', '');
    end
end
function edit_BackgroundPercentile_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% ========================================================================

% Run
% ---
function popupmenu_TrackMode_Callback(hObject, eventdata, handles)
global Parameters
Parameters.TrackModeID = get(hObject, 'Value');
function popupmenu_TrackMode_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function radiobutton_ShowFrame_Callback(hObject, eventdata, handles)
global Parameters
Parameters.ShowFrame = get(hObject, 'Value');

function radiobutton_TrackSearch_Callback(hObject, eventdata, handles)
global Flags Trace
Flags.Search = get(hObject, 'Value');
Trace.Param.TrackSearch = Flags.Search;

function pushbutton_Go_Callback(hObject, eventdata, handles)
global Trace Flags Parameters
CheckROI = 1-isempty(Trace.ROI);
if CheckROI
    i = get(handles.listbox_Frames, 'Value');
    Trace.Subgroup.ID = 1:Trace.Param.NumFrames;
    if ~isempty(Trace.Subgroup.IDSkipped)
        Trace.Subgroup.ID = setdiff(Trace.Subgroup.ID, Trace.Subgroup.IDSkipped);
        if i<=length(Trace.Subgroup.ID)
            ID = Trace.Subgroup.ID(i);
            RunInd = Trace.Subgroup.ID(Trace.Subgroup.ID>=ID);
        end
        if ID>1
            Confirm = questdlg('Are you sure you want to start running from this frame?');
            PreRunInd = setdiff(Trace.Subgroup.ID, RunInd);
        else
            Confirm = 'Yes';
            PreRunInd = [];
        end
    else
        ID = i;
        RunInd = ID:Trace.Param.NumFrames;
        if ID>1
            Confirm = questdlg('Are you sure you want to start running from this frame?');
            PreRunInd = 1:ID-1;
        else
            Confirm = 'Yes';
            PreRunInd = [];
        end
    end
    if strcmpi(Confirm, 'yes')
        if ~Flags.Run
            Flags.Run = 1;
            set(hObject, 'String', 'Running');
            set(handles.pushbutton_Stop, 'Enable', 'on');
            set(handles.File, 'Enable', 'off');
            set(handles.listbox_Frames, 'Enable', 'off');
            set(handles.pushbutton_PlotTrace, 'Enable', 'off');
            if ID==1
                ResetTrace;
            else
                Trace.Flag = 0;
            end
            ClearPlots(handles);
%             for i = 1:Trace.Param.NumFrames
            k = 0;
            for i = RunInd
                k = k+1;
                NumSkipped = length(Trace.Subgroup.IDSkipped);
                set(handles.listbox_Frames, 'Value', i-NumSkipped);
                TrackStep(handles, i);
                if Flags.Stop
                    Flags.Stop = 0;
                    break;
                end
            end
            Flags.Run = 0;
            Trace.Flag = 1;
            Trace.Param.LastFrame = i;
            if Parameters.MacroID ~= 6 & Parameters.MacroID ~= 7 & Parameters.MacroID ~= 8
    %             Trace.Data.Tmean = Trace.Data.Tmean(1:Trace.Param.LastFrame);
    %             Trace.Data.Tstamp = Trace.Data.Tstamp(1:Trace.Param.LastFrame);
                Trace.Data.Tmean = [Trace.Data.Tmean(PreRunInd) Trace.Data.Tmean(RunInd(1:k))];
                Trace.Data.Tstamp = [Trace.Data.Tstamp(PreRunInd) Trace.Data.Tstamp(RunInd(1:k))];
                if strcmp(Trace.Param.TimeType, 'stamp')
                    Trace.Data.T = Trace.Data.Tstamp;
                else
                    Trace.Data.T = Trace.Data.Tmean;
                end
            end
%             Trace.Data.Fluo = Trace.Data.Fluo(:,1:Trace.Param.LastFrame);
            Trace.Data.Fluo = [Trace.Data.Fluo(:,PreRunInd) Trace.Data.Fluo(:,RunInd(1:k))];
            Trace.Data.Bgrnd = [Trace.Data.Bgrnd(:,PreRunInd) Trace.Data.Bgrnd(:,RunInd(1:k))];
            Trace.Data.BgrndRaw = Trace.Data.Bgrnd;
%             Trace.Subgroup.ID = Trace.Subgroup.ID(Trace.Subgroup.ID<=Trace.Param.LastFrame);
            Trace.Subgroup.ID = [Trace.Subgroup.ID(PreRunInd) Trace.Subgroup.ID(RunInd(1:k))];
            set(handles.pushbutton_PlotTrace, 'Enable', 'on');
            set(handles.edit_FMS, 'Enable', 'on');
            set(hObject, 'String', 'Go', 'Value', 0);
            set(handles.pushbutton_Stop, 'Enable', 'off');
            set(handles.File, 'Enable', 'on');
            set(handles.listbox_Frames, 'Enable', 'on');
            set(handles.pushbutton_PlotTrace, 'Enable', 'on');
            if Parameters.MacroID == 2
                Trace.Subgroup.Marks = Parameters.Macro2.Mark;
            end
            if Parameters.MacroID == 3
                Trace.Subgroup.Marks = Parameters.Macro3.Mark;
            end
            AnalyzeTrace(handles);
            PlotTrace(handles);
        end
    else
        errordlg('Please select an ROI before running', 'ROI not selected');
    end
end

function pushbutton_Stop_Callback(hObject, eventdata, handles)
global Flags
Flags.Stop = 1;
disp('Stop')


function pushbutton_Switch_Callback(hObject, eventdata, handles)
global Flags Trace Parameters
if ~Flags.Run
    Flags.Switch = 1-Flags.Switch;
    Trace.Param.Switch = Flags.Switch;
    set(handles.text_Ch1, 'ForegroundColor', Parameters.TraceColor(Flags.Switch+1))
    set(handles.text_Ch2, 'ForegroundColor', Trace.Param.Color(2-Flags.Switch))
    if Trace.Flag
        AnalyzeTrace;
        PlotTrace(handles)
    end
end

% ========================================================================

% Manual
% ------

function radiobutton_Manual_Callback(hObject, eventdata, handles)
global Flags Parameters
Flags.Manual = get(hObject, 'Value');
if Flags.Manual
    set(handles.radiobutton_ShowFrame, 'Value', 1);
    Parameters.ShowFrame = 1;
end

% edit an ROI after manual tracking
function pushbutton_Edit_Callback(hObject, eventdata, handles)
global Flags Trace FrameList
i = get(handles.listbox_Frames, 'Value');
ID = Trace.Subgroup.ID(i);
if Trace.ROI.Rect(ID,3) && Trace.ROI.Rect(ID,4)
    Flags.EditManual = 1;
    Manual = Flags.Manual;
    Flags.Manual = 1;
    TrackStep(handles, ID);
    Flags.Manual = Manual;
    Flags.EditManual = 0;
    if i<length(Trace.Subgroup.ID)
        i=i+1;
    end
    set(handles.listbox_Frames, 'Value', i);
    Trace.Axis.Lim0(4) = max(Trace.Analyzed.Ratio(Trace.Subgroup.ID));
    pushbutton_PlotTrace_Callback(handles.pushbutton_PlotTrace, eventdata, handles);
    listbox_Frames_Callback(handles.listbox_Frames, eventdata, handles);
else
%     errordlg()
end

function listbox_FramesSkipped_Callback(hObject, eventdata, handles)
global Trace
iskp = get(handles.listbox_FramesSkipped, 'Value');
IDskp = Trace.Subgroup.IDSkipped(iskp);
TrackStep(handles, IDskp);
if Trace.Flag
    pushbutton_PlotTrace_Callback(handles.pushbutton_PlotTrace, eventdata, handles);
    axes(handles.axes_Ratio)
    hold on
    plot(Trace.Data.T(IDskp),Trace.Analyzed.Ratio(IDskp),'+r');
end
function listbox_FramesSkipped_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pushbutton_Skip_Callback(hObject, eventdata, handles)
global Trace Flags
NT_SkipFrame(handles);
if ~Flags.Run
    Trace.Axis.Lim0(4) = max(Trace.Analyzed.Ratio(Trace.Subgroup.ID));
    pushbutton_PlotTrace_Callback(handles.pushbutton_PlotTrace, eventdata, handles);
end

function pushbutton_UnSkip_Callback(hObject, eventdata, handles)
global Trace FrameList
s = length(Trace.Subgroup.IDSkipped);
if s>0
    iskp = get(handles.listbox_FramesSkipped, 'Value');
    IDskp = Trace.Subgroup.IDSkipped(iskp);
    [check ind] = ismember(IDskp, Trace.Subgroup.IDSkipped);
    if check
        Trace.Subgroup.IDSkipped = setdiff(Trace.Subgroup.IDSkipped, IDskp);
        Trace.Subgroup.ID = [Trace.Subgroup.ID IDskp];
        Trace.Subgroup.ID = sort(Trace.Subgroup.ID);
        i = find(Trace.Subgroup.ID == IDskp);
        FrameList.ID = Trace.Subgroup.ID;
        FrameList.IDSkipped = Trace.Subgroup.IDSkipped;
%         Trace.Param.LastFrame = Trace.ParamLastFrame+1;
        Trace.Axis.Lim0(4) = max(Trace.Analyzed.Ratio(Trace.Subgroup.ID));
        s = s-1;
        if s>1 && iskp>1
            set(handles.listbox_FramesSkipped, 'Value', iskp-1);
        else
            set(handles.listbox_FramesSkipped, 'Value', 1);
        end
        set(handles.listbox_Frames, 'Value', i);
        set(handles.listbox_Frames, 'String', FrameList.Display(FrameList.ID));
        set(handles.listbox_FramesSkipped, 'String', FrameList.Display(FrameList.IDSkipped));
        pushbutton_PlotTrace_Callback(handles.pushbutton_PlotTrace, eventdata, handles);
    end
end

function pushbutton_FramesUnskipAll_Callback(hObject, eventdata, handles)
global Trace FrameList
button = questdlg('Are you sure you want to unskip all skipped frames?','Unskip All');
if button
    i = get(handles.listbox_Frames, 'Value');
    ID = Trace.Subgroup.ID(i);
    Trace.Subgroup.ID = sort([Trace.Subgroup.ID Trace.Subgroup.IDSkipped]);
    Trace.Subgroup.IDSkipped = [];
    FrameList.ID = Trace.Subgroup.ID;
    FrameList.IDSkipped = Trace.Subgroup.IDSkipped;
    Trace.Axis.Lim0(4) = max(Trace.Analyzed.Ratio);
    i = find(Trace.Subgroup.ID == ID);
    set(handles.listbox_Frames, 'Value', i);
    set(handles.listbox_Frames, 'String', FrameList.Display(FrameList.ID));
    set(handles.listbox_FramesSkipped, 'Value', 1);
    set(handles.listbox_FramesSkipped, 'String', FrameList.Display(FrameList.IDSkipped));
    pushbutton_PlotTrace_Callback(handles.pushbutton_PlotTrace, eventdata, handles);
end
% ========================================================================

% Traces
% ------

function pushbutton_PlotTrace_Callback(hObject, eventdata, handles)
AnalyzeTrace(handles);
PlotTrace(handles);

function radiobutton_BackgroundSubtract_Callback(hObject, eventdata, handles)
global Flags
Flags.BackgroundSubtract = get(hObject, 'Value');
Flags.BackgroundSubtract_Change = 1;
pushbutton_PlotTrace_Callback(handles.pushbutton_PlotTrace, eventdata, handles)
Flags.BackgroundSubtract_Change = 0;

function radiobutton_BackgroundCorrect_Callback(hObject, eventdata, handles)
global Flags Trace
Flags.BackgroundCorrect = get(hObject, 'Value');
Flags.BackgroundCorrect_Change = 1;
pushbutton_PlotTrace_Callback(handles.pushbutton_PlotTrace, eventdata, handles)
Flags.BackgroundCorrect_Change = 0;
Trace.Param.BackgroundCorrect = Flags.BackgroundCorrect;

function edit_BackgroundCorrectNBins_Callback(hObject, eventdata, handles)
global Parameters Trace
BCNBins = str2num(get(hObject, 'String'));
Parameters.BackgroundCorrectNBins = BCNBins;
Trace.Param.BackgroundCorrectNBins = BCNBins;
pushbutton_PlotTrace_Callback(handles.pushbutton_PlotTrace, eventdata, handles)
function edit_BackgroundCorrectNBins_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_Bleed_Callback(hObject, eventdata, handles)
global Parameters Trace
Bleed = str2double(get(hObject, 'String'));
Parameters.Bleed = Bleed;
Trace.Param.Bleed = Bleed;
pushbutton_PlotTrace_Callback(handles.pushbutton_PlotTrace, eventdata, handles)
function edit_Bleed_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function SaveTraces_Callback(hObject, eventdata, handles)
global Parameters Trace
% [FileName, PathName] = uiputfile('*.mat', 'Save Traces', fullfile(Parameters.ResultPath,Parameters.TraceName));
[FileName, PathName] = uiputfile('*.mat', 'Save Traces', fullfile(Parameters.ResultPath,Parameters.FileName(1:end-4)));
FullFileName = [PathName, FileName];
if FileName ~= 0
    save([PathName, FileName], '-struct', 'Trace');
end

% create a text file with JMalyze-emulated output
function SaveJMalyzeLOG_Callback(hObject, eventdata, handles)
global Parameters Trace
if isfield(Parameters, 'ResultPath') && isfield(Parameters, 'TraceName')
    [FileName, PathName] = uiputfile('*.log', 'Save JMalyze style log file', fullfile(Parameters.ResultPath,[Parameters.TraceName(1:end-4) '.log']));
else
    [FileName, PathName] = uigetfile('*.log', 'Save JMalyze style log file');
end
if FileName ~= 0
    if isfield(Trace, 'Subgroup') && isfield(Trace.Subgroup, 'ID')
        Ind = Trace.Subgroup.ID; % only frames that were not excluded
    else
        Ind = 1:length(Trace.Data.T);
    end
    ID1 = Trace.Param.Switch+1; % yellow channel
    ID2 = 2-Trace.Param.Switch; % cyan channel
    NR = length(Ind); % number of 'good' frames
    NC = 11; % jmalyze log files should have 11 columns
    JMalyze = nan(NC, NR);
    JMalyze(1,:) = Trace.Data.T(Ind)*1000; % time (depends on user selection stamp/mean)
    JMalyze(2,:) = Trace.Data.Bgrnd(ID1,Ind)'; % background level of yellow channel
    JMalyze(3,:) = Trace.Data.Bgrnd(ID2,Ind)'; % background level of cfp channel
    JMalyze(4,:) = Trace.ROI.C_M(Ind,1); % x coordinate yellow
    JMalyze(5,:) = Trace.ROI.C_M(Ind,2); % y coordinate yellow
    ROIArea = Trace.ROI.Rect(:,3).*Trace.ROI.Rect(:,4);
    JMalyze(6,:) = ROIArea; % yellow ROI area
    JMalyze(7,:) = Trace.Data.Fluo(ID1,Ind)'; % yellow fluorescence
    JMalyze(8,:) = Trace.ROI.C_M(Ind,1)+Trace.ROI.Offset(1); % x coordinate cyan (redundant since there is a constant offset)
    JMalyze(9,:) = Trace.ROI.C_M(Ind,2)+Trace.ROI.Offset(2); % y coordinate cyan (redundant since there is a constant offset)
    JMalyze(10,:) = ROIArea; % cyan ROI area
    JMalyze(11,:) = Trace.Data.Fluo(ID2,Ind)'; % cyan fluorescence
    fid = fopen(fullfile(PathName, FileName), 'wt');
    fprintf(fid, '%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\n', JMalyze);
    fclose(fid);
end


function LoadTraces_Callback(hObject, eventdata, handles)
global Trace FrameList Parameters
if isfield(Parameters, 'ResultPath') && isfield(Parameters, 'TraceName')
    [FileName, PathName] = uigetfile('*.mat', 'Load Traces', fullfile(Parameters.ResultPath,Parameters.TraceName));
else
    [FileName, PathName] = uigetfile('*.mat', 'Load Traces');
end
if FileName ~= 0
    Parameters.TraceName = FileName;
    Parameters.ResultPath = PathName;
    Trace = load([PathName,FileName]);
    TraceFieldsCheck;
    set(handles.pushbutton_PlotTrace, 'Enable', 'on');
    if isfield(Trace, 'Param')
        set(handles.edit_FMS, 'Enable', 'on', 'String', num2str(Trace.Param.FMS));
        if isfield(Trace.Param, 'BgrndPrcntile')
            set(handles.edit_BackgroundPercentile, 'String', num2str(Trace.Param.BgrndPrcntile));
        else
            set(handles.edit_BackgroundPercentile,'String', '');
        end
        if isfield(Trace.Param, 'Comment')
            set(handles.edit_Comment, 'String', Trace.Param.Comment);
        else
            set(handles.edit_Comment, 'String', '');
        end
        if isfield(Trace.Param, 'Experiment')
            NumExpParam = numel(Parameters.Experiment.ParamList);
            for i=1:NumExpParam
                eval(sprintf('Parameters.Experiment.Values{i} = Trace.Param.Experiment.%s;', Parameters.Experiment.ParamList{i}));
                Parameters.Experiment.Defaults{i} = Parameters.Experiment.Values{i};
            end
        end
        if isfield(Trace.Param, 'Fields')
            if isfield(Trace.Param.Fields, 'NumFields') && isfield(Trace.Param.Fields, 'FieldID')
                set(handles.edit_NumFields,'String',num2str(Trace.Param.Fields.NumFields));
                set(handles.popupmenu_FieldID,'String',cellstr(num2str((1:Trace.Param.Fields.NumFields)')));
                set(handles.popupmenu_FieldID,'Value',Trace.Param.Fields.FieldID);
            end
        end
    end
    if isfield(Trace, 'Subgroup')
        FrameList.ID = Trace.Subgroup.ID;
        FrameList.IDSkipped = Trace.Subgroup.IDSkipped;
        if isfield(FrameList, 'Display')
            set(handles.listbox_FramesSkipped, 'String', FrameList.Display(FrameList.IDSkipped));
            set(handles.listbox_Frames, 'String', FrameList.Display(FrameList.ID));
        end
    end
    AnalyzeTrace;
    PlotTrace(handles)
end

function uibuttongroup_Crosstalk_SelectionChangeFcn(source, eventdata, handles)
global Trace
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object
    case 'radiobutton_None'
        Trace.Param.Method = 0;
        set(handles.edit_Fraction, 'Enable', 'off');
    case 'radiobutton_DC'
        Trace.Param.Method = 1;
        set(handles.edit_Fraction, 'Enable', 'off');
    case 'radiobutton_Fraction'
        Trace.Param.Method = 2;
        set(handles.edit_Fraction, 'Enable', 'on');
        Trace.Param.Factor = str2num(get(handles.edit_Fraction, 'String'));
end

function edit_Fraction_Callback(hObject, eventdata, handles)
global Trace
Trace.Param.Factor = str2num(get(handles.edit_Fraction, 'String'));
function edit_Fraction_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_FMS_Callback(hObject, eventdata, handles)
global Trace Flags
FMS = str2num(get(hObject, 'String'));
if FMS > 0
    Trace.Param.FMS = FMS;
    if Trace.Flag
        Flags.FMS_change = 1;
        pushbutton_PlotTrace_Callback(handles.pushbutton_PlotTrace, eventdata, handles);
        Flags.FMS_change = 0;
    end
end
function edit_FMS_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pushbutton_ResetFMS_Callback(hObject, eventdata, handles)
global Trace
FMS = 1;
Record = AndorRecord('Average=', '%f');
if isempty(Record)
    NumFrames = AndorRecord('Time : ', '%f');
    if ~isempty(NumFrames)
        TimeStart = AndorRecord('Time=', '%f:%f:%f');
        TimeEnd = AndorRecord('SavedTime=', '%*f/%*f/%*f %f:%f:%f');
        TElapsed = 3600*(TimeEnd{1}-TimeStart{1}) + 60*(TimeEnd{2}-TimeStart{2}) + TimeEnd{3}-TimeStart{3};
        FMS = NumFrames{1}/TElapsed;
    else
        FMS = Trace.Param.FMS;
    end
else
    FMS = Record{1};
end
set(handles.edit_FMS, 'String', num2str(FMS, '%2.1f'));
edit_FMS_Callback(handles.edit_FMS, eventdata, handles);

% ROI in graph
function pushbutton_Axis_Callback(hObject, eventdata, handles)
global Trace
Rect = getrect(handles.axes_Ratio);
Trace.Axis.Rect = Rect;
Trace.Axis.Lim = [Rect(1) Rect(1)+Rect(3) Rect(2) Rect(2)+Rect(4)];
pushbutton_PlotTrace_Callback(handles.pushbutton_PlotTrace, eventdata, handles);

% find frame along graph
function pushbutton_GraphFrame_Callback(hObject, eventdata, handles)
global Trace
[x, y] = ginput(1);
diff = abs(Trace.Data.T(Trace.Subgroup.ID) - x);
[diffmin diffminind] = min(diff);
FrameID = Trace.Subgroup.ID(diffminind);
% set(handles.listbox_Frames, 'Value', FrameID);
set(handles.listbox_Frames, 'Value', diffminind);
listbox_Frames_Callback(handles.listbox_Frames, eventdata, handles);
% axes_single(handles.axes_single_Ratio)
% hold on
% plot(Trace.Data.T(FrameID), Trace.Analyzed.Ratio(FrameID), '*r')
% hold off

function pushbutton_Reset_Callback(hObject, eventdata, handles)
global Trace
Trace.Axis.Lim = Trace.Axis.Lim0;
pushbutton_PlotTrace_Callback(handles.pushbutton_PlotTrace, eventdata, handles);

function edit_Comment_Callback(hObject, eventdata, handles)
global Trace
Trace.Param.Comment = get(hObject,'String');
function edit_Comment_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popupmenu_TimeType_Callback(hObject, eventdata, handles)
global Trace Flags
TimeTypes = get(hObject, 'String');
Trace.Param.TimeType = TimeTypes{get(hObject, 'Value')};
Flags.TimeType_Change = 1;
pushbutton_PlotTrace_Callback(handles.pushbutton_PlotTrace, eventdata, handles);
Flags.TimeType_Change = 0;
function popupmenu_TimeType_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% add time stamps to a previous Trace
function pushbutton_TimeStamp_Callback(hObject, eventdata, handles)
NT_TraceStamp



% ========================================================================

% Marks
% -----

function pushbutton_Mark_Callback(hObject, eventdata, handles)
global Trace
i = Trace.Subgroup.ID(get(handles.listbox_Frames, 'Value'));
if ~ismember(i, Trace.Subgroup.Marks)
    Trace.Subgroup.Marks = [Trace.Subgroup.Marks i];
    Trace.Subgroup.Marks = sort(Trace.Subgroup.Marks);
end
pushbutton_PlotTrace_Callback(handles.pushbutton_PlotTrace, eventdata, handles)

function pushbutton_UnMark_Callback(hObject, eventdata, handles)
global Trace
i = Trace.Subgroup.ID(get(handles.listbox_Frames, 'Value'));
[check ind] = ismember(i, Trace.Subgroup.Marks);
if check
    Trace.Subgroup.Marks = setdiff(Trace.Subgroup.Marks, i);
end
pushbutton_PlotTrace_Callback(handles.pushbutton_PlotTrace, eventdata, handles)


% ========================================================================

% Macros
% -----

function listbox_Macros_Callback(hObject, eventdata, handles)
global Parameters
Parameters.MacroID = get(handles.listbox_Macros, 'Value');
if Parameters.MacroID == 4
    Parameters.FileFilter = '*ch00.tif';
    set(handles.edit_Filter, 'String', Parameters.FileFilter);
end
function listbox_Macros_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------

% Frames
% ------

function slider_ContrastTop_Callback(hObject, eventdata, handles)
global Parameters
Top = get(hObject, 'Value');
Bottom = get(handles.slider_ContrastBottom, 'Value');
if Top<=Bottom
    Top = Bottom+1;
    set(hObject, 'Value', Top);
end
Parameters.Contrast.Top = Top;
listbox_Frames_Callback(handles.listbox_Frames, eventdata, handles);
function slider_ContrastTop_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function slider_ContrastBottom_Callback(hObject, eventdata, handles)
global Parameters
Bottom = get(hObject, 'Value');
Top = get(handles.slider_ContrastTop, 'Value');
if Bottom>=Top
    Bottom = Top-1;
    set(hObject, 'Value', Bottom);
end
Parameters.Contrast.Bottom = Bottom;
listbox_Frames_Callback(handles.listbox_Frames, eventdata, handles);
function slider_ContrastBottom_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function togglebutton_ManualContrast_Callback(hObject, eventdata, handles)
global Flags
Flags.ManualContrast = get(hObject, 'Value');
if Flags.ManualContrast
    set(handles.slider_ContrastTop, 'Enable', 'on')
    set(handles.slider_ContrastBottom, 'Enable', 'on')
else
    set(handles.slider_ContrastTop, 'Enable', 'off')
    set(handles.slider_ContrastBottom, 'Enable', 'off')
end
listbox_Frames_Callback(handles.listbox_Frames, eventdata, handles);
