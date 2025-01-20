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
%   hSI.hIntegrationRoiManager.postProcessFcn = @integrationPostProcessingFcn_test1;
%
% SET UP PHYSICAL OUTPUTS IN 'INTEGRATION CONTROL'
%   Output function: @(vals,varargin)(vals)>0

function integrationValues = integrationPostProcessingFcn_test1(rois,integrationDone,arrayIndices,integrationValueHistory,integrationTimestampHistory,integrationFrameNumberHistory)
% TEST1:
%   - RT clk changes state on every processed frame
%   - Cycle through the 5 output classes on every processed frame

    row_ind = arrayIndices(1);
    
    % By copying integrationValueHistory, we make sure that
    % integrationValues has the correct number of ROIs for ScanImage
    integrationValues = integrationValueHistory(row_ind,:);

    % Predict different classes in sequence
    frame_number = integrationFrameNumberHistory(row_ind);
    class_number = mod(frame_number, 5);
    if class_number == 0
        class_number = 5;
    end
    integrationValues(1:5) = 0;
    integrationValues(class_number) = 1;

    % "Real-time clock"
    integrationValues(6) = mod(row_ind,2);
end