function [subStartIdx, subType, pnaIdx] = analyzeSubmovements(projVel, projAcc, projJerk, onsetIdx, offsetIdx, fs, minDurationSubmov)
% ANALYZESUBMOVEMENTS Classifies submovements.

arguments 
    projVel double 
    projAcc double 
    projJerk double 
    onsetIdx double {mustBeInteger}
    offsetIdx double {mustBeInteger}
    fs double 
    minDurationSubmov double 
end 

stableSamples = round(minDurationSubmov * fs);

% 1. Find PNA
if offsetIdx > length(projAcc); offsetIdx = length(projAcc); end
if onsetIdx > offsetIdx; onsetIdx = 1; end

segmentAcc = projAcc(onsetIdx:offsetIdx);
if isempty(segmentAcc)
    subStartIdx = NaN; subType = "None"; pnaIdx = onsetIdx; return;
end

[~, minLoc] = min(segmentAcc);
pnaIdx = onsetIdx + minLoc - 1;

subStartIdx = NaN;
subType = "None";

% 2. Search from PNA to Offset
searchEnd = offsetIdx - stableSamples;

if searchEnd < pnaIdx
    return; 
end

for k = pnaIdx : searchEnd
    detected = false;
    
    % Type 1 (Vel + -> -)
    if projVel(k) >= 0 && projVel(k+1) < 0
         if all(projVel(k+1 : k+1+stableSamples) < 0)
             subType = "Type 1";
             subStartIdx = k;
             detected = true;
         end
    end
    
    % Type 2 (Acc - -> +)
    if ~detected && projAcc(k) <= 0 && projAcc(k+1) > 0
        if all(projAcc(k+1 : k+1+stableSamples) > 0)
            subType = "Type 2";
            subStartIdx = k;
            detected = true;
        end
    end
    
    % Type 3 (Jerk + -> -)
    if ~detected && projJerk(k) >= 0 && projJerk(k+1) < 0
        if all(projJerk(k+1 : k+1+stableSamples) < 0)
            subType = "Type 3";
            subStartIdx = k;
            detected = true;
        end
    end
    
    if detected; break; end
end

end