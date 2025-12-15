function dataDir = getDefaultPath()
% GETDEFAULTPATH Returns the absolute path to the 'data/samples' directory.
    
    % Get the location of this function
    currentFile = mfilename('fullpath');
    [pathDir, ~, ~] = fileparts(currentFile);
    
    % Go up levels: +FileIO -> +MotionAnalysis -> ProjectRoot -> data -> samples
    projectRoot = fullfile(pathDir, '..', '..');
    dataDir = fullfile(projectRoot, 'data', 'samples');
    
    if ~exist(dataDir, 'dir')
        dataDir = pwd; % Fallback
    end
end