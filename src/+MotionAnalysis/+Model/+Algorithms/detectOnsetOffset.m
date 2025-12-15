function [onsetIdx, offsetIdx] = detectOnsetOffset(tangentialVel, fs, velThresh, minDuration)
% DETECTONSETOFFSET Detects movement start and end using Peak-Velocity backtracking.
%
% Inputs:
%   tangentialVel   : Velocity magnitude vector
%   fs              : Sampling frequency
%   velThresh       : Threshold for onset/offset (mm/s) [Default: 10]
%   minDuration     : Minimum duration for offset stability (s) [Default: 0.040]

    arguments 
        tangentialVel double 
        fs (1,1) double 
        velThresh (1,1) double = 10    % Default: 10 mm/s
        minDuration (1,1) double = 0.040 % Default: 40 ms
    end 

    n = length(tangentialVel);
    stableSamples = round(minDuration * fs);

    % --- Onset Detection (Backward Search from Peak) ---
    % Logic: Find Peak Velocity, then search backwards for the first point < threshold.
    
    [maxVel, maxIdx] = max(tangentialVel);
    
    % Default fallback if peak velocity never exceeds threshold
    if maxVel <= velThresh
        onsetIdx = 1;
        offsetIdx = n;
        return;
    end
    
    onsetIdx = 1; % Fallback to start
    
    % Iterate backwards from Peak Velocity index
    for k = maxIdx : -1 : 1
        if tangentialVel(k) < velThresh
            onsetIdx = k;
            break; 
        end
    end

    % --- Offset Detection (Forward Search from Onset) ---
    % Logic: Find first point AFTER onset where velocity < threshold AND stays low for minDuration
    
    offsetIdx = n; % Default fallback to end of data
    
    if onsetIdx < n
        % Search range: from Onset to End
        candidatesOffset = find(tangentialVel(onsetIdx:end) < velThresh) + onsetIdx - 1;
        
        for i = 1:length(candidatesOffset)
            idx = candidatesOffset(i);
            
            % Define stability window end
            idxEnd = min(idx + stableSamples, n);
            
            % Check if velocity stays BELOW threshold for the duration (Offset criteria)
            if all(tangentialVel(idx : idxEnd) < velThresh)
                offsetIdx = idx;
                break; % The first valid point is the offset
            end
        end
    end
end