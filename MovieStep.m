function MFrame = MovieStep(hMovie, i, FrameList)

global Parameters Trace
if Parameters.MacroID == 4
    Frame1Name = FrameList{i};
    Nch1 = str2num(Frame1Name(end-4));
    Frame1 = imread(Frame1Name);
else
    Frame = imread(FrameList{i});
    % Frame = imadjust(imread(FrameList{i}));
    % Frame(find(Frame<median(median(Frame)))) = 0;
    [Frame1, Frame2] = SplitFrame(Frame); % Split
end
figure(hMovie.Figure)
subplot(hMovie.Image)
imagesc(Frame1);
subplot(hMovie.Trace)
T = Trace.Data.T;
R = Trace.Analyzed.Ratio;
if i>1
    plot([T(i-1) T(i)], [R(i-1) R(i)], 'k');
end
MFrame = getframe(hMovie.Figure);
   