function posSmooth = smoothData(posRaw, fs, fc, filtOrder)
% SMOOTHDATA Applies 2nd-order dual-pass Butterworth filter
%
% Inputs:
%   posRaw : N x 3 matrix of raw position data
%   fs     : Sampling frequency (Hz)
%   fc     : Cutoff frequency (Hz) [Default: 10]
%   order (optional) : Filter order [Default: 2] 

arguments 
    posRaw (:,3) double 
    fs (1,1) double {mustBeInteger}
    fc (1,1) double {mustBeInteger} = 10 
    filtOrder (1,1) double {mustBeInteger} = 2 
end 

fn = fs / 2;
[b, a] = butter(filtOrder, fc/fn, 'low');

% filtfilt ensures zero-phase (dual-pass)
posSmooth = filtfilt(b, a, posRaw);

end