% assume:
% PageName always includes : 'T=x C=Red/Green (x Cam) Z=x'
% frames are ordered by Z, then camera and then by T
% there are only 2 channels (cameras): top and rear

Z0 = 2;
C0ID = 1;

FileName = 'irabinow_112017_40x_GR_01 4.ome.tiff';

IMINF = imfinfo(FileName);
NumIMFrames = numel(IMINF);
Zmax = 0;
Ctype = {};
CtypeID = 0;
Cnames = {[],[]};
for i=1:NumIMFrames
    PageName = IMINF(i).PageName;
    ZID = strfind(PageName,'Z=');
    CID = strfind(PageName,'C=Red/Green (');
    CID2 = strfind(PageName, 'Cam)');
    TID = strfind(PageName,'T=');
    T = str2double(PageName(TID+2:CID-2));
    Z = str2double(PageName(ZID+2:end));
    C = PageName(CID+13:CID2-2);
    if Z>Zmax
        Zmax = Z;
        Cnames{1} = C;
    elseif Zmax>0 & isempty(Cnames{2})
        Cnames{2} = C;
    end
    if i==NumIMFrames
        Tmax = T;
    end
end

figure(1)
colormap(gray)
F(Tmax) = struct('cdata',[],'colormap',[]);
for t=1:Tmax
    k = (t-1)*2*Zmax + 2;
    IM1 = imread(FileName,k);
    IM2 = imread(FileName,k+Zmax);
    subplot(2,2,1)
    imagesc(IM1)
    axis off
    axis square
%     imagesc(IM1./IM2)
    subplot(2,2,3)
    imagesc(IM2)
    axis off
    axis square
    k = (t-1)*2*Zmax + 7;
    IM1 = imread(FileName,k);
    IM2 = imread(FileName,k+Zmax);
    subplot(2,2,2)
    imagesc(IM1)
    axis off
    axis square
%     imagesc(IM1./IM2)
    subplot(2,2,4)
    imagesc(IM2)
    axis off
    axis square
    F(t) = getframe(gcf);
end
fig = figure(2);
movie(fig,F,1,5);
%     IM = imread('irabinow_112017_40x_GR_01 4.ome.tiff',i);
%     subplot(2,9,i)
%     imagesc(IM)
