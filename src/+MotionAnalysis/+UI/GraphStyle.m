classdef GraphStyle
    % GraphStyle: Centralized repository for plot styles and colors.
    % Edit this file to change the appearance of charts.
    
    properties (Constant)
        % --- Colors (RGB Triplets) ---
        ColorGhost     = [0.80, 0.80, 0.80]; % Light Gray
        ColorHighlight = [0.00, 0.45, 0.74]; % MATLAB Blue
        ColorZeroLine  = [0.00, 0.00, 0.00]; % Black
        
        ColorStart     = [0.00, 1.00, 0.00]; % Green
        ColorEnd       = [1.00, 0.00, 0.00]; % Red
        ColorSub       = [1.00, 0.00, 1.00]; % Magenta
        
        % --- Line Styles ---
        LineStyleSolid  = '-';
        LineStyleDash   = '--';
        LineStyleDot    = ':';
        
        % --- Line Widths ---
        WidthGhost     = 0.5;
        WidthHighlight = 1.5;
        WidthEvent     = 1.0;
        
        % --- Markers ---
        MarkerCircle   = 'o';
        MarkerSquare   = 's';
        
        % --- Marker Sizes ---
        SizeStandard   = 6;
        SizeLarge      = 8;
        
        % --- Text Labels ---
        LabelPNA       = 'PNA';
    end
end