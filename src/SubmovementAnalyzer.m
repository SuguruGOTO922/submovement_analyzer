classdef SubmovementAnalyzer < matlab.apps.AppBase

    % ---------------------------------------------------------------------
    % Properties
    % ---------------------------------------------------------------------
    properties (Access = public)
        UIFigure      matlab.ui.Figure
        GridLayout    matlab.ui.container.GridLayout
        LeftPanel     matlab.ui.container.Panel
        
        % Import Settings
        SettingsLabel    matlab.ui.control.Label
        TimeColLabel     matlab.ui.control.Label
        TimeColSpinner   matlab.ui.control.Spinner
        PosColLabel      matlab.ui.control.Label
        PosColSpinner    matlab.ui.control.Spinner
        HeaderCheckBox   matlab.ui.control.CheckBox
        
        % --- New: Axis Mapping UI ---
        AxisMapLabel     matlab.ui.control.Label
        AxisXLabel       matlab.ui.control.Label
        AxisXSpinner     matlab.ui.control.Spinner
        AxisYLabel       matlab.ui.control.Label
        AxisYSpinner     matlab.ui.control.Spinner
        AxisZLabel       matlab.ui.control.Label
        AxisZSpinner     matlab.ui.control.Spinner
        % ----------------------------
        
        % Analysis Params
        ParamsLabel      matlab.ui.control.Label
        VelThreshLabel   matlab.ui.control.Label
        VelThreshSpinner matlab.ui.control.Spinner
        DurLabel         matlab.ui.control.Label
        DurSpinner       matlab.ui.control.Spinner

        % Action Components
        LoadButton    matlab.ui.control.Button
        AnalyzeButton matlab.ui.control.Button
        ExportButton  matlab.ui.control.Button
        StatusLabel   matlab.ui.control.Label
        FileDropDown  matlab.ui.control.DropDown
        FileLabel     matlab.ui.control.Label
        
        % Visualization
        TabGroup      matlab.ui.container.TabGroup
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

    % ---------------------------------------------------------------------
    % Public Methods (Constructor)
    % ---------------------------------------------------------------------
    methods (Access = public)
        function app = SubmovementAnalyzer
            % SINGLETON CHECK:
            % Before creating components, check if an instance already exists.
            appTag = 'SubmovementAnalyzer_Singleton_Tag';
            existingFigs = findall(groot, 'Type', 'figure', 'Tag', appTag);
            
            if ~isempty(existingFigs)
                % Instance exists: Bring to front
                figure(existingFigs(1));
                fprintf('SubmovementAnalyzer is already running.\n');
                
                % Return early WITHOUT creating new components.
                % The 'app' object returned here will be valid but empty (no UI).
                % This prevents a duplicate window from appearing.
                return;
            end
            
            % 1. Create UI Components
            createComponents(app);
            
            % Tag the figure for future singleton checks
            app.UIFigure.Tag = appTag;

            % 2. Register App
            registerApp(app, app.UIFigure);
            
            % 3. Load Settings (Startup Logic)
            startup(app);

            if nargout == 0; clear app; end
        end
    end

    % ---------------------------------------------------------------------
    % Private Methods
    % ---------------------------------------------------------------------
    methods (Access = private)

        % --- Lifecycle Methods ---

        function startup(app)
            % Called after UI creation. Loads settings from JSON.
            s = MotionAnalysis.FileIO.Settings.load();
            
            % Import Settings
            app.TimeColSpinner.Value = s.Import.TimeCol;
            app.PosColSpinner.Value = s.Import.PosCol;
            app.HeaderCheckBox.Value = s.Import.HasHeader;
            
            % Axis Mapping (Apply saved settings or defaults)
            if isfield(s.Import, 'AxisMapX'); app.AxisXSpinner.Value = s.Import.AxisMapX; end
            if isfield(s.Import, 'AxisMapY'); app.AxisYSpinner.Value = s.Import.AxisMapY; end
            if isfield(s.Import, 'AxisMapZ'); app.AxisZSpinner.Value = s.Import.AxisMapZ; end
            
            % Analysis Params
            app.VelThreshSpinner.Value = s.Analysis.VelThresh;
            app.DurSpinner.Value = s.Analysis.MinDuration;
        end
        
        function onClose(app, ~, ~)
            try
                % Gather Settings
                s.Import.TimeCol = app.TimeColSpinner.Value;
                s.Import.PosCol = app.PosColSpinner.Value;
                s.Import.HasHeader = app.HeaderCheckBox.Value;
                
                % Gather Axis Mapping
                s.Import.AxisMapX = app.AxisXSpinner.Value;
                s.Import.AxisMapY = app.AxisYSpinner.Value;
                s.Import.AxisMapZ = app.AxisZSpinner.Value;
                
                % Gather Analysis Params
                s.Analysis.VelThresh = app.VelThreshSpinner.Value;
                s.Analysis.MinDuration = app.DurSpinner.Value;
                
                MotionAnalysis.FileIO.Settings.save(s);
            catch ME
                warning(ME.identifier, 'Failed to save settings: %s', ME.message);
            end
            
            delete(app.UIFigure);
            delete(app);
        end

        % --- Callback Methods ---

        function LoadButtonPushed(app, ~, ~)
            timeCol = app.TimeColSpinner.Value;
            posStartCol = app.PosColSpinner.Value;
            hasHeader = app.HeaderCheckBox.Value;

            dataDir = MotionAnalysis.FileIO.getDefaultPath();
            [files, path] = uigetfile(fullfile(dataDir, '*.csv'), 'Select CSV Files', 'MultiSelect', 'on');
            
            figure(app.UIFigure); 

            if isequal(files, 0); return; end
            
            try
                app.BatchData = MotionAnalysis.FileIO.loadBatch(files, path, timeCol, posStartCol, hasHeader);
                
                count = length(app.BatchData);
                app.StatusLabel.Text = sprintf('Loaded %d files.', count);
                app.AnalyzeButton.Enable = 'on';
                app.ExportButton.Enable = 'off';
                app.FileDropDown.Enable = 'off';
                app.FileDropDown.Items = {};
                app.IsAnalyzed = false;
                
            catch ME
                uialert(app.UIFigure, ME.message, 'Load Error');
            end
        end

        function AnalyzeButtonPushed(app, ~, ~)
            if isempty(app.BatchData); return; end
            
            try
                params.VelThresh = app.VelThreshSpinner.Value;
                params.MinDuration = app.DurSpinner.Value / 1000; 
                
                d = uiprogressdlg(app.UIFigure, 'Title', 'Analyzing...', 'Message', 'Starting...');
                progressFcn = @(ratio, msg) set(d, 'Value', ratio, 'Message', msg);
                
                app.BatchData = MotionAnalysis.processBatch(app.BatchData, params, ...
                    "progressCallback", progressFcn);
                
                close(d);
                figure(app.UIFigure); 

                app.IsAnalyzed = true;
                app.StatusLabel.Text = 'Analysis Complete.';
                app.ExportButton.Enable = 'on';
                
                nFiles = length(app.BatchData);
                app.FileDropDown.Items = [app.BatchData.FileName];
                app.FileDropDown.ItemsData = 1:nFiles;
                app.FileDropDown.Enable = 'on';
                app.FileDropDown.Value = 1;
                
                updateView(app, 1);
                
            catch ME
                uialert(app.UIFigure, "Analysis Failed: " + ME.message, 'Error');
            end
        end
        
        function FileDropDownValueChanged(app, ~, ~)
            if ~app.IsAnalyzed; return; end
            idx = app.FileDropDown.Value;
            updateView(app, idx);
        end
        
        function AxisSpinnerChanged(app, ~, ~)
            % Redraw plot when axis mapping changes
            if ~app.IsAnalyzed; return; end
            idx = app.FileDropDown.Value;
            updateView(app, idx);
        end

        function ExportButtonPushed(app, ~, ~)
            if ~app.IsAnalyzed; return; end
            [file, path] = uiputfile('*.csv', 'Save Batch Results');
            figure(app.UIFigure);
            if isequal(file, 0); return; end
            try
                MotionAnalysis.FileIO.exportSummary(app.BatchData, fullfile(path, file));
                uialert(app.UIFigure, 'Export successful.', 'Success');
            catch ME
                uialert(app.UIFigure, "Export Failed: " + ME.message, 'Error');
            end
        end

        % --- Helper Methods ---

        function updateView(app, highlightIdx)
            axesHandles.Ax3D = app.Ax3D;
            axesHandles.AxVel = app.AxVel;
            axesHandles.AxAcc = app.AxAcc;
            axesHandles.AxJerk = app.AxJerk;
            
            % Get Mapping from UI
            mapX = app.AxisXSpinner.Value;
            mapY = app.AxisYSpinner.Value;
            mapZ = app.AxisZSpinner.Value;
            axisMap = [mapX, mapY, mapZ];
            
            MotionAnalysis.Graphics.updatePlots(axesHandles, app.BatchData, highlightIdx, axisMap);
            
            res = app.BatchData(highlightIdx).Results;
            app.StatusLabel.Text = "File: " + app.BatchData(highlightIdx).FileName + ...
                                   " | Type: " + res.SubType;
        end

        % --- UI Creation ---

        function createComponents(app)
            % Main Window (Increased height for new controls)
            app.UIFigure = uifigure('Visible', 'off', 'Position', [100 100 1050 780], 'Name', 'Submovement Analyzer v3.5');
            app.UIFigure.CloseRequestFcn = @(src, event) app.onClose(src, event);

            app.GridLayout = uigridlayout(app.UIFigure, 'ColumnWidth', {260, '1x'}, 'RowHeight', {'1x'});

            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1; app.LeftPanel.Layout.Column = 1;
            
            yPos = 740;
            
            % 1. Import Settings
            app.SettingsLabel = uilabel(app.LeftPanel, 'Text', '1. Import Settings', 'Position', [10 yPos 200 20], 'FontWeight', 'bold');
            yPos = yPos - 30;
            app.TimeColLabel = uilabel(app.LeftPanel, 'Text', 'Time Col:', 'Position', [10 yPos 80 20]);
            app.TimeColSpinner = uispinner(app.LeftPanel, 'Position', [90 yPos 50 20], 'Limits', [1 100], 'Value', 1);
            app.PosColLabel = uilabel(app.LeftPanel, 'Text', 'Pos Start:', 'Position', [150 yPos 60 20]);
            app.PosColSpinner = uispinner(app.LeftPanel, 'Position', [210 yPos 35 20], 'Limits', [1 100], 'Value', 2);
            yPos = yPos - 25;
            app.HeaderCheckBox = uicheckbox(app.LeftPanel, 'Text', 'First Row is Header', 'Position', [10 yPos 150 20], 'Value', false);
            
            % --- New: Axis Mapping UI ---
            yPos = yPos - 30;
            app.AxisMapLabel = uilabel(app.LeftPanel, 'Text', '3D Axis Map (Pos Col #):', 'Position', [10 yPos 200 20], 'FontSize', 11);
            yPos = yPos - 30;
            
            % X Mapping
            app.AxisXLabel = uilabel(app.LeftPanel, 'Text', 'Plot X:', 'Position', [10 yPos 50 20]);
            app.AxisXSpinner = uispinner(app.LeftPanel, 'Position', [60 yPos 40 20], 'Limits', [1 3], 'Value', 1, 'ValueChangedFcn', @app.AxisSpinnerChanged);
            
            % Y Mapping
            app.AxisYLabel = uilabel(app.LeftPanel, 'Text', 'Y:', 'Position', [110 yPos 20 20]);
            app.AxisYSpinner = uispinner(app.LeftPanel, 'Position', [130 yPos 40 20], 'Limits', [1 3], 'Value', 2, 'ValueChangedFcn', @app.AxisSpinnerChanged);
            
            % Z Mapping
            app.AxisZLabel = uilabel(app.LeftPanel, 'Text', 'Z:', 'Position', [180 yPos 20 20]);
            app.AxisZSpinner = uispinner(app.LeftPanel, 'Position', [200 yPos 40 20], 'Limits', [1 3], 'Value', 3, 'ValueChangedFcn', @app.AxisSpinnerChanged);
            
            % 2. Analysis Params
            yPos = yPos - 40;
            app.ParamsLabel = uilabel(app.LeftPanel, 'Text', '2. Analysis Params', 'Position', [10 yPos 200 20], 'FontWeight', 'bold');
            yPos = yPos - 30;
            app.VelThreshLabel = uilabel(app.LeftPanel, 'Text', 'Vel Thresh (mm/s):', 'Position', [10 yPos 120 20]);
            app.VelThreshSpinner = uispinner(app.LeftPanel, 'Position', [140 yPos 60 20], 'Limits', [1 1000], 'Value', 10);
            yPos = yPos - 25;
            app.DurLabel = uilabel(app.LeftPanel, 'Text', 'Min Dur (ms):', 'Position', [10 yPos 120 20]);
            app.DurSpinner = uispinner(app.LeftPanel, 'Position', [140 yPos 60 20], 'Limits', [1 1000], 'Value', 40);

            % Action Buttons
            yPos = yPos - 50; 
            app.LoadButton = uibutton(app.LeftPanel, 'push', 'Text', 'Load CSV Files', 'Position', [20 yPos 220 30], 'ButtonPushedFcn', @app.LoadButtonPushed);
            yPos = yPos - 40;
            app.AnalyzeButton = uibutton(app.LeftPanel, 'push', 'Text', 'Analyze All', 'Position', [20 yPos 220 30], 'Enable', 'off', 'ButtonPushedFcn', @app.AnalyzeButtonPushed);
            
            yPos = yPos - 50;
            app.FileLabel = uilabel(app.LeftPanel, 'Text', 'Select File to View:', 'Position', [20 yPos 220 20]);
            yPos = yPos - 25;
            app.FileDropDown = uidropdown(app.LeftPanel, 'Position', [20 yPos 220 25], 'Enable', 'off', 'ValueChangedFcn', @app.FileDropDownValueChanged);
            
            yPos = yPos - 50;
            app.ExportButton = uibutton(app.LeftPanel, 'push', 'Text', 'Export Summary', 'Position', [20 yPos 220 30], 'Enable', 'off', 'ButtonPushedFcn', @app.ExportButtonPushed);
            
            % Status
            app.StatusLabel = uilabel(app.LeftPanel, 'Text', 'Ready.', 'Position', [20 20 220 50], 'WordWrap', 'on', 'VerticalAlignment', 'top');

            % Visualization
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = 1; app.TabGroup.Layout.Column = 2;

            app.Tab3D = uitab(app.TabGroup, 'Title', '3D Trajectory');
            app.Ax3D = uiaxes(app.Tab3D, 'Position', [10 10 700 700]);

            app.TabKinematics = uitab(app.TabGroup, 'Title', 'Kinematics');
            kg = uigridlayout(app.TabKinematics, [3, 1]);
            app.AxVel = uiaxes(kg); app.AxVel.Layout.Row = 1;
            app.AxAcc = uiaxes(kg); app.AxAcc.Layout.Row = 2;
            app.AxJerk = uiaxes(kg); app.AxJerk.Layout.Row = 3;

            app.UIFigure.Visible = 'on';
        end
    end
end