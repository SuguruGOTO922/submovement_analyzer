classdef Resources
    % Resources: Central repository for string constants and configuration.
    
    properties (Constant)
        AppTag  = 'SubmovementAnalyzer_Singleton_Tag';
        AppName = 'SubmovementAnalyzer v9.1';

        Title_TabImport      = '1. Import';
        Title_TabAnalyze     = '2. Analyze';
        Title_TabVis         = '3. Visualization';
        Title_TabExport      = '4. Export';

        % UI Text: Import Section
        Label_ImportSettings = 'CSV Format';
        Label_TimeCol        = 'Time Col:';
        Label_PosCol         = 'Pos Start:';
        Label_HeaderRow      = 'Header Row';
        Label_Unit           = 'Unit:';
        Items_Unit           = {'mm', 'cm', 'm'};

        % UI Text: Visualization Section (New Structure)
        Label_VisSettings    = 'Visualization Settings'; % New Panel Title
        Label_AxisMapping    = 'Axis Mapping';           % Sub-header
        Label_VisOptions     = 'Display Options';        % Sub-header
        
        Label_PlotX          = 'X (Col):'; % Shortened
        Label_PlotY          = 'Y (Col):';
        Label_PlotZ          = 'Z (Col):';
        
        Check_ShowGrid       = 'Show Grid';
        Check_ShowTraj       = 'Show Trajectory';
        Check_ShowEvents     = 'Show Events';

        % UI Text: Filter & Fs Section
        Label_FilterSettings = 'Filter Settings';
        Label_FilterOrder    = 'Order:';
        Label_Cutoff         = 'Cutoff (Hz):';
        Label_FsAuto         = 'Auto Fs:';
        Label_FsVal          = 'Manual Fs (Hz):';

        % UI Text: Analysis Params Section
        Label_AnalysisParams = 'Detection Params';
        Label_VelThresh      = 'Vel Thresh (mm/s):';
        Label_MinDur         = 'Min Dur (ms):';

        % UI Text: Actions
        Text_LoadButton      = 'Load CSV Files';
        Text_AnalyzeButton   = 'Run Analysis';
        Text_ExportButton    = 'Export to CSV';
        
        % UI Text: Result View
        Label_ResultTable    = 'Analysis Results:';
        
        % UI Text: Export Options
        Label_ExportOpts     = 'Output Options';
        Label_CatGeneral     = 'General';
        Label_CatCoords      = 'Coordinates (XYZ)';
        Label_CatMetrics     = 'Kinematic Metrics';
        Check_Type           = 'Submovement Type';
        Check_OnsetPos       = 'Onset Position';
        Check_OffsetPos      = 'Offset Position';
        Check_SubPos         = 'Submov Position';
        Check_TotalDur       = 'Total Duration';
        Check_TimeSub        = 'Time to Submov';
        Check_SubDur         = 'Submov Duration';
        Check_MaxVel         = 'Max Velocity';
        Check_SubMaxVel      = 'Sub Max Velocity';
        
        % Messages
        Text_Ready           = 'Ready.';
        Msg_SelectCSV        = 'Select CSV Files';
        Msg_LoadedCount      = 'Loaded %d files.'; 
        Msg_AnalyzeProgressTitle = 'Analyzing...';
        Msg_AnalyzeStart     = 'Starting...';
        Msg_AnalyzeComplete  = 'Analysis Complete.';
        Msg_AnalyzeErrorTitle = 'Analysis Error';
        Msg_SaveBatchTitle   = 'Save Batch Results';
        Msg_ExportSuccess    = 'Export successful.';
        Msg_ExportSuccessTitle = 'Success';
        Msg_ExportErrorTitle = 'Export Failed';
        
        % Visualization Titles
        Tab_3DTrajectory     = '3D Trajectory';
        Tab_Kinematics       = 'Kinematics';
    end
end