% Load the Excel file
filename = "C:\Users\kastu\Downloads\round_data_clean.xlsx";

% Get sheet names
[~, sheetNames] = xlsfinfo(filename);

% Known value of d
d = 0.15;

% Define the models as anonymous functions with offset term e outside the exp()
M1 = @(a, b, c, e, t) (a ./ sqrt(t)) .* exp(-b * ((d - c*t).^2) ./ t) + e;
M2 = @(a, b, c, e, t) (a ./ t.^(3/2)) .* exp(-b * ((c*t - d).^2) ./ t) + e;

% Define the fit options with starting points and bounds
opts1 = fitoptions('Method', 'NonlinearLeastSquares', ...
                   'StartPoint', [1, 1, 1, 0], ...
                   'Lower', [0, 0, 0, 0], ...
                   'Upper', [Inf, Inf, Inf, 0.8]);

opts2 = fitoptions('Method', 'NonlinearLeastSquares', ...
                   'StartPoint', [1, 1, 1, 0], ...
                   'Lower', [0, 0, 0, 0], ...
                   'Upper', [Inf, Inf, Inf, 0.8], ...
                   'MaxIter', 1000, ...
                   'TolFun', 1e-8);

% Define the fit types using 'fittype' and the fit options
ft1 = fittype('a / sqrt(t) * exp(-b * (d - c*t)^2 / t) + e', ...
              'independent', 't', 'coefficients', {'a', 'b', 'c', 'e'}, 'problem', 'd', 'options', opts1);
ft2 = fittype('a / t^(3/2) * exp(-b * (c*t - d)^2 / t) + e', ...
              'independent', 't', 'coefficients', {'a', 'b', 'c', 'e'}, 'problem', 'd', 'options', opts2);

% Loop through each sheet and fit the models
for i = 1:length(sheetNames)
    % Read the data from the sheet
    data = readtable(filename, 'Sheet', sheetNames{i});
    timeData = data.Time;
    voltageData = data.Voltage;  % Subtract 0.5 from all voltage data points

    % Specify the time interval for fitting
    startTimeFit = 2.2; % Start time for fitting (seconds)
    endTimeFit = 10;  % End time for fitting (seconds)

    % Extract the subset of data within the specified time interval
    fitIdx = (timeData >= startTimeFit) & (timeData <= endTimeFit);
    fitTimeData = timeData(fitIdx);
    fitVoltageData = voltageData(fitIdx);

    % Shift the time data so that t = 2 becomes t = 0
    fitTimeDataShifted = fitTimeData - startTimeFit;

    % Fit the models to the subset of the data
    [fitResult1, gof1] = fit(fitTimeDataShifted, fitVoltageData, ft1, 'problem', d);
    [fitResult2, gof2] = fit(fitTimeDataShifted, fitVoltageData, ft2, 'problem', d);

    % Display the fit coefficients
    coefficients1 = coeffvalues(fitResult1);
    coefficients2 = coeffvalues(fitResult2);
    disp(['Fit Coefficients for Model 1 - ' sheetNames{i} ':']);
    disp(coefficients1);
    disp(['Fit Coefficients for Model 2 - ' sheetNames{i} ':']);
    disp(coefficients2);

    % Evaluate the fits
    fitVoltageData1 = feval(fitResult1, fitTimeDataShifted);
    fitVoltageData2 = feval(fitResult2, fitTimeDataShifted);

    % Plot the data and the fitted curves
    figure;
    hold on;
    plot(timeData - startTimeFit, voltageData, 'b.', 'MarkerSize', 10); % Data (shifted)
    plot(fitTimeDataShifted, fitVoltageData, 'ko', 'MarkerSize', 5); % Subset data used for fitting (shifted)
    plot(fitTimeDataShifted, fitVoltageData1, 'g-', 'LineWidth', 1.5); % Fit for Model 1 (green)
    plot(fitTimeDataShifted, fitVoltageData2, 'r-', 'LineWidth', 1.5); % Fit for Model 2 (red)
    xlabel('Time (s)');
    ylabel('Voltage (V)');
    title(['Sensor Voltage vs. Time with Model Fits - ' sheetNames{i}]);
    legend('Data', 'Subset Data for Fit', 'Model 1 Fit', 'Model 2 Fit');
    hold off;

    % Display goodness of fit metrics
    disp(['Goodness of fit for M1 - ' sheetNames{i} ':']);
    disp(gof1);
    disp(['Goodness of fit for M2 - ' sheetNames{i} ':']);
    disp(gof2);
end
