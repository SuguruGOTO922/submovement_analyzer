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
            
            % Check for existing instance
            existingFigs = findall(groot, 'Type', 'figure', 'Tag', Resources.AppTag);
            
            if ~isempty(existingFigs)
                % Instance exists: Bring to front
                fig = existingFigs(1);
                figure(fig);
                if isprop(fig, 'UserData') && ~isempty(fig.UserData)
                    app = fig.UserData;
                else
                    app = []; 
                end
            else
                % Create new instance
                app = SubmovementAnalyzer();
            end
        end
    end
    
    % ---------------------------------------------------------------------
    % Public Methods (Destructor)
    % ---------------------------------------------------------------------
    methods (Access = public)
        function delete(app)
            % Clean up the View when Controller is deleted
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
            
            % Singleton Check
            existingFigs = findall(groot, 'Type', 'figure', 'Tag', Resources.AppTag);
            if ~isempty(existingFigs)
                figure(existingFigs(1));
                delete(app); 
                return;
            end
            
            % 1. Instantiate View
            app.View = MotionAnalysis.UI.MainView();
            
            % 2. Setup Tag & Store App Reference
            app.View.UIFigure.Tag = Resources.AppTag;
            app.View.UIFigure.UserData = app;
            
            % 3. Bind Callbacks
            app.bindCallbacks();

            % 4. Load Settings
            app.initialize();
            
            if nargout == 0; clear app; end
        end
        
        function bindCallbacks(app)
            v = app.View;
            
            % Window
            v.UIFigure.CloseRequestFcn        = @(src, event) app.onClose(src, event);
            
            % Actions
            v.LoadButton.ButtonPushedFcn      = @app.LoadButtonPushed;
            v.AnalyzeButton.ButtonPushedFcn   = @app.AnalyzeButtonPushed;
            v.ExportButton.ButtonPushedFcn    = @app.ExportButtonPushed;
            
            % Interactive UI
            v.FsAutoCheckBox.ValueChangedFcn  = @app.FsAutoChanged;
            v.ResultTable.SelectionChangedFcn = @app.ResultTableSelectionChanged;
            
            % Visualization Triggers
            v.AxisXSpinner.ValueChangedFcn    = @app.AxisSpinnerChanged;
            v.AxisYSpinner.ValueChangedFcn    = @app.AxisSpinnerChanged;
            v.AxisZSpinner.ValueChangedFcn    = @app.AxisSpinnerChanged;
            
            v.CheckShowGrid.ValueChangedFcn   = @app.VisOptionChanged;
            v.CheckShowTraj.ValueChangedFcn   = @app.VisOptionChanged;
            v.CheckShowEvents.ValueChangedFcn = @app.VisOptionChanged;
        end

        function initialize(app)
            % Load settings from JSON and populate the UI
            s = MotionAnalysis.FileIO.Settings.load();
            v = app.View;
            
            % 1. Import Settings
            v.TimeColSpinner.Value = s.Import.TimeCol;
            v.PosColSpinner.Value = s.Import.PosCol;
            v.HeaderCheckBox.Value = s.Import.HasHeader;
            v.UnitDropDown.Value = s.Import.Unit;
            
            % 2. Analysis Settings
            v.VelThreshSpinner.Value = s.Analysis.VelThresh;
            v.DurSpinner.Value = s.Analysis.MinDuration;
            v.OrderSpinner.Value = s.Analysis.FilterOrder;
            v.CutoffSpinner.Value = s.Analysis.CutoffFreq;
            v.FsAutoCheckBox.Value = s.Analysis.FsAuto;
            v.FsSpinner.Value = s.Analysis.FsValue;
            
            % 3. Visualization Settings
            v.AxisXSpinner.Value = s.Visualization.AxisMapX;
            v.AxisYSpinner.Value = s.Visualization.AxisMapY;
            v.AxisZSpinner.Value = s.Visualization.AxisMapZ;
            v.CheckShowGrid.Value = s.Visualization.ShowGrid;
            v.CheckShowTraj.Value = s.Visualization.ShowTraj;
            v.CheckShowEvents.Value = s.Visualization.ShowEvents;
            
            % 4. Export Settings
            v.CheckType.Value = s.Export.IncludeType;
            v.CheckOnsetPos.Value = s.Export.IncludeOnsetPos;
            v.CheckOffsetPos.Value = s.Export.IncludeOffsetPos;
            v.CheckSubPos.Value = s.Export.IncludeSubPos;
            v.CheckTotalDur.Value = s.Export.IncludeTotalDur;
            v.CheckTimeSub.Value = s.Export.IncludeTimeToSub;
            v.CheckSubDur.Value = s.Export.IncludeSubDur;
            v.CheckMaxVel.Value = s.Export.IncludeMaxVel;
            v.CheckSubMaxVel.Value = s.Export.IncludeSubMaxVel;
            
            % Update UI State
            v.FsSpinner.Enable = ~v.FsAutoCheckBox.Value;
        end
                
        function onClose(app, ~, ~)
            app.saveSettings();
            app.View.UIFigure.CloseRequestFcn = '';
            delete(app);
        end

        function saveSettings(app)
            try
                v = app.View;
                
                % Import
                s.Import.TimeCol = v.TimeColSpinner.Value;
                s.Import.PosCol = v.PosColSpinner.Value;
                s.Import.HasHeader = v.HeaderCheckBox.Value;
                s.Import.Unit = v.UnitDropDown.Value;
                
                % Analysis
                s.Analysis.VelThresh = v.VelThreshSpinner.Value;
                s.Analysis.MinDuration = v.DurSpinner.Value;
                s.Analysis.FilterOrder = v.OrderSpinner.Value;
                s.Analysis.CutoffFreq = v.CutoffSpinner.Value;
                s.Analysis.FsAuto = v.FsAutoCheckBox.Value;
                s.Analysis.FsValue = v.FsSpinner.Value;
                
                % Visualization
                s.Visualization.AxisMapX = v.AxisXSpinner.Value;
                s.Visualization.AxisMapY = v.AxisYSpinner.Value;
                s.Visualization.AxisMapZ = v.AxisZSpinner.Value;
                s.Visualization.ShowGrid = v.CheckShowGrid.Value;
                s.Visualization.ShowTraj = v.CheckShowTraj.Value;
                s.Visualization.ShowEvents = v.CheckShowEvents.Value;
                
                % Export
                s.Export.IncludeType = v.CheckType.Value;
                s.Export.IncludeOnsetPos = v.CheckOnsetPos.Value;
                s.Export.IncludeOffsetPos = v.CheckOffsetPos.Value;
                s.Export.IncludeSubPos = v.CheckSubPos.Value;
                s.Export.IncludeTotalDur = v.CheckTotalDur.Value;
                s.Export.IncludeTimeToSub = v.CheckTimeSub.Value;
                s.Export.IncludeSubDur = v.CheckSubDur.Value;
                s.Export.IncludeMaxVel = v.CheckMaxVel.Value;
                s.Export.IncludeSubMaxVel = v.CheckSubMaxVel.Value;
                
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
                % Pass Unit Selection to Loader
                app.BatchData = MotionAnalysis.FileIO.loadBatch(files, path, ...
                    v.TimeColSpinner.Value, ...
                    v.PosColSpinner.Value, ...
                    v.HeaderCheckBox.Value, ...
                    v.UnitDropDown.Value);
                
                count = length(app.BatchData);
                v.StatusLabel.Text = sprintf(Resources.Msg_LoadedCount, count);
                
                v.AnalyzeButton.Enable = 'on';
                v.ExportButton.Enable = 'off';
                v.ResultTable.Data = {};
                
                app.IsAnalyzed = false;
                v.LeftTabGroup.SelectedTab = v.TabAnalyze;
                
                app.saveSettings();
                
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
                params.MinDuration = v.DurSpinner.Value / 1000; % ms to s
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
                
                app.populateResultTable();
                v.LeftTabGroup.SelectedTab = v.TabVis;
                
                app.saveSettings();
                                
            catch ME
                uialert(v.UIFigure, [Resources.Msg_AnalyzeErrorTitle ': ' ME.message], 'Error');
            end
        end
        
        function FsAutoChanged(app, ~, ~)
            app.View.FsSpinner.Enable = ~app.View.FsAutoCheckBox.Value;
        end
        
        function ResultTableSelectionChanged(app, ~, event)
            if ~app.IsAnalyzed; return; end
            if ~isempty(event.Selection)
                idx = event.Selection(1);
                app.updateView(idx);
            end
        end
        
        function AxisSpinnerChanged(app, ~, ~)
            if app.IsAnalyzed && ~isempty(app.View.ResultTable.Selection)
                 idx = app.View.ResultTable.Selection(1);
                 app.updateView(idx);
            end
        end
        
        function VisOptionChanged(app, ~, ~)
            if app.IsAnalyzed && ~isempty(app.View.ResultTable.Selection)
                 idx = app.View.ResultTable.Selection(1);
                 app.updateView(idx);
            end
        end

        function ExportButtonPushed(app, ~, ~)
            import MotionAnalysis.UI.Resources
            if ~app.IsAnalyzed; return; end
            v = app.View;
            
            % Read Export Options
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
                app.saveSettings();
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
                app.updateView(1);
            end
        end

        function updateView(app, highlightIdx)
            if isempty(app.BatchData) || highlightIdx < 1 || highlightIdx > length(app.BatchData)
                return;
            end
            
            v = app.View;
            
            axesHandles.Ax3D = v.Ax3D;
            axesHandles.AxVel = v.AxVel;
            axesHandles.AxAcc = v.AxAcc;
            axesHandles.AxJerk = v.AxJerk;
            
            mapX = v.AxisXSpinner.Value;
            mapY = v.AxisYSpinner.Value;
            mapZ = v.AxisZSpinner.Value;
            axisMap = [mapX, mapY, mapZ];
            
            visOpts.ShowGrid   = v.CheckShowGrid.Value;
            visOpts.ShowTraj   = v.CheckShowTraj.Value;
            visOpts.ShowEvents = v.CheckShowEvents.Value;
            
            MotionAnalysis.UI.Plotter.update(axesHandles, app.BatchData, highlightIdx, axisMap, visOpts);
            
            res = app.BatchData(highlightIdx).Results;
            v.StatusLabel.Text = sprintf('File: %s | Type: %s | Fs: %d Hz', ...
                app.BatchData(highlightIdx).FileName, res.SubType, res.Fs);
        end
    end
end