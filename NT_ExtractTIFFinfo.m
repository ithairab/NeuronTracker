function TIFF = NT_ExtractTIFFinfo(IMINF)

% Extract F (frame), Z and channel information from TIFF stack structure

% Assumptions:
% PageName always includes : 'T=x C=Red/Green (x Cam) Z=x'
% frames are ordered by Z, then camera and then by T
% there are only 2 channels (cameras): top and rear

NumIMFrames = numel(IMINF);
Znum = 0;
Cnames = {[],[]};
for i=1:NumIMFrames
    PageName = IMINF(i).PageName;
    ZID = strfind(PageName,'Z=');
    CID = strfind(PageName,'C=Red/Green (');
    CID2 = strfind(PageName, 'Cam)');
    TID = strfind(PageName,'T=');
    F = str2double(PageName(TID+2:CID-2));
    Z = str2double(PageName(ZID+2:end));
    C = PageName(CID+13:CID2-2);
    if Z>Znum
        Znum = Z;
        Cnames{1} = C;
    elseif Znum>0 & isempty(Cnames{2})
        Cnames{2} = C;
    end
    if i==NumIMFrames
        Fnum = F;
    end
end

TIFF.Fnum = Fnum;
TIFF.Znum = Znum;
TIFF.Cnames = Cnames;

