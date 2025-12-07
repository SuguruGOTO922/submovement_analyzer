function exportSummary(batchData, fullPath)
% EXPORTSUMMARY Exports analysis results to a summary CSV file.
%
% Inputs:
%   batchData : Struct array containing analysis results
%   fullPath  : Full path (directory + filename) to save the CSV

    nFiles = length(batchData);
    
    % Pre-allocate arrays
    ID = strings(nFiles, 1);
    Onset = zeros(nFiles, 1);
    Offset = zeros(nFiles, 1);
    Submovement = zeros(nFiles, 1);
    Type = zeros(nFiles, 1);
    
    for i = 1:nFiles
        if isempty(batchData(i).Results)
            continue; % Skip unanalyzed files
        end
        
        res = batchData(i).Results;
        
        ID(i) = batchData(i).FileName;
        Onset(i) = res.OnsetIdx;
        Offset(i) = res.OffsetIdx;
        Submovement(i) = res.SubStartIdx; % NaN remains NaN
        
        % Parse Submovement Type String to Number
        typeStr = res.SubType;
        if typeStr == "None"
            Type(i) = NaN;
        else
            % Extract number from "Type X"
            val = sscanf(typeStr, "Type %d");
            if isempty(val)
                Type(i) = NaN;
            else
                Type(i) = val;
            end
        end
    end
    
    % Create Table
    T = table(ID, Onset, Offset, Submovement, Type);
    
    % Write to CSV
    writetable(T, fullPath);
end