% This code detects commands ["UP" OR "DOWN"] using streaming audio from microphone.

load('commandNet.mat'); % Loads the pretrained network
fs = 16e3;
classificationRate = 20;
adr = audioDeviceReader('SampleRate', fs, 'SamplesPerFrame', floor(fs / classificationRate));

audioBuffer = dsp.AsyncBuffer(fs);

labels = trainedNet.Layers(end).Classes;
YBuffer(1:classificationRate/2) = categorical("background");

probBuffer = zeros([numel(labels), classificationRate / 2]);

countThreshold = ceil(classificationRate * 0.2);
probThreshold = 0.7;
signalInterval = 2.0;

h = figure('Units', 'normalized', 'Position', [0.2 0.1 0.6 0.8]);

timeLimit = inf; % You may change the time limit

tic
cooldownStart = -signalInterval; % Initialize to start accepting commands immediately

while ishandle(h) && toc < timeLimit

    % Extract audio samples from the audio device and add the samples to the buffer.
    x = adr();
    write(audioBuffer, x);
    y = read(audioBuffer, fs, fs - adr.SamplesPerFrame);

    spec = helperExtractAuditoryFeatures(y, fs);
    
    % Classify the current spectrogram, save the label to the label buffer,
    % and save the predicted probabilities to the probability buffer.
    [YPredicted, probs] = classify(trainedNet, spec, 'ExecutionEnvironment', 'cpu');
    YBuffer = [YBuffer(2:end), YPredicted];
    probBuffer = [probBuffer(:,2:end), probs(:)];

    % Plot the current waveform and spectrogram.
    subplot(2, 1, 1)
    plot(y)
    axis tight
    ylim([-1, 1])

    subplot(2, 1, 2)
    pcolor(spec')
    caxis([-4 2.6445])
    shading flat

    % Perform command detection
    [YMode, count] = mode(YBuffer);
    maxProb = max(probBuffer(labels == YMode, :));
    
    subplot(2, 1, 1)

    if toc - cooldownStart < signalInterval
        title('Processing... Please wait', 'FontSize', 20)
    else
        title('Speak Now', 'FontSize', 20)
        if YMode ~= "background" && count >= countThreshold && maxProb >= probThreshold
            title(string(YMode), 'FontSize', 20)
            if YMode == "up"
                fprintf('1\n');
                controlSprayer(a, 0.001);
                cooldownStart = toc;
            elseif YMode == "down"
                fprintf('0\n');
                cooldownStart = toc;
            end
            
        end
    end

    drawnow
end
