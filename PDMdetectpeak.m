% Clear any existing Arduino object
clear a;

% Define the threshold value
Threshold = 1;
totalDuration = 140;

% Create an Arduino object
a = arduino('COM3', 'Uno'); % Change 'COM3' to your Arduino's serial port

% MQ3 pin
MQ3pin = 'A0';

disp('MQ3 warming up!');
pause(1); % Allow the MQ3 to warm up for 1 second



% Initialize variables for plotting and decoding
voltageData = [];
timeData = [];
derivativeData = [];
decodedSignal = [];
symbolDecoded = false;
currentIntervalStart = 0;
symbolInterval = 15; % 15-second interval
firstSymbolDetected = false;

% Set up the plot
figure;
subplot(2, 1, 1);
h1 = plot(NaN, NaN);
ylim([0 3]); % Assuming the voltage range is 0 to 5V
xlim([0 totalDuration]);
xlabel('Time (s)');
ylabel('Voltage (V)');
title('Sensor Voltage');

subplot(2, 1, 2);
h2 = plot(NaN, NaN);
ylim([-5 5]); % Adjust as needed based on expected derivative range
xlim([0 totalDuration]);
xlabel('Time (s)');
ylabel('dV/dt (V/s)');
title('First Derivative of Voltage');

startTime = tic;

while toc(startTime) < totalDuration
    % Read the sensor value from analog pin A0
    voltage = readVoltage(a, MQ3pin);
    
    % Update the voltage data and time data
    currentTime = toc(startTime);
    voltageData = [voltageData, voltage];
    timeData = [timeData, currentTime];
    
    % Calculate the first derivative if we have enough data points
    if length(voltageData) > 1
        derivativeData = [derivativeData, (voltageData(end) - voltageData(end-1)) / (timeData(end) - timeData(end-1))];
    else
        derivativeData = [derivativeData, 0]; % First point derivative is zero
    end
    
    % Start the first interval based on the first time the derivative exceeds 1
    if ~firstSymbolDetected && derivativeData(end) > 1
        firstSymbolDetected = true;
        currentIntervalStart = currentTime;
        fprintf('First symbol detected at %.2f seconds\n', currentTime);
    end
    
    % Check if the current interval has ended
    if firstSymbolDetected && currentTime >= currentIntervalStart + symbolInterval
        % Find the peak value within the current interval
        intervalIndices = timeData >= currentIntervalStart & timeData < currentIntervalStart + symbolInterval;
        intervalPeak = max(voltageData(intervalIndices));
        
        % Decode the symbol based on the peak value
        if intervalPeak > Threshold
            decodedSignal = [decodedSignal, 1]; % Decoded as 1
            fprintf('1\n');
        else
            decodedSignal = [decodedSignal, 0]; % Decoded as 0
            fprintf('0\n');
        end
        
        % Update for the next interval
        currentIntervalStart = currentIntervalStart + symbolInterval;
        symbolDecoded = false;
    end
    
    % Update the plots
    set(h1, 'XData', timeData, 'YData', voltageData);
    set(h2, 'XData', timeData, 'YData', derivativeData);
    drawnow;
    
    % Wait a short time before the next reading
    pause(0.01); % Adjust the pause duration as needed
end

% Clear the Arduino object
clear a;

% Display the decoded signal
disp('Decoded Signal:');
disp(decodedSignal);


