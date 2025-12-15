classdef Plotter < handle
    
    % ... (Style Constants unchanged) ...
    properties (Constant)
        GhostColor       = [0.8 0.8 0.8];
        GhostWidth       = 0.5;
        HighlightColor   = [0 0.4470 0.7410]; 
        HighlightWidth   = 1.5;
        MarkerStart      = 'go';
        MarkerStartFace  = 'g';
        MarkerEnd        = 'ro';
        MarkerEndFace    = 'r';
        MarkerSub        = 'ms';
        MarkerSubFace    = 'm';
        MarkerSubSize    = 8;
        LineOnset        = 'g--';
        LineOffset       = 'r--';
        LineSub          = 'm-';
        LineSubWidth     = 1.5;
        LineZero         = 'k-';
        LinePNA          = 'k:';
        LinePNALabel     = 'PNA';
    end
    
    methods (Static)
        function update(axesHandles, batchData, highlightIdx, axisMap, visOptions)
            % UPDATE Updates plots based on options.
            % visOptions: struct(.ShowGrid, .ShowTraj, .ShowEvents)
            
            if nargin < 4; axisMap = [1 2 3]; end
            % Default options if not provided
            if nargin < 5
                visOptions.ShowGrid = true;
                visOptions.ShowTraj = true;
                visOptions.ShowEvents = true;
            end
            
            import MotionAnalysis.UI.Plotter
            
            ax3D = axesHandles.Ax3D;
            axVel = axesHandles.AxVel;
            axAcc = axesHandles.AxAcc;
            axJerk = axesHandles.AxJerk;

            % Reset Axes
            cla(ax3D); axis(ax3D, 'equal'); hold(ax3D, 'on');
            cla(axVel); hold(axVel, 'on');
            cla(axAcc); hold(axAcc, 'on');
            cla(axJerk); hold(axJerk, 'on');
            
            % --- Apply Grid Option ---
            if visOptions.ShowGrid
                grid(ax3D, 'on'); grid(axVel, 'on'); grid(axAcc, 'on'); grid(axJerk, 'on');
            else
                grid(ax3D, 'off'); grid(axVel, 'off'); grid(axAcc, 'off'); grid(axJerk, 'off');
            end
            
            function pMapped = mapPos(pRaw)
                pMapped = pRaw(:, axisMap);
            end
            
            % 1. Draw Ghost Traces (Background) - Always draw if Traj is on? Or separate option?
            % Assuming 'Show Trajectory' applies to foreground primarily, but keeping background for context is standard.
            % Let's hide ghosts if ShowTraj is off for clarity.
            if visOptions.ShowTraj
                for i = 1:length(batchData)
                    if i == highlightIdx; continue; end
                    if isempty(batchData(i).Results); continue; end
                    res = batchData(i).Results;
                    t = res.Time;
                    posM = mapPos(res.PosSmooth);
                    plot3(ax3D, posM(:,1), posM(:,2), posM(:,3), 'Color', Plotter.GhostColor, 'LineWidth', Plotter.GhostWidth);
                    plot(axVel, t, res.ProjVel, 'Color', Plotter.GhostColor, 'LineWidth', Plotter.GhostWidth);
                    plot(axAcc, t, res.ProjAcc, 'Color', Plotter.GhostColor, 'LineWidth', Plotter.GhostWidth);
                    plot(axJerk, t, res.ProjJerk, 'Color', Plotter.GhostColor, 'LineWidth', Plotter.GhostWidth);
                end
            end
            
            % 2. Draw Highlighted Trace
            res = batchData(highlightIdx).Results;
            if isempty(res); return; end
            t = res.Time;
            posM = mapPos(res.PosSmooth);
            
            % --- Trajectory ---
            if visOptions.ShowTraj
                plot3(ax3D, posM(:,1), posM(:,2), posM(:,3), ...
                    'Color', Plotter.HighlightColor, 'LineWidth', Plotter.HighlightWidth);
            end
            
            % --- Events (Markers) ---
            if visOptions.ShowEvents
                startPt = mapPos(res.PosSmooth(res.OnsetIdx, :));
                endPt   = mapPos(res.PosSmooth(res.OffsetIdx, :));
                
                plot3(ax3D, startPt(1), startPt(2), startPt(3), Plotter.MarkerStart, 'MarkerFaceColor', Plotter.MarkerStartFace);
                plot3(ax3D, endPt(1), endPt(2), endPt(3), Plotter.MarkerEnd, 'MarkerFaceColor', Plotter.MarkerEndFace);
                
                if ~isnan(res.SubStartIdx)
                    subPt = mapPos(res.PosSmooth(res.SubStartIdx, :));
                    plot3(ax3D, subPt(1), subPt(2), subPt(3), Plotter.MarkerSub, ...
                        'MarkerFaceColor', Plotter.MarkerSubFace, 'MarkerSize', Plotter.MarkerSubSize);
                end
            end
            
            labels = ["Col 1", "Col 2", "Col 3"];
            title(ax3D, ["3D Trajectory", "File: " + batchData(highlightIdx).FileName], 'Interpreter', 'none');
            xlabel(ax3D, "X (" + labels(axisMap(1)) + ")");
            ylabel(ax3D, "Y (" + labels(axisMap(2)) + ")");
            zlabel(ax3D, "Z (" + labels(axisMap(3)) + ")");

            % Kinematics Helper
            function drawEvents(ax, yData, titleStr)
                if visOptions.ShowTraj
                    plot(ax, t, yData, 'Color', Plotter.HighlightColor, 'LineWidth', Plotter.HighlightWidth);
                end
                
                if visOptions.ShowEvents
                    xline(ax, t(res.OnsetIdx), Plotter.LineOnset);
                    xline(ax, t(res.OffsetIdx), Plotter.LineOffset);
                    if ~isnan(res.SubStartIdx)
                        xline(ax, t(res.SubStartIdx), Plotter.LineSub, 'LineWidth', Plotter.LineSubWidth);
                    end
                end
                
                yline(ax, 0, Plotter.LineZero);
                title(ax, titleStr);
            end

            drawEvents(axVel, res.ProjVel, 'Velocity (Primary Axis)');
            
            % Acceleration (PNA is an event)
            drawEvents(axAcc, res.ProjAcc, 'Acceleration (Primary Axis)');
            if visOptions.ShowEvents
                xline(axAcc, t(res.PNAIdx), Plotter.LinePNA, 'Label', Plotter.LinePNALabel);
            end
            
            drawEvents(axJerk, res.ProjJerk, 'Jerk (Primary Axis)');
        end
    end
end