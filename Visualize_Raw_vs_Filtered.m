%% VISUALIZE RAW VS FILTERED SIGNALS
clc; clear; close all;

% --- CONFIGURATION ---
subject = 'P1'; % Change to 'P2' or 'P3' if you want
fs = 2048;      % Sampling Rate

% List of files to check
gestures = {'stone.otb+.mat', ...
            'paper.otb+.mat', ...
            'scissors.otb+.mat', ...
            'pointing.otb+.mat', ...
            'Rock metal.otb+.mat'}; 

base_path = fullfile(pwd, subject);

if ~isfolder(base_path)
    error('Folder %s not found. Make sure you are in the "share" folder.', subject);
end

%% MAIN LOOP
for i = 1:length(gestures)
    filename = gestures{i};
    filepath = fullfile(base_path, filename);
    
    if isfile(filepath)
        % 1. Load the Raw Data (No Filters!)
        raw_signal = load_raw_data(filepath);
        
        % 2. Create the Filtered Data (Apply your recipe)
        filtered_signal = apply_filters(raw_signal, fs);
        
        % 3. Plot Comparison
        f = figure('Name', ['Comparison: ', filename], 'Color', 'w');
        f.Position = [100, 100, 1200, 600]; % Wide window
        
        t = (0:length(raw_signal)-1) / fs; % Time axis
        
        % --- TOP PLOT: RAW ---
        subplot(2,1,1);
        plot(t, raw_signal, 'Color', [0.5 0.5 0.5]); % Grey
        title(['RAW Signal (No Filters): ', filename], 'Interpreter', 'none');
        ylabel('Amplitude (mV)');
        grid on;
        % Force the Y-axis to center on the signal mean so we can see it
        ylim([mean(raw_signal)-0.5, mean(raw_signal)+0.5]); 
        
        % --- BOTTOM PLOT: FILTERED ---
        subplot(2,1,2);
        plot(t, filtered_signal, 'Color', 'b'); % Blue
        title('FILTERED (Bandpass 20-450Hz + Notch 50Hz)');
        ylabel('Amplitude (mV)');
        xlabel('Time (s)');
        grid on;
        ylim([-0.5, 0.5]); % Fixed scale for clean comparison
        
        % Link axes so zooming one zooms the other
        linkaxes(get(f, 'Children'), 'x');
        
    else
        fprintf('File missing: %s\n', filename);
    end
end
disp('Done! Check the pop-up windows.');

%% --- HELPER FUNCTIONS ---

function raw = load_raw_data(path)
    % loads and averages channels. 
    d = load(path);
    vars = fieldnames(d);
    data = d.(vars{1});
    
    if size(data,1) > size(data,2)
        raw = mean(data, 2); 
    else
        raw = mean(data, 1)'; 
    end
end

function clean = apply_filters(sig, fs)
    nyq = fs/2;
    
    % 1. Bandpass Filter (20-450Hz)
    [b,a] = butter(4, [20 450]/nyq, 'bandpass');
    clean = filtfilt(b,a, sig);
    
    % 2. Notch Filter (50Hz) - with correct math
    wo = 50 / nyq;
    bw = wo / 30; 
    [bn,an] = iirnotch(wo, bw);
    clean = filtfilt(bn,an, clean);
end