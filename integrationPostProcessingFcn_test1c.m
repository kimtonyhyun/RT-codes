% OPTIMIZE FOR PERFORMANCE
%   - Disable all live visualizations
%   - For main display, set Rolling average factor = 1
%
% SET UP REAL-TIME CALLBACK
%   hSI.hIntegrationRoiManager.integrationHistoryLength = 15000;
%   hSI.hIntegrationRoiManager.postProcessFcn = @integrationPostProcessingFcn_test1c;
%
function integrationValues = integrationPostProcessingFcn_test1c(rois,integrationDone,arrayIndices,integrationValueHistory,integrationTimestampHistory,integrationFrameNumberHistory)
% TEST1B:
%   - RT clk changes state on every processed frame
%   - Cycle through the 5 output classes on every processed frame
%   - Direct control of vDAQ TTL outputs

persistent hDigitalOutputs hIntegrationRoiManager

% One-time setup of digital decoder outputs
if isempty(hDigitalOutputs)
    vDAQ = '/vDAQ0/';
    % Port mappings: {LL, L, 0, R, RR, RT_clk}
    ports = {'D0.6', 'D0.7', 'D1.4', 'D1.6', 'D1.7', 'D1.5'};

    fullnames = strcat(vDAQ, ports);
    hDigitalOutputs = dabs.resources.ResourceStore.filterByNameStatic(fullnames);
end

if isempty(hIntegrationRoiManager)
    hIntegrationRoiManager = dabs.resources.ResourceStore.filterByNameStatic('SI IntegrationRoiManager');
end

row_ind = arrayIndices(1);

% Predict different classes in sequence
frame_number = integrationFrameNumberHistory(row_ind);
class_number = mod(frame_number, 5);
if class_number == 0
    class_number = 5;
end

decoder_values = zeros(1, 6);
decoder_values(class_number) = 1;
decoder_values(6) = mod(row_ind,2); % RT clock
hIntegrationRoiManager.decoder_values = decoder_values; % Record values into CSV file

for i = 1:6
    hDigitalOutputs{i}.setValue(decoder_values(i));
end

integrationValues = integrationValueHistory(row_ind,:); % Passthrough
