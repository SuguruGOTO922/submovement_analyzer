function batchData = processBatch(batchData, params, progressCallback) 
% PROCESSBATCH Runs the analysis pipeline on all loaded files.
%
% Inputs:
%   batchData        : Struct array of loaded data
%   params           : Analysis parameters struct
%   progressCallback : (Optional) Function handle @(percent, message)
%
% Output:
%   batchData        : Updated struct array with .Results populated

arguments 
    batchData struct 
    params struct
    progressCallback function_handle = []
end 

nFiles = length(batchData);

for i = 1:nFiles
    % --- Determine Sampling Rate ---
    if isfield(params, 'FsAuto') && ~params.FsAuto && isfield(params, 'FsValue')
        % Manual Override
        currentFs = params.FsValue;
    else
        % Auto (Default)
        currentFs = batchData(i).Fs;
    end

    % Notify progress if callback is provided
    if ~isempty(progressCallback)
        msg = sprintf('Processing %d of %d: %s', i, nFiles, batchData(i).FileName);
        progressCallback(i / nFiles, msg);
    end
    
    % Run Pipeline
    batchData(i).Results = MotionAnalysis.runPipeline(...
        batchData(i).RawData(:,1), ...
        batchData(i).RawData(:,2:4), ...
        currentFs, ...
        params);
end

end