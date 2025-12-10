function m = calculateMetrics(res)
% CALCULATEMETRICS Computes scalar metrics from analysis results.
%
% Returns a struct 'm' with fields:
%   TotalDuration, TimeToSub, SubDuration, MaxVel, SubMaxVel

    % Basic timing
    tOnset = res.Time(res.OnsetIdx);
    tOffset = res.Time(res.OffsetIdx);
    
    % (a) Total Duration
    m.TotalDuration = tOffset - tOnset;
    
    % Velocity Segment
    velSegment = res.TanVel(res.OnsetIdx : res.OffsetIdx);
    
    % (d) Max Velocity
    if ~isempty(velSegment)
        m.MaxVel = max(velSegment);
    else
        m.MaxVel = NaN;
    end
    
    % Submovement Metrics
    if ~isnan(res.SubStartIdx)
        tSub = res.Time(res.SubStartIdx);
        
        % (b) Time to Submovement
        m.TimeToSub = tSub - tOnset;
        
        % (c) Submovement Duration
        m.SubDuration = tOffset - tSub;
        
        % (e) Submovement Max Velocity
        % Determine range: from SubStart to Offset
        if res.SubStartIdx < res.OffsetIdx
            subVelSegment = res.TanVel(res.SubStartIdx : res.OffsetIdx);
            m.SubMaxVel = max(subVelSegment);
        else
            m.SubMaxVel = NaN;
        end
    else
        m.TimeToSub = NaN;
        m.SubDuration = NaN;
        m.SubMaxVel = NaN;
    end
end