[filename,pathname] = uigetfile('*.tif','Select Tiff');

% Time stamp extraction written by Yoshihiko Katayama yoshihiko.katayama@cup.uni-muenchen.de

fid = fopen([pathname filename], 'r');
fseek(fid, 0, 'bof');
fseek(fid, 4, 'bof');
ifh = fread(fid, 4, 'uint8');
jumpfirst=str2num([int2str(ifh(4)) int2str(ifh(3)) int2str(ifh(2)) int2str(ifh(1))]);

fseek(fid, jumpfirst, 'bof');
ifd = fread(fid, 2, 'uint8');
rep=str2num([int2str(ifd(2)) int2str(ifd(1))]);

%next ifd
fseek(fid, jumpfirst+2+((rep-2)*12), 'bof');
a=dec2hex(fread(fid, 12, 'uint8'),2);
nextsixtwotag=hex2dec([a(12,:) a(11,:) a(10,:) a(9,:)]);
fseek(fid, nextsixtwotag, 'bof');
ifd62TimeStamps(1)= fread(fid, 1, 'float64', 'ieee-le.l64');

disp(ifd62TimeStamps)

fclose(fid);

