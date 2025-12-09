function updatePlots(axesHandles, batchData, highlightIdx, axisMap)
% UPDATEPLOTS Updates all visualizations with centralized style management.

    if nargin < 4; axisMap = [1 2 3]; end

    % STYLE CONFIGURATION (Centralized)
    stl = MotionAnalysis.Graphics.plotStyle(); 

    ax3D = axesHandles.Ax3D;
    axVel = axesHandles.AxVel;
    axAcc = axesHandles.AxAcc;
    axJerk = axesHandles.AxJerk;

    % Reset Axes
    cla(ax3D);   grid(ax3D, 'on');   axis(ax3D, 'equal'); hold(ax3D, 'on');
    cla(axVel);  grid(axVel, 'on');  hold(axVel, 'on');
    cla(axAcc);  grid(axAcc, 'on');  hold(axAcc, 'on');
    cla(axJerk); grid(axJerk, 'on'); hold(axJerk, 'on');
    
    % Helper map function
    function pMapped = mapPos(pRaw)
        pMapped = pRaw(:, axisMap);
    end
    
    % 1. Draw Ghost Traces
    for i = 1:length(batchData)
        if i == highlightIdx; continue; end
        if isempty(batchData(i).Results); continue; end
        
        res = batchData(i).Results;
        t = res.Time;
        posM = mapPos(res.PosSmooth);
        
        plot3(ax3D, posM(:,1), posM(:,2), posM(:,3), ...
            'Color', stl.GhostColor, 'LineWidth', stl.GhostWidth);
        
        plot(axVel, t, res.ProjVel, 'Color', stl.GhostColor, 'LineWidth', stl.GhostWidth);
        plot(axAcc, t, res.ProjAcc, 'Color', stl.GhostColor, 'LineWidth', stl.GhostWidth);
        plot(axJerk, t, res.ProjJerk, 'Color', stl.GhostColor, 'LineWidth', stl.GhostWidth);
    end
    
    % 2. Draw Highlighted Trace
    res = batchData(highlightIdx).Results;
    if isempty(res); return; end
    
    t = res.Time;
    posM = mapPos(res.PosSmooth);
    
    % 3D
    plot3(ax3D, posM(:,1), posM(:,2), posM(:,3), ...
            'Color', stl.BaseColor, 'LineWidth', stl.BaseWidth);
    plot3(ax3D, posM(res.OnsetIdx:res.OffsetIdx, 1), ...
                posM(res.OnsetIdx:res.OffsetIdx, 2), ...
                posM(res.OnsetIdx:res.OffsetIdx, 3), ...
                'Color', stl.HighlightColor, 'LineWidth', stl.HighlightWidth)
    
    % Markers
    stPt = mapPos(res.PosSmooth(res.OnsetIdx,  :));
    edPt = mapPos(res.PosSmooth(res.OffsetIdx, :));
    
    plot3(ax3D, stPt(1), stPt(2), stPt(3), stl.MarkerStart, 'MarkerEdgeColor', stl.MarkerStartFace, ...
        'LineWidth', stl.MarkerStartWidth);
    plot3(ax3D, edPt(1), edPt(2), edPt(3), stl.MarkerEnd,   'MarkerEdgeColor', stl.MarkerEndFace, ...
        'LineWidth', stl.MarkerEndWidth);
    
    if ~isnan(res.SubStartIdx)
        subPt = mapPos(res.PosSmooth(res.SubStartIdx:res.OffsetIdx, :));
        plot3(ax3D, subPt(:,1), subPt(:,2), subPt(:,3), ...
            'Color', stl.SubHighlightColor, 'LineWidth', stl.SubHighlightWidth); 
        plot3(ax3D, subPt(1,1), subPt(1,2), subPt(1,3), stl.MarkerSub, ...
            'MarkerFaceColor', stl.MarkerSubFace, 'MarkerSize', stl.MarkerSubSize);
    end
    
    labels = ["Col 1", "Col 2", "Col 3"];
    title(ax3D, ["3D Trajectory", "File: " + batchData(highlightIdx).FileName], 'Interpreter', 'none');
    xlabel(ax3D, "X (" + labels(axisMap(1)) + ")");
    ylabel(ax3D, "Y (" + labels(axisMap(2)) + ")");
    zlabel(ax3D, "Z (" + labels(axisMap(3)) + ")");

    % Kinematics Helper
    function drawEvents(ax, yData, titleStr)
       plot(ax, t, yData, 'Color', stl.BaseColor, 'LineWidth', stl.BaseWidth);
        plot(ax, t(res.OnsetIdx:res.OffsetIdx), yData(res.OnsetIdx:res.OffsetIdx), ...
            'Color', stl.HighlightColor, 'LineWidth', stl.HighlightWidth);
        xline(ax, t(res.OnsetIdx), stl.LineOnset, 'Color', stl.LineOnsetColor, 'LineWidth', stl.LineOnsetWidth);
        xline(ax, t(res.OffsetIdx), stl.LineOffset, 'Color', stl.LineOffsetColor, 'LineWidth', stl.LineOffsetWidth);
        if ~isnan(res.SubStartIdx)
            xline(ax, t(res.SubStartIdx), 'LineStyle', stl.LineSub, ...
                'Color', stl.LineSubColor, 'LineWidth', stl.LineSubWidth);
            subT = t(res.SubStartIdx:res.OffsetIdx, :);
            subYData = yData(res.SubStartIdx:res.OffsetIdx, :);
            plot(ax, subT, subYData, 'Color', stl.SubHighlightColor, 'LineWidth', stl.SubHighlightWidth); 
        end
        yline(ax, 0, stl.LineZero);
        title(ax, titleStr);
    end

    drawEvents(axVel, res.ProjVel, 'Velocity (Primary Axis)');
    drawEvents(axAcc, res.ProjAcc, 'Acceleration (Primary Axis)');
    xline(axAcc, t(res.PNAIdx), stl.LinePNA, stl.LinePNALabel, ...
        'Color', stl.LinePNAColor, 'LineWidth', stl.LinePNAWidth); 
    drawEvents(axJerk, res.ProjJerk, 'Jerk (Primary Axis)');
end