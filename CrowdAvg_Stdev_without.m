% This script calculates crowd average and standard deviation without each architecture and its 100 replicates

%% Request input file and inspect for required sheets
[file, path, ~] = uigetfile('*.xlsx', 'Pick an excel file with FM-MV Combined');
inputFile = strcat(path, file);

% Define sheet to read
sheetName = 'Prediction error'; % Change this if your sheet name is different

% Read raw data into a table
rawData = readtable(inputFile, 'Sheet', sheetName);

% Get variable names from the read table
varNamesAll = rawData.Properties.VariableNames; % All variables
varNamesProps = varNamesAll(1:5); % Just properties (architecture attributes)
varNamesData = varNamesAll(6:end); % Product data (prediction errors)

% Initialize arrays for the mean and std deviation
numRows = size(rawData, 1); % Total rows (18900)
numProducts = length(varNamesData); % Number of products (20 in your case)

% Check if we need to clean up any NaNs or non-numeric entries
% We'll make sure the prediction data is numeric and valid
for j = 6:numel(varNamesAll)
    % Check if the data in the current column is numeric
    if ~isnumeric(rawData.(varNamesAll{j}))
        % Convert only non-numeric entries to numeric
        rawData.(varNamesAll{j}) = str2double(rawData.(varNamesAll{j}));
    end
end

% Loop through the data to find unique architectures
uniqueArchitectures = unique(rawData.Architecture); % Assuming "Architecture" is the column for architectures

% Create empty arrays to store results for each architecture
meanWithoutArch = zeros(numRows, numProducts); % Mean without each architecture
stdWithoutArch = zeros(numRows, numProducts);  % Standard deviation without each architecture

% Loop through each unique architecture
for archIdx = 1:length(uniqueArchitectures)
    currentArch = uniqueArchitectures(archIdx);
    
    % Find the rows corresponding to the current architecture's 100 replicates
    archRows = rawData.Architecture == currentArch; % Logical indexing for rows belonging to this architecture
    
    % Loop through each product (from column 6 to the end)
    for j = 1:numProducts
        % Extract all prediction errors for the current product (column j)
        productErrors = table2array(rawData(:, 5 + j)); % Collect product error data for all architectures
        
        % Remove the entire current architecture's 100 replicates from the product errors
        productErrorsWithoutArch = productErrors(~archRows); % Exclude the rows for the current architecture
        
        % Remove NaNs or non-numeric entries, ensure only valid values are used
        productErrorsWithoutArch = productErrorsWithoutArch(~isnan(productErrorsWithoutArch));

        % Calculate the mean and standard deviation without the current architecture's 100 replicates
        archMean = mean(productErrorsWithoutArch); % Mean of remaining data
        archStd = std(productErrorsWithoutArch);   % Std dev of remaining data
        
        % Assign the calculated mean and standard deviation to all 100 replicates of the current architecture
        meanWithoutArch(archRows, j) = archMean;
        stdWithoutArch(archRows, j) = archStd;
    end
end

% Convert results into tables
meanTable = array2table(meanWithoutArch, 'VariableNames', strcat(varNamesData, '_MeanWithoutArch'));
stdTable = array2table(stdWithoutArch, 'VariableNames', strcat(varNamesData, '_StdWithoutArch'));

% Concatenate the original data with new mean and std columns
resultTable = [rawData, meanTable, stdTable];

% Save the result to a new Excel file
outputFile = strcat(path, 'Processed_', file);
writetable(resultTable, outputFile);

disp('Processing complete. Results saved to:');
disp(outputFile);
