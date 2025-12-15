classdef AppModel < handle
    % AppModel (Model Layer)
    % Holds state and delegates business logic to IO and AnalysisEngine.

    properties (SetAccess = private)
        BatchData struct
        Settings struct
        IsAnalyzed logical = false
    end

    methods (Access = public)
        function obj = AppModel()
            % Load Config
            obj.Settings = MotionAnalysis.IO.Config.load();
            obj.resetData();
        end

        function resetData(obj)
            obj.BatchData = struct('FileName', {}, 'RawData', {}, 'Fs', {}, 'Results', {});
            obj.IsAnalyzed = false;
        end

        function count = loadFiles(obj, files, path, importParams)
            % Delegate to IO
            obj.BatchData = MotionAnalysis.IO.loadBatch(...
                files, path, ...
                importParams.TimeCol, ...
                importParams.PosCol, ...
                importParams.HasHeader, ...
                importParams.Unit);
            
            obj.IsAnalyzed = false;
            count = length(obj.BatchData);
        end

        function runAnalysis(obj, analysisParams, progressCallback)
            obj.updateAnalysisSettings(analysisParams);

            % Delegate to AnalysisEngine
            obj.BatchData = MotionAnalysis.Model.AnalysisEngine.processBatch(...
                obj.BatchData, analysisParams, progressCallback);
                
            obj.IsAnalyzed = true;
        end

        function exportResults(obj, path, exportOptions)
            if ~obj.IsAnalyzed
                error('No analysis data available to export.');
            end
            % Delegate to IO
            MotionAnalysis.IO.exportSummary(obj.BatchData, path, exportOptions);
            obj.Settings.Export = exportOptions;
        end

        function saveSettings(obj)
            MotionAnalysis.IO.Config.save(obj.Settings);
        end

        % --- Update Helpers ---
        function updateImportSettings(obj, s), obj.Settings.Import = s; end
        function updateAnalysisSettings(obj, s)
            f = fieldnames(s);
            for i = 1:numel(f), obj.Settings.Analysis.(f{i}) = s.(f{i}); end
        end
        function updateVisSettings(obj, s), obj.Settings.Visualization = s; end
        function updateExportSettings(obj, s), obj.Settings.Export = s; end

        % --- Accessors ---
        function data = getDataByIndex(obj, idx)
            if isempty(obj.BatchData) || idx < 1 || idx > length(obj.BatchData)
                data = [];
            else
                data = obj.BatchData(idx);
            end
        end
        
        function count = getFileCount(obj)
            count = length(obj.BatchData);
        end
    end
end