function exportSummary(batchData, fullPath)
% EXPORTSUMMARY Exports analysis results to a summary CSV file.
% Includes Frame indices and XYZ coordinates for Onset, Offset, and Submovement.
%
% Inputs:
%   batchData : Struct array containing analysis results
%   fullPath  : Full path (directory + filename) to save the CSV

    nFiles = length(batchData);
    
    % --- Pre-allocate arrays for Table columns ---
    ID = strings(nFiles, 1);
    
    % Frame Indices
    Onset_Frame = zeros(nFiles, 1);
    Offset_Frame = zeros(nFiles, 1);
    Sub_Frame = zeros(nFiles, 1);
    Sub_Type = zeros(nFiles, 1);
    
    % Coordinates: Onset
    Onset_X = zeros(nFiles, 1);
    Onset_Y = zeros(nFiles, 1);
    Onset_Z = zeros(nFiles, 1);
    
    % Coordinates: Offset
    Offset_X = zeros(nFiles, 1);
    Offset_Y = zeros(nFiles, 1);
    Offset_Z = zeros(nFiles, 1);
    
    % Coordinates: Submovement
    Sub_X = zeros(nFiles, 1);
    Sub_Y = zeros(nFiles, 1);
    Sub_Z = zeros(nFiles, 1);
    
    for i = 1:nFiles
        if isempty(batchData(i).Results)
            continue; % Skip unanalyzed files
        end
        
        res = batchData(i).Results;
        
        % 1. Basic Info & Frame Indices
        ID(i) = batchData(i).FileName;
        Onset_Frame(i) = res.OnsetIdx;
        Offset_Frame(i) = res.OffsetIdx;
        Sub_Frame(i) = res.SubStartIdx; % NaN remains NaN
        
        % Parse Submovement Type
        typeStr = res.SubType;
        if typeStr == "None"
            Sub_Type(i) = NaN;
        else
            val = sscanf(typeStr, "Type %d");
            if isempty(val), Sub_Type(i) = NaN; else, Sub_Type(i) = val; end
        end
        
        % 2. Extract Coordinates (from smoothed data)
        % Note: Using original column order (not mapped)
        
        % Onset Position
        posOnset = res.PosSmooth(res.OnsetIdx, :);
        Onset_X(i) = posOnset(1);
        Onset_Y(i) = posOnset(2);
        Onset_Z(i) = posOnset(3);
        
        % Offset Position
        posOffset = res.PosSmooth(res.OffsetIdx, :);
        Offset_X(i) = posOffset(1);
        Offset_Y(i) = posOffset(2);
        Offset_Z(i) = posOffset(3);
        
        % Submovement Position
        if ~isnan(res.SubStartIdx)
            posSub = res.PosSmooth(res.SubStartIdx, :);
            Sub_X(i) = posSub(1);
            Sub_Y(i) = posSub(2);
            Sub_Z(i) = posSub(3);
        else
            Sub_X(i) = NaN;
            Sub_Y(i) = NaN;
            Sub_Z(i) = NaN;
        end
    end
    
    % --- Create Table ---
    T = table(ID, ...
        Onset_Frame, Offset_Frame, Sub_Frame, Sub_Type, ...
        Onset_X, Onset_Y, Onset_Z, ...
        Offset_X, Offset_Y, Offset_Z, ...
        Sub_X, Sub_Y, Sub_Z);
    
    % --- Write to CSV ---
    writetable(T, fullPath);
end