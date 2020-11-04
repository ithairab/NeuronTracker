function [Frame1, Frame2] = SplitFrame(Frame)

% imadjust(Frame);
% Split into two channels
[m n] = size(Frame);
n1 = floor(n/2);
Frame1 = imcrop(Frame, [1 1 n1-1 m-1]);
Frame2 = imcrop(Frame, [n1+1 1 n1-1 m-1]);
if n1 > m
    Frame1 = Frame1';
    Frame2 = Frame2';
end
