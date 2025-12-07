function batchData = processBatch(batchData, params, opts) 
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
    opts.progressCallback function_handle
end 

nFiles = length(batchData);

for i = 1:nFiles
    % Notify progress if callback is provided
    if ~isempty(opts.progressCallback)
        msg = sprintf('Processing %d of %d: %s', i, nFiles, batchData(i).FileName);
        opts.progressCallback(i / nFiles, msg);
    end
    
    % Run Pipeline
    batchData(i).Results = MotionAnalysis.runPipeline(...
        batchData(i).RawData(:,1), ...
        batchData(i).RawData(:,2:4), ...
        batchData(i).Fs, ...
        "minDuration", params.MinDuration, ...
        "velThresh",   params.VelThresh);
end

end