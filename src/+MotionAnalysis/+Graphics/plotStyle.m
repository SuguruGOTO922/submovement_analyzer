function stl = plotStyle()     

    Style = struct(); 
    Style.GhostColor       = [0.8 0.8 0.8];
    Style.GhostWidth       = 0.5;
    
    Style.BaseColor        = [0.5, 0.5, 0.5]; 
    Style.BaseWidth        = 1.5; 
    Style.HighlightColor   = [0.044, 0.112, 0.385]; % Keio blue 
    Style.HighlightWidth   = 2.0;
    Style.SubHighlightColor = [0.945, 0.811, 0.190]; % Keio yellow 
    Style.SubHighlightWidth = 2.0; 
    
    Style.MarkerStart      = '^';
    Style.MarkerStartFace  =  [0.693, 0.001, 0.123];
    Style.MarkerStartWidth = 2.0; 
    
    Style.MarkerEnd        = 'v';
    Style.MarkerEndFace    =  [0.693, 0.001, 0.123];
    Style.MarkerEndWidth   = 2.0; 
    
    Style.MarkerSub        = 's';
    Style.MarkerSubFace    = [0.693, 0.001, 0.123];
    Style.MarkerSubSize    = 10;
    
    Style.LineOnset        = '--';
    Style.LineOnsetColor =  [0.693, 0.001, 0.123];
    Style.LineOffset       = '--';
    Style.LineOffsetColor =  [0.693, 0.001, 0.123];
    Style.LineSub          = '-';
    Style.LineSubColor     = [0.693, 0.001, 0.123];
    Style.LineOnsetWidth   = 1.5; 
    Style.LineOffsetWidth  = 1.5; 
    Style.LineSubWidth     = 1.5;
    
    Style.LineZero         = 'k-';
    Style.LinePNA          = '--';
    Style.LinePNAColor     = [0.693, 0.001, 0.123];
    Style.LinePNAWidth     = 1.5; 
    Style.LinePNALabel     = 'PNA';

    stl = Style; 
end 