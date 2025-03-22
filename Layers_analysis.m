
% Layer Analysis Script for ANN Crowd Diversity and Performance

% Step 1: Load Data
[file, path] = uigetfile('*.xlsx', 'Pick an excel file with Analysis (Onedrive)');
inputFile = fullfile(path, file);
sheetName = 'AM-MV'; % Adjust if needed (e.g., FM-MP)
rawData = readtable(inputFile, 'Sheet', sheetName);
disp('Variable names in the table:');
disp(rawData.Properties.VariableNames);

% Step 2: Clean and Rename Columns
data = rawData;
data.Properties.VariableNames = {'Arch_Name', 'Layers', 'Nodes', 'Sequence', 'Product', ...
    'Normality', 'Centrality', 'Width', 'Normality_Label', 'Centrality_Label', 'Width_Label', ...
    'Avg_With', 'Avg_Without', 'Avg_Diff_Percent', 'Stdev_With', 'Stdev_Without', 'Stdev_Diff_Percent'};

% Clean Behavior Labels (e.g., 'High'/'Good'/'Same' → 'High/Good/Same')
data.Normality_Label = regexprep(strrep(data.Normality_Label, '''', ''), '[,\s]+$', '');
data.Centrality_Label = regexprep(strrep(data.Centrality_Label, '''', ''), '[,\s]+$', '');
data.Width_Label = regexprep(strrep(data.Width_Label, '''', ''), '[,\s]+$', '');
% Replace missing Sequence with 'Null'
data.Sequence(cellfun(@isempty, data.Sequence)) = {'Null'};

% Step 3: Detect and Handle Outliers in Avg_Diff_Percent
meanAvgDiff = mean(data.Avg_Diff_Percent, 'omitnan');
stdAvgDiff = std(data.Avg_Diff_Percent, 'omitnan');
outlierThreshold = 3; % Define outliers as > 3 standard deviations from mean
outliers = abs(data.Avg_Diff_Percent - meanAvgDiff) > outlierThreshold * stdAvgDiff;
dataClean = data(~outliers, :); % Exclude outliers
disp(['Number of outliers removed (Avg_Diff_Percent > ' num2str(outlierThreshold) ' std devs): ' num2str(sum(outliers))]);

% Step 4: Create and Validate Behavioral Categories
dataClean.Behavior_Category = categorical(strcat(dataClean.Normality_Label, '/', dataClean.Centrality_Label, '/', dataClean.Width_Label));
uniqueCategories = unique(dataClean.Behavior_Category);
disp('Unique Behavioral Categories (expected up to 18):');
disp(uniqueCategories);
fprintf('Number of unique categories: %d\n', length(uniqueCategories));

% Step 5: Descriptive Statistics by Product and Layers
performanceMetrics = {'Avg_With', 'Avg_Without', 'Avg_Diff_Percent', 'Stdev_With', 'Stdev_Without', 'Stdev_Diff_Percent'};
descStats = groupsummary(dataClean, {'Product', 'Layers'}, {'mean', 'std'}, performanceMetrics);
disp('Descriptive Statistics by Product and Layers:');
disp(descStats);

% Step 6: Trend Analysis - Correlation of Layers with Performance
if length(unique(dataClean.Layers)) > 1
    corrData = table2array(dataClean(:, [{'Layers'}, performanceMetrics]));
    layerCorr = corr(corrData, 'Rows', 'complete');
    disp('Correlation of Layers with Performance (positive r = more layers improve):');
    disp(array2table(layerCorr, 'VariableNames', [{'Layers'}, performanceMetrics]));
else
    disp('No variation in Layers within this subset; correlation analysis skipped.');
end

% Step 6.5: Two-Way ANOVA - Interaction Effects of Layers and Product
if length(unique(dataClean.Layers)) > 1 && length(unique(dataClean.Product)) > 1
    [pAvgInteract, tblAvgInteract, statsAvgInteract] = anovan(dataClean.Avg_Diff_Percent, ...
        {dataClean.Layers, dataClean.Product}, 'model', 'interaction', 'varnames', {'Layers', 'Product'}, 'display', 'off');
    disp('Two-Way ANOVA Table (Avg_Diff_Percent by Layers and Product, alpha = 0.05):');
    fprintf('Layers p = %.4f, Product p = %.4f, Interaction p = %.4f\n', ...
        tblAvgInteract{2,6}, tblAvgInteract{3,6}, tblAvgInteract{4,6});
    disp('Significant if p < 0.05 for any factor or interaction.');
    
    [pStdevInteract, tblStdevInteract, statsStdevInteract] = anovan(dataClean.Stdev_Diff_Percent, ...
        {dataClean.Layers, dataClean.Product}, 'model', 'interaction', 'varnames', {'Layers', 'Product'}, 'display', 'off');
    disp('Two-Way ANOVA Table (Stdev_Diff_Percent by Layers and Product, alpha = 0.05):');
    fprintf('Layers p = %.4f, Product p = %.4f, Interaction p = %.4f\n', ...
        tblStdevInteract{2,6}, tblStdevInteract{3,6}, tblStdevInteract{4,6});
    disp('Significant if p < 0.05 for any factor or interaction.');
else
    disp('Insufficient variation in Layers or Product for two-way ANOVA.');
end

% Step 7: ANOVA - Effect of Layers on Performance Metrics
if length(unique(dataClean.Layers)) > 1
    for metric = performanceMetrics
        [p, tbl, stats] = anova1(dataClean.(metric{1}), dataClean.Layers, 'off');
        disp(['ANOVA Table (' metric{1} ' by Layers, alpha = 0.05):']);
        fprintf('F = %.4f, p = %.4f, Significant effect of Layers if p < 0.05: %d\n', tbl{2,5}, p, p < 0.05);
    end
else
    disp('No variation in Layers within this subset; ANOVA skipped.');
end

% Step 7.5: Separate ANOVA and Correlation Analysis for Each Layer Count
layerCounts = unique(dataClean.Layers);
for layer = layerCounts'
    layerData = dataClean(dataClean.Layers == layer, :);
    if height(layerData) > 1
        % ANOVA for Each Layer
        if length(unique(layerData.Product)) > 1
            disp(['Separate ANOVA for Layer = ' num2str(layer) ':']);
            for metric = performanceMetrics
                [p, tbl, stats] = anova1(layerData.(metric{1}), layerData.Product, 'off');
                disp(['ANOVA Table (' metric{1} ' by Product for Layer = ' num2str(layer) ', alpha = 0.05):']);
                fprintf('F = %.4f, p = %.4f, Significant effect of Product if p < 0.05: %d\n', tbl{2,5}, p, p < 0.05);
            end
        else
            disp(['No sufficient Product variation for Layer = ' num2str(layer) '; ANOVA skipped.']);
        end

        % Correlation Analysis for Each Layer
        corrMatrix = corr(table2array(layerData(:, {'Normality', 'Centrality', 'Width', 'Avg_Diff_Percent', 'Stdev_Diff_Percent'})), 'Rows', 'complete');
        disp(['Correlation Matrix for Layer = ' num2str(layer) ':']);
        disp(array2table(corrMatrix, 'VariableNames', {'Normality', 'Centrality', 'Width', 'Avg_Diff', 'Stdev_Diff'}, ...
            'RowNames', {'Normality', 'Centrality', 'Width', 'Avg_Diff', 'Stdev_Diff'}));

        % Heatmap: Correlation Matrix for this Layer
        if all(isnan(corrMatrix(:)))
            disp(['Correlation matrix for Layer = ' num2str(layer) ' contains only NaNs; heatmap cannot be displayed.']);
        else
            figure;
            heatmap(corrMatrix, 'XData', {'Normality', 'Centrality', 'Width', 'Avg_Diff', 'Stdev_Diff'}, ...
                'YData', {'Normality', 'Centrality', 'Width', 'Avg_Diff', 'Stdev_Diff'}, 'Colormap', parula);
            title(['Correlation Heatmap for Layer ' num2str(layer)]);
            saveas(gcf, ['Correlation_Heatmap_Layer_' num2str(layer) '.png']);
            % Removed close(gcf) to keep heatmaps open
        end
    else
        disp(['Insufficient data (' num2str(height(layerData)) ' rows) for Layer = ' num2str(layer) '; analysis skipped.']);
    end
end

% Step 8: Separate Behavior Analysis
% Normality
normStats = groupsummary(dataClean, 'Normality_Label', {'mean', 'std'}, performanceMetrics);
disp('Performance by Normality:');
disp(normStats);
normCorr = corr(table2array(dataClean(:, [{'Normality'}, performanceMetrics])), 'Rows', 'complete');
disp('Normality Correlations:');
disp(array2table(normCorr, 'VariableNames', [{'Normality'}, performanceMetrics]));

% Centrality
centStats = groupsummary(dataClean, 'Centrality_Label', {'mean', 'std'}, performanceMetrics);
disp('Performance by Centrality:');
disp(centStats);
centCorr = corr(table2array(dataClean(:, [{'Centrality'}, performanceMetrics])), 'Rows', 'complete');
disp('Centrality Correlations:');
disp(array2table(centCorr, 'VariableNames', [{'Centrality'}, performanceMetrics]));

% Width
widthStats = groupsummary(dataClean, 'Width_Label', {'mean', 'std'}, performanceMetrics);
disp('Performance by Width:');
disp(widthStats);
widthCorr = corr(table2array(dataClean(:, [{'Width'}, performanceMetrics])), 'Rows', 'complete');
disp('Width Correlations:');
disp(array2table(widthCorr, 'VariableNames', [{'Width'}, performanceMetrics]));

% Step 9: Behavioral Category Analysis
behaviorStats = groupsummary(dataClean, 'Behavior_Category', {'mean', 'std'}, performanceMetrics);
disp('Performance by Behavioral Category:');
disp(behaviorStats);

% Step 10: Top/Bottom Architectures with Threshold and Significance
threshold = 5; % Define significant impact as |Avg_Diff_Percent| > 5%
topImpactful = dataClean(dataClean.Avg_Diff_Percent > threshold, {'Arch_Name', 'Product', 'Layers', 'Behavior_Category', 'Avg_Diff_Percent'});
bottomImpactful = dataClean(dataClean.Avg_Diff_Percent < -threshold, {'Arch_Name', 'Product', 'Layers', 'Behavior_Category', 'Avg_Diff_Percent'});
disp(['Top Impactful Architectures (Avg_Diff_Percent > ' num2str(threshold) '%):']);
disp(topImpactful);
disp(['Bottom Impactful Architectures (Avg_Diff_Percent < -' num2str(threshold) '%):']);
disp(bottomImpactful);

% Test if top/bottom layers differ significantly from overall mean
if ~isempty(topImpactful) && length(unique(dataClean.Layers)) > 1
    overallMeanLayers = mean(dataClean.Layers);
    [hTop, pTop] = ttest2(topImpactful.Layers, dataClean.Layers, 'Alpha', 0.05);
    disp('Significance of Layer Counts in Top Impactful Architectures (vs. overall mean):');
    fprintf('Top: p = %.4f, Significant if p < 0.05: %d\n', pTop, pTop < 0.05);
else
    disp('No top impactful architectures or no layer variation; significance test skipped.');
end

if ~isempty(bottomImpactful) && length(unique(dataClean.Layers)) > 1
    [hBottom, pBottom] = ttest2(bottomImpactful.Layers, dataClean.Layers, 'Alpha', 0.05);
    disp('Significance of Layer Counts in Bottom Impactful Architectures (vs. overall mean):');
    fprintf('Bottom: p = %.4f, Significant if p < 0.05: %d\n', pBottom, pBottom < 0.05);
else
    disp('No bottom impactful architectures or no layer variation; significance test skipped.');
end
% Step 11: Visualization Code (Run locally)
% Bar Chart: Mean Normality by Layers
normByLayers = groupsummary(dataClean, 'Layers', 'mean', 'Normality');
figure;
bar(normByLayers.Layers, normByLayers.mean_Normality);
title('Mean Normality by Layers');
xlabel('Layers'); ylabel('Mean Normality');
saveas(gcf, 'Normality_by_Layers.png');

% Boxplot: Avg_Diff_Percent by Behavior Category
figure;
boxplot(dataClean.Avg_Diff_Percent * 100, dataClean.Behavior_Category); % Convert to percentage for display
title('Avg_Diff_Percent by Behavior Category');
xlabel('Behavior Category'); ylabel('Avg_Diff_Percent (%)');
xtickangle(45);
saveas(gcf, 'Avg_Diff_by_Behavior.png');

% Heatmap: Correlation Matrix
corrMatrix = corr(table2array(dataClean(:, {'Layers', 'Normality', 'Centrality', 'Width', 'Avg_Diff_Percent', 'Stdev_Diff_Percent'})));
% Convert Avg_Diff_Percent and Stdev_Diff_Percent correlations to decimal form, round to two decimal places
corrMatrix(5:end, :) = round(corrMatrix(5:end, :) * 100, 2); % Rows 5+ for Avg_Diff_Percent and Stdev_Diff_Percent
corrMatrix(:, 5:end) = round(corrMatrix(:, 5:end) * 100, 2); % Columns 5+ for Avg_Diff_Percent and Stdev_Diff_Percent
figure;
heatmap(corrMatrix, 'XData', {'Layers', 'Normality', 'Centrality', 'Width', 'Avg_Diff', 'Stdev_Diff'}, ...
    'YData', {'Layers', 'Normality', 'Centrality', 'Width', 'Avg_Diff', 'Stdev_Diff'}, 'Colormap', parula);
title('Correlation Heatmap');
saveas(gcf, 'Correlation_Heatmap.png');

% Step 12: New Visualization - Table for Behavioral Category Impacts by Layer
% Create table for FM-MV and FM-AT (assuming FM-AT data is in a separate sheet or subset)
% For now, use FM-MV data; adjust if FM-AT data is available
behaviorLayerStats = groupsummary(dataClean, {'Behavior_Category', 'Layers'}, {'mean', 'std'}, 'Avg_Diff_Percent');
behaviorLayerStats.mean_Avg_Diff_Percent = round(behaviorLayerStats.mean_Avg_Diff_Percent * 100, 2);
behaviorLayerStats.std_Avg_Diff_Percent = round(behaviorLayerStats.std_Avg_Diff_Percent * 100, 2);
disp('Table 4: Behavioral Category Impacts by Layer for AM-AT (in %):');
disp(behaviorLayerStats);

% Step 13: New Visualization - Boxplot of Avg_Diff_Percent by Layer for One Product
% Select AM-AT data (assuming sheet switch or subset); for now, use current data with specified product
selectedProduct = {'Electric Drill'}; % Focus on one product
selectedData = dataClean(ismember(dataClean.Product, selectedProduct), :);
figure;
boxplot(selectedData.Avg_Diff_Percent * 100, selectedData.Layers); % Convert to percentage for display
title('Boxplot of Avg_Diff_Percent by Layer for Electric Drill');
xlabel('Layers'); ylabel('Avg_Diff_Percent (%)');
saveas(gcf, 'Boxplot_Avg_Diff_by_Layer_3HolePunch.png');



