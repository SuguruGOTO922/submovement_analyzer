classdef MainView < handle
    % ... (Properties for other tabs unchanged) ...
    properties (Access = public)
        UIFigure      matlab.ui.Figure
        MainGrid      matlab.ui.container.GridLayout
        LeftPanel     matlab.ui.container.Panel
        LeftMainGrid  matlab.ui.container.GridLayout
        LeftTabGroup  matlab.ui.container.TabGroup
        
        TabImport     matlab.ui.container.Tab
        TabAnalyze    matlab.ui.container.Tab
        TabResult     matlab.ui.container.Tab
        TabExport     matlab.ui.container.Tab
        
        GridImport    matlab.ui.container.GridLayout
        GridAnalyze   matlab.ui.container.GridLayout
        GridResult    matlab.ui.container.GridLayout
        GridExport    matlab.ui.container.GridLayout
        
        % ... (Import/Analyze/Result Components unchanged) ...
        SettingsLabel    matlab.ui.control.Label
        TimeColLabel     matlab.ui.control.Label
        TimeColSpinner   matlab.ui.control.Spinner
        PosColLabel      matlab.ui.control.Label
        PosColSpinner    matlab.ui.control.Spinner
        HeaderCheckBox   matlab.ui.control.CheckBox
        LoadButton       matlab.ui.control.Button
        
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
        AxisMapLabel     matlab.ui.control.Label
        AxisXLabel       matlab.ui.control.Label
        AxisXSpinner     matlab.ui.control.Spinner
        AxisYLabel       matlab.ui.control.Label
        AxisYSpinner     matlab.ui.control.Spinner
        AxisZLabel       matlab.ui.control.Label
        AxisZSpinner     matlab.ui.control.Spinner
        AnalyzeButton    matlab.ui.control.Button
        
        ResultLabel      matlab.ui.control.Label
        ResultTable      matlab.ui.control.Table
        
        % --- Export Tab Components (New Structure) ---
        ExportLabel      matlab.ui.control.Label
        ExportPanel      matlab.ui.container.Panel
        
        % Category Labels
        CatGeneral       matlab.ui.control.Label
        CatCoords        matlab.ui.control.Label
        CatMetrics       matlab.ui.control.Label
        
        % Checkboxes
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
        RightTabGroup matlab.ui.container.TabGroup
        Tab3D         matlab.ui.container.Tab
        Ax3D          matlab.ui.control.UIAxes
        TabKinematics matlab.ui.container.Tab
        AxVel         matlab.ui.control.UIAxes
        AxAcc         matlab.ui.control.UIAxes
        AxJerk        matlab.ui.control.UIAxes
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
            obj.MainGrid = uigridlayout(obj.UIFigure, 'ColumnWidth', {320, '1x'}, 'RowHeight', {'1x'}); % Slightly wider left panel

            obj.LeftPanel = uipanel(obj.MainGrid);
            obj.LeftPanel.Layout.Row = 1; obj.LeftPanel.Layout.Column = 1;
            
            obj.LeftMainGrid = uigridlayout(obj.LeftPanel, 'ColumnWidth', {'1x'}, 'RowHeight', {'1x', 'fit'});
            obj.LeftMainGrid.Padding = [0 0 0 0]; obj.LeftMainGrid.RowSpacing = 5;

            obj.LeftTabGroup = uitabgroup(obj.LeftMainGrid);
            obj.LeftTabGroup.Layout.Row = 1;

            obj.TabImport  = uitab(obj.LeftTabGroup, 'Title', Resources.Title_TabImport);
            obj.TabAnalyze = uitab(obj.LeftTabGroup, 'Title', Resources.Title_TabAnalyze);
            obj.TabResult  = uitab(obj.LeftTabGroup, 'Title', Resources.Title_TabResult);
            obj.TabExport  = uitab(obj.LeftTabGroup, 'Title', Resources.Title_TabExport);

            buildImportTab(obj);
            buildAnalyzeTab(obj);
            buildResultTab(obj);
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
        
        % ... (buildImportTab, buildAnalyzeTab, buildResultTab are unchanged) ...
        function buildImportTab(obj)
            import MotionAnalysis.UI.Resources
            obj.GridImport = uigridlayout(obj.TabImport, 'ColumnWidth', {'1x'}, 'RowHeight', {'fit', 'fit', '1x'}); 
            obj.GridImport.Padding = [10 10 10 10]; obj.GridImport.RowSpacing = 15;
            p1 = uipanel(obj.GridImport, 'Title', Resources.Label_ImportSettings); p1.Layout.Row = 1;
            g1 = uigridlayout(p1, 'ColumnWidth', {'1x', '1x'}, 'RowHeight', {'fit', 'fit', 'fit'});
            obj.TimeColLabel = uilabel(g1, 'Text', Resources.Label_TimeCol); obj.TimeColSpinner = uispinner(g1, 'Limits', [1 100], 'Value', 1);
            obj.PosColLabel = uilabel(g1, 'Text', Resources.Label_PosCol); obj.PosColSpinner = uispinner(g1, 'Limits', [1 100], 'Value', 2);
            obj.HeaderCheckBox = uicheckbox(g1, 'Text', Resources.Label_HeaderRow); obj.HeaderCheckBox.Layout.Column = [1 2]; 
            obj.LoadButton = uibutton(obj.GridImport, 'push', 'Text', Resources.Text_LoadButton, 'FontWeight', 'bold'); obj.LoadButton.Layout.Row = 2;
        end
        function buildAnalyzeTab(obj)
            import MotionAnalysis.UI.Resources
            obj.GridAnalyze = uigridlayout(obj.TabAnalyze, 'ColumnWidth', {'1x'}, 'RowHeight', {'fit', 'fit', 'fit', 'fit', '1x'});
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
            pA = uipanel(obj.GridAnalyze, 'Title', Resources.Label_AxisMapping); pA.Layout.Row = 3;
            gA = uigridlayout(pA, 'ColumnWidth', {'fit', '1x'}, 'RowHeight', {'fit', 'fit', 'fit'});
            obj.AxisXLabel = uilabel(gA, 'Text', Resources.Label_PlotX); obj.AxisXSpinner = uispinner(gA, 'Limits', [1 3], 'Value', 1);
            obj.AxisYLabel = uilabel(gA, 'Text', Resources.Label_PlotY); obj.AxisYSpinner = uispinner(gA, 'Limits', [1 3], 'Value', 2);
            obj.AxisZLabel = uilabel(gA, 'Text', Resources.Label_PlotZ); obj.AxisZSpinner = uispinner(gA, 'Limits', [1 3], 'Value', 3);
            obj.AnalyzeButton = uibutton(obj.GridAnalyze, 'push', 'Text', Resources.Text_AnalyzeButton, 'FontWeight', 'bold'); obj.AnalyzeButton.Layout.Row = 4;
        end
        function buildResultTab(obj)
            import MotionAnalysis.UI.Resources
            obj.GridResult = uigridlayout(obj.TabResult, 'ColumnWidth', {'1x'}, 'RowHeight', {'fit', '1x'});
            obj.GridResult.Padding = [10 10 10 10]; obj.GridResult.RowSpacing = 10;
            obj.ResultLabel = uilabel(obj.GridResult, 'Text', Resources.Label_ResultTable, 'FontWeight', 'bold'); obj.ResultLabel.Layout.Row = 1;
            obj.ResultTable = uitable(obj.GridResult); obj.ResultTable.Layout.Row = 2;
            obj.ResultTable.ColumnName = {'File Name', 'Type'}; obj.ResultTable.ColumnWidth = {'auto', 80}; obj.ResultTable.SelectionType = 'row';
        end
        
        function buildExportTab(obj)
            import MotionAnalysis.UI.Resources
            
            obj.GridExport = uigridlayout(obj.TabExport, 'ColumnWidth', {'1x'}, 'RowHeight', {'1x', 'fit'});
            obj.GridExport.Padding = [10 10 10 10];
            obj.GridExport.RowSpacing = 10;
            
            % Options Panel
            obj.ExportPanel = uipanel(obj.GridExport, 'Title', Resources.Label_ExportOpts);
            obj.ExportPanel.Layout.Row = 1;
            
            % 2-column layout for checkboxes: Left(Coords/Gen), Right(Metrics)
            gOpt = uigridlayout(obj.ExportPanel, 'ColumnWidth', {'1x', '1x'}, ...
                'RowHeight', {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'});
            gOpt.Padding = [5 5 5 5]; gOpt.ColumnSpacing = 15;
            
            % Left Column: General & Coords
            obj.CatGeneral = uilabel(gOpt, 'Text', Resources.Label_CatGeneral, 'FontWeight', 'bold');
            obj.CatGeneral.Layout.Row = 1; obj.CatGeneral.Layout.Column = 1;
            
            obj.CheckType = uicheckbox(gOpt, 'Text', Resources.Check_Type, 'Value', true);
            obj.CheckType.Layout.Row = 2; obj.CheckType.Layout.Column = 1;
            
            obj.CatCoords = uilabel(gOpt, 'Text', Resources.Label_CatCoords, 'FontWeight', 'bold');
            obj.CatCoords.Layout.Row = 3; obj.CatCoords.Layout.Column = 1;
            
            obj.CheckOnsetPos = uicheckbox(gOpt, 'Text', Resources.Check_OnsetPos, 'Value', true);
            obj.CheckOnsetPos.Layout.Row = 4; obj.CheckOnsetPos.Layout.Column = 1;
            
            obj.CheckOffsetPos = uicheckbox(gOpt, 'Text', Resources.Check_OffsetPos, 'Value', true);
            obj.CheckOffsetPos.Layout.Row = 5; obj.CheckOffsetPos.Layout.Column = 1;
            
            obj.CheckSubPos = uicheckbox(gOpt, 'Text', Resources.Check_SubPos, 'Value', true);
            obj.CheckSubPos.Layout.Row = 6; obj.CheckSubPos.Layout.Column = 1;
            
            % Right Column: Metrics
            obj.CatMetrics = uilabel(gOpt, 'Text', Resources.Label_CatMetrics, 'FontWeight', 'bold');
            obj.CatMetrics.Layout.Row = 1; obj.CatMetrics.Layout.Column = 2;
            
            obj.CheckTotalDur = uicheckbox(gOpt, 'Text', Resources.Check_TotalDur, 'Value', true);
            obj.CheckTotalDur.Layout.Row = 2; obj.CheckTotalDur.Layout.Column = 2;
            
            obj.CheckTimeSub = uicheckbox(gOpt, 'Text', Resources.Check_TimeSub, 'Value', true);
            obj.CheckTimeSub.Layout.Row = 3; obj.CheckTimeSub.Layout.Column = 2;
            
            obj.CheckSubDur = uicheckbox(gOpt, 'Text', Resources.Check_SubDur, 'Value', true);
            obj.CheckSubDur.Layout.Row = 4; obj.CheckSubDur.Layout.Column = 2;
            
            obj.CheckMaxVel = uicheckbox(gOpt, 'Text', Resources.Check_MaxVel, 'Value', true);
            obj.CheckMaxVel.Layout.Row = 5; obj.CheckMaxVel.Layout.Column = 2;
            
            obj.CheckSubMaxVel = uicheckbox(gOpt, 'Text', Resources.Check_SubMaxVel, 'Value', true);
            obj.CheckSubMaxVel.Layout.Row = 6; obj.CheckSubMaxVel.Layout.Column = 2;
            
            % Export Button (Bottom)
            obj.ExportButton = uibutton(obj.GridExport, 'push', 'Text', Resources.Text_ExportButton, 'FontWeight', 'bold');
            obj.ExportButton.Layout.Row = 2;
        end
    end
end