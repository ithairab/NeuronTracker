function x1 = Normalize(x, lo_, hi_)

lo = 0; % default
hi = 1; % defai;t
if nargin > 1
    lo = lo_;
end
if nargin >2
    hi = hi_;
end
x1 = (hi-lo) * (x - min(x)) / (max(x) - min(x)) + lo;