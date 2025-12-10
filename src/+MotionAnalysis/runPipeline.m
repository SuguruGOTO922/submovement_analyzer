function res = runPipeline(timeVec, posRaw, fs, params)
% RUNPIPELINE Orchestrates the analysis with configurable parameters.

    import MotionAnalysis.Algorithms.*

    if nargin < 4
        params.VelThresh = 10;
        params.MinDuration = 0.040;
        params.FilterOrder = 2;
        params.CutoffFreq = 10;
    end

    % 1. Smoothing
    posCentered = posRaw - posRaw(1,:); 
    posSmooth = smoothData(posCentered, fs, params.CutoffFreq, params.FilterOrder);

    % 2. Tangential Velocity
    vel3D = centralDiff(posSmooth, fs);
    tanVel = sqrt(sum(vel3D.^2, 2)); % Calculate magnitude

    % 3. Detect Onset/Offset
    [onset, offset] = detectOnsetOffset(tanVel, fs, params.VelThresh, params.MinDuration);

    % 4. Define Primary Axis
    startPos = posSmooth(onset, :);
    endPos   = posSmooth(offset, :);
    axisVec  = endPos - startPos;
    if norm(axisVec) == 0; axisUnit = [1 0 0]; else; axisUnit = axisVec / norm(axisVec); end

    % 5. Project data
    projDisp = posSmooth * axisUnit';
    projVel  = centralDiff(projDisp, fs);
    
    % Ensure Positive Bell-Shape Velocity
    [~, maxIdx] = max(abs(projVel(onset:offset)));
    peakVal = projVel(onset + maxIdx - 1);
    
    if peakVal < 0
        % projDisp = -projDisp;
        projVel  = -projVel;
    end

    projAcc  = centralDiff(projVel, fs);
    projJerk = centralDiff(projAcc, fs);

    % 6. Submovement Analysis
    [subStart, subType, pna] = analyzeSubmovements(projVel, projAcc, projJerk, onset, offset, fs, params.MinDuration);

    % Pack Results
    res.Time        = timeVec;
    res.Fs          = fs;
    res.PosSmooth   = posSmooth;
    res.TanVel      = tanVel;     % NEW: Store Tangential Velocity for metrics
    res.ProjVel     = projVel;
    res.ProjAcc     = projAcc;
    res.ProjJerk    = projJerk;
    res.OnsetIdx    = onset;
    res.OffsetIdx   = offset;
    res.PNAIdx      = pna;
    res.SubStartIdx = subStart;
    res.SubType     = subType;
    res.Params      = params; 
end