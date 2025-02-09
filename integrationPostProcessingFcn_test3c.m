% OPTIMIZE FOR PERFORMANCE
%   - Disable all live visualizations
%   - For main display, set Rolling average factor = 1
%
% SET UP REAL-TIME CALLBACK
%   hSI.hIntegrationRoiManager.integrationHistoryLength = 45000;
%   pls = load('test3_betaPLS.mat', 'betaPLS', 'y_std', 'y_mean');
%   hSI.hIntegrationRoiManager.postProcessFcn = @(r,id,ai,ivh,ith,ifnh) integrationPostProcessingFcn_test3c(r,id,ai,ivh,ith,ifnh, pls.betaPLS, pls.y_std, pls.y_mean);
%
function integrationValues = integrationPostProcessingFcn_test3c(rois,integrationDone,arrayIndices,integrationValueHistory,integrationTimestampHistory,integrationFrameNumberHistory, betaPLS, y_std, y_mean)
% TEST3C:
%   - Compute DFFs on real ROIs (typically 50 cells)
%   - Run PLS prediction
%   - Direct control of vDAQ TTL outputs
%   - Log decoder results via modified IntegrationRoiManager

persistent hDigitalOutputs hIntegrationRoiManager

% One-time setup of persistent variables
%------------------------------------------------------------
if isempty(hDigitalOutputs)
    vDAQ = '/vDAQ0/';
    ports = {'D0.6', 'D0.7', 'D1.4', 'D1.6', 'D1.7', 'D1.5'}; % LL, L, 0, R, RR, RT_clk

    fullnames = strcat(vDAQ, ports);
    hDigitalOutputs = dabs.resources.ResourceStore.filterByNameStatic(fullnames);
end

if isempty(hIntegrationRoiManager)
    hIntegrationRoiManager = dabs.resources.ResourceStore.filterByNameStatic('SI IntegrationRoiManager');
end

% Calculate DF/F values
% TODO: Consider exponential averaging for F0, using persistent variables
%------------------------------------------------------------
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
Y_pred_all = [1 integrationValues] * betaPLS;
Y_pred_all = Y_pred_all.*y_std + y_mean; % convert it from Z-score to real measured value 
Y_pred_spd = Y_pred_all(1);
% Y_pred_original = Y_pred_spd;

% Clamp the speed range, then predict discrete output
constant = 1;
Y_pred_spd = max([Y_pred_spd -1024*constant]);
Y_pred_spd = min([Y_pred_spd  1024*constant]);
Y_pred_class = round(Y_pred_spd/(512*constant)); % -2 to 2

class_output = zeros(1, 6);
class_output(Y_pred_class+3) = 1;
class_output(6) = mod(row_ind,2); % RT clock

hIntegrationRoiManager.decoder_values = class_output; % Record values into CSV file

% Send values to TTLs
for i = 1:6
    hDigitalOutputs{i}.setValue(class_output(i));
end

