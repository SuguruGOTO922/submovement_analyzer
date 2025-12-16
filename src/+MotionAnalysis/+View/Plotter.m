classdef Plotter < handle
    % Plotter: Handles data visualization using styles from GraphStyle.
    % Part of the View layer.
    
    methods (Static)
        function update(axesHandles, batchData, highlightIdx, axisMap, visOptions)
            % UPDATE Updates plots on the given axes.
            %
            % Inputs:
            %   axesHandles  : Struct (.Ax3D, .AxVel, .AxAcc, .AxJerk)
            %   batchData    : Data structure from Model
            %   highlightIdx : Index of file to highlight
            %   axisMap      : [X_Col, Y_Col, Z_Col]
            %   visOptions   : Struct (.ShowGrid, .ShowTraj, .ShowEvents)
            
            if nargin < 4; axisMap = [1 2 3]; end
            if nargin < 5
                visOptions.ShowGrid = true;
                visOptions.ShowTraj = true;
                visOptions.ShowEvents = true;
            end
            
            % Import Style Definitions from the View package
            import MotionAnalysis.View.GraphStyle
            
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
            
            % Apply Grid Option
            if visOptions.ShowGrid
                grid(ax3D, 'on'); grid(axVel, 'on'); grid(axAcc, 'on'); grid(axJerk, 'on');
            else
                grid(ax3D, 'off'); grid(axVel, 'off'); grid(axAcc, 'off'); grid(axJerk, 'off');
            end
            
            % Helper to map position
            function pMapped = mapPos(pRaw)
                pMapped = pRaw(:, axisMap); 
            end
            
            % 1. Draw Ghost Traces (Background)
            % Only draw if ShowTraj is ON to avoid clutter when hiding traces
            if visOptions.ShowTraj
                for i = 1:length(batchData)
                    if i == highlightIdx; continue; end
                    if isempty(batchData(i).Results); continue; end
                    
                    res = batchData(i).Results;
                    t = res.Time;
                    posM = mapPos(res.PosSmooth);
                    
                    % Plot 3D Ghost
                    plot3(ax3D, posM(:,1), posM(:,2), posM(:,3), ...
                        'Color', GraphStyle.ColorGhost, ...
                        'LineStyle', GraphStyle.LineStyleSolid, ...
                        'LineWidth', GraphStyle.WidthGhost);
                    
                    % Plot Kinematics Ghost
                    plot(axVel, t, res.ProjVel, 'Color', GraphStyle.ColorGhost, 'LineWidth', GraphStyle.WidthGhost);
                    plot(axAcc, t, res.ProjAcc, 'Color', GraphStyle.ColorGhost, 'LineWidth', GraphStyle.WidthGhost);
                    plot(axJerk, t, res.ProjJerk, 'Color', GraphStyle.ColorGhost, 'LineWidth', GraphStyle.WidthGhost);
                end
            end
            
            % 2. Draw Highlighted Trace (Foreground)
            res = batchData(highlightIdx).Results;
            if isempty(res); return; end
            
            t = res.Time;
            posM = mapPos(res.PosSmooth);
            
            % --- 3D Trajectory ---
            if visOptions.ShowTraj
                plot3(ax3D, posM(:,1), posM(:,2), posM(:,3), ...
                    'Color', GraphStyle.ColorHighlight, ...
                    'LineStyle', GraphStyle.LineStyleSolid, ...
                    'LineWidth', GraphStyle.WidthHighlight);
            end
            
            % --- Events (Markers) ---
            if visOptions.ShowEvents
                startPt = mapPos(res.PosSmooth(res.OnsetIdx, :));
                endPt   = mapPos(res.PosSmooth(res.OffsetIdx, :));
                
                plot3(ax3D, startPt(1), startPt(2), startPt(3), ...
                    'Marker', GraphStyle.MarkerCircle, ...
                    'MarkerEdgeColor', GraphStyle.ColorStart, ...
                    'MarkerFaceColor', GraphStyle.ColorStart);
                    
                plot3(ax3D, endPt(1), endPt(2), endPt(3), ...
                    'Marker', GraphStyle.MarkerCircle, ...
                    'MarkerEdgeColor', GraphStyle.ColorEnd, ...
                    'MarkerFaceColor', GraphStyle.ColorEnd);
                
                if ~isnan(res.SubStartIdx)
                    subPt = mapPos(res.PosSmooth(res.SubStartIdx, :));
                    plot3(ax3D, subPt(1), subPt(2), subPt(3), ...
                        'Marker', GraphStyle.MarkerSquare, ...
                        'MarkerSize', GraphStyle.SizeLarge, ...
                        'MarkerEdgeColor', GraphStyle.ColorSub, ...
                        'MarkerFaceColor', GraphStyle.ColorSub);
                end
            end
            
            % Labels
            labels = ["Col 1", "Col 2", "Col 3"];
            title(ax3D, ["3D Trajectory", "File: " + batchData(highlightIdx).FileName], 'Interpreter', 'none');
            xlabel(ax3D, "X (" + labels(axisMap(1)) + ")");
            ylabel(ax3D, "Y (" + labels(axisMap(2)) + ")");
            zlabel(ax3D, "Z (" + labels(axisMap(3)) + ")");

            % --- Kinematics Helper ---
            function drawEvents(ax, yData, titleStr)
                if visOptions.ShowTraj
                    plot(ax, t, yData, ...
                        'Color', GraphStyle.ColorHighlight, ...
                        'LineStyle', GraphStyle.LineStyleSolid, ...
                        'LineWidth', GraphStyle.WidthHighlight);
                end
                
                if visOptions.ShowEvents
                    % Onset
                    xline(ax, t(res.OnsetIdx), ...
                        'Color', GraphStyle.ColorStart, ...
                        'LineStyle', GraphStyle.LineStyleDash, ...
                        'LineWidth', GraphStyle.WidthEvent);
                    % Offset
                    xline(ax, t(res.OffsetIdx), ...
                        'Color', GraphStyle.ColorEnd, ...
                        'LineStyle', GraphStyle.LineStyleDash, ...
                        'LineWidth', GraphStyle.WidthEvent);
                    % Submovement
                    if ~isnan(res.SubStartIdx)
                        xline(ax, t(res.SubStartIdx), ...
                            'Color', GraphStyle.ColorSub, ...
                            'LineStyle', GraphStyle.LineStyleSolid, ...
                            'LineWidth', GraphStyle.WidthHighlight);
                    end
                end
                
                yline(ax, 0, ...
                    'Color', GraphStyle.ColorZeroLine, ...
                    'LineStyle', GraphStyle.LineStyleSolid);
                    
                title(ax, titleStr);
            end

            drawEvents(axVel, res.ProjVel, 'Velocity (Primary Axis)');
            
            % Acceleration (PNA is special event)
            drawEvents(axAcc, res.ProjAcc, 'Acceleration (Primary Axis)');
            if visOptions.ShowEvents
                xline(axAcc, t(res.PNAIdx), ...
                    'Color', GraphStyle.ColorZeroLine, ...
                    'LineStyle', GraphStyle.LineStyleDot, ...
                    'Label', GraphStyle.LabelPNA);
            end
            
            drawEvents(axJerk, res.ProjJerk, 'Jerk (Primary Axis)');
        end
    end
end