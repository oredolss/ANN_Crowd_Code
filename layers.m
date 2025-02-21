% Request input file and check the required files
[file, path, ~] = uigetfile('*.xlsx', 'Pick an excel file with LAYERS ANALYSIS'); 
inputFile = strcat(path, file);

% Define the sheet to read
sheetName = 'LAYERS(FM-MV)'; 

% Read raw data into a table
rawData = readtable(inputFile, 'Sheet', sheetName);

% Display variable names to confirm they are correct
disp('Variable names in the table:');
disp(rawData.Properties.VariableNames);

% Define columns for Layer, Product, Normality, Centrality, and Width
layerCol = 'Layers';
productCol = 'Product';
normalityCol = 'Normality';
centralityCol = 'Centrality';
widthCol = 'Width';

% Initialize structure to store results for each layer and product combination
layerProductResults = struct();

% Get unique layers and products
uniqueLayers = unique(rawData.(layerCol)); 
uniqueProducts = unique(rawData.(productCol));

% Loop through each layer
for i = 1:length(uniqueLayers)
    % Filter data for the current layer
    layerData = rawData(rawData.(layerCol) == uniqueLayers(i), :);
    
    % Initialize an array to hold product results for each layer
    layerProductResults(i).Layer = uniqueLayers(i);
    layerProductResults(i).Products = struct();
    
    % Loop through each product within the current layer
    for j = 1:length(uniqueProducts)
        % Filter data for the current product within this layer
        productData = layerData(strcmp(layerData.(productCol), uniqueProducts{j}), :);
        
        if isempty(productData)
            continue; % Skip if there is no data for this product in this layer
        end
        
        % Get unique combinations of Normality, Centrality, and Width in this product within this layer
        uniqueBehaviors = unique(productData(:, {normalityCol, centralityCol, widthCol}), 'rows');
        
        % Initialize counters for each behavior
        behaviorCounts = zeros(height(uniqueBehaviors), 1);
        
        % Count occurrences of each behavior combination
        for k = 1:height(uniqueBehaviors)
            % Count rows matching each unique behavior combination
            behaviorCounts(k) = sum(ismember(productData(:, {normalityCol, centralityCol, widthCol}), uniqueBehaviors(k, :), 'rows'));
        end
        
        % Calculate total count and percentage for each behavior in the product within this layer
        totalBehaviors = sum(behaviorCounts);
        behaviorPercentages = (behaviorCounts / totalBehaviors) * 100;
        
        % Store results in the structure
        layerProductResults(i).Products(j).Product = uniqueProducts{j};
        layerProductResults(i).Products(j).Behaviors = uniqueBehaviors;
        layerProductResults(i).Products(j).Counts = behaviorCounts;
        layerProductResults(i).Products(j).Percentages = behaviorPercentages;
    end
end

% Initialize cell array to store results for table output
tableData = {};

% Loop through each layer and product to gather data for the table
for i = 1:length(layerProductResults)
    for j = 1:length(layerProductResults(i).Products)
        if isempty(layerProductResults(i).Products(j).Product)
            continue; % Skip if no product data
        end
        % Get behaviors, counts, and percentages for each product in the current layer
        for k = 1:height(layerProductResults(i).Products(j).Behaviors)
            % Create behavior name by joining normality, centrality, and width values
            behaviorName = strjoin(table2cell(layerProductResults(i).Products(j).Behaviors(k, :)), ' ');
            
            % Append data to tableData cell array
            tableData = [tableData; {layerProductResults(i).Layer, ...
                                     layerProductResults(i).Products(j).Product, ...
                                     behaviorName, ...
                                     layerProductResults(i).Products(j).Counts(k), ...
                                     layerProductResults(i).Products(j).Percentages(k)}];
        end
    end
end


