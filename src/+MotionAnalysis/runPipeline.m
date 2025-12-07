function res = runPipeline(timeVec, posRaw, fs, opts)
% RUNPIPELINE Orchestrates the analysis with configurable parameters.
%
% Inputs:
%   ...
%   params : Struct with fields:
%       .VelThresh (mm/s)
%       .MinDuration (s)
        
arguments
    timeVec double 
    posRaw double 
    fs (1,1) double 
    opts.velThresh (1,1) double = 10; 
    opts.minDuration (1,1) double = 0.040; 
end

import MotionAnalysis.Algorithms.*

% 1. Smoothing
posSmooth = smoothData(posRaw, fs);

% 2. Tangential Velocity
vel3D = centralDiff(posSmooth, fs);
tanVel = sqrt(sum(vel3D.^2, 2));

% 3. Detect Onset/Offset (Pass params)
[onset, offset] = detectOnsetOffset(tanVel, fs, opts.velThresh, opts.minDuration);

% 4. Define Primary Axis
startPos = posSmooth(onset, :);
endPos   = posSmooth(offset, :);
axisVec  = endPos - startPos;
if norm(axisVec) == 0; axisUnit = [1 0 0]; else; axisUnit = axisVec / norm(axisVec); end

% 5. Project data
projDisp = posSmooth * axisUnit';
projVel  = centralDiff(projDisp, fs);

% --- CHANGE: Ensure Positive Bell-Shape Velocity ---
% Find the peak velocity magnitude
[~, maxIdx] = max(abs(projVel(onset:offset))); % Search within movement
peakVal = projVel(onset + maxIdx - 1);

% If the dominant peak is negative, flip the axis direction
if peakVal < 0
    projVel  = -projVel;
    % Note: We flip Disp/Vel here so Acc/Jerk calculated below will align.
end
% ---------------------------------------------------

projAcc  = centralDiff(projVel, fs);
projJerk = centralDiff(projAcc, fs);

% 6. Submovement Analysis (Pass params)
[subStart, subType, pna] = analyzeSubmovements(projVel, projAcc, projJerk, ...
                                        onset, offset, fs, opts.minDuration);

% Pack Results
res.Time        = timeVec;
res.Fs          = fs;
res.PosSmooth   = posSmooth;
res.ProjVel     = projVel;
res.ProjAcc     = projAcc;
res.ProjJerk    = projJerk;
res.OnsetIdx    = onset;
res.OffsetIdx   = offset;
res.PNAIdx      = pna;
res.SubStartIdx = subStart;
res.SubType     = subType;
% Save params used for reference
% res.Params      = params; 

end