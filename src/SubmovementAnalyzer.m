classdef SubmovementAnalyzer < handle
    % SubmovementAnalyzer (Presenter)
    % Orchestrates interactions between MainView (UI) and AppModel (Logic).
    % Refactored for MVP pattern and clean namespaces.

    properties (Access = public)
        View   % MotionAnalysis.View.MainView
        Model  % MotionAnalysis.Model.AppModel
    end

    % ---------------------------------------------------------------------
    % Static Methods (Launcher)
    % ---------------------------------------------------------------------
    methods (Static)
        function app = launch()
            import MotionAnalysis.View.AppConstants
            
            existingFigs = findall(groot, 'Type', 'figure', 'Tag', AppConstants.AppTag);
            
            if ~isempty(existingFigs)
                fig = existingFigs(1);
                figure(fig);
                if isprop(fig, 'UserData') && ~isempty(fig.UserData)
                    app = fig.UserData;
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
            % Clean up View when Presenter is deleted
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
            import MotionAnalysis.View.AppConstants
            
            % Singleton Check
            existingFigs = findall(groot, 'Type', 'figure', 'Tag', AppConstants.AppTag);
            if ~isempty(existingFigs)
                figure(existingFigs(1));
                delete(app); 
                return;
            end
            
            % 1. Instantiate Model (AppState)
            app.Model = MotionAnalysis.Model.AppModel();

            % 2. Instantiate View (MainView)
            app.View = MotionAnalysis.View.MainView();
            
            % 3. Setup Tag & Reference
            app.View.UIFigure.Tag = AppConstants.AppTag;
            app.View.UIFigure.UserData = app;
            
            % 4. Bind Callbacks
            app.bindCallbacks();

            % 5. Initialize View
            app.initializeView();
            
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
            
            % Interactivity
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

        function initializeView(app)
            % Fetch settings from Model
            s = app.Model.Settings;
            v = app.View;
            
            % 1. Import
            v.TimeColSpinner.Value = s.Import.TimeCol;
            v.PosColSpinner.Value = s.Import.PosCol;
            v.HeaderCheckBox.Value = s.Import.HasHeader;
            v.UnitDropDown.Value = s.Import.Unit;
            
            % 2. Analysis
            v.VelThreshSpinner.Value = s.Analysis.VelThresh;
            v.DurSpinner.Value = s.Analysis.MinDuration;
            v.OrderSpinner.Value = s.Analysis.FilterOrder;
            v.CutoffSpinner.Value = s.Analysis.CutoffFreq;
            v.FsAutoCheckBox.Value = s.Analysis.FsAuto;
            v.FsSpinner.Value = s.Analysis.FsValue;
            v.FsSpinner.Enable = ~v.FsAutoCheckBox.Value;
            
            % 3. Visualization
            v.AxisXSpinner.Value = s.Visualization.AxisMapX;
            v.AxisYSpinner.Value = s.Visualization.AxisMapY;
            v.AxisZSpinner.Value = s.Visualization.AxisMapZ;
            v.CheckShowGrid.Value = s.Visualization.ShowGrid;
            v.CheckShowTraj.Value = s.Visualization.ShowTraj;
            v.CheckShowEvents.Value = s.Visualization.ShowEvents;
            
            % 4. Export
            v.CheckType.Value = s.Export.IncludeType;
            v.CheckOnsetPos.Value = s.Export.IncludeOnsetPos;
            v.CheckOffsetPos.Value = s.Export.IncludeOffsetPos;
            v.CheckSubPos.Value = s.Export.IncludeSubPos;
            v.CheckTotalDur.Value = s.Export.IncludeTotalDur;
            v.CheckTimeSub.Value = s.Export.IncludeTimeToSub;
            v.CheckSubDur.Value = s.Export.IncludeSubDur;
            v.CheckMaxVel.Value = s.Export.IncludeMaxVel;
            v.CheckSubMaxVel.Value = s.Export.IncludeSubMaxVel;
        end
                
        function onClose(app, ~, ~)
            app.syncSettingsToModel();
            app.Model.saveSettings();
            
            app.View.UIFigure.CloseRequestFcn = '';
            delete(app);
        end

        function syncSettingsToModel(app)
            v = app.View;
            
            % Import
            sImport.TimeCol = v.TimeColSpinner.Value;
            sImport.PosCol = v.PosColSpinner.Value;
            sImport.HasHeader = v.HeaderCheckBox.Value;
            sImport.Unit = v.UnitDropDown.Value;
            app.Model.updateImportSettings(sImport);
            
            % Analysis
            sAnal.VelThresh = v.VelThreshSpinner.Value;
            sAnal.MinDuration = v.DurSpinner.Value;
            sAnal.FilterOrder = v.OrderSpinner.Value;
            sAnal.CutoffFreq = v.CutoffSpinner.Value;
            sAnal.FsAuto = v.FsAutoCheckBox.Value;
            sAnal.FsValue = v.FsSpinner.Value;
            app.Model.updateAnalysisSettings(sAnal);
            
            % Visualization
            sVis.AxisMapX = v.AxisXSpinner.Value;
            sVis.AxisMapY = v.AxisYSpinner.Value;
            sVis.AxisMapZ = v.AxisZSpinner.Value;
            sVis.ShowGrid = v.CheckShowGrid.Value;
            sVis.ShowTraj = v.CheckShowTraj.Value;
            sVis.ShowEvents = v.CheckShowEvents.Value;
            app.Model.updateVisSettings(sVis);
            
            % Export
            sExp.IncludeType = v.CheckType.Value;
            sExp.IncludeOnsetPos = v.CheckOnsetPos.Value;
            sExp.IncludeOffsetPos = v.CheckOffsetPos.Value;
            sExp.IncludeSubPos = v.CheckSubPos.Value;
            sExp.IncludeTotalDur = v.CheckTotalDur.Value;
            sExp.IncludeTimeToSub = v.CheckTimeSub.Value;
            sExp.IncludeSubDur = v.CheckSubDur.Value;
            sExp.IncludeMaxVel = v.CheckMaxVel.Value;
            sExp.IncludeSubMaxVel = v.CheckSubMaxVel.Value;
            app.Model.updateExportSettings(sExp);
        end

        % --- Callback Methods ---

        function LoadButtonPushed(app, ~, ~)
            import MotionAnalysis.View.AppConstants
            v = app.View;
            
            dataDir = MotionAnalysis.IO.getDefaultPath();
            [files, path] = uigetfile(fullfile(dataDir, '*.csv'), AppConstants.Msg_SelectCSV, 'MultiSelect', 'on');
            
            figure(v.UIFigure); 
            if isequal(files, 0); return; end
            
            try
                % Params from View
                p.TimeCol = v.TimeColSpinner.Value;
                p.PosCol = v.PosColSpinner.Value;
                p.HasHeader = v.HeaderCheckBox.Value;
                p.Unit = v.UnitDropDown.Value;
                
                % Delegate to Model
                count = app.Model.loadFiles(files, path, p);
                
                % Update View
                v.StatusLabel.Text = sprintf(AppConstants.Msg_LoadedCount, count);
                v.AnalyzeButton.Enable = 'on';
                v.ExportButton.Enable = 'off';
                v.ResultTable.Data = {};
                
                v.LeftTabGroup.SelectedTab = v.TabAnalyze;
                
                app.syncSettingsToModel();
                app.Model.saveSettings();
                
            catch ME
                uialert(v.UIFigure, ME.message, AppConstants.Msg_LoadErrorTitle);
            end
        end

        function AnalyzeButtonPushed(app, ~, ~)
            import MotionAnalysis.View.AppConstants
            if app.Model.getFileCount() == 0; return; end
            v = app.View;
            
            try
                % Gather Params
                p.VelThresh = v.VelThreshSpinner.Value;
                p.MinDuration = v.DurSpinner.Value / 1000; 
                p.FilterOrder = v.OrderSpinner.Value;
                p.CutoffFreq = v.CutoffSpinner.Value;
                p.FsAuto = v.FsAutoCheckBox.Value;
                p.FsValue = v.FsSpinner.Value;
                
                d = uiprogressdlg(v.UIFigure, 'Title', AppConstants.Msg_AnalyzeProgressTitle, 'Message', AppConstants.Msg_AnalyzeStart);
                progressFcn = @(ratio, msg) set(d, 'Value', ratio, 'Message', msg);
                
                % Delegate to Model
                app.Model.runAnalysis(p, progressFcn);
                
                close(d);
                figure(v.UIFigure); 
                
                v.StatusLabel.Text = AppConstants.Msg_AnalyzeComplete;
                v.ExportButton.Enable = 'on';
                
                app.populateResultTable();
                v.LeftTabGroup.SelectedTab = v.TabVis;
                
                app.syncSettingsToModel();
                app.Model.saveSettings();
                                
            catch ME
                uialert(v.UIFigure, [AppConstants.Msg_AnalyzeErrorTitle ': ' ME.message], 'Error');
            end
        end
        
        function FsAutoChanged(app, ~, ~)
            app.View.FsSpinner.Enable = ~app.View.FsAutoCheckBox.Value;
        end
        
        function ResultTableSelectionChanged(app, ~, event)
            if ~app.Model.IsAnalyzed; return; end
            if ~isempty(event.Selection)
                idx = event.Selection(1);
                app.updatePlotsForIndex(idx);
            end
        end
        
        function AxisSpinnerChanged(app, ~, ~)
            if app.Model.IsAnalyzed && ~isempty(app.View.ResultTable.Selection)
                 idx = app.View.ResultTable.Selection(1);
                 app.updatePlotsForIndex(idx);
            end
        end
        
        function VisOptionChanged(app, ~, ~)
            if app.Model.IsAnalyzed && ~isempty(app.View.ResultTable.Selection)
                 idx = app.View.ResultTable.Selection(1);
                 app.updatePlotsForIndex(idx);
            end
        end

        function ExportButtonPushed(app, ~, ~)
            import MotionAnalysis.View.AppConstants
            if ~app.Model.IsAnalyzed; return; end
            v = app.View;
            
            % Gather Export Options
            opts.IncType = v.CheckType.Value;
            opts.IncOnsetPos = v.CheckOnsetPos.Value;
            opts.IncOffsetPos = v.CheckOffsetPos.Value;
            opts.IncSubPos = v.CheckSubPos.Value;
            opts.IncTotalDur = v.CheckTotalDur.Value;
            opts.IncTimeToSub = v.CheckTimeSub.Value;
            opts.IncSubDur = v.CheckSubDur.Value;
            opts.IncMaxVel = v.CheckMaxVel.Value;
            opts.IncSubMaxVel = v.CheckSubMaxVel.Value;
            
            [file, path] = uiputfile('*.csv', AppConstants.Msg_SaveBatchTitle);
            figure(v.UIFigure);
            if isequal(file, 0); return; end
            
            try
                app.Model.exportResults(fullfile(path, file), opts);
                app.syncSettingsToModel();
                app.Model.saveSettings();
                uialert(v.UIFigure, AppConstants.Msg_ExportSuccess, AppConstants.Msg_ExportSuccessTitle);
            catch ME
                uialert(v.UIFigure, [AppConstants.Msg_ExportErrorTitle ': ' ME.message], 'Error');
            end
        end

        % --- Helpers ---

        function populateResultTable(app)
            n = app.Model.getFileCount();
            d = cell(n, 2);
            for i = 1:n
                data = app.Model.getDataByIndex(i);
                d{i, 1} = char(data.FileName);
                d{i, 2} = char(data.Results.SubType);
            end
            app.View.ResultTable.Data = d;
            
            if n > 0
                app.View.ResultTable.Selection = 1;
                app.updatePlotsForIndex(1);
            end
        end

        function updatePlotsForIndex(app, idx)
            data = app.Model.getDataByIndex(idx);
            if isempty(data) || isempty(data.Results); return; end
            
            v = app.View;
            
            axesHandles.Ax3D = v.Ax3D;
            axesHandles.AxVel = v.AxVel;
            axesHandles.AxAcc = v.AxAcc;
            axesHandles.AxJerk = v.AxJerk;
            
            map = [v.AxisXSpinner.Value, v.AxisYSpinner.Value, v.AxisZSpinner.Value];
            visOpts.ShowGrid = v.CheckShowGrid.Value;
            visOpts.ShowTraj = v.CheckShowTraj.Value;
            visOpts.ShowEvents = v.CheckShowEvents.Value;
            
            % Note: Plotter needs full batch for ghosts. 
            % Accessing property directly via handle reference.
            fullBatch = app.Model.BatchData; 
            
            % Call View Plotter
            MotionAnalysis.View.Plotter.update(axesHandles, fullBatch, idx, map, visOpts);
            
            res = data.Results;
            v.StatusLabel.Text = sprintf('File: %s | Type: %s | Fs: %d Hz', ...
                data.FileName, res.SubType, res.Fs);
        end
    end
end