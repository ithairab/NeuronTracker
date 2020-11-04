function stack = tiffread(filename, indices)

% tiffread, version 2.6c April 30th, 2008
%
% stack = tiffread;
% stack = tiffread(filename);
% stack = tiffread(filename, indices);
%
% Reads 8,16,32 bits uncompressed grayscale and (some) color tiff files,
% as well as stacks or multiple tiff images, for example those produced
% by metamorph, Zeiss LSM or NIH-image.
%
% The function can be called with a file name in the current directory,
% or without argument, in which case it pops up a file opening dialog
% to allow for a manual selection of the file.
% If the stacks contains multiples images, reading can be restricted by
% specifying the indices of the images to read, or just one index.
%
% The returned value 'stack' is a vector struct containing the images 
% and their meta-data. The length of the vector is the number of images.
% The image pixels values are stored:
%   in a field .data for gray level images,
%   in the fields .red, .green and .blue for color images.
% (the .red .green and .blue fields are read in the order in which they are
% stored in the file, which may not correspond to these colors)
%
% The pixels values are returned in their native (usually integer) format,
% and must be converted to be used in most matlab functions.
%
% Example:
% im = tiffread('spindle.stk');
% imshow( double(im(5).data) );
%
% Only a fraction of the TIFF standard is supported, but you may extend support
% by modifying this file. If you do so, please return your modification to
% F. Nedelec, so that the added functionality can be distributed in the future.
%
% Francois Nedelec, EMBL, Copyright 1999-2008.
% rewriten July 7th, 2004 at Woods Hole during the physiology course.
% last modified March 7, 2008.
% With contributions from:
%   Kendra Burbank for the waitbar
%   Hidenao Iwai for the code to read floating point images,
%   Stephen Lang to be more compliant with PlanarConfiguration
%   Jan-Ulrich Kreft for Zeiss LSM support
%   Elias Beauchanp and David Kolin for additional Metamorph support
%   Jean-Pierre Ghobril for requesting that image indices may be specified
%   
% Please, send us feedback/bugs/suggestions to improve this code.
% This software is provided at no cost by a public research institution.
%
% Francois Nedelec
% nedelec (at) embl.de
% Cell Biology and Biophysics, EMBL; Meyerhofstrasse 1; 69117 Heidelberg; Germany
% http://www.embl.org
% http://www.cytosim.org




%Optimization: join adjacent TIF strips: this results in faster reads
consolidateStrips = 1;

%without argument, we ask the user to choose a file:
if nargin < 1
    [filename, pathname] = uigetfile('*.tif;*.stk;*.lsm', 'select image file');
    filename = [ pathname, filename ];
end

if (nargin<=1);  indices = 1:10000; end


% not all valid tiff tags have been included, as they are really a lot...
% if needed, tags can easily be added to this code
% See the official list of tags:
% http://partners.adobe.com/asn/developer/pdfs/tn/TIFF6.pdf
%
% the structure IMG is returned to the user, while TIF is not.
% so tags usefull to the user should be stored as fields in IMG, while
% those used only internally can be stored in TIF.

global TIF;
TIF = [];

%counters for the number of images read and skipped
img_skip  = 0;
img_read  = 1;
hWaitbar  = [];

% set defaults values :
TIF.SampleFormat     = 1;
TIF.SamplesPerPixel  = 1;
TIF.BOS              = 'ieee-le';          %byte order string

if  isempty(findstr(filename,'.'))
    filename = [filename,'.tif'];
end

TIF.file = fopen(filename,'r','l');
if TIF.file == -1
    filename = strrep(filename, '.tif', '.stk');
    TIF.file = fopen(filename,'r','l');
end
[stat, mess] = fileattrib(filename);
if stat ~= 1
    error(['File "',filename,'" not found.']);
end
filename = mess.Name;

% read header
% read byte order: II = little endian, MM = big endian
byte_order = fread(TIF.file, 2, '*char');
if ( strcmp(byte_order', 'II') )
    TIF.BOS = 'ieee-le';                                %normal PC format
elseif ( strcmp(byte_order','MM') )
    TIF.BOS = 'ieee-be';
else
    error('This is not a TIFF file (no MM or II).');
end


%% ---- read in a number which identifies file as TIFF format
tiff_id = fread(TIF.file,1,'uint16', TIF.BOS);
if (tiff_id ~= 42)
    error('This is not a TIFF file (missing 42).');
end

%% ---- read the byte offset for the first image file directory (IFD)
TIF.img_pos = fread(TIF.file, 1, 'uint32', TIF.BOS);

while  TIF.img_pos ~= 0 

    clear IMG;
    IMG.filename = filename;
    % move in the file to the first IFD
    fseek(TIF.file, TIF.img_pos, -1);
    %disp(strcat('reading img at pos :',num2str(TIF.img_pos)));

    %read in the number of IFD entries
    num_entries = fread(TIF.file,1,'uint16', TIF.BOS);
    %disp(strcat('num_entries =', num2str(num_entries)));

    %read and process each IFD entry
    for i = 1:num_entries

        % save the current position in the file
        file_pos  = ftell(TIF.file);

        % read entry tag
        TIF.entry_tag = fread(TIF.file, 1, 'uint16', TIF.BOS);
        entry = readIFDentry;
        %disp(strcat('reading entry <',num2str(TIF.entry_tag),'>'));

        switch TIF.entry_tag
            case 254
                TIF.NewSubfiletype = entry.val;
            case 256         % image width - number of column
                IMG.width          = entry.val;
            case 257         % image height - number of row
                IMG.height         = entry.val;
                TIF.ImageLength    = entry.val;
            case 258         % BitsPerSample per sample
                TIF.BitsPerSample  = entry.val;
                TIF.BytesPerSample = TIF.BitsPerSample / 8;
                IMG.bits           = TIF.BitsPerSample(1);
                %fprintf('BitsPerSample %i %i %i\n', entry.val);
            case 259         % compression
                if ( entry.val ~= 1 )
                    error(['Compression format ', num2str(entry.val),' not supported.']);
                end
            case 262         % photometric interpretation
                TIF.PhotometricInterpretation = entry.val;
                if ( TIF.PhotometricInterpretation == 3 )
                    warning('tiffread2:LookUp', 'Ignoring TIFF look-up table');
                end
            case 269
                IMG.document_name  = entry.val;
            case 270         % comments:
                IMG.info           = entry.val;
            case 271
                IMG.make           = entry.val;
            case 273         % strip offset
                TIF.StripOffsets   = entry.val;
                TIF.StripNumber    = entry.cnt;
                %fprintf('StripNumber = %i, size(StripOffsets) = %i %i\n', TIF.StripNumber, size(TIF.StripOffsets));
            case 277         % sample_per pixel
                TIF.SamplesPerPixel  = entry.val;
                %fprintf('Color image: sample_per_pixel=%i\n',  TIF.SamplesPerPixel);
            case 278         % rows per strip
                TIF.RowsPerStrip   = entry.val;
            case 279         % strip byte counts - number of bytes in each strip after any compressio
                TIF.StripByteCounts= entry.val;
            case 282         % X resolution
                IMG.x_resolution   = entry.val;
            case 283         % Y resolution
                IMG.y_resolution   = entry.val;
            case 284         %planar configuration describe the order of RGB
                TIF.PlanarConfiguration = entry.val;
            case 296         % resolution unit
                IMG.resolution_unit= entry.val;
            case 305         % software
                IMG.software       = entry.val;
            case 306         % datetime
                IMG.datetime       = entry.val;
            case 315
                IMG.artist         = entry.val;
            case 317        %predictor for compression
                if (entry.val ~= 1); error('unsuported predictor value'); end
            case 320         % color map
                IMG.cmap           = entry.val;
                IMG.colors         = entry.cnt/3;
            case 339
                TIF.SampleFormat   = entry.val;
            case 33628       %metamorph specific data
                IMG.MM_private1    = entry.val;
            case 33629       %this tag identify the image as a Metamorph stack!
                TIF.MM_stack       = entry.val;
                TIF.MM_stackCnt    = entry.cnt;
                if  TIF.MM_stackCnt  && numel(indices) > 1
                    hWaitbar = waitbar(0,'Reading images...','Name','TiffRead');
                end
            case 33630       %metamorph stack data: wavelength
                TIF.MM_wavelength  = entry.val;
            case 33631       %metamorph stack data: gain/background?
                TIF.MM_private2    = entry.val;
            case 34412       % Zeiss LSM data
                IMG.lsm            = entry.val;
            otherwise
                fprintf( 'Ignored TIFF entry with tag %i (cnt %i)\n', TIF.entry_tag, entry.cnt);
        end
        % move to next IFD entry in the file
        fseek(TIF.file, file_pos+12, -1);
    end

    %Planar configuration is not fully supported
    %Per tiff spec 6.0 PlanarConfiguration irrelevent if SamplesPerPixel==1
    %Contributed by Stephen Lang
    if (TIF.SamplesPerPixel ~= 1) && (TIF.PlanarConfiguration == 1)
        error('PlanarConfiguration = %i is not supported', TIF.PlanarConfiguration);
    end

    %total number of bytes per image:
    PlaneBytesCnt = IMG.width * IMG.height * TIF.BytesPerSample;

    if consolidateStrips
        %Try to consolidate the strips into a single one to speed-up reading:
        BytesCnt = TIF.StripByteCounts(1);

        if BytesCnt < PlaneBytesCnt

            ConsolidateCnt = 1;
            %Count how many Strip are needed to produce a plane
            while TIF.StripOffsets(1) + BytesCnt == TIF.StripOffsets(ConsolidateCnt+1)
                ConsolidateCnt = ConsolidateCnt + 1;
                BytesCnt = BytesCnt + TIF.StripByteCounts(ConsolidateCnt);
                if ( BytesCnt >= PlaneBytesCnt ); break; end
            end

            %Consolidate the Strips
            if ( BytesCnt <= PlaneBytesCnt(1) ) && ( ConsolidateCnt > 1 )
                %fprintf('Consolidating %i stripes out of %i', ConsolidateCnt, TIF.StripNumber);
                TIF.StripByteCounts = [BytesCnt; TIF.StripByteCounts(ConsolidateCnt+1:TIF.StripNumber ) ];
                TIF.StripOffsets = TIF.StripOffsets( [1 , ConsolidateCnt+1:TIF.StripNumber] );
                TIF.StripNumber  = 1 + TIF.StripNumber - ConsolidateCnt;
            end
        end
    end

    %read the next IFD address:
    TIF.img_pos = fread(TIF.file, 1, 'uint32', TIF.BOS);
    %if (TIF.img_pos) disp(['next ifd at', num2str(TIF.img_pos)]); end

    if isfield( TIF, 'MM_stack' )

        sel = ( indices <= TIF.MM_stackCnt );
        indices = indices(sel);
        
        %this loop is to read metamorph stacks:
        for ii = indices

            TIF.StripCnt = 1;

            %read the image
            fileOffset = PlaneBytesCnt * ( ii - 1 );
            %fileOffset = 0;
            %fileOffset = ftell(TIF.file) - TIF.StripOffsets(1);

            if ( TIF.SamplesPerPixel == 1 )
                IMG.data  = read_plane(fileOffset, IMG.width, IMG.height, 1);
            else
                IMG.red   = read_plane(fileOffset, IMG.width, IMG.height, 1);
                IMG.green = read_plane(fileOffset, IMG.width, IMG.height, 2);
                IMG.blue  = read_plane(fileOffset, IMG.width, IMG.height, 3);
            end

            % print a text timer on the main window, or update the waitbar
            % fprintf('img_read %i img_skip %i\n', img_read, img_skip);
            if ~isempty( hWaitbar )
                waitbar( img_read/numel(indices), hWaitbar);
            end
            
            [ IMG.MM_stack, IMG.MM_wavelength, IMG.MM_private2 ] = splitMetamorph(ii);
            
            stack(img_read) = IMG;
            img_read = img_read + 1;

        end
        break;

    else

        %this part to read a normal TIFF stack:

        if  any( img_skip + img_read == indices )

            TIF.StripCnt = 1;
            %read the image
            if ( TIF.SamplesPerPixel == 1 )
                IMG.data  = read_plane(0, IMG.width, IMG.height, 1);
            else
                IMG.red   = read_plane(0, IMG.width, IMG.height, 1);
                IMG.green = read_plane(0, IMG.width, IMG.height, 2);
                IMG.blue  = read_plane(0, IMG.width, IMG.height, 3);
            end


            try
                stack(img_read) = IMG;
            catch
                fprintf( 'Tiffread exit after finding dissimilar image %i\n', img_read);
                break;
            end
            
            img_read = img_read + 1;
            
            if  all( img_skip + img_read > indices )
                break;
            end

        else
            img_skip = img_skip + 1;
        end

    end
end


if isfield( TIF, 'MM_stack' ) && ~isempty(IMG.info)
    MM = parseMetamorphInfo(IMG.info, TIF.MM_stackCnt);
    for i = 1:numel(stack)
        stack(i).MM = MM(i);
    end
end

if ~ exist( 'stack', 'var')
    stack = [];
end
  
%clean-up
fclose(TIF.file);
if ~isempty( hWaitbar )
    delete( hWaitbar );
end



end


%% ===========================================================================

function plane = read_plane(offset, width, height, planeCnt)

global TIF;

%return an empty array if the sample format has zero bits
if ( TIF.BitsPerSample(planeCnt) == 0 )
    plane=[];
    return;
end

%fprintf('reading plane %i size %i %i\n', planeCnt, width, height);

%determine the type needed to store the pixel values:
switch( TIF.SampleFormat )
    case 1
        classname = sprintf('uint%i', TIF.BitsPerSample(planeCnt));
    case 2
        classname = sprintf('int%i', TIF.BitsPerSample(planeCnt));
    case 3
        if ( TIF.BitsPerSample(planeCnt) == 32 )
            classname = 'single';
        else
            classname = 'double';
        end
    otherwise
        error('unsuported TIFF sample format %i', TIF.SampleFormat);
end

% Preallocate a matrix to hold the sample data:
plane = zeros(width, height, classname);

% Read the strips and concatenate them:
line = 1;
while ( TIF.StripCnt <= TIF.StripNumber )

    strip = read_strip(offset, width, planeCnt, TIF.StripCnt, classname);
    TIF.StripCnt = TIF.StripCnt + 1;

    % copy the strip onto the data
    plane(:, line:(line+size(strip,2)-1)) = strip;

    line = line + size(strip,2);
    if ( line > height )
        break;
    end

end

% Extract valid part of data if needed
if ~all(size(plane) == [width height]),
    plane = plane(1:width, 1:height);
    warning('tiffread2:Crop','Cropping data: found more bytes than needed');
end

% transpose the image (otherwise display is rotated in matlab)
plane = plane';

end


%% ================== sub-functions to read a strip ===================

function strip = read_strip(offset, width, planeCnt, stripCnt, classname)

global TIF;

%fprintf('reading strip at position %i\n',TIF.StripOffsets(stripCnt) + offset);
StripLength = TIF.StripByteCounts(stripCnt) ./ TIF.BytesPerSample(planeCnt);

%fprintf( 'reading strip %i\n', stripCnt);
fseek(TIF.file, TIF.StripOffsets(stripCnt) + offset, 'bof');
bytes = fread( TIF.file, StripLength, classname, TIF.BOS );

if any( length(bytes) ~= StripLength )
    error('End of file reached unexpectedly.');
end

strip = reshape(bytes, width, StripLength / width);

end


%% ==================sub-functions that reads an IFD entry:===================


function [nbBytes, matlabType] = convertType(tiffType)
switch (tiffType)
    case 1
        nbBytes=1;
        matlabType='uint8';
    case 2
        nbBytes=1;
        matlabType='uchar';
    case 3
        nbBytes=2;
        matlabType='uint16';
    case 4
        nbBytes=4;
        matlabType='uint32';
    case 5
        nbBytes=8;
        matlabType='uint32';
    case 7
        nbBytes=1;
        matlabType='uchar';
    case 11
        nbBytes=4;
        matlabType='float32';
    case 12
        nbBytes=8;
        matlabType='float64';
    otherwise
        error('tiff type %i not supported', tiffType)
end
end

%% ==================sub-functions that reads an IFD entry:===================

function  entry = readIFDentry()

global TIF;
entry.tiffType = fread(TIF.file, 1, 'uint16', TIF.BOS);
entry.cnt      = fread(TIF.file, 1, 'uint32', TIF.BOS);
%disp(['tiffType =', num2str(entry.tiffType),', cnt = ',num2str(entry.cnt)]);

[ entry.nbBytes, entry.matlabType ] = convertType(entry.tiffType);

if entry.nbBytes * entry.cnt > 4
    %next field contains an offset:
    offset = fread(TIF.file, 1, 'uint32', TIF.BOS);
    %disp(strcat('offset = ', num2str(offset)));
    fseek(TIF.file, offset, -1);
end

if TIF.entry_tag == 33629   % metamorph 'rationals'
    entry.val = fread(TIF.file, 6*entry.cnt, entry.matlabType, TIF.BOS);
elseif TIF.entry_tag == 34412
    entry.val = readLSMinfo;
else
    if entry.tiffType == 5
        entry.val = fread(TIF.file, 2*entry.cnt, entry.matlabType, TIF.BOS);
    else
        entry.val = fread(TIF.file, entry.cnt, entry.matlabType, TIF.BOS);
    end
end

if ( entry.tiffType == 2 );
    entry.val = char(entry.val');
end

end


%% =============distribute the metamorph infos to each frame:
function [MMstack, MMwavelength, MMprivate2] = splitMetamorph(imgCnt)

global TIF;

MMstack = [];
MMwavelength = [];
MMprivate2 = [];

if TIF.MM_stackCnt == 1
    return;
end

left  = imgCnt - 1;

if isfield( TIF, 'MM_stack' )
    S = length(TIF.MM_stack) / TIF.MM_stackCnt;
    MMstack = TIF.MM_stack(S*left+1:S*left+S);
end

if isfield( TIF, 'MM_wavelength' )
    S = length(TIF.MM_wavelength) / TIF.MM_stackCnt;
    MMwavelength = TIF.MM_wavelength(S*left+1:S*left+S);
end

if isfield( TIF, 'MM_private2' )
    S = length(TIF.MM_private2) / TIF.MM_stackCnt;
    MMprivate2 = TIF.MM_private2(S*left+1:S*left+S);
end

end


%% %%  Parse the Metamorph camera info tag into respective fields
% EVBR 2/7/2005, FJN Dec. 2007
function mm = parseMetamorphInfo(info, cnt)

info   = regexprep(info, '\r\n|\o0', '\n');
parse  = textscan(info, '%s %s', 'Delimiter', ':');
tokens = parse{1};
values = parse{2};

first = char(tokens(1,1));

k = 0;
mm = struct('Exposure', zeros(cnt,1));
for i=1:size(tokens,1)
    tok = char(tokens(i,1));
    val = char(values(i,1));
    %fprintf( '"%s" : "%s"\n', tok, val);
    if strcmp(tok, first)
        k = k + 1;
    end
    if strcmp(tok, 'Exposure')
        [v, c, e, pos] = sscanf(val, '%i');
        unit = val(pos:length(val));
        %return the exposure in milli-seconds
        switch( unit )
            case 'ms'
                mm(k).Exposure = v;
            case 's'
                mm(k).Exposure = v * 1000;
            otherwise
                warning('tiffread2:Unit', ['Exposure unit "',unit,'" not recognized']);
                mm(k).Exposure = v;
        end
    else
        switch tok
            case 'Binning'
                % Binning: 1 x 1 -> [1 1]
                mm(k).Binning = sscanf(val, '%d x %d')';
            case 'Region'
                mm(k).Region = sscanf(val, '%d x %d, offset at (%d, %d)')';
            otherwise
                field  = regexprep(tok, ' ', '');
                if strcmp(val, 'Off')
                    eval(['mm(k).',field,'=0;']);
                elseif strcmp(val, 'On')
                    eval(['mm(k).',field,'=1;']);
                elseif isstrprop(val,'digit')
                    eval(['mm(k).',field,'=str2num(val)'';']);
                else
                    eval(['mm(k).',field,'=val;']);
                end
        end
    end
end

end

%% ==============partial-parse of LSM info:

function R = readLSMinfo()

% only the first table is read!
% this provides only very partial information, since the offset indicate that
% additional data is stored in the file
global TIF;

R.MagicNumber            = sprintf('0x%x',fread(TIF.file, 1, 'uint32', TIF.BOS));
StructureSize            = fread(TIF.file, 1, 'int32', TIF.BOS);
R.DimensionX             = fread(TIF.file, 1, 'int32', TIF.BOS);
R.DimensionY             = fread(TIF.file, 1, 'int32', TIF.BOS);
R.DimensionZ             = fread(TIF.file, 1, 'int32', TIF.BOS);
R.DimensionChannels      = fread(TIF.file, 1, 'int32', TIF.BOS);
R.DimensionTime          = fread(TIF.file, 1, 'int32', TIF.BOS);
R.DataType               = fread(TIF.file, 1, 'int32', TIF.BOS);
R.ThumbnailX             = fread(TIF.file, 1, 'int32', TIF.BOS);
R.ThumbnailY             = fread(TIF.file, 1, 'int32', TIF.BOS);
R.VoxelSizeX             = fread(TIF.file, 1, 'float64', TIF.BOS);
R.VoxelSizeY             = fread(TIF.file, 1, 'float64', TIF.BOS);
R.VoxelSizeZ             = fread(TIF.file, 1, 'float64', TIF.BOS);
R.ScanType               = fread(TIF.file, 1, 'uint32', TIF.BOS);
R.DataType               = fread(TIF.file, 1, 'uint32', TIF.BOS);
OffsetVectorOverlay    = fread(TIF.file, 1, 'uint32', TIF.BOS);
OffsetInputLut         = fread(TIF.file, 1, 'uint32', TIF.BOS);
OffsetOutputLut        = fread(TIF.file, 1, 'uint32', TIF.BOS);
OffsetChannelColors    = fread(TIF.file, 1, 'uint32', TIF.BOS);
R.TimeInterval           = fread(TIF.file, 1, 'float64', TIF.BOS);
OffsetChannelDataTypes = fread(TIF.file, 1, 'uint32', TIF.BOS);
OffsetScanInformation  = fread(TIF.file, 1, 'uint32', TIF.BOS);
OffsetKsData           = fread(TIF.file, 1, 'uint32', TIF.BOS);
OffsetTimeStamps       = fread(TIF.file, 1, 'uint32', TIF.BOS);
OffsetEventList        = fread(TIF.file, 1, 'uint32', TIF.BOS);
OffsetRoi              = fread(TIF.file, 1, 'uint32', TIF.BOS);
OffsetBleachRoi        = fread(TIF.file, 1, 'uint32', TIF.BOS);
OffsetNextRecording    = fread(TIF.file, 1, 'uint32', TIF.BOS);
R.Reserved               = fread(TIF.file, 1, 'uint32', TIF.BOS);

end


