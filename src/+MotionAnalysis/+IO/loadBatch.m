function batchData = loadBatch(files, sourcePath, timeCol, posStartCol, hasHeader, inputUnit)
% LOADBATCH Reads multiple CSV files.
% Converts position data to mm if inputUnit is 'cm' or 'm'.

    if nargin < 3; timeCol = 1; end
    if nargin < 4; posStartCol = 2; end
    if nargin < 5; hasHeader = false; end
    if nargin < 6; inputUnit = 'mm'; end % Default

    if ischar(files) || (isstring(files) && isscalar(files))
        files = {files};
    end

    batchData = struct('FileName', {}, 'RawData', {}, 'Fs', {}, 'Results', {});
    validCount = 0;

    if hasHeader
        numHeaderLines = 1;
    else
        numHeaderLines = 0;
    end
    
    % Determine scaling factor to convert to mm
    scaleFactor = 1;
    switch inputUnit
        case 'cm'
            scaleFactor = 10;
        case 'm'
            scaleFactor = 1000;
        case 'mm'
            scaleFactor = 1;
        otherwise
            warning('Unknown unit: %s. Assuming mm.', inputUnit);
    end

    for i = 1:length(files)
        currentFile = files{i};
        fullPath = fullfile(sourcePath, currentFile);
        
        try
            rawFull = readmatrix(fullPath, 'NumHeaderLines', numHeaderLines);
            
            maxColNeeded = max(timeCol, posStartCol + 2);
            if size(rawFull, 2) < maxColNeeded
                warning('File %s skipped: Not enough columns.', currentFile);
                continue;
            end
            
            tVal = rawFull(:, timeCol);
            posVal = rawFull(:, posStartCol : posStartCol+2);
            
            % Normalize Time
            if ~isempty(tVal)
                tVal = tVal - tVal(1);
            end
            
            % Convert Units to mm
            posVal = posVal * scaleFactor;
            
            standardizedData = [tVal, posVal];
            
            validCount = validCount + 1;
            batchData(validCount).FileName = string(currentFile);
            batchData(validCount).RawData = standardizedData;
            
            if length(tVal) > 1
                dt = mean(diff(tVal));
                if isnan(dt) || dt <= 0
                    warning('File %s skipped: Invalid time vector.', currentFile);
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