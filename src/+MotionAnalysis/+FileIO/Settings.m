classdef Settings
    methods (Static)
        function defaults = getDefaults()
            % GETDEFAULTS Returns the hardcoded default configuration
            defaults.Import.TimeCol = 1;
            defaults.Import.PosCol = 2;
            defaults.Import.HasHeader = false;
            
            % New: Axis Mapping (1=1st pos col, 2=2nd, 3=3rd)
            defaults.Import.AxisMapX = 1;
            defaults.Import.AxisMapY = 2;
            defaults.Import.AxisMapZ = 3;
            
            defaults.Analysis.VelThresh = 10;
            defaults.Analysis.MinDuration = 40; % ms
        end

        function settings = load()
            % LOAD Reads settings.json or returns defaults if not found
            filePath = MotionAnalysis.FileIO.Settings.getFilePath();
            defaults = MotionAnalysis.FileIO.Settings.getDefaults();
            
            if exist(filePath, 'file')
                try
                    text = fileread(filePath);
                    loaded = jsondecode(text);
                    
                    % Merge loaded settings with defaults
                    settings = defaults;
                    
                    % Merge Import
                    if isfield(loaded, 'Import')
                        f = fieldnames(loaded.Import);
                        for i = 1:numel(f)
                            settings.Import.(f{i}) = loaded.Import.(f{i});
                        end
                    end
                    
                    % Merge Analysis
                    if isfield(loaded, 'Analysis')
                        f = fieldnames(loaded.Analysis);
                        for i = 1:numel(f)
                            settings.Analysis.(f{i}) = loaded.Analysis.(f{i});
                        end
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
                if fid == -1
                    error('Cannot create settings file.');
                end
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