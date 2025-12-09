classdef SubmovementAnalyzer < handle
    % SubmovementAnalyzer
    % MATLAB App for analyzing 3D movement data based on Roberts et al. (2024).

    properties (Constant, Access = private)
        AppTag  = 'SubmovementAnalyzer_Singleton_Tag';
        AppName = 'SubmovementAnalyzer v7.2';

        Title_TabImport      = '1. Import';
        Title_TabAnalyze     = '2. Analyze';
        Title_TabExport      = '3. Result';

        % UI Text
        Label_ImportSettings = 'CSV Format';
        Label_TimeCol        = 'Time Col:';
        Label_PosCol         = 'Pos Start:';
        Label_HeaderRow      = 'Header Row';

        Label_AxisMapping    = '3D Axis Mapping';
        Label_PlotX          = 'Plot X (Col):';
        Label_PlotY          = 'Plot Y (Col):';
        Label_PlotZ          = 'Plot Z (Col):';

        Label_FilterSettings = 'Filter Settings'; % New
        Label_FilterOrder    = 'Order:';
        Label_Cutoff         = 'Cutoff (Hz):';
        
        Label_FsSettings     = 'Sampling Rate'; % New
        Label_FsVal          = 'Fs (Hz):';
        Label_FsAuto         = 'Auto Calc';

        Label_AnalysisParams = 'Detection Params';
        Label_VelThresh      = 'Vel Thresh (mm/s):';
        Label_MinDur         = 'Min Dur (ms):';

        Text_LoadButton      = 'Load CSV Files';
        Text_AnalyzeButton   = 'Run Analysis';
        Text_ExportButton    = 'Export to CSV';
        Label_ResultTable    = 'Analysis Results:';
        
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

    properties (Access = public)
        UIFigure      matlab.ui.Figure
        MainGrid      matlab.ui.container.GridLayout
        LeftPanel     matlab.ui.container.Panel
        LeftMainGrid  matlab.ui.container.GridLayout
        LeftTabGroup  matlab.ui.container.TabGroup
        
        TabImport     matlab.ui.container.Tab
        TabAnalyze    matlab.ui.container.Tab
        TabExport     matlab.ui.container.Tab
        
        GridImport    matlab.ui.container.GridLayout
        GridAnalyze   matlab.ui.container.GridLayout
        GridExport    matlab.ui.container.GridLayout
        
        % --- TAB 1 ---
        SettingsLabel    matlab.ui.control.Label
        TimeColLabel     matlab.ui.control.Label
        TimeColSpinner   matlab.ui.control.Spinner
        PosColLabel      matlab.ui.control.Label
        PosColSpinner    matlab.ui.control.Spinner
        HeaderCheckBox   matlab.ui.control.CheckBox
        LoadButton       matlab.ui.control.Button
        
        % --- TAB 2 ---
        AxisMapLabel     matlab.ui.control.Label
        AxisXLabel       matlab.ui.control.Label
        AxisXSpinner     matlab.ui.control.Spinner
        AxisYLabel       matlab.ui.control.Label
        AxisYSpinner     matlab.ui.control.Spinner
        AxisZLabel       matlab.ui.control.Label
        AxisZSpinner     matlab.ui.control.Spinner
        
        % Filter UI
        FilterLabel      matlab.ui.control.Label
        OrderLabel       matlab.ui.control.Label
        OrderSpinner     matlab.ui.control.Spinner
        CutoffLabel      matlab.ui.control.Label
        CutoffSpinner    matlab.ui.control.Spinner
        
        % Fs UI
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

        % --- TAB 3 ---
        ResultLabel      matlab.ui.control.Label
        ResultTable      matlab.ui.control.Table
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

    properties (Access = private)
        BatchData struct
        IsAnalyzed logical = false
    end

    methods (Static)
        function app = launch()
            existingFigs = findall(groot, 'Type', 'figure', 'Tag', SubmovementAnalyzer.AppTag);
            if ~isempty(existingFigs)
                figure(existingFigs(1));
                if isprop(existingFigs(1), 'UserData') && ~isempty(existingFigs(1).UserData)
                    app = existingFigs(1).UserData;
                else
                    app = []; 
                end
            else
                app = SubmovementAnalyzer();
            end
        end
    end
    
    methods (Access = public)
        function delete(app)
            if isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end

    methods (Access = private)
        function app = SubmovementAnalyzer
            existingFigs = findall(groot, 'Type', 'figure', 'Tag', SubmovementAnalyzer.AppTag);
            if ~isempty(existingFigs)
                figure(existingFigs(1));
                delete(app); 
                return;
            end
            
            createComponents(app);
            app.UIFigure.Tag = SubmovementAnalyzer.AppTag;
            app.UIFigure.UserData = app;
            Startup(app);
            if nargout == 0; clear app; end
        end

        function Startup(app)
            s = MotionAnalysis.FileIO.Settings.load();
            
            app.TimeColSpinner.Value = s.Import.TimeCol;
            app.PosColSpinner.Value = s.Import.PosCol;
            app.HeaderCheckBox.Value = s.Import.HasHeader;
            
            if isfield(s.Analysis, 'AxisMapX'); app.AxisXSpinner.Value = s.Analysis.AxisMapX; end
            if isfield(s.Analysis, 'AxisMapY'); app.AxisYSpinner.Value = s.Analysis.AxisMapY; end
            if isfield(s.Analysis, 'AxisMapZ'); app.AxisZSpinner.Value = s.Analysis.AxisMapZ; end
            
            app.VelThreshSpinner.Value = s.Analysis.VelThresh;
            app.DurSpinner.Value = s.Analysis.MinDuration;
            
            % New Filter/Fs settings
            if isfield(s.Analysis, 'FilterOrder'); app.OrderSpinner.Value = s.Analysis.FilterOrder; end
            if isfield(s.Analysis, 'CutoffFreq'); app.CutoffSpinner.Value = s.Analysis.CutoffFreq; end
            
            if isfield(s.Analysis, 'FsAuto'); app.FsAutoCheckBox.Value = s.Analysis.FsAuto; end
            if isfield(s.Analysis, 'FsValue'); app.FsSpinner.Value = s.Analysis.FsValue; end
            
            % Initial UI State
            app.FsSpinner.Enable = ~app.FsAutoCheckBox.Value;
        end
                
        function onClose(app, ~, ~)
            saveSettings(app);
            app.UIFigure.CloseRequestFcn = '';
            delete(app);
        end

        function saveSettings(app)
            try
                s.Import.TimeCol = app.TimeColSpinner.Value;
                s.Import.PosCol = app.PosColSpinner.Value;
                s.Import.HasHeader = app.HeaderCheckBox.Value;
                
                s.Analysis.AxisMapX = app.AxisXSpinner.Value;
                s.Analysis.AxisMapY = app.AxisYSpinner.Value;
                s.Analysis.AxisMapZ = app.AxisZSpinner.Value;
                
                s.Analysis.VelThresh = app.VelThreshSpinner.Value;
                s.Analysis.MinDuration = app.DurSpinner.Value;
                
                % Save New Params
                s.Analysis.FilterOrder = app.OrderSpinner.Value;
                s.Analysis.CutoffFreq = app.CutoffSpinner.Value;
                s.Analysis.FsAuto = app.FsAutoCheckBox.Value;
                s.Analysis.FsValue = app.FsSpinner.Value;
                
                MotionAnalysis.FileIO.Settings.save(s);
            catch ME
                warning(ME.identifier, 'Failed to save settings: %s', ME.message);
            end
        end

        % --- Callbacks ---

        function LoadButtonPushed(app, ~, ~)
            timeCol = app.TimeColSpinner.Value;
            posStartCol = app.PosColSpinner.Value;
            hasHeader = app.HeaderCheckBox.Value;
            
            dataDir = MotionAnalysis.FileIO.getDefaultPath();
            [files, path] = uigetfile(fullfile(dataDir, '*.csv'), app.Msg_SelectCSV, 'MultiSelect', 'on');
            
            figure(app.UIFigure); 
            if isequal(files, 0); return; end
            
            try
                app.BatchData = MotionAnalysis.FileIO.loadBatch(files, path, timeCol, posStartCol, hasHeader);
                
                count = length(app.BatchData);
                app.StatusLabel.Text = sprintf(app.Msg_LoadedCount, count);
                
                app.AnalyzeButton.Enable = 'on';
                app.ExportButton.Enable = 'off';
                app.ResultTable.Data = {};
                
                app.IsAnalyzed = false;
                app.LeftTabGroup.SelectedTab = app.TabAnalyze;
                
                saveSettings(app);
                
            catch ME
                uialert(app.UIFigure, ME.message, app.Msg_LoadErrorTitle);
            end
        end

        function AnalyzeButtonPushed(app, ~, ~)
            if isempty(app.BatchData); return; end
            
            try
                % Params
                params.VelThresh = app.VelThreshSpinner.Value;
                params.MinDuration = app.DurSpinner.Value / 1000; 
                params.FilterOrder = app.OrderSpinner.Value;
                params.CutoffFreq = app.CutoffSpinner.Value;
                
                % Fs Logic
                params.FsAuto = app.FsAutoCheckBox.Value;
                params.FsValue = app.FsSpinner.Value;
                
                d = uiprogressdlg(app.UIFigure, 'Title', app.Msg_AnalyzeProgressTitle, 'Message', app.Msg_AnalyzeStart);
                progressFcn = @(ratio, msg) set(d, 'Value', ratio, 'Message', msg);
                
                app.BatchData = MotionAnalysis.processBatch(app.BatchData, params, progressFcn);
                
                close(d);
                figure(app.UIFigure); 
                app.IsAnalyzed = true;
                
                app.StatusLabel.Text = app.Msg_AnalyzeComplete;
                app.ExportButton.Enable = 'on';
                
                populateResultTable(app);
                app.LeftTabGroup.SelectedTab = app.TabExport;
                
                saveSettings(app);
                                
            catch ME
                uialert(app.UIFigure, [app.Msg_AnalyzeErrorTitle ': ' ME.message], 'Error');
                disp([ME.stack.line])
                disp([ME.stack.file]) 
            end
        end
        
        function FsAutoChanged(app, ~, ~)
            % Toggle Spinner Enable state
            app.FsSpinner.Enable = ~app.FsAutoCheckBox.Value;
        end
        
        function ResultTableSelectionChanged(app, ~, event)
            if ~app.IsAnalyzed; return; end
            indices = event.Selection;
            if ~isempty(indices)
                idx = indices(1);
                updateView(app, idx);
            end
        end
        
        function AxisSpinnerChanged(app, ~, ~)
            if app.IsAnalyzed && ~isempty(app.ResultTable.Selection)
                 idx = app.ResultTable.Selection(1);
                 updateView(app, idx);
            end
        end

        function ExportButtonPushed(app, ~, ~)
            if ~app.IsAnalyzed; return; end
            [file, path] = uiputfile('*.csv', app.Msg_SaveBatchTitle);
            figure(app.UIFigure);
            if isequal(file, 0); return; end
            try
                MotionAnalysis.FileIO.exportSummary(app.BatchData, fullfile(path, file));
                uialert(app.UIFigure, app.Msg_ExportSuccess, app.Msg_ExportSuccessTitle);
            catch ME
                uialert(app.UIFigure, [app.Msg_ExportErrorTitle ': ' ME.message], 'Error');
            end
        end

        % --- Helpers ---

        function populateResultTable(app)
            nFiles = length(app.BatchData);
            tData = cell(nFiles, 2);
            for i = 1:nFiles
                tData{i, 1} = char(app.BatchData(i).FileName);
                tData{i, 2} = char(app.BatchData(i).Results.SubType);
            end
            app.ResultTable.Data = tData;
            if nFiles > 0
                app.ResultTable.Selection = 1;
                updateView(app, 1);
            end
        end

        function updateView(app, highlightIdx)
            if isempty(app.BatchData) || highlightIdx < 1 || highlightIdx > length(app.BatchData)
                return;
            end

            axesHandles.Ax3D = app.Ax3D;
            axesHandles.AxVel = app.AxVel;
            axesHandles.AxAcc = app.AxAcc;
            axesHandles.AxJerk = app.AxJerk;
            
            mapX = app.AxisXSpinner.Value;
            mapY = app.AxisYSpinner.Value;
            mapZ = app.AxisZSpinner.Value;
            axisMap = [mapX, mapY, mapZ];
            
            MotionAnalysis.Graphics.updatePlots(axesHandles, app.BatchData, highlightIdx, axisMap);
            
            res = app.BatchData(highlightIdx).Results;
            app.StatusLabel.Text = sprintf('File: %s | Type: %s | Fs: %d Hz', ...
                app.BatchData(highlightIdx).FileName, res.SubType, res.Fs);
        end

        % --- UI Creation ---

        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off', ...
                'Position', [100 100 1100 780], ... 
                'Name', SubmovementAnalyzer.AppName);
            app.UIFigure.CloseRequestFcn = @(src, event) app.onClose(src, event);

            app.MainGrid = uigridlayout(app.UIFigure, 'ColumnWidth', {300, '1x'}, 'RowHeight', {'1x'});

            app.LeftPanel = uipanel(app.MainGrid);
            app.LeftPanel.Layout.Row = 1; app.LeftPanel.Layout.Column = 1;
            
            app.LeftMainGrid = uigridlayout(app.LeftPanel, 'ColumnWidth', {'1x'}, 'RowHeight', {'1x', 'fit'});
            app.LeftMainGrid.Padding = [0 0 0 0];
            app.LeftMainGrid.RowSpacing = 5;

            app.LeftTabGroup = uitabgroup(app.LeftMainGrid);
            app.LeftTabGroup.Layout.Row = 1;

            app.TabImport  = uitab(app.LeftTabGroup, 'Title', app.Title_TabImport);
            app.TabAnalyze = uitab(app.LeftTabGroup, 'Title', app.Title_TabAnalyze);
            app.TabExport  = uitab(app.LeftTabGroup, 'Title', app.Title_TabExport);

            buildImportTab(app);
            buildAnalyzeTab(app);
            buildExportTab(app);

            app.StatusLabel = uilabel(app.LeftMainGrid, 'Text', app.Text_Ready, ...
                'WordWrap', 'on', 'VerticalAlignment', 'top', 'FontWeight', 'bold');
            app.StatusLabel.Layout.Row = 2;

            app.RightTabGroup = uitabgroup(app.MainGrid);
            app.RightTabGroup.Layout.Row = 1; app.RightTabGroup.Layout.Column = 2;

            app.Tab3D = uitab(app.RightTabGroup, 'Title', app.Tab_3DTrajectory);
            app.Ax3D = uiaxes(app.Tab3D, 'Position', [10 10 700 700]); 

            app.TabKinematics = uitab(app.RightTabGroup, 'Title', app.Tab_Kinematics);
            kg = uigridlayout(app.TabKinematics, [3, 1]);
            app.AxVel = uiaxes(kg); app.AxVel.Layout.Row = 1;
            app.AxAcc = uiaxes(kg); app.AxAcc.Layout.Row = 2;
            app.AxJerk = uiaxes(kg); app.AxJerk.Layout.Row = 3;

            app.UIFigure.Visible = 'on';
        end
        
        function buildImportTab(app)
            app.GridImport = uigridlayout(app.TabImport, 'ColumnWidth', {'1x'}, ...
                'RowHeight', {'fit', 'fit', '1x'}); 
            app.GridImport.Padding = [10 10 10 10];
            app.GridImport.RowSpacing = 15;
            
            p1 = uipanel(app.GridImport, 'Title', app.Label_ImportSettings);
            p1.Layout.Row = 1;
            g1 = uigridlayout(p1, 'ColumnWidth', {'1x', '1x'}, 'RowHeight', {'fit', 'fit', 'fit'});
            
            app.TimeColLabel = uilabel(g1, 'Text', app.Label_TimeCol);
            app.TimeColSpinner = uispinner(g1, 'Limits', [1 100], 'Value', 1);
            app.PosColLabel = uilabel(g1, 'Text', app.Label_PosCol);
            app.PosColSpinner = uispinner(g1, 'Limits', [1 100], 'Value', 2);
            app.HeaderCheckBox = uicheckbox(g1, 'Text', app.Label_HeaderRow);
            app.HeaderCheckBox.Layout.Column = [1 2]; 

            app.LoadButton = uibutton(app.GridImport, 'push', 'Text', app.Text_LoadButton, ...
                'ButtonPushedFcn', @app.LoadButtonPushed, 'FontWeight', 'bold');
            app.LoadButton.Layout.Row = 2;
        end
        
        function buildAnalyzeTab(app)
            % 4 panels: AxisMap, Filter, Fs, Params
            app.GridAnalyze = uigridlayout(app.TabAnalyze, 'ColumnWidth', {'1x'}, ...
                'RowHeight', {'fit', 'fit', 'fit', 'fit', 'fit', '1x'});
            app.GridAnalyze.Padding = [10 10 10 10];
            app.GridAnalyze.RowSpacing = 10;

            % 1. Axis Map
            p1 = uipanel(app.GridAnalyze, 'Title', app.Label_AxisMapping);
            p1.Layout.Row = 1;
            g1 = uigridlayout(p1, 'ColumnWidth', {'fit', '1x'}, 'RowHeight', {'fit', 'fit', 'fit'});
            app.AxisXLabel = uilabel(g1, 'Text', app.Label_PlotX);
            app.AxisXSpinner = uispinner(g1, 'Limits', [1 3], 'Value', 1, 'ValueChangedFcn', @app.AxisSpinnerChanged);
            app.AxisYLabel = uilabel(g1, 'Text', app.Label_PlotY);
            app.AxisYSpinner = uispinner(g1, 'Limits', [1 3], 'Value', 2, 'ValueChangedFcn', @app.AxisSpinnerChanged);
            app.AxisZLabel = uilabel(g1, 'Text', app.Label_PlotZ);
            app.AxisZSpinner = uispinner(g1, 'Limits', [1 3], 'Value', 3, 'ValueChangedFcn', @app.AxisSpinnerChanged);
            
            % 2. Sampling Rate
            pFs = uipanel(app.GridAnalyze, 'Title', app.Label_FsSettings);
            pFs.Layout.Row = 2;
            gFs = uigridlayout(pFs, 'ColumnWidth', {'fit', '1x'}, 'RowHeight', {'fit', 'fit'});
            app.FsLabel = uilabel(gFs, 'Text', app.Label_FsAuto);
            app.FsAutoCheckBox = uicheckbox(gFs, 'Text', '', 'Value', true, 'ValueChangedFcn', @app.FsAutoChanged);
            app.FsValLabel = uilabel(gFs, 'Text', app.Label_FsVal);
            app.FsSpinner = uispinner(gFs, 'Limits', [1 10000], 'Value', 1000, 'Enable', 'off');

            % 3. Filter Settings
            pF = uipanel(app.GridAnalyze, 'Title', app.Label_FilterSettings);
            pF.Layout.Row = 3;
            gF = uigridlayout(pF, 'ColumnWidth', {'fit', '1x'}, 'RowHeight', {'fit', 'fit'});
            app.OrderLabel = uilabel(gF, 'Text', app.Label_FilterOrder);
            app.OrderSpinner = uispinner(gF, 'Limits', [1 10], 'Value', 2);
            app.CutoffLabel = uilabel(gF, 'Text', app.Label_Cutoff);
            app.CutoffSpinner = uispinner(gF, 'Limits', [0.1 500], 'Value', 10);

            % 4. Detection Params
            p2 = uipanel(app.GridAnalyze, 'Title', app.Label_AnalysisParams);
            p2.Layout.Row = 4;
            g2 = uigridlayout(p2, 'ColumnWidth', {'1x', '1x'}, 'RowHeight', {'fit', 'fit'});
            app.VelThreshLabel = uilabel(g2, 'Text', app.Label_VelThresh);
            app.VelThreshSpinner = uispinner(g2, 'Limits', [1 1000], 'Value', 10);
            app.DurLabel = uilabel(g2, 'Text', app.Label_MinDur);
            app.DurSpinner = uispinner(g2, 'Limits', [1 1000], 'Value', 40);
            
            % Analyze Button
            app.AnalyzeButton = uibutton(app.GridAnalyze, 'push', 'Text', app.Text_AnalyzeButton, ...
                'Enable', 'off', 'ButtonPushedFcn', @app.AnalyzeButtonPushed, 'FontWeight', 'bold');
            app.AnalyzeButton.Layout.Row = 5;
        end
        
        function buildExportTab(app)
            app.GridExport = uigridlayout(app.TabExport, 'ColumnWidth', {'1x'}, 'RowHeight', {'fit', '1x', 'fit'});
            app.GridExport.Padding = [10 10 10 10];
            app.GridExport.RowSpacing = 10;
            
            app.ResultLabel = uilabel(app.GridExport, 'Text', app.Label_ResultTable, 'FontWeight', 'bold');
            app.ResultLabel.Layout.Row = 1;
            
            app.ResultTable = uitable(app.GridExport);
            app.ResultTable.Layout.Row = 2;
            app.ResultTable.ColumnName = {'File Name', 'Type'};
            app.ResultTable.ColumnWidth = {'auto', 80}; 
            app.ResultTable.SelectionType = 'row';
            app.ResultTable.SelectionChangedFcn = @app.ResultTableSelectionChanged;
            
            app.ExportButton = uibutton(app.GridExport, 'push', 'Text', app.Text_ExportButton, ...
                'Enable', 'off', 'ButtonPushedFcn', @app.ExportButtonPushed, 'FontWeight', 'bold');
            app.ExportButton.Layout.Row = 3;
        end
    end
end