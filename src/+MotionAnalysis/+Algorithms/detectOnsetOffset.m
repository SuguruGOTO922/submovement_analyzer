function [onsetIdx, offsetIdx] = detectOnsetOffset(tangentialVel, fs, velThresh, minDuration)
% DETECTONSETOFFSET Detects movement start and end.
%
% Inputs:
%   tangentialVel   : Velocity magnitude vector
%   fs              : Sampling frequency
%   minDuration     : Minimum duration to stay below offset threshold (s)
%   velThresh       : Threshold for onset (mm/s)

arguments 
    tangentialVel double 
    fs (1,1) double 
    velThresh (1,1) double = 1
    minDuration (1,1) double = 0.4  
end 

stableSamples = round(minDuration * fs);
n = length(tangentialVel);

% --- Onset ---
% Use velThreshOnset
onsetIdx = find(tangentialVel > velThresh, 1, 'first');
if isempty(onsetIdx)
    onsetIdx = 1; % Safeguard 
end

% --- Offset ---
% Use velThreshOffset and minDuration
offsetIdx = n; 

if onsetIdx < n
    % Find candidates below offset threshold
    candidates = find(tangentialVel(onsetIdx:end) < velThresh) + onsetIdx - 1;
    
    for i = 1:length(candidates)
        idx = candidates(i);
        idxEnd = min(idx + stableSamples, n);
        % Check stability window
        if all(tangentialVel(idx : idxEnd) < velThresh)
            offsetIdx = idx;
            break;
        end
    end
end

end