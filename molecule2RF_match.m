% Ensure Arduino is bound to a with a=arduino
% Clear any existing Arduino object
clear a;

% Create an Arduino object
a = arduino('COM3', 'Uno'); % Change 'COM3' to your Arduino's serial port

% Define the MQ3 pin and drone control pin
MQ3pin = 'A0'; % MQ3 pin of gas sensor
dronePin = 'D10'; % Pin connected to the drone controller
droneState = 0; % 0 is down, 1 is up

% Initialize variables for decoding
intervalDuration = 2; % Time window of each bit
derivativeThreshold = 0.5;

% Define the template signal for the matched filter
templateSignal = [0 0 0.1 0.5 0.7 1.0 0.7 0.5 0.1 0 0]; % Example template based on the described shape

% The detection algorithm will wait for a 1 signal
% It will then detect the next symbol
% If it is a 0, the drone will go up
% If it is a 1, the drone will go down
% It will then wait for the next 1 signal.

while true
    startTime = tic;

    % Wait here until the derivative is above the derivative threshold
    fprintf('Waiting for 1 signal...\n');
    ready = false;
    previousVoltage = readVoltage(a, MQ3pin);
    previousTime = toc(startTime);
    voltageData = [];
    derivativeData = [];
    
    while ~ready
        voltage = readVoltage(a, MQ3pin);
        currentTime = toc(startTime);
        voltageData = [voltageData, voltage];
        
        % Calculate the first derivative
        if length(voltageData) > 1
            derivative = (voltageData(end) - voltageData(end-1)) / (currentTime - previousTime);
            derivativeData = [derivativeData, derivative];
            
            % Apply the matched filter
            if length(derivativeData) >= length(templateSignal)
                % Convolve the derivative data with the template signal
                matchedOutput = conv(derivativeData, templateSignal, 'same');
                filteredDerivativeData = matchedOutput(end-length(derivativeData)+1:end);
                
                % Check if the filtered derivative exceeds the threshold
                if filteredDerivativeData(end) > derivativeThreshold
                    fprintf('1 signal detected with derivative %f\n', filteredDerivativeData(end));
                    ready = true;
                end
            end
        end
        
        previousVoltage = voltage;
        previousTime = currentTime;
        pause(0.01);
    end
    
    % At this point we are still in the 1 symbol so need to wait for the next symbol
    pause(intervalDuration/2); % /2 so that the next symbol happens in the middle

    startTime = tic;
    bit = 0;
    voltageData = [];
    derivativeData = [];
    previousVoltage = readVoltage(a, MQ3pin);
    previousTime = toc(startTime);
    
    while toc(startTime) < intervalDuration
        voltage = readVoltage(a, MQ3pin);
        currentTime = toc(startTime);
        voltageData = [voltageData, voltage];
        
        % Calculate the first derivative
        if length(voltageData) > 1
            derivative = (voltageData(end) - voltageData(end-1)) / (currentTime - previousTime);
            derivativeData = [derivativeData, derivative];
            
            % Apply the matched filter
            if length(derivativeData) >= length(templateSignal)
                % Convolve the derivative data with the template signal
                matchedOutput = conv(derivativeData, templateSignal, 'same');
                filteredDerivativeData = matchedOutput(end-length(derivativeData)+1:end);
                
                % Check if the filtered derivative exceeds the threshold
                if filteredDerivativeData(end) > derivativeThreshold
                    bit = 1;
                end
            end
        end
        
        previousVoltage = voltage;
        previousTime = currentTime;
        pause(0.01);
    end

    % Display the decoded signal
    fprintf('Received bit: %d.', bit);
    if bit == 0 && droneState == 0
        fprintf(' Going up\n');
        controlDrone(a, "up");
        droneState = 1;
    elseif bit == 1 && droneState == 1 
        fprintf(' Going down\n');
        controlDrone(a, "down");
        droneState = 0;
    else
        fprintf('Stay where you are\n')
    end
end
