classdef MainView < handle
    % MainView: Handles UI component creation and layout.
    
    properties (Access = public)
        UIFigure      matlab.ui.Figure
        MainGrid      matlab.ui.container.GridLayout
        
        LeftPanel     matlab.ui.container.Panel
        LeftMainGrid  matlab.ui.container.GridLayout
        LeftTabGroup  matlab.ui.container.TabGroup
        
        TabImport     matlab.ui.container.Tab
        TabAnalyze    matlab.ui.container.Tab
        TabVis        matlab.ui.container.Tab
        TabExport     matlab.ui.container.Tab
        
        GridImport    matlab.ui.container.GridLayout
        GridAnalyze   matlab.ui.container.GridLayout
        GridVis       matlab.ui.container.GridLayout
        GridExport    matlab.ui.container.GridLayout
        
        % --- TAB 1: Import ---
        SettingsLabel    matlab.ui.control.Label
        TimeColLabel     matlab.ui.control.Label
        TimeColSpinner   matlab.ui.control.Spinner
        PosColLabel      matlab.ui.control.Label
        PosColSpinner    matlab.ui.control.Spinner
        HeaderCheckBox   matlab.ui.control.CheckBox
        UnitLabel        matlab.ui.control.Label
        UnitDropDown     matlab.ui.control.DropDown
        LoadButton       matlab.ui.control.Button
        
        % --- TAB 2: Analyze ---
        FilterLabel      matlab.ui.control.Label
        OrderLabel       matlab.ui.control.Label
        OrderSpinner     matlab.ui.control.Spinner
        CutoffLabel      matlab.ui.control.Label
        CutoffSpinner    matlab.ui.control.Spinner
        FsLabel          matlab.ui.control.Label
        FsValLabel       matlab.ui.control.Label
        FsSpinner        matlab.ui.control.Spinner
        FsAutoCheckBox   matlab.ui.control.CheckBox
        ParamsLabel      matlab.ui.control.Label
        VelThreshLabel   matlab.ui.control.Label
        VelThreshSpinner matlab.ui.control.Spinner
        DurLabel         matlab.ui.control.Label
        DurSpinner       matlab.ui.control.Spinner
        AnalyzeButton    matlab.ui.control.Button
        
        % --- TAB 3: Visualization ---
        VisSettingsPanel matlab.ui.container.Panel
        VisGrid          matlab.ui.container.GridLayout
        
        AxisMapLabel     matlab.ui.control.Label
        AxisXLabel       matlab.ui.control.Label
        AxisXSpinner     matlab.ui.control.Spinner
        AxisYLabel       matlab.ui.control.Label
        AxisYSpinner     matlab.ui.control.Spinner
        AxisZLabel       matlab.ui.control.Label
        AxisZSpinner     matlab.ui.control.Spinner
        
        VisOptLabel      matlab.ui.control.Label
        CheckShowGrid    matlab.ui.control.CheckBox
        CheckShowTraj    matlab.ui.control.CheckBox
        CheckShowEvents  matlab.ui.control.CheckBox
        
        ResultLabel      matlab.ui.control.Label
        ResultTable      matlab.ui.control.Table
        
        % --- TAB 4: Export ---
        ExportLabel      matlab.ui.control.Label
        ExportPanel      matlab.ui.container.Panel
        CatGeneral       matlab.ui.control.Label
        CatCoords        matlab.ui.control.Label
        CatMetrics       matlab.ui.control.Label
        CheckType        matlab.ui.control.CheckBox
        CheckOnsetPos    matlab.ui.control.CheckBox
        CheckOffsetPos   matlab.ui.control.CheckBox
        CheckSubPos      matlab.ui.control.CheckBox
        CheckTotalDur    matlab.ui.control.CheckBox
        CheckTimeSub     matlab.ui.control.CheckBox
        CheckSubDur      matlab.ui.control.CheckBox
        CheckMaxVel      matlab.ui.control.CheckBox
        CheckSubMaxVel   matlab.ui.control.CheckBox
        ExportButton     matlab.ui.control.Button
        
        StatusLabel      matlab.ui.control.Label
        RightTabGroup    matlab.ui.container.TabGroup
        Tab3D            matlab.ui.container.Tab
        Ax3D             matlab.ui.control.UIAxes
        TabKinematics    matlab.ui.container.Tab
        AxVel            matlab.ui.control.UIAxes
        AxAcc            matlab.ui.control.UIAxes
        AxJerk           matlab.ui.control.UIAxes
    end
    
    methods (Access = public)
        function obj = MainView()
            createComponents(obj);
        end
        function delete(obj)
            if isvalid(obj.UIFigure), delete(obj.UIFigure); end
        end
    end
    
    methods (Access = private)
        function createComponents(obj)
            import MotionAnalysis.UI.Resources
            obj.UIFigure = uifigure('Visible', 'off', 'Position', [100 100 1100 780], 'Name', Resources.AppName);
            obj.MainGrid = uigridlayout(obj.UIFigure, 'ColumnWidth', {320, '1x'}, 'RowHeight', {'1x'});

            obj.LeftPanel = uipanel(obj.MainGrid);
            obj.LeftPanel.Layout.Row = 1; obj.LeftPanel.Layout.Column = 1;
            
            obj.LeftMainGrid = uigridlayout(obj.LeftPanel, 'ColumnWidth', {'1x'}, 'RowHeight', {'1x', 'fit'});
            obj.LeftMainGrid.Padding = [0 0 0 0]; obj.LeftMainGrid.RowSpacing = 5;

            obj.LeftTabGroup = uitabgroup(obj.LeftMainGrid);
            obj.LeftTabGroup.Layout.Row = 1;

            obj.TabImport  = uitab(obj.LeftTabGroup, 'Title', Resources.Title_TabImport);
            obj.TabAnalyze = uitab(obj.LeftTabGroup, 'Title', Resources.Title_TabAnalyze);
            obj.TabVis     = uitab(obj.LeftTabGroup, 'Title', Resources.Title_TabVis);
            obj.TabExport  = uitab(obj.LeftTabGroup, 'Title', Resources.Title_TabExport);

            buildImportTab(obj);
            buildAnalyzeTab(obj);
            buildVisTab(obj);
            buildExportTab(obj);

            obj.StatusLabel = uilabel(obj.LeftMainGrid, 'Text', Resources.Text_Ready, ...
                'WordWrap', 'on', 'VerticalAlignment', 'top', 'FontWeight', 'bold');
            obj.StatusLabel.Layout.Row = 2;

            obj.RightTabGroup = uitabgroup(obj.MainGrid);
            obj.RightTabGroup.Layout.Row = 1; obj.RightTabGroup.Layout.Column = 2;
            obj.Tab3D = uitab(obj.RightTabGroup, 'Title', Resources.Tab_3DTrajectory);
            obj.Ax3D = uiaxes(obj.Tab3D, 'Position', [10 10 700 700]); 
            obj.TabKinematics = uitab(obj.RightTabGroup, 'Title', Resources.Tab_Kinematics);
            kg = uigridlayout(obj.TabKinematics, [3, 1]);
            obj.AxVel = uiaxes(kg); obj.AxVel.Layout.Row = 1;
            obj.AxAcc = uiaxes(kg); obj.AxAcc.Layout.Row = 2;
            obj.AxJerk = uiaxes(kg); obj.AxJerk.Layout.Row = 3;
            obj.UIFigure.Visible = 'on';
        end
        
        function buildImportTab(obj)
            import MotionAnalysis.UI.Resources
            obj.GridImport = uigridlayout(obj.TabImport, 'ColumnWidth', {'1x'}, 'RowHeight', {'fit', 'fit', '1x'}); 
            obj.GridImport.Padding = [10 10 10 10]; obj.GridImport.RowSpacing = 15;
            
            p1 = uipanel(obj.GridImport, 'Title', Resources.Label_ImportSettings); p1.Layout.Row = 1;
            g1 = uigridlayout(p1, 'ColumnWidth', {'1x', '1x'}, 'RowHeight', {'fit', 'fit', 'fit', 'fit'});
            
            obj.TimeColLabel = uilabel(g1, 'Text', Resources.Label_TimeCol); obj.TimeColSpinner = uispinner(g1, 'Limits', [1 100], 'Value', 1);
            obj.PosColLabel = uilabel(g1, 'Text', Resources.Label_PosCol); obj.PosColSpinner = uispinner(g1, 'Limits', [1 100], 'Value', 2);
            obj.HeaderCheckBox = uicheckbox(g1, 'Text', Resources.Label_HeaderRow); obj.HeaderCheckBox.Layout.Column = [1 2]; 
            obj.UnitLabel = uilabel(g1, 'Text', Resources.Label_Unit); obj.UnitDropDown = uidropdown(g1, 'Items', Resources.Items_Unit, 'Value', 'mm');

            obj.LoadButton = uibutton(obj.GridImport, 'push', 'Text', Resources.Text_LoadButton, 'FontWeight', 'bold'); obj.LoadButton.Layout.Row = 2;
        end
        
        function buildAnalyzeTab(obj)
            import MotionAnalysis.UI.Resources
            obj.GridAnalyze = uigridlayout(obj.TabAnalyze, 'ColumnWidth', {'1x'}, 'RowHeight', {'fit', 'fit', '1x'});
            obj.GridAnalyze.Padding = [10 10 10 10]; obj.GridAnalyze.RowSpacing = 10;

            pF = uipanel(obj.GridAnalyze, 'Title', Resources.Label_FilterSettings); pF.Layout.Row = 1;
            gF = uigridlayout(pF, 'ColumnWidth', {'fit', '1x'}, 'RowHeight', {'fit', 'fit', 'fit', 'fit'});
            obj.OrderLabel = uilabel(gF, 'Text', Resources.Label_FilterOrder); obj.OrderSpinner = uispinner(gF, 'Limits', [1 10], 'Value', 2);
            obj.CutoffLabel = uilabel(gF, 'Text', Resources.Label_Cutoff); obj.CutoffSpinner = uispinner(gF, 'Limits', [0.1 500], 'Value', 10);
            obj.FsLabel = uilabel(gF, 'Text', Resources.Label_FsAuto); obj.FsAutoCheckBox = uicheckbox(gF, 'Text', '', 'Value', true);
            obj.FsValLabel = uilabel(gF, 'Text', Resources.Label_FsVal); obj.FsSpinner = uispinner(gF, 'Limits', [1 10000], 'Value', 1000, 'Enable', 'off');

            pD = uipanel(obj.GridAnalyze, 'Title', Resources.Label_AnalysisParams); pD.Layout.Row = 2;
            gD = uigridlayout(pD, 'ColumnWidth', {'1x', '1x'}, 'RowHeight', {'fit', 'fit'});
            obj.VelThreshLabel = uilabel(gD, 'Text', Resources.Label_VelThresh); obj.VelThreshSpinner = uispinner(gD, 'Limits', [1 1000], 'Value', 10);
            obj.DurLabel = uilabel(gD, 'Text', Resources.Label_MinDur); obj.DurSpinner = uispinner(gD, 'Limits', [1 1000], 'Value', 40);
            
            obj.AnalyzeButton = uibutton(obj.GridAnalyze, 'push', 'Text', Resources.Text_AnalyzeButton, 'FontWeight', 'bold'); obj.AnalyzeButton.Layout.Row = 3;
        end
        
        function buildVisTab(obj)
            import MotionAnalysis.UI.Resources
            
            obj.GridVis = uigridlayout(obj.TabVis, 'ColumnWidth', {'1x'}, 'RowHeight', {'fit', 'fit', '1x'});
            obj.GridVis.Padding = [10 10 10 10]; obj.GridVis.RowSpacing = 10;
            
            % 1. Merged Settings Panel
            obj.VisSettingsPanel = uipanel(obj.GridVis, 'Title', Resources.Label_VisSettings);
            obj.VisSettingsPanel.Layout.Row = 1;
            
            % 2-Column Grid inside Panel
            obj.VisGrid = uigridlayout(obj.VisSettingsPanel, 'ColumnWidth', {'1x', '1x'}, 'RowHeight', {'fit', 'fit', 'fit', 'fit'});
            obj.VisGrid.Padding = [5 5 5 5]; obj.VisGrid.ColumnSpacing = 10;
            
            % -- Left Column: Axis Mapping --
            obj.AxisMapLabel = uilabel(obj.VisGrid, 'Text', Resources.Label_AxisMapping, 'FontWeight', 'bold');
            obj.AxisMapLabel.Layout.Row = 1; obj.AxisMapLabel.Layout.Column = 1;
            
            gAxis = uigridlayout(obj.VisGrid, 'ColumnWidth', {'fit', '1x'}, 'RowHeight', {'fit', 'fit', 'fit'});
            gAxis.Layout.Row = [2 4]; gAxis.Layout.Column = 1; gAxis.Padding = [0 0 0 0];
            
            obj.AxisXLabel = uilabel(gAxis, 'Text', Resources.Label_PlotX); obj.AxisXSpinner = uispinner(gAxis, 'Limits', [1 3], 'Value', 1);
            obj.AxisYLabel = uilabel(gAxis, 'Text', Resources.Label_PlotY); obj.AxisYSpinner = uispinner(gAxis, 'Limits', [1 3], 'Value', 2);
            obj.AxisZLabel = uilabel(gAxis, 'Text', Resources.Label_PlotZ); obj.AxisZSpinner = uispinner(gAxis, 'Limits', [1 3], 'Value', 3);

            % -- Right Column: Display Options --
            obj.VisOptLabel = uilabel(obj.VisGrid, 'Text', Resources.Label_VisOptions, 'FontWeight', 'bold');
            obj.VisOptLabel.Layout.Row = 1; obj.VisOptLabel.Layout.Column = 2;
            
            obj.CheckShowGrid = uicheckbox(obj.VisGrid, 'Text', Resources.Check_ShowGrid, 'Value', true);
            obj.CheckShowGrid.Layout.Row = 2; obj.CheckShowGrid.Layout.Column = 2;
            obj.CheckShowTraj = uicheckbox(obj.VisGrid, 'Text', Resources.Check_ShowTraj, 'Value', true);
            obj.CheckShowTraj.Layout.Row = 3; obj.CheckShowTraj.Layout.Column = 2;
            obj.CheckShowEvents = uicheckbox(obj.VisGrid, 'Text', Resources.Check_ShowEvents, 'Value', true);
            obj.CheckShowEvents.Layout.Row = 4; obj.CheckShowEvents.Layout.Column = 2;

            % 2. Result Label
            obj.ResultLabel = uilabel(obj.GridVis, 'Text', Resources.Label_ResultTable, 'FontWeight', 'bold');
            obj.ResultLabel.Layout.Row = 2;
            
            % 3. Result Table
            obj.ResultTable = uitable(obj.GridVis);
            obj.ResultTable.Layout.Row = 3;
            obj.ResultTable.ColumnName = {'File Name', 'Type'};
            obj.ResultTable.ColumnWidth = {'auto', 80}; 
            obj.ResultTable.SelectionType = 'row';
        end
        
        function buildExportTab(obj)
            import MotionAnalysis.UI.Resources
            
            % --- MODIFIED ROW HEIGHT HERE ---
            % Changed from {'1x', 'fit'} (which made button giant '1x' relative to panel)
            % to {'fit', 'fit', '1x'} to make button 'fit' size and push up with spacer.
            obj.GridExport = uigridlayout(obj.TabExport, 'ColumnWidth', {'1x'}, 'RowHeight', {'fit', 'fit', '1x'});
            obj.GridExport.Padding = [10 10 10 10]; obj.GridExport.RowSpacing = 10;
            
            % Options Panel
            obj.ExportPanel = uipanel(obj.GridExport, 'Title', Resources.Label_ExportOpts); 
            obj.ExportPanel.Layout.Row = 1;
            
            gOpt = uigridlayout(obj.ExportPanel, 'ColumnWidth', {'1x', '1x'}, 'RowHeight', {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'});
            gOpt.Padding = [5 5 5 5]; gOpt.ColumnSpacing = 15;
            
            obj.CatGeneral = uilabel(gOpt, 'Text', Resources.Label_CatGeneral, 'FontWeight', 'bold'); obj.CatGeneral.Layout.Row = 1; obj.CatGeneral.Layout.Column = 1;
            obj.CheckType = uicheckbox(gOpt, 'Text', Resources.Check_Type, 'Value', true); obj.CheckType.Layout.Row = 2; obj.CheckType.Layout.Column = 1;
            
            obj.CatCoords = uilabel(gOpt, 'Text', Resources.Label_CatCoords, 'FontWeight', 'bold'); obj.CatCoords.Layout.Row = 3; obj.CatCoords.Layout.Column = 1;
            obj.CheckOnsetPos = uicheckbox(gOpt, 'Text', Resources.Check_OnsetPos, 'Value', true); obj.CheckOnsetPos.Layout.Row = 4; obj.CheckOnsetPos.Layout.Column = 1;
            obj.CheckOffsetPos = uicheckbox(gOpt, 'Text', Resources.Check_OffsetPos, 'Value', true); obj.CheckOffsetPos.Layout.Row = 5; obj.CheckOffsetPos.Layout.Column = 1;
            obj.CheckSubPos = uicheckbox(gOpt, 'Text', Resources.Check_SubPos, 'Value', true); obj.CheckSubPos.Layout.Row = 6; obj.CheckSubPos.Layout.Column = 1;
            
            obj.CatMetrics = uilabel(gOpt, 'Text', Resources.Label_CatMetrics, 'FontWeight', 'bold'); obj.CatMetrics.Layout.Row = 1; obj.CatMetrics.Layout.Column = 2;
            obj.CheckTotalDur = uicheckbox(gOpt, 'Text', Resources.Check_TotalDur, 'Value', true); obj.CheckTotalDur.Layout.Row = 2; obj.CheckTotalDur.Layout.Column = 2;
            obj.CheckTimeSub = uicheckbox(gOpt, 'Text', Resources.Check_TimeSub, 'Value', true); obj.CheckTimeSub.Layout.Row = 3; obj.CheckTimeSub.Layout.Column = 2;
            obj.CheckSubDur = uicheckbox(gOpt, 'Text', Resources.Check_SubDur, 'Value', true); obj.CheckSubDur.Layout.Row = 4; obj.CheckSubDur.Layout.Column = 2;
            obj.CheckMaxVel = uicheckbox(gOpt, 'Text', Resources.Check_MaxVel, 'Value', true); obj.CheckMaxVel.Layout.Row = 5; obj.CheckMaxVel.Layout.Column = 2;
            obj.CheckSubMaxVel = uicheckbox(gOpt, 'Text', Resources.Check_SubMaxVel, 'Value', true); obj.CheckSubMaxVel.Layout.Row = 6; obj.CheckSubMaxVel.Layout.Column = 2;
            
            % Export Button (Directly below options)
            obj.ExportButton = uibutton(obj.GridExport, 'push', 'Text', Resources.Text_ExportButton, 'FontWeight', 'bold'); 
            obj.ExportButton.Layout.Row = 2;
            
            % Spacer Row is 3 ('1x') automatically
        end
    end
end