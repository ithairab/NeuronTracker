function PlotFrame(h, Frame, ManualContrast)

global Parameters Flags

% Plot frame
axes(h)
hold off
if Flags.ManualContrast & ManualContrast
    Clims = [Parameters.Contrast.Bottom Parameters.Contrast.Top];
    imagesc(Frame, Clims);
else
    imagesc(Frame);
end
hold on
axis equal
axis off
axis ij
colormap(gray)


