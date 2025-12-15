classdef Config
    % Config: Handles loading/saving of application settings (JSON).
    % Renamed from 'Settings' to avoid namespace shadowing.

    methods (Static)
        function defaults = getDefaults()
            % ... (内容は前回のSettings.mと同じ) ...
            defaults.Import.TimeCol = 1;
            defaults.Import.PosCol = 2;
            defaults.Import.HasHeader = false;
            defaults.Import.Unit = 'mm';
            
            defaults.Analysis.FilterOrder = 2;
            defaults.Analysis.CutoffFreq = 10;
            defaults.Analysis.FsAuto = true;
            defaults.Analysis.FsValue = 1000;
            defaults.Analysis.VelThresh = 10;
            defaults.Analysis.MinDuration = 40; 
            
            defaults.Visualization.AxisMapX = 1;
            defaults.Visualization.AxisMapY = 2;
            defaults.Visualization.AxisMapZ = 3;
            defaults.Visualization.ShowGrid = true;
            defaults.Visualization.ShowTraj = true;
            defaults.Visualization.ShowEvents = true;
            
            defaults.Export.IncludeType = true;
            defaults.Export.IncludeOnsetPos = true;
            defaults.Export.IncludeOffsetPos = true;
            defaults.Export.IncludeSubPos = true;
            defaults.Export.IncludeTotalDur = true;
            defaults.Export.IncludeTimeToSub = true;
            defaults.Export.IncludeSubDur = true;
            defaults.Export.IncludeMaxVel = true;
            defaults.Export.IncludeSubMaxVel = true;
        end

        function settings = load()
            filePath = MotionAnalysis.IO.Config.getFilePath(); % Class name updated
            defaults = MotionAnalysis.IO.Config.getDefaults();
            settings = defaults; 
            
            if exist(filePath, 'file')
                try
                    text = fileread(filePath);
                    loaded = jsondecode(text);
                    % ... (Merge logic same as before) ...
                    sections = fieldnames(defaults);
                    for i = 1:numel(sections)
                        secName = sections{i};
                        if isfield(loaded, secName)
                            f = fieldnames(defaults.(secName));
                            for k = 1:numel(f)
                                fName = f{k};
                                if isfield(loaded.(secName), fName)
                                    settings.(secName).(fName) = loaded.(secName).(fName);
                                end
                            end
                        end
                    end
                catch
                    warning('Failed to parse settings.json. Using defaults.');
                end
            end
        end

        function save(currentSettings)
            filePath = MotionAnalysis.IO.Config.getFilePath();
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
            % Go up: +IO -> +MotionAnalysis -> ProjectRoot
            projectRoot = fullfile(pathDir, '..', '..');
            path = fullfile(projectRoot, 'settings.json');
        end
    end
end