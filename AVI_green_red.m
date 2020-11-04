function FrameList = AVI_green_red(filename)

vidObj = VideoReader(filename);

vidHeight = vidObj.Height;
vidWidth = vidObj.Width;

FrameList = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),...
    'colormap',[]);

k = 1;
while hasFrame(vidObj)
    FrameList(k).cdata = readFrame(vidObj);
    k = k+1;
end


