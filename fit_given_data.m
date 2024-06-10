% Load the Excel file
filename = "C:\Users\kastu\Downloads\round_data_clean.xlsx";

% Get sheet names
[~, sheetNames] = xlsfinfo(filename);

% Initialize arrays to store the voltage and time data
allVoltageData = [];
allTimeData = [];

% Loop through each sheet and extract the voltage data
for i = 1:length(sheetNames)
    data = readtable(filename, 'Sheet', sheetNames{i});
    allTimeData = [allTimeData; data.Time'];
    allVoltageData = [allVoltageData; data.Voltage'];
end

% Average the data across all rounds
avgVoltageData = mean(allVoltageData, 1);
avgTimeData = mean(allTimeData, 1);

% Trim the averaged data to remove trailing zeros
validIdx = find(avgTimeData > 0);
avgTimeData = avgTimeData(validIdx);
avgVoltageData = avgVoltageData(validIdx);

% Ensure timeData and voltageData are column vectors
avgTimeData = avgTimeData(:);
avgVoltageData = avgVoltageData(:);

% Specify the time interval for fitting
startTimeFit = 2.19; % Start time for fitting (seconds)
endTimeFit = 20;  % End time for fitting (seconds)

% Extract the subset of data within the specified time interval
fitIdx = (avgTimeData >= startTimeFit) & (avgTimeData <= endTimeFit);
fitTimeData = avgTimeData(fitIdx);
fitVoltageData = avgVoltageData(fitIdx);

% Shift the time data so that t = 2 becomes t = 0
fitTimeDataShifted = fitTimeData - startTimeFit;
avgTimeDataShifted = avgTimeData - startTimeFit;

% Known value of d
d = 0.15;

% Define the models as anonymous functions with offset term e outside the exp()
M1 = @(a, b, c, e, t) (a ./ sqrt(t)) .* exp(-b * ((d - c*t).^2) ./ t) + e;
M2 = @(a, b, c, e, t) (a ./ t.^(3/2)) .* exp(-b * ((c*t - d).^2) ./ t) + e;

% Define the fit options with starting points and bounds
opts1 = fitoptions('Method', 'NonlinearLeastSquares', ...
                   'StartPoint', [1, 1, 1, 0.3], ...
                   'Lower', [0, 0, 0, 0], ...
                   'Upper', [Inf, Inf, Inf, 0.8]);

opts2 = fitoptions('Method', 'NonlinearLeastSquares', ...
                   'StartPoint', [1, 1, 1, 0.3], ...
                   'Lower', [0, 0, 0, 0], ...
                   'Upper', [Inf, Inf, Inf, 0.8], ...
                   'MaxIter', 1000, ...
                   'TolFun', 1e-8);

% Define the fit types using 'fittype' and the fit options
ft1 = fittype('a / sqrt(t) * exp(-b * (d - c*t)^2 / t) + e', ...
              'independent', 't', 'coefficients', {'a', 'b', 'c', 'e'}, 'problem', 'd', 'options', opts1);
ft2 = fittype('a / t^(3/2) * exp(-b * (c*t - d)^2 / t) + e', ...
              'independent', 't', 'coefficients', {'a', 'b', 'c', 'e'}, 'problem', 'd', 'options', opts2);

% Fit the models to the subset of the data
[fitResult1, gof1] = fit(fitTimeDataShifted, fitVoltageData, ft1, 'problem', d);
[fitResult2, gof2] = fit(fitTimeDataShifted, fitVoltageData, ft2, 'problem', d);

% Display the fit coefficients
coefficients1 = coeffvalues(fitResult1);
coefficients2 = coeffvalues(fitResult2);
disp('Fit Coefficients for Model 1:');
disp(coefficients1);
disp('Fit Coefficients for Model 2:');
disp(coefficients2);

% Evaluate the fits
fitVoltageData1 = feval(fitResult1, fitTimeDataShifted);
fitVoltageData2 = feval(fitResult2, fitTimeDataShifted);

% Plot the averaged data, the subset used for fitting, and the fitted curves
figure;
hold on;
plot(avgTimeDataShifted, avgVoltageData, 'b.', 'MarkerSize', 10); % Averaged data (shifted)
plot(fitTimeDataShifted, fitVoltageData, 'ko', 'MarkerSize', 5); % Subset data used for fitting (shifted)
plot(fitTimeDataShifted, fitVoltageData1, 'g-', 'LineWidth', 2); % Fit for Model 1 (green)
plot(fitTimeDataShifted, fitVoltageData2, 'r-', 'LineWidth', 1.5); % Fit for Model 2 (red)
xlabel('Time (s)', 'FontSize', 65);
ylabel('Voltage (V)', 'FontSize', 65);
%title('Averaged Sensor Voltage vs. Time with Model Fits', 'FontSize', 26);
legend('Averaged Data', 'Subset Data for Fit', 'Model 1 Fit', 'Model 2 Fit', 'FontSize', 30);
set(gca, 'FontSize', 22); % Set font size for the axes
hold off;

% Display goodness of fit metrics
disp('Goodness of fit for M1:');
disp(gof1);
disp('Goodness of fit for M2:');
disp(gof2);
