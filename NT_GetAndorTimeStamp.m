function NT_GetAndorTimeStamp(i)

% adapted from Yoshihiko Katayama pooky@gmx.net

global Trace Parameters FrameList

if Parameters.MacroID ~= 4 & Parameters.MacroID ~= 5 & Parameters.MacroID ~= 7  & Parameters.MacroID ~= 8 & Parameters.MacroID ~= 9 & Parameters.MacroID ~= 10 % not Andor (two photon or AVI)

    FrameName = FrameList.FileNames{i};
    
    % Andor tiff files are encoded differently for single field vs multi-field imaging
    shift = 0; % single field
    if isfield(Trace.Param, 'Fields')
        if Trace.Param.Fields.NumFields > 1
            shift = 8; % multi-field
        end
    end

    fid = fopen(FrameName, 'r');
    fseek(fid, 0, 'bof'); % go to beginning of file
    fseek(fid, 4, 'bof'); % go to position 4 - offset to first IFD (Image File Directory)
    ifh = fread(fid, 4, 'uint8'); % first IFD offset
    jumpfirst=str2num([int2str(ifh(4)) int2str(ifh(3)) int2str(ifh(2)) int2str(ifh(1))]);

    fseek(fid, jumpfirst, 'bof'); % go to first IFD
    ifd = fread(fid, 2, 'uint8'); % number of tags in IFD
    rep=str2num([int2str(ifd(2)) int2str(ifd(1))]);

    %next ifd
    fseek(fid, jumpfirst+2+((rep-2)*12), 'bof'); % go to 2nd tag before last
    a=dec2hex(fread(fid, 12, 'uint8'),2); % each tag contains 12 bytes
    nextsixtwotag=hex2dec([a(12,:) a(11,:) a(10,:) a(9,:)]); % last 4 bytes include pointer to tag's value
    fseek(fid, nextsixtwotag+shift, 'bof'); % go to tag's value
    ifd62TimeStamps = fread(fid, 1, 'float64', 'ieee-le.l64'); % read tag's value
    Trace.Data.Tstamp(i) = ifd62TimeStamps/1000;
    fclose(fid);

end
