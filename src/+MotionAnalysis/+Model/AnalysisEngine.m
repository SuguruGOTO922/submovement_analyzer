classdef AnalysisEngine
    % AnalysisEngine: Encapsulates the core calculation logic.
    % Moves 'runPipeline' and 'processBatch' into a proper Model class.
    
    methods (Static)
        function batchData = processBatch(batchData, params, progressCallback)
            % Runs the pipeline on all files in batchData
            nFiles = length(batchData);
            for i = 1:nFiles
                if nargin > 2 && ~isempty(progressCallback)
                    msg = sprintf('Processing %d of %d: %s', i, nFiles, batchData(i).FileName);
                    progressCallback(i / nFiles, msg);
                end
                
                % Determine Sampling Rate
                if isfield(params, 'FsAuto') && ~params.FsAuto && isfield(params, 'FsValue')
                    currentFs = params.FsValue;
                else
                    currentFs = batchData(i).Fs;
                end
                
                % Run Pipeline (Call static method in this class)
                batchData(i).Results = MotionAnalysis.Model.AnalysisEngine.runPipeline(...
                    batchData(i).RawData(:,1), ...
                    batchData(i).RawData(:,2:4), ...
                    currentFs, ...
                    params);
            end
        end

        function res = runPipeline(timeVec, posRaw, fs, params)
            % Core analysis pipeline for a single trial
            
            % Import Algorithms from the new location
            import MotionAnalysis.Model.Algorithms.*

            if nargin < 4
                params.VelThresh = 10;
                params.MinDuration = 0.040;
                params.FilterOrder = 2;
                params.CutoffFreq = 10;
            end

            % 1. Smoothing
            posSmooth = smoothData(posRaw, fs, params.CutoffFreq, params.FilterOrder);

            % 2. Tangential Velocity
            vel3D = centralDiff(posSmooth, fs);
            tanVel = sqrt(sum(vel3D.^2, 2));

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
                projDisp = -projDisp;
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
            res.TanVel      = tanVel;
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
    end
end