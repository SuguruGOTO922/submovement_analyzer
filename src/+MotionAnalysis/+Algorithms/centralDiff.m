function d = centralDiff(x, fs)
% CENTRALDIFF Computes derivative using 3-point central difference
%
% Inputs:
%   x  : N x M matrix (data)
%   fs : Sampling frequency (Hz)

arguments 
    x double
    fs (1,1) double
end 

dt = 1/fs;
n = size(x, 1);
d = zeros(size(x));

% Internal points: f'(x_i) = (f(x_{i+1}) - f(x_{i-1})) / (2*h)
d(2:n-1, :) = (x(3:n, :) - x(1:n-2, :)) / (2 * dt);

% Boundaries: Forward/Backward difference
d(1, :) = (x(2, :) - x(1, :)) / dt;
d(n, :) = (x(n, :) - x(n-1, :)) / dt;

end