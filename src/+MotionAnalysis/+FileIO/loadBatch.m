function batchData = loadBatch(files, sourcePath, timeCol, posStartCol, hasHeader, opts)
% LOADBATCH Reads multiple CSV files with flexible column mapping.
% Normalizes Time column to start at 0.

arguments 
    files
    sourcePath 
    timeCol (1,1) double {mustBeInteger} = 1 
    posStartCol (1,1) double {mustBeInteger} = 2 
    hasHeader (1,1) logical = false 
    opts.normalizeTime (1,1) logical = true 
end 
    if ischar(files) || (isstring(files) && isscalar(files))
        files = {files};
    end

    batchData = struct('FileName', {}, 'RawData', {}, 'Fs', {}, 'Results', {});
    validCount = 0;

    % Setup read options
    if hasHeader
        numHeaderLines = 1;
    else
        numHeaderLines = 0;
    end

    for i = 1:length(files)
        currentFile = files{i};
        fullPath = fullfile(sourcePath, currentFile);
        
        try
            % Read raw matrix
            rawFull = readmatrix(fullPath, 'NumHeaderLines', numHeaderLines);
            
            % Check dimensions
            maxColNeeded = max(timeCol, posStartCol + 2);
            if size(rawFull, 2) < maxColNeeded
                warning('File %s skipped: Not enough columns.', currentFile);
                continue;
            end
            
            % Extract Data
            tVal = rawFull(:, timeCol);
            posVal = rawFull(:, posStartCol : posStartCol+2);
            
            % Normalize Time to start at 0 
            if ~isempty(tVal) && opts.normalizeTime
                tVal = tVal - tVal(1);
            end
            
            % Store standardized data
            standardizedData = [tVal, posVal];
            
            validCount = validCount + 1;
            batchData(validCount).FileName = string(currentFile);
            batchData(validCount).RawData = standardizedData;
            
            % Calculate Fs
            % Handle cases where time might be constant or single point
            if length(tVal) > 1
                dt = mean(diff(tVal));
                if isnan(dt) || dt <= 0
                    warning('File %s skipped: Invalid time vector (dt <= 0 or NaN).', currentFile);
                    validCount = validCount - 1; 
                    continue;
                end
                batchData(validCount).Fs = round(1/dt);
            else
                warning('File %s skipped: Not enough data points.', currentFile);
                validCount = validCount - 1;
                continue;
            end
            
        catch ME
            warning('File %s skipped: %s', currentFile, ME.message);
        end
    end

    if validCount == 0
        error('No valid files could be loaded with the current settings.');
    end
end