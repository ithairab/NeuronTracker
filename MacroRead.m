function FrameList = MacroRead

global Parameters Trace

switch Parameters.MacroID
    case 1 % single tiffs
        FrameDir = dir(Parameters.FileFilter);
        FrameList = {FrameDir.name};
        % in case frames are numbered without zero padding, add padding for
        % proper sorting
        NumFrames = numel(FrameList);
        NameLength = zeros(NumFrames,1);
        for i=1:NumFrames
            [~,name,ext] = fileparts(FrameList{i});
            NameLength(i) = length(name);
        end
        MaxLen = max(NameLength);
        MinLen = min(NameLength);
        if MaxLen>MinLen % padding needed
            PadFrameList = FrameList;
            for i=1:NumFrames
                if NameLength(i)<MaxLen
                    dLen = MaxLen-NameLength(i);
                    [~,name] = fileparts(FrameList{i});
                    PadFrameList{i} = [name(1:MinLen-1),sprintf('%d',zeros(dLen,1)),name(MinLen:end),ext];
                end
            end
            [~,srtInd] = sort(PadFrameList);
            FrameList = FrameList(srtInd);
        end
    case 2 % 3 Folder
        FrameList = {};
        Dir = dir('irstim0*');
        FrameDir = dir(sprintf('%s/%s', Dir.name, Parameters.FileFilter));
        K1 = size(FrameDir,1);
        for k = 2:K1
            FrameList(k-1) = {sprintf('%s/%s', Dir.name, FrameDir(k).name)};
        end
        Dir = dir('irstim1*');
        FrameDir = dir(sprintf('%s/%s', Dir.name, Parameters.FileFilter));
        K2 = size(FrameDir,1);
        for k = 1:K2
            FrameList(K1+k-1) = {sprintf('%s/%s', Dir.name, FrameDir(k).name)};
        end
        Dir = dir('irstim2*');
        FrameDir = dir(sprintf('%s/%s', Dir.name, Parameters.FileFilter));
        K3 = size(FrameDir,1);
        for k = 1:K3
            FrameList(K1+K2+k-1) = {sprintf('%s/%s', Dir.name, FrameDir(k).name)};
        end
        Parameters.Macro2.Mark = [K1 K1+K2];
    case 3 % Fast LZ
        FrameDir = dir(Parameters.FileFilter);
        K = size(FrameDir,1);
        for k = 3:K
            FrameList(k-2) = {FrameDir(k).name};
        end
        Parameters.Macro3.Mark = [48 148];
    case 4 % 2 Photon
        FrameDir = dir(Parameters.FileFilter);
        FrameList = {FrameDir.name};
    case 5 % AVI
        FrameList = mmreader(Parameters.FileName);
    case 6 % MAT
        M = load(fullfile(Parameters.PathName, Parameters.FileName));
        FrameList = M.Data;
        Trace.Data.Tstamp = M.Time';
        dt = 1/M.Performance.FPS;
        Trace.Data.Tmean = 0:dt:dt*(size(FrameList,4)-1);
        if strcmp(Trace.Param.TimeType, 'stamp')
            Trace.Data.T = Trace.Data.Tstamp;
        else
            Trace.Data.T = Trace.Data.Tmean;
        end
        FNames = fieldnames(M.Params);
        for i=1:numel(FNames)
            eval(sprintf('Trace.Param.%s = M.Params.%s;', FNames{i}, FNames{i}));
        end
        FNames = fieldnames(M.Performance);
        for i=1:numel(FNames)
            eval(sprintf('Trace.Param.%s = M.Performance.%s;', FNames{i}, FNames{i}));
        end
        Trace.Param.FMS = Trace.Param.FPS;
    case 7 % TIFF sequence
        FrameList = imfinfo(Parameters.FileName);
        if isfield(FrameList, 'DateTime')
            for i=1:numel(FrameList)
                TimeStr = FrameList(i).DateTime;
                SepInd = strfind(TimeStr, ':');
                TimeRaw = 60*str2double(TimeStr(SepInd(1)+1:SepInd(2)-1))+str2double(TimeStr(SepInd(2)+1:end));
                if i==1
                    T0 = TimeRaw;
                    Trace.Data.Tstamp(i) = 0;
                else
                    Trace.Data.Tstamp(i) = TimeRaw-T0;
                end
            end
        else
            Trace.Data.Tstamp = 1:numel(FrameList);
        end
        Trace.Param.imfinfo = FrameList(1);
    case 8 % TIFF Z dual
        FrameList{1} = Trace.Param.imfinfo(1).Filename;
    case 9 % Two separate AVI files for green and red
        FileNameRed = Parameters.FileName;
        FrameList.Red = AVI_green_red(FileNameRed);
        % temporary
        FileNameGreen = [FileNameRed(1:end-7), 'green', FileNameRed(end-3:end)];
        FrameList.Green = AVI_green_red(FileNameGreen);
    case 10 % Zeiss Zen czi file
        % it is important to set the path to bgmatlab and to
        % ZEN_Matlab-master
        out = ReadImage6DIR(Parameters.FileName);
        % out{1} is the image data in 6 dimensions: Series,T,Z,C,X,Y
        % the current macro is just for X,Y, so remove Series, and Z
        % dimensions, and use only EGFP color, if more channels are present
        IMlist = out{1};
        % image dimensions: T,Z,C,X,Y
        IMlist = reshape(IMlist,size(IMlist,2,3,4,5,6));
        % check if more than one layer exists and keep just one
        if size(IMlist,2)>1
            IMlist = IMlist(:,1,:,:,:);
            msg = 'Only first Z plane used';
            warning(msg);
        end
        % image dimensions: T,C,X,Y
        IMlist = reshape(IMlist,size(IMlist,1,3,4,5));
        % check if more than one channel exists and keep only EGFP
        if size(IMlist,2)>1
            Cid = find(strcmp('EGFP',out{2}.Channels));
            if Cid>0
                IMlist = IMlist(:,Cid,:,:);
            else
                IMlist = IMlist(:,1,:,:);
                msg = 'No EGFP channel found';
                warning(msg);
            end
        end
        % image dimensions: T,X,Y
        IMlist = reshape(IMlist,size(IMlist,1,3,4));
        FrameList = IMlist;
        % out{2} provides image information
        Trace.Param.imfinfo = out{2};
end


        
