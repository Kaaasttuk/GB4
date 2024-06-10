% Clear any existing Arduino object
clear a;

% Define the threshold value
Threshold = 0.6;

% Create an Arduino object
a = arduino('COM3', 'Uno'); % Change 'COM3' to your Arduino's serial port

% MQ3 pin
MQ3pin = 'A0';

disp('MQ3 warming up!');
pause(1); % Allow the MQ3 to warm up for 1 second

% Define the duration of the data acquisition in seconds
totalDuration = 120; % Duration in seconds

% Initialize variables for plotting and decoding
voltageData = [];
timeData = [];
derivativeData = [];
decodedSignal = [];
currentIntervalStart = 0;
intervalDuration = 3; % 5-second interval
signalDecoded = false;

% Set up the plot
figure;
subplot(2, 1, 1);
h1 = plot(NaN, NaN);
ylim([0 5]); % Assuming the voltage range is 0 to 5V
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
    
    % Check if the first derivative exceeds 1 within the current interval
    if currentTime >= currentIntervalStart + intervalDuration
        if ~signalDecoded
            decodedSignal = [decodedSignal, 0]; % Decoded as 0
            fprintf('0\n');
        end
        currentIntervalStart = currentTime;
        signalDecoded = false;
    end
    
    if derivativeData(end) > Threshold
        if ~signalDecoded
            decodedSignal = [decodedSignal, 1]; % Decoded as 1
            fprintf('1\n');
            signalDecoded = true;
            currentIntervalStart = currentTime; % Skip to the next interval
        end
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
