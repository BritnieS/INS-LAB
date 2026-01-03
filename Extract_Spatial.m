%% SPATIAL FEATURE EXTRACTION (Fixed & Ready)
clc; clear; close all;

% 1. Setup
subjects = {'P1', 'P2', 'P3'};
gestures = {'stone.otb+.mat', 'paper.otb+.mat', 'scissors.otb+.mat', ...
            'pointing.otb+.mat', 'rockmetal.otb+.mat'}; 
fs = 2048; 
data_table = table();

% Feature Thresholds
ZC_thresh = 0.005; 
SSC_thresh = 0.005;

%% 2. Main Loop
for s = 1:length(subjects)
    subj = subjects{s};
    base_path = fullfile(pwd, subj);
    
    if ~isfolder(base_path), continue; end
    fprintf('Processing %s (Spatial Mode)...\n', subj);
    
    % --- Determine Activity Threshold ---
    rest_file = fullfile(base_path, 'rest.otb+.mat');
    threshold = 0.02; 
    if isfile(rest_file)
        % --- FIX IS HERE: Only ask for one output ---
        sig_full = load_and_filter(rest_file, fs); 
        
        % Average all channels just to find the start/stop time
        avg_sig = mean(abs(sig_full), 2);
        
        % Robust Threshold Calculation
        median_val = median(avg_sig);
        mad_val = median(abs(avg_sig - median_val));
        threshold = max(median_val + 5*mad_val, 0.02);
    end
    
    % --- Loop Gestures ---
    for g = 1:length(gestures)
        filename = gestures{g};
        clean_name = strrep(filename, '.otb+.mat', ''); 
        filepath = fullfile(base_path, filename);
        
        if isfile(filepath)
            % 1. Load 64-Channel Data
            sig_matrix = load_and_filter(filepath, fs); % Returns [Samples x 64]
            
            % 2. Create a "Detection Signal" (Average of all to find the burst)
            detection_sig = mean(abs(sig_matrix), 2);
            env = movmean(detection_sig, round(0.15 * fs));
            is_active = env > threshold;
            [labeled_signal, num_blobs] = bwlabel(is_active);
            
            valid_count = 0; 
            for k = 1:num_blobs
                idx = find(labeled_signal == k);
                if length(idx) < (0.5 * fs), continue; end 
                
                % Slice the time segment for ALL 64 channels
                segment_matrix = sig_matrix(idx, :); 
                
                % --- THE SPATIAL FIX: Process 4 Zones ---
                % We assume channels are ordered. We split 64 into 4 chunks of 16.
                
                features_row = {subj, clean_name, valid_count + 1};
                
                % Loop through 4 Zones
                for zone = 1:4
                    % Define start and end channel for this zone
                    ch_start = (zone - 1) * 16 + 1;
                    ch_end = zone * 16;
                    
                    % Extract only these 16 channels and average them into 1 "Zone Signal"
                    zone_sig = mean(segment_matrix(:, ch_start:ch_end), 2);
                    
                    % --- Extract Features for this Zone ---
                    f_mav = mean(abs(zone_sig));
                    f_rms = rms(zone_sig);
                    f_wl  = sum(abs(diff(zone_sig)));
                    
                    % Zero Crossing (Vectorized)
                    x1 = zone_sig(1:end-1); x2 = zone_sig(2:end);
                    diff_s = abs(x1 - x2);
                    f_zc = sum((x1.*x2 < 0) & (diff_s > ZC_thresh));
                    
                    % Slope Sign Change
                    mid = zone_sig(2:end-1); left = zone_sig(1:end-2); right = zone_sig(3:end);
                    f_ssc = sum(((mid > left & mid > right) | (mid < left & mid < right)) & ...
                                (abs(mid - left) > SSC_thresh | abs(mid - right) > SSC_thresh));
                    
                    % Add to row
                    features_row = [features_row, {f_mav, f_rms, f_wl, f_zc, f_ssc}];
                end
                
                valid_count = valid_count + 1;
                data_table = [data_table; features_row];
            end
            fprintf('  -> %s: Found %d valid repetitions\n', clean_name, valid_count);
        end
    end
end

%% 3. Save
% Naming columns for 4 zones
var_names = {'Subject', 'Gesture', 'RepetitionID'};
for z = 1:4
    prefix = sprintf('Z%d_', z);
    var_names = [var_names, {[prefix 'MAV'], [prefix 'RMS'], [prefix 'WL'], [prefix 'ZC'], [prefix 'SSC']}];
end

data_table.Properties.VariableNames = var_names;
writetable(data_table, 'EMG_Spatial.xlsx');
fprintf('\nSUCCESS! Saved to "EMG_Spatial.xlsx".\n');

%% --- HELPER FUNCTIONS ---
function sig = load_and_filter(path, fs)
    d = load(path);
    vars = fieldnames(d);
    raw = d.(vars{1});
    
    % Ensure dimensions are [Samples x Channels]
    if size(raw,1) < size(raw,2) 
        raw = raw'; 
    end
    
    % Filters (Applied to all columns automatically)
    nyq = fs/2;
    [b,a] = butter(4, [20 450]/nyq, 'bandpass');
    sig = filtfilt(b,a, raw);
    
    wo = 50/nyq; bw = wo/30;
    [bn,an] = iirnotch(wo, bw);
    sig = filtfilt(bn,an, sig);
end