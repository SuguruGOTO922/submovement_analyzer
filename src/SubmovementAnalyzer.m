classdef SubmovementAnalyzer < handle
    % SubmovementAnalyzer (Controller)
    % Orchestrates the interactions between MainView (UI), Model (Algorithms), and FileIO.

    properties (Access = public)
        View  % Instance of MotionAnalysis.UI.MainView
    end

    properties (Access = private)
        BatchData struct
        IsAnalyzed logical = false
    end

    % ---------------------------------------------------------------------
    % Static Methods (Launcher)
    % ---------------------------------------------------------------------
    methods (Static)
        function app = launch()
            import MotionAnalysis.UI.Resources
            
            existingFigs = findall(groot, 'Type', 'figure', 'Tag', Resources.AppTag);
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
    
    % ---------------------------------------------------------------------
    % Public Methods (Destructor)
    % ---------------------------------------------------------------------
    methods (Access = public)
        function delete(app)
            if ~isempty(app.View) && isvalid(app.View)
                delete(app.View);
            end
        end
    end

    % ---------------------------------------------------------------------
    % Private Methods (Constructor & Logic)
    % ---------------------------------------------------------------------
    methods (Access = private)
        function app = SubmovementAnalyzer
            import MotionAnalysis.UI.Resources
            
            existingFigs = findall(groot, 'Type', 'figure', 'Tag', Resources.AppTag);
            if ~isempty(existingFigs)
                figure(existingFigs(1));
                delete(app); 
                return;
            end
            
            % 1. Instantiate View
            app.View = MotionAnalysis.UI.MainView();
            
            % 2. Setup Tag
            app.View.UIFigure.Tag = Resources.AppTag;
            app.View.UIFigure.UserData = app;
            
            % 3. Bind Callbacks
            app.bindCallbacks();

            % 4. Initialize Settings
            app.initialize();
            
            if nargout == 0; clear app; end
        end
        
        function bindCallbacks(app)
            v = app.View;
            
            v.UIFigure.CloseRequestFcn        = @(src, event) app.onClose(src, event);
            v.LoadButton.ButtonPushedFcn      = @app.LoadButtonPushed;
            v.AnalyzeButton.ButtonPushedFcn   = @app.AnalyzeButtonPushed;
            v.ExportButton.ButtonPushedFcn    = @app.ExportButtonPushed;
            v.FsAutoCheckBox.ValueChangedFcn  = @app.FsAutoChanged;
            v.ResultTable.SelectionChangedFcn = @app.ResultTableSelectionChanged;
            
            v.AxisXSpinner.ValueChangedFcn    = @app.AxisSpinnerChanged;
            v.AxisYSpinner.ValueChangedFcn    = @app.AxisSpinnerChanged;
            v.AxisZSpinner.ValueChangedFcn    = @app.AxisSpinnerChanged;
        end

        function initialize(app)
            s = MotionAnalysis.FileIO.Settings.load();
            v = app.View;
            
            v.TimeColSpinner.Value = s.Import.TimeCol;
            v.PosColSpinner.Value = s.Import.PosCol;
            v.HeaderCheckBox.Value = s.Import.HasHeader;
            
            if isfield(s.Analysis, 'AxisMapX'); v.AxisXSpinner.Value = s.Analysis.AxisMapX; end
            if isfield(s.Analysis, 'AxisMapY'); v.AxisYSpinner.Value = s.Analysis.AxisMapY; end
            if isfield(s.Analysis, 'AxisMapZ'); v.AxisZSpinner.Value = s.Analysis.AxisMapZ; end
            
            v.VelThreshSpinner.Value = s.Analysis.VelThresh;
            v.DurSpinner.Value = s.Analysis.MinDuration;
            
            if isfield(s.Analysis, 'FilterOrder'); v.OrderSpinner.Value = s.Analysis.FilterOrder; end
            if isfield(s.Analysis, 'CutoffFreq'); v.CutoffSpinner.Value = s.Analysis.CutoffFreq; end
            if isfield(s.Analysis, 'FsAuto'); v.FsAutoCheckBox.Value = s.Analysis.FsAuto; end
            if isfield(s.Analysis, 'FsValue'); v.FsSpinner.Value = s.Analysis.FsValue; end
            
            v.FsSpinner.Enable = ~v.FsAutoCheckBox.Value;
        end
                
        function onClose(app, ~, ~)
            saveSettings(app);
            app.View.UIFigure.CloseRequestFcn = '';
            delete(app);
        end

        function saveSettings(app)
            try
                v = app.View;
                s.Import.TimeCol = v.TimeColSpinner.Value;
                s.Import.PosCol = v.PosColSpinner.Value;
                s.Import.HasHeader = v.HeaderCheckBox.Value;
                
                s.Analysis.AxisMapX = v.AxisXSpinner.Value;
                s.Analysis.AxisMapY = v.AxisYSpinner.Value;
                s.Analysis.AxisMapZ = v.AxisZSpinner.Value;
                
                s.Analysis.VelThresh = v.VelThreshSpinner.Value;
                s.Analysis.MinDuration = v.DurSpinner.Value;
                
                s.Analysis.FilterOrder = v.OrderSpinner.Value;
                s.Analysis.CutoffFreq = v.CutoffSpinner.Value;
                s.Analysis.FsAuto = v.FsAutoCheckBox.Value;
                s.Analysis.FsValue = v.FsSpinner.Value;
                
                MotionAnalysis.FileIO.Settings.save(s);
            catch ME
                warning(ME.identifier, 'Failed to save settings: %s', ME.message);
            end
        end

        % --- Callback Methods ---

        function LoadButtonPushed(app, ~, ~)
            import MotionAnalysis.UI.Resources
            v = app.View;
            
            dataDir = MotionAnalysis.FileIO.getDefaultPath();
            [files, path] = uigetfile(fullfile(dataDir, '*.csv'), Resources.Msg_SelectCSV, 'MultiSelect', 'on');
            
            figure(v.UIFigure); 
            if isequal(files, 0); return; end
            
            try
                app.BatchData = MotionAnalysis.FileIO.loadBatch(files, path, v.TimeColSpinner.Value, v.PosColSpinner.Value, v.HeaderCheckBox.Value);
                
                count = length(app.BatchData);
                v.StatusLabel.Text = sprintf(Resources.Msg_LoadedCount, count);
                
                v.AnalyzeButton.Enable = 'on';
                v.ExportButton.Enable = 'off';
                v.ResultTable.Data = {};
                
                app.IsAnalyzed = false;
                v.LeftTabGroup.SelectedTab = v.TabAnalyze;
                
                saveSettings(app);
                
            catch ME
                uialert(v.UIFigure, ME.message, Resources.Msg_LoadErrorTitle);
            end
        end

        function AnalyzeButtonPushed(app, ~, ~)
            import MotionAnalysis.UI.Resources
            if isempty(app.BatchData); return; end
            v = app.View;
            
            try
                params.VelThresh = v.VelThreshSpinner.Value;
                params.MinDuration = v.DurSpinner.Value / 1000; 
                params.FilterOrder = v.OrderSpinner.Value;
                params.CutoffFreq = v.CutoffSpinner.Value;
                params.FsAuto = v.FsAutoCheckBox.Value;
                params.FsValue = v.FsSpinner.Value;
                
                d = uiprogressdlg(v.UIFigure, 'Title', Resources.Msg_AnalyzeProgressTitle, 'Message', Resources.Msg_AnalyzeStart);
                progressFcn = @(ratio, msg) set(d, 'Value', ratio, 'Message', msg);
                
                app.BatchData = MotionAnalysis.processBatch(app.BatchData, params, progressFcn);
                
                close(d);
                figure(v.UIFigure); 
                app.IsAnalyzed = true;
                
                v.StatusLabel.Text = Resources.Msg_AnalyzeComplete;
                v.ExportButton.Enable = 'on';
                
                populateResultTable(app);
                
                v.LeftTabGroup.SelectedTab = v.TabResult;
                
                saveSettings(app);
                                
            catch ME
                uialert(v.UIFigure, [Resources.Msg_AnalyzeErrorTitle ': ' ME.message], 'Error');
            end
        end
        
        function FsAutoChanged(app, ~, ~)
            app.View.FsSpinner.Enable = ~app.View.FsAutoCheckBox.Value;
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
            if app.IsAnalyzed && ~isempty(app.View.ResultTable.Selection)
                 idx = app.View.ResultTable.Selection(1);
                 updateView(app, idx);
            end
        end

        function ExportButtonPushed(app, ~, ~)
            import MotionAnalysis.UI.Resources
            if ~app.IsAnalyzed; return; end
            
            v = app.View;
            
            % Read options
            options.IncType      = v.CheckType.Value;
            
            options.IncOnsetPos  = v.CheckOnsetPos.Value;
            options.IncOffsetPos = v.CheckOffsetPos.Value;
            options.IncSubPos    = v.CheckSubPos.Value;
            
            options.IncTotalDur  = v.CheckTotalDur.Value;
            options.IncTimeToSub = v.CheckTimeSub.Value;
            options.IncSubDur    = v.CheckSubDur.Value;
            options.IncMaxVel    = v.CheckMaxVel.Value;
            options.IncSubMaxVel = v.CheckSubMaxVel.Value;
            
            [file, path] = uiputfile('*.csv', Resources.Msg_SaveBatchTitle);
            figure(v.UIFigure);
            if isequal(file, 0); return; end
            try
                MotionAnalysis.FileIO.exportSummary(app.BatchData, fullfile(path, file), options);
                uialert(v.UIFigure, Resources.Msg_ExportSuccess, Resources.Msg_ExportSuccessTitle);
            catch ME
                uialert(v.UIFigure, [Resources.Msg_ExportErrorTitle ': ' ME.message], 'Error');
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
            app.View.ResultTable.Data = tData;
            if nFiles > 0
                app.View.ResultTable.Selection = 1;
                updateView(app, 1);
            end
        end

        function updateView(app, highlightIdx)
            if isempty(app.BatchData) || highlightIdx < 1 || highlightIdx > length(app.BatchData)
                return;
            end
            
            v = app.View;
            
            % Pack axes
            axesHandles.Ax3D = v.Ax3D;
            axesHandles.AxVel = v.AxVel;
            axesHandles.AxAcc = v.AxAcc;
            axesHandles.AxJerk = v.AxJerk;
            
            mapX = v.AxisXSpinner.Value;
            mapY = v.AxisYSpinner.Value;
            mapZ = v.AxisZSpinner.Value;
            axisMap = [mapX, mapY, mapZ];
            
            % Call UI Plotter
            MotionAnalysis.UI.Plotter.update(axesHandles, app.BatchData, highlightIdx, axisMap);
            
            res = app.BatchData(highlightIdx).Results;
            v.StatusLabel.Text = sprintf('File: %s | Type: %s | Fs: %d Hz', ...
                app.BatchData(highlightIdx).FileName, res.SubType, res.Fs);
        end
    end
end