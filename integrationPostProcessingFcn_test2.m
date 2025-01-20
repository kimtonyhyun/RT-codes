% STANDARD TEST CONDITIONS
%   - 7 "dummy" ROIs to hold real-time calculation results
%       - ROI 1:5 == LL/L/0/R/RR
%       - ROI 6 == RT clock
%       - ROI 7 == Unused in this code
%   - RT Clock must be the LAST real-time output in Machine Configuration
%
% OPTIMIZE FOR PERFORMANCE
%   - Disable all live visualizations
%   - For main display, set Rolling average factor = 1
%
% SET UP REAL-TIME CALLBACK
%   hSI.hIntegrationRoiManager.integrationHistoryLength = 15000;
%   hSI.hIntegrationRoiManager.postProcessFcn = @integrationPostProcessingFcn_test2;
%
% SET UP PHYSICAL OUTPUTS IN 'INTEGRATION CONTROL'
%   Output function: @(vals,varargin)(vals)>0

function integrationValues = integrationPostProcessingFcn_test2(rois,integrationDone,arrayIndices,integrationValueHistory,integrationTimestampHistory,integrationFrameNumberHistory)
% TEST2:
%   - Compute DFFs on real ROIs (typically 50)
%
% Expected outputs:
%   - RT clk changes state on every processed frame
%   - Cycle through the 5 output classes on every processed frame

    N = 900; % Number of frames used for F0 averaging (900 == 30 s @ 30 Hz)

    row_ind = arrayIndices(1);

    F0 = sum(integrationValueHistory(max([row_ind-N 1]):max([row_ind-1 1]), :), 1);
    F0 = F0 / min([N row_ind]);
    F = integrationValueHistory(row_ind,:);
    integrationValues = (F-F0)./F0;

    % Safety
    integrationValues(isnan(integrationValues)) = 0;

    % Predict different classes in sequence
    frame_number = integrationFrameNumberHistory(row_ind);
    class_number = mod(frame_number, 5);
    if class_number == 0
        class_number = 5;
    end
    class_output = zeros(1,6);
    class_output(class_number) = 1;

    % "Real-time clock"
    class_output(6) = mod(row_ind,2);

    integrationValues(end-6:end-1) = class_output;
    integrationValues(end) = 0;
end