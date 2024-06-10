% Ensure arduino is bound to a with a=arduino
% Clear any existing Arduino object
clear a;

% Create an Arduino object
a = arduino('COM3', 'Uno'); % Change 'COM3' to your Arduino's serial port

MQ3pin = 'A0'; % MQ3 pin of gas sensor
dronePin = 'D10'; % pin connected to the drone controller

% Initialize variables for decoding
intervalDuration = 3; % time window of each bit
derivativeThreshold = 0.5;

% The detection algorithm will wait for a 1 signal
% It will then detect the next symbol
% If it is a 0, the drone will go up
% If it is a 1, the drone will go down
% It will then wait for the next 1 signal.

while true
    startTime = tic;

    % wait here until the derivative is above derivative threshold
    fprintf('Waiting for 1 signal...');
    ready = false;
    previousVoltage = readVoltage(a, MQ3pin);
    previousTime = toc(startTime);
    while ~ready
        voltage = readVoltage(a, MQ3pin);
        currentTime = toc(startTime);
        derivative = (voltage - previousVoltage) / (currentTime - previousTime);

        % Check if the derivative exceeds the threshold
        if derivative > derivativeThreshold
            fprintf('1 signal detected at %d derivative\n', derivative);
            ready = true;
        end

        previousVoltage = voltage;
        previousTime = currentTime;
        pause(0.01);
    end
    % at this point we are still in the 1 symbol so need to wait for the next symbol
    pause(intervalDuration/2); % /2 so that the next symbol happens in the middle

    startTime = tic;
    bit = 0;
    previousVoltage = readVoltage(a, MQ3pin);
    previousTime = toc(startTime);
    while toc(startTime) < intervalDuration
        voltage = readVoltage(a, MQ3pin);
        currentTime = toc(startTime);
        derivative = (voltage - previousVoltage) / (currentTime - previousTime);

        % Check if the derivative exceeds the threshold
        if derivative > derivativeThreshold
            bit = 1;
        end

        previousVoltage = voltage;
        previousTime = currentTime;
        pause(0.01);
    end

    % Display the decoded signal
    fprintf('Received bit: %d.', bit);
    if bit == 0
        fprintf(' Going up\n');
        %controlDrone(a, "up");
    else
        fprintf(' Going down\n');
        %controlDrone(a, "down");
    end

end