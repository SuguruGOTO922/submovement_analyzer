classdef Resources
    % Resources: Central repository for string constants and configuration.
    
    properties (Constant)
        AppTag  = 'SubmovementAnalyzer_Singleton_Tag';
        AppName = 'SubmovementAnalyzer v8.2';

        Title_TabImport      = '1. Import';
        Title_TabAnalyze     = '2. Analyze';
        Title_TabResult      = '3. Result'; 
        Title_TabExport      = '4. Export';

        % ... (Import, Axis, Filter, Analysis sections are unchanged) ...
        Label_ImportSettings = 'CSV Format';
        Label_TimeCol        = 'Time Col:';
        Label_PosCol         = 'Pos Start:';
        Label_HeaderRow      = 'Header Row';
        Label_AxisMapping    = '3D Axis Mapping';
        Label_PlotX          = 'Plot X (Col):';
        Label_PlotY          = 'Plot Y (Col):';
        Label_PlotZ          = 'Plot Z (Col):';
        Label_FilterSettings = 'Filter Settings';
        Label_FilterOrder    = 'Order:';
        Label_Cutoff         = 'Cutoff (Hz):';
        Label_FsAuto         = 'Auto Fs:';
        Label_FsVal          = 'Manual Fs (Hz):';
        Label_AnalysisParams = 'Detection Params';
        Label_VelThresh      = 'Vel Thresh (mm/s):';
        Label_MinDur         = 'Min Dur (ms):';
        Text_LoadButton      = 'Load CSV Files';
        Text_AnalyzeButton   = 'Run Analysis';
        Text_ExportButton    = 'Export to CSV';
        Label_ResultTable    = 'Analysis Results:';
        
        % --- Export Options (Refined) ---
        Label_ExportOpts     = 'Output Options';
        
        % Category Labels (Bold in UI)
        Label_CatGeneral     = 'General';
        Label_CatCoords      = 'Coordinates (XYZ)';
        Label_CatMetrics     = 'Kinematic Metrics';
        
        % Checkboxes
        Check_Type           = 'Submovement Type';
        Check_OnsetPos       = 'Onset Position';
        Check_OffsetPos      = 'Offset Position';
        Check_SubPos         = 'Submov Position';
        
        Check_TotalDur       = 'Total Duration';
        Check_TimeSub        = 'Time to Submov';
        Check_SubDur         = 'Submov Duration';
        Check_MaxVel         = 'Max Velocity';
        Check_SubMaxVel      = 'Sub Max Velocity';
        
        % ... (Messages unchanged) ...
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
        Tab_3DTrajectory     = '3D Trajectory';
        Tab_Kinematics       = 'Kinematics';
    end
end