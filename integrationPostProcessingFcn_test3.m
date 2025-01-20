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
%   pls = load('test3_betaPLS.mat', 'betaPLS', 'y_std', 'y_mean');
%   hSI.hIntegrationRoiManager.postProcessFcn = @(r,id,ai,ivh,ith,ifnh) integrationPostProcessingFcn_test3(r,id,ai,ivh,ith,ifnh, pls.betaPLS, pls.y_std, pls.y_mean);
%
% SET UP PHYSICAL OUTPUTS IN 'INTEGRATION CONTROL'
%   Output function: @(vals,varargin)(vals)>0

function integrationValues = integrationPostProcessingFcn_test3(rois,integrationDone,arrayIndices,integrationValueHistory,integrationTimestampHistory,integrationFrameNumberHistory, betaPLS, y_std, y_mean)
% TEST3:
%   - Compute DFFs on real ROIs (typically 50)
%   - Run PLS prediction
%
% Expected outputs:
%   - RT clk changes state on every processed frame

    N = 900; % Number of frames used for F0 averaging (900 == 30 s @ 30 Hz)

    row_ind = arrayIndices(1);

    F0 = sum(integrationValueHistory(max([row_ind-N 1]):max([row_ind-1 1]), :), 1);
    F0 = F0 / min([N row_ind]);
    F = integrationValueHistory(row_ind,:);
    integrationValues = (F-F0)./F0;

    % Safety
    integrationValues(isnan(integrationValues)) = 0;

    % PLS decoding
    % Columns of 'betaPLS': [wheel-speed, cursor-position, licking]
    %------------------------------------------------------------
    Y_pred_all = [1 integrationValues(1:end-7)] * betaPLS;
    Y_pred_all = Y_pred_all.*y_std + y_mean; % convert it from Z-score to real measured value 
    Y_pred_spd = Y_pred_all(1);
    Y_pred_original = Y_pred_spd;

    % Clamp the speed range, then predict discrete output
    constant = 1;
    Y_pred_spd = max([Y_pred_spd -1024*constant]);
    Y_pred_spd = min([Y_pred_spd  1024*constant]);
    Y_pred_class = round(Y_pred_spd/(512*constant)); % -2 to 2

    class_output = zeros(1,6);
    class_output(Y_pred_class+3) = 1;

    % "Real-time clock"
    class_output(6) = mod(row_ind,2);

    integrationValues(end-6:end-1) = class_output;
    integrationValues(end) = Y_pred_original;
end