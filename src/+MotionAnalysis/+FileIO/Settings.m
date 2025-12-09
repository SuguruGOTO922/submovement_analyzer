classdef Settings
    methods (Static)
        function defaults = getDefaults()
            % GETDEFAULTS Returns the hardcoded default configuration
            
            % --- Import Defaults ---
            defaults.Import.TimeCol = 1;
            defaults.Import.PosCol = 2;
            defaults.Import.HasHeader = false;
            
            % --- Analysis Defaults ---
            defaults.Analysis.AxisMapX = 1;
            defaults.Analysis.AxisMapY = 2;
            defaults.Analysis.AxisMapZ = 3;
            
            % Event Detection
            defaults.Analysis.VelThresh = 10;
            defaults.Analysis.MinDuration = 40; % ms
            
            % Filter Settings
            defaults.Analysis.FilterOrder = 2;   % 2nd order
            defaults.Analysis.CutoffFreq = 10;   % 10 Hz
            
            % Sampling Rate (0 or NaN means Auto)
            defaults.Analysis.FsAuto = true;
            defaults.Analysis.FsValue = 1000;    % Default fallback if manual
        end

        function settings = load()
            % LOAD Reads settings.json or returns defaults if not found
            filePath = MotionAnalysis.FileIO.Settings.getFilePath();
            defaults = MotionAnalysis.FileIO.Settings.getDefaults();
            
            if exist(filePath, 'file')
                try
                    text = fileread(filePath);
                    loaded = jsondecode(text);
                    settings = defaults;
                    
                    if isfield(loaded, 'Import')
                        f = fieldnames(loaded.Import);
                        for i = 1:numel(f); settings.Import.(f{i}) = loaded.Import.(f{i}); end
                    end
                    if isfield(loaded, 'Analysis')
                        f = fieldnames(loaded.Analysis);
                        for i = 1:numel(f); settings.Analysis.(f{i}) = loaded.Analysis.(f{i}); end
                    end
                catch
                    warning('Failed to parse settings.json. Using defaults.');
                    settings = defaults;
                end
            else
                settings = defaults;
            end
        end

        function save(currentSettings)
            % SAVE Writes the current settings structure to settings.json
            filePath = MotionAnalysis.FileIO.Settings.getFilePath();
            try
                text = jsonencode(currentSettings, 'PrettyPrint', true);
                fid = fopen(filePath, 'w');
                if fid == -1; error('Cannot create settings file.'); end
                fprintf(fid, '%s', text);
                fclose(fid);
            catch ME
                warning(ME.identifier, 'Failed to save settings: %s', ME.message);
            end
        end
        
        function path = getFilePath()
            currentFile = mfilename('fullpath');
            [pathDir, ~, ~] = fileparts(currentFile);
            projectRoot = fullfile(pathDir, '..', '..');
            path = fullfile(projectRoot, 'settings.json');
        end
    end
end