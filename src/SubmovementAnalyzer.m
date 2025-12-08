classdef SubmovementAnalyzer < handle

    % ---------------------------------------------------------------------
    % Properties
    % ---------------------------------------------------------------------
    properties (Access = public)
        UIFigure      matlab.ui.Figure
        MainGrid      matlab.ui.container.GridLayout
        LeftPanel     matlab.ui.container.Panel
        LeftGrid      matlab.ui.container.GridLayout
        
        % Import Settings
        SettingsLabel    matlab.ui.control.Label
        TimeColLabel     matlab.ui.control.Label
        TimeColSpinner   matlab.ui.control.Spinner
        PosColLabel      matlab.ui.control.Label
        PosColSpinner    matlab.ui.control.Spinner
        HeaderCheckBox   matlab.ui.control.CheckBox
        
        % Axis Mapping UI
        AxisMapLabel     matlab.ui.control.Label
        AxisXLabel       matlab.ui.control.Label
        AxisXSpinner     matlab.ui.control.Spinner
        AxisYLabel       matlab.ui.control.Label
        AxisYSpinner     matlab.ui.control.Spinner
        AxisZLabel       matlab.ui.control.Label
        AxisZSpinner     matlab.ui.control.Spinner
        
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
    
    methods (Static) 
        function app = launch() 
            persistent instance 
            
            if isempty(instance) || ~isvalid(instance) 
                instance = SubmovementAnalyzer(); 
            else 
                figure(instance.UIFigure) 
            end 

            if nargout > 0 
                app = instance; 
            end 
        end 
    end 

    % ---------------------------------------------------------------------
    % Public Methods (Constructor)
    % ---------------------------------------------------------------------
    methods (Access = private)
        function app = SubmovementAnalyzer
            % Constructor: Handles Singleton logic and initialization.
            
            % 1. Singleton Check
            appTag = 'SubmovementAnalyzer_Singleton_Tag';
            existingFigs = findall(groot, 'Type', 'figure', 'Tag', appTag);
            
            if ~isempty(existingFigs)
                % If instance exists, bring it to front
                figure(existingFigs(1));
                
                % Delete this new instance immediately to prevent duplicate windows
                delete(app);
                
                % Return early (caller will receive a deleted handle)
                return;
            end
            
            % 2. Create UI Components
            createComponents(app);
            
            % 3. Tag the figure for future singleton checks
            app.UIFigure.Tag = appTag;
            
            % 4. Load Settings (Startup Logic)
            startup(app.UIFigure);
        end

        function delete(app) 
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure) 
                delete(app.UIFigure) 
            end 
            % For debugging 
            disp('App has been deleted.')
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
            
            % Axis Mapping
            if isfield(s.Import, 'AxisMapX'); app.AxisXSpinner.Value = s.Import.AxisMapX; end
            if isfield(s.Import, 'AxisMapY'); app.AxisYSpinner.Value = s.Import.AxisMapY; end
            if isfield(s.Import, 'AxisMapZ'); app.AxisZSpinner.Value = s.Import.AxisMapZ; end
            
            % Analysis Params
            app.VelThreshSpinner.Value = s.Analysis.VelThresh;
            app.DurSpinner.Value = s.Analysis.MinDuration;
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
                
                app.BatchData = MotionAnalysis.processBatch(app.BatchData, params, progressFcn);
                
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

        % --- UI Creation (Modularized) ---

        function createComponents(app)
            % 1. Main Window
            app.UIFigure = uifigure('Visible', 'off', 'Position', [100 100 1050 780], 'Name', 'Submovement Analyzer v4.3');
            app.UIFigure.CloseRequestFcn = @(src, event) delete(app);

            app.MainGrid = uigridlayout(app.UIFigure, 'ColumnWidth', {260, '1x'}, 'RowHeight', {'1x'});

            % 2. Left Panel
            app.LeftPanel = uipanel(app.MainGrid);
            app.LeftPanel.Layout.Row = 1; app.LeftPanel.Layout.Column = 1;
            
            app.LeftGrid = uigridlayout(app.LeftPanel, 'ColumnWidth', {'1x'}, 'RowHeight', ...
                {'fit','fit','fit','fit', 'fit','fit','fit','fit', 'fit','fit','fit','fit', '1x'}); 
            app.LeftGrid.RowSpacing = 10;
            app.LeftGrid.Padding = [10 10 10 10];

            % 3. Build UI Sections
            buildImportSection(app);
            buildAxisSection(app);
            buildParamsSection(app);
            buildActionSection(app);

            % 4. Right Panel
            app.TabGroup = uitabgroup(app.MainGrid);
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
        
        function buildImportSection(app)
            panel = uipanel(app.LeftGrid, 'Title', '1. Import Settings', 'FontWeight', 'bold');
            panel.Layout.Row = 1;
            g = uigridlayout(panel, 'ColumnWidth', {'1x', '1x'}, 'RowHeight', {'fit', 'fit', 'fit'});
            
            app.TimeColLabel = uilabel(g, 'Text', 'Time Column:');
            app.TimeColSpinner = uispinner(g, 'Limits', [1 100], 'Value', 1);
            
            app.PosColLabel = uilabel(g, 'Text', 'Pos Start Col:');
            app.PosColSpinner = uispinner(g, 'Limits', [1 100], 'Value', 2);
            
            app.HeaderCheckBox = uicheckbox(g, 'Text', 'Header Row');
            app.HeaderCheckBox.Layout.Column = [1 2]; 
        end
        
        function buildAxisSection(app)
            panel = uipanel(app.LeftGrid, 'Title', '3D Axis Mapping', 'FontWeight', 'bold');
            panel.Layout.Row = 2;
            g = uigridlayout(panel, 'ColumnWidth', {'fit', '1x'}, 'RowHeight', {'fit', 'fit', 'fit'});
            
            app.AxisXLabel = uilabel(g, 'Text', 'Plot X (Col):');
            app.AxisXSpinner = uispinner(g, 'Limits', [1 3], 'Value', 1, 'ValueChangedFcn', @app.AxisSpinnerChanged);
            
            app.AxisYLabel = uilabel(g, 'Text', 'Plot Y (Col):');
            app.AxisYSpinner = uispinner(g, 'Limits', [1 3], 'Value', 2, 'ValueChangedFcn', @app.AxisSpinnerChanged);
            
            app.AxisZLabel = uilabel(g, 'Text', 'Plot Z (Col):');
            app.AxisZSpinner = uispinner(g, 'Limits', [1 3], 'Value', 3, 'ValueChangedFcn', @app.AxisSpinnerChanged);
        end
        
        function buildParamsSection(app)
            panel = uipanel(app.LeftGrid, 'Title', '2. Analysis Params', 'FontWeight', 'bold');
            panel.Layout.Row = 3;
            g = uigridlayout(panel, 'ColumnWidth', {'1x', '1x'}, 'RowHeight', {'fit', 'fit'});
            
            app.VelThreshLabel = uilabel(g, 'Text', 'Vel Thresh:');
            app.VelThreshSpinner = uispinner(g, 'Limits', [1 1000], 'Value', 10);
            
            app.DurLabel = uilabel(g, 'Text', 'Min Dur (ms):');
            app.DurSpinner = uispinner(g, 'Limits', [1 1000], 'Value', 40);
        end
        
        function buildActionSection(app)
            app.LoadButton = uibutton(app.LeftGrid, 'push', 'Text', 'Load CSV Files', ...
                'ButtonPushedFcn', @app.LoadButtonPushed);
            app.LoadButton.Layout.Row = 4;
            
            app.AnalyzeButton = uibutton(app.LeftGrid, 'push', 'Text', 'Analyze All', ...
                'Enable', 'off', 'ButtonPushedFcn', @app.AnalyzeButtonPushed);
            app.AnalyzeButton.Layout.Row = 5;
            
            app.FileLabel = uilabel(app.LeftGrid, 'Text', 'Select File:');
            app.FileLabel.Layout.Row = 6;
            
            app.FileDropDown = uidropdown(app.LeftGrid, 'Enable', 'off', ...
                'ValueChangedFcn', @app.FileDropDownValueChanged);
            app.FileDropDown.Layout.Row = 7;
            
            app.ExportButton = uibutton(app.LeftGrid, 'push', 'Text', 'Export Summary', ...
                'Enable', 'off', 'ButtonPushedFcn', @app.ExportButtonPushed);
            app.ExportButton.Layout.Row = 8;
            
            app.StatusLabel = uilabel(app.LeftGrid, 'Text', 'Ready.', 'WordWrap', 'on', ...
                'VerticalAlignment', 'top');
            app.StatusLabel.Layout.Row = 9;
        end
    end
end