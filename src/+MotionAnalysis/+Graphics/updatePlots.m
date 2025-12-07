function updatePlots(axesHandles, batchData, highlightIdx, axisMap)
% UPDATEPLOTS Updates all visualizations based on the selected file.
%
% Inputs:
%   axesHandles  : Struct containing handles to .Ax3D, .AxVel, .AxAcc, .AxJerk
%   batchData    : Struct array of loaded data and results
%   highlightIdx : Index of the file to highlight
%   axisMap      : [New] 1x3 vector for X,Y,Z mapping (e.g., [1, 2, 3])

    if nargin < 4; axisMap = [1 2 3]; end

    % Unpack handles
    ax3D = axesHandles.Ax3D;
    axVel = axesHandles.AxVel;
    axAcc = axesHandles.AxAcc;
    axJerk = axesHandles.AxJerk;

    % Reset Axes
    cla(ax3D); grid(ax3D, 'on'); axis(ax3D, 'equal'); hold(ax3D, 'on');
    cla(axVel); grid(axVel, 'on'); hold(axVel, 'on');
    cla(axAcc); grid(axAcc, 'on'); hold(axAcc, 'on');
    cla(axJerk); grid(axJerk, 'on'); hold(axJerk, 'on');
    
    grayColor = [0.8 0.8 0.8]; 
    
    % --- Helper to map position columns to plot axes ---
    function pMapped = mapPos(pRaw)
        % pRaw is N x 3 (Original Data columns 1,2,3)
        % axisMap contains indices. e.g., if axisMap is [2, 1, 3]:
        % PlotX takes Col 2, PlotY takes Col 1, PlotZ takes Col 3.
        pMapped = pRaw(:, axisMap);
    end
    
    % --- 1. Draw Ghost Traces (Background) ---
    for i = 1:length(batchData)
        if i == highlightIdx; continue; end
        if isempty(batchData(i).Results); continue; end
        
        res = batchData(i).Results;
        t = res.Time;
        
        % Map 3D coords according to user setting
        posM = mapPos(res.PosSmooth);
        
        plot3(ax3D, posM(:,1), posM(:,2), posM(:,3), ...
            'Color', grayColor, 'LineWidth', 0.5);
        
        % Kinematics (Scalar values, no mapping needed usually)
        plot(axVel, t, res.ProjVel, 'Color', grayColor, 'LineWidth', 0.5);
        plot(axAcc, t, res.ProjAcc, 'Color', grayColor, 'LineWidth', 0.5);
        plot(axJerk, t, res.ProjJerk, 'Color', grayColor, 'LineWidth', 0.5);
    end
    
    % --- 2. Draw Highlighted Trace (Foreground) ---
    res = batchData(highlightIdx).Results;
    if isempty(res); return; end
    
    t = res.Time;
    posM = mapPos(res.PosSmooth); % Map highlighted trace
    
    % 3D Trajectory
    plot3(ax3D, posM(:,1), posM(:,2), posM(:,3), ...
        'Color', 'b', 'LineWidth', 1.5);
    
    % Markers (Start/End/Sub) - Need to map these points too
    startPt = mapPos(res.PosSmooth(res.OnsetIdx, :));
    endPt   = mapPos(res.PosSmooth(res.OffsetIdx, :));
    
    plot3(ax3D, startPt(1), startPt(2), startPt(3), 'go', 'MarkerFaceColor','g');
    plot3(ax3D, endPt(1), endPt(2), endPt(3), 'ro', 'MarkerFaceColor','r');
    
    if ~isnan(res.SubStartIdx)
        subPt = mapPos(res.PosSmooth(res.SubStartIdx, :));
        plot3(ax3D, subPt(1), subPt(2), subPt(3), 'ms', 'MarkerFaceColor','m', 'MarkerSize', 8);
    end
    
    % Update Title with Mapping Info
    labels = ["Data Col 1", "Data Col 2", "Data Col 3"];
    title(ax3D, ["File: " + batchData(highlightIdx).FileName], 'Interpreter', 'none');
    xlabel(ax3D, "X (Src: " + labels(axisMap(1)) + ")");
    ylabel(ax3D, "Y (Src: " + labels(axisMap(2)) + ")");
    zlabel(ax3D, "Z (Src: " + labels(axisMap(3)) + ")");

    % --- Helper Function for Kinematics ---
    function drawEvents(ax, yData, titleStr)
        plot(ax, t, yData, 'b', 'LineWidth', 1.5);
        xline(ax, t(res.OnsetIdx), 'g--');
        xline(ax, t(res.OffsetIdx), 'r--');
        if ~isnan(res.SubStartIdx)
            xline(ax, t(res.SubStartIdx), 'm-', 'LineWidth', 1.5);
        end
        yline(ax, 0, 'k-');
        title(ax, titleStr);
    end

    drawEvents(axVel, res.ProjVel, 'Velocity (Primary Axis)');
    drawEvents(axAcc, res.ProjAcc, 'Acceleration (Primary Axis)');
    xline(axAcc, t(res.PNAIdx), 'k:', 'Label', 'PNA');
    drawEvents(axJerk, res.ProjJerk, 'Jerk (Primary Axis)');
end