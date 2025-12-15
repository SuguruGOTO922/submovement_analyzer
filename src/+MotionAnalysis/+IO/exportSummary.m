function exportSummary(batchData, fullPath, options)
% EXPORTSUMMARY Exports results based on granular options.
%
% options fields:
%   .IncType        (bool)
%   .IncOnsetPos    (bool) -> Onset_X, Onset_Y, Onset_Z
%   .IncOffsetPos   (bool)
%   .IncSubPos      (bool)
%   .IncTotalDur    (bool)
%   .IncTimeToSub   (bool)
%   .IncSubDur      (bool)
%   .IncMaxVel      (bool)
%   .IncSubMaxVel   (bool)

    import MotionAnalysis.Algorithms.calculateMetrics

    nFiles = length(batchData);
    
    % --- 1. Base Columns (Mandatory) ---
    ID = strings(nFiles, 1);
    Onset_Frame = zeros(nFiles, 1);
    Offset_Frame = zeros(nFiles, 1);
    Sub_Frame = zeros(nFiles, 1);
    
    % --- 2. Optional Arrays Initialization ---
    % General
    if options.IncType, Sub_Type = zeros(nFiles, 1); end
    
    % Coordinates
    if options.IncOnsetPos
        Onset_X = zeros(nFiles, 1); Onset_Y = zeros(nFiles, 1); Onset_Z = zeros(nFiles, 1);
    end
    if options.IncOffsetPos
        Offset_X = zeros(nFiles, 1); Offset_Y = zeros(nFiles, 1); Offset_Z = zeros(nFiles, 1);
    end
    if options.IncSubPos
        Sub_X = zeros(nFiles, 1); Sub_Y = zeros(nFiles, 1); Sub_Z = zeros(nFiles, 1);
    end
    
    % Metrics
    if options.IncTotalDur,  Total_Duration = zeros(nFiles, 1); end
    if options.IncTimeToSub, Time_To_Sub = zeros(nFiles, 1); end
    if options.IncSubDur,    Sub_Duration = zeros(nFiles, 1); end
    if options.IncMaxVel,    Max_Vel = zeros(nFiles, 1); end
    if options.IncSubMaxVel, Sub_Max_Vel = zeros(nFiles, 1); end
    
    % --- 3. Loop Data ---
    for i = 1:nFiles
        if isempty(batchData(i).Results); continue; end
        res = batchData(i).Results;
        
        % Mandatory
        ID(i) = batchData(i).FileName;
        Onset_Frame(i) = res.OnsetIdx;
        Offset_Frame(i) = res.OffsetIdx;
        Sub_Frame(i) = res.SubStartIdx;
        
        % Type
        if options.IncType
            typeStr = res.SubType;
            if typeStr == "None"
                Sub_Type(i) = NaN;
            else
                val = sscanf(typeStr, "Type %d");
                if isempty(val), Sub_Type(i) = NaN; else, Sub_Type(i) = val; end
            end
        end
        
        % Coords
        if options.IncOnsetPos
            p = res.PosSmooth(res.OnsetIdx, :);
            Onset_X(i)=p(1); Onset_Y(i)=p(2); Onset_Z(i)=p(3);
        end
        if options.IncOffsetPos
            p = res.PosSmooth(res.OffsetIdx, :);
            Offset_X(i)=p(1); Offset_Y(i)=p(2); Offset_Z(i)=p(3);
        end
        if options.IncSubPos
            if ~isnan(res.SubStartIdx)
                p = res.PosSmooth(res.SubStartIdx, :);
                Sub_X(i)=p(1); Sub_Y(i)=p(2); Sub_Z(i)=p(3);
            else
                Sub_X(i)=NaN; Sub_Y(i)=NaN; Sub_Z(i)=NaN;
            end
        end
        
        % Metrics (Calculate only if needed)
        if options.IncTotalDur || options.IncTimeToSub || options.IncSubDur || options.IncMaxVel || options.IncSubMaxVel
            m = calculateMetrics(res);
            if options.IncTotalDur,  Total_Duration(i) = m.TotalDuration; end
            if options.IncTimeToSub, Time_To_Sub(i)    = m.TimeToSub; end
            if options.IncSubDur,    Sub_Duration(i)   = m.SubDuration; end
            if options.IncMaxVel,    Max_Vel(i)        = m.MaxVel; end
            if options.IncSubMaxVel, Sub_Max_Vel(i)    = m.SubMaxVel; end
        end
    end
    
    % --- 4. Build Table Dynamically ---
    T = table(ID, Onset_Frame, Offset_Frame, Sub_Frame);
    
    if options.IncType,      T = addvars(T, Sub_Type); end
    
    if options.IncOnsetPos,  T = addvars(T, Onset_X, Onset_Y, Onset_Z); end
    if options.IncOffsetPos, T = addvars(T, Offset_X, Offset_Y, Offset_Z); end
    if options.IncSubPos,    T = addvars(T, Sub_X, Sub_Y, Sub_Z); end
    
    if options.IncTotalDur,  T = addvars(T, Total_Duration); end
    if options.IncTimeToSub, T = addvars(T, Time_To_Sub); end
    if options.IncSubDur,    T = addvars(T, Sub_Duration); end
    if options.IncMaxVel,    T = addvars(T, Max_Vel); end
    if options.IncSubMaxVel, T = addvars(T, Sub_Max_Vel); end
    
    % Write
    writetable(T, fullPath);
end