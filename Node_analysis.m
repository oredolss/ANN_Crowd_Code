% Node Analysis Script for ANN Crowd Diversity and Performance

% Step 1: Load Data
[file, path] = uigetfile('*.xlsx', 'Pick an excel file with LAYERS ANALYSIS');
inputFile = fullfile(path, file);
sheetName = 'FM-AT'; % Adjust if needed (e.g., FM-MP)
rawData = readtable(inputFile, 'Sheet', sheetName);
disp('Variable names in the table:');
disp(rawData.Properties.VariableNames);

% Step 2: Clean and Rename Columns
data = rawData;
data.Properties.VariableNames = {'Arch_Name', 'Layers', 'Nodes', 'Sequence', 'Product', ...
    'Normality', 'Centrality', 'Width', 'Normality_Label', 'Centrality_Label', 'Width_Label', ...
    'Avg_With', 'Avg_Without', 'Stdev_With', 'Stdev_Without', 'Avg_Diff_Percent', 'Stdev_Diff_Percent'};

% Clean Behavior Labels (e.g., 'High'/'Good'/'Same' → 'High/Good/Same')
data.Normality_Label = regexprep(strrep(data.Normality_Label, '''', ''), '[,\s]+$', '');
data.Centrality_Label = regexprep(strrep(data.Centrality_Label, '''', ''), '[,\s]+$', '');
data.Width_Label = regexprep(strrep(data.Width_Label, '''', ''), '[,\s]+$', '');
% Replace missing Sequence with 'Null'
data.Sequence(cellfun(@isempty, data.Sequence)) = {'Null'};

% Step 3: Create and Validate Behavioral Categories
data.Behavior_Category = categorical(strcat(data.Normality_Label, '/', data.Centrality_Label, '/', data.Width_Label));
uniqueCategories = unique(data.Behavior_Category);
disp('Unique Behavioral Categories (expected up to 18):');
disp(uniqueCategories);
fprintf('Number of unique categories: %d\n', length(uniqueCategories));

% Step 4: Descriptive Statistics by Product and Nodes
descStats = groupsummary(data, {'Product', 'Nodes'}, {'mean', 'std'}, {'Avg_Diff_Percent', 'Stdev_Diff_Percent'});
disp('Descriptive Statistics by Product and Nodes (Avg_Diff_Percent = accuracy impact, Stdev_Diff_Percent = precision impact):');
disp(descStats);

% Step 5: Trend Analysis - Correlation of Nodes with Performance
nodeCorr = corr(table2array(data(:, {'Nodes', 'Avg_Diff_Percent', 'Stdev_Diff_Percent'})));
disp('Correlation of Nodes with Performance (positive r = higher nodes improve):');
disp(array2table(nodeCorr, 'VariableNames', {'Nodes', 'Avg_Diff', 'Stdev_Diff'}));

% Step 6: ANOVA - Effect of Nodes on Avg_Diff_Percent
[pAvg, tblAvg, statsAvg] = anova1(data.Avg_Diff_Percent, data.Nodes, 'off');
disp('ANOVA Table (Avg_Diff_Percent by Nodes, alpha = 0.05):');
fprintf('F = %.4f, p = %.4f, Significant effect of Nodes on accuracy if p < 0.05: %d\n', tblAvg{2,5}, pAvg, pAvg < 0.05);

% ANOVA - Effect of Nodes on Stdev_Diff_Percent
[pStdev, tblStdev, statsStdev] = anova1(data.Stdev_Diff_Percent, data.Nodes, 'off');
disp('ANOVA Table (Stdev_Diff_Percent by Nodes, alpha = 0.05):');
fprintf('F = %.4f, p = %.4f, Significant effect of Nodes on precision if p < 0.05: %d\n', tblStdev{2,5}, pStdev, pStdev < 0.05);

% Step 6.5: Node Group Analysis - Categorize Nodes into Small, Middle, Large
% Categorize nodes: Small (1-5), Middle (6-10), Large (11-15)
data.Node_Group = categorical(zeros(height(data), 1));
data.Node_Group(data.Nodes >= 1 & data.Nodes <= 5) = categorical({'Small'});
data.Node_Group(data.Nodes >= 6 & data.Nodes <= 10) = categorical({'Middle'});
data.Node_Group(data.Nodes >= 11 & data.Nodes <= 15) = categorical({'Large'});
disp('Node Group Distribution:');
disp(groupsummary(data, 'Node_Group'));

% Descriptive Statistics by Product and Node_Group
descStatsGroup = groupsummary(data, {'Product', 'Node_Group'}, {'mean', 'std'}, {'Avg_Diff_Percent', 'Stdev_Diff_Percent'});
disp('Descriptive Statistics by Product and Node Group:');
disp(descStatsGroup);

% ANOVA - Effect of Node_Group on Avg_Diff_Percent
[pGroupAvg, tblGroupAvg, statsGroupAvg] = anova1(data.Avg_Diff_Percent, data.Node_Group, 'off');
disp('ANOVA Table (Avg_Diff_Percent by Node Group, alpha = 0.05):');
fprintf('F = %.4f, p = %.4f, Significant effect of Node Group on accuracy if p < 0.05: %d\n', tblGroupAvg{2,5}, pGroupAvg, pGroupAvg < 0.05);

% ANOVA - Effect of Node_Group on Stdev_Diff_Percent
[pGroupStdev, tblGroupStdev, statsGroupStdev] = anova1(data.Stdev_Diff_Percent, data.Node_Group, 'off');
disp('ANOVA Table (Stdev_Diff_Percent by Node Group, alpha = 0.05):');
fprintf('F = %.4f, p = %.4f, Significant effect of Node Group on precision if p < 0.05: %d\n', tblGroupStdev{2,5}, pGroupStdev, pGroupStdev < 0.05);

% Visualization: Boxplot of Avg_Diff_Percent by Node_Group
figure;
boxplot(data.Avg_Diff_Percent, data.Node_Group);
title('Avg_Diff_Percent by Node Group (Small: 1-5, Middle: 6-10, Large: 11-15)');
xlabel('Node Group'); ylabel('Avg_Diff_Percent');
saveas(gcf, 'Avg_Diff_by_Node_Group.png');

% Step 7: Separate Behavior Analysis
% Normality
normStats = groupsummary(data, 'Normality_Label', {'mean', 'std'}, {'Avg_Diff_Percent', 'Stdev_Diff_Percent'});
disp('Performance by Normality:');
disp(normStats);
normCorr = corr(table2array(data(:, {'Normality', 'Avg_Diff_Percent', 'Stdev_Diff_Percent'})));
disp('Normality Correlations:');
disp(array2table(normCorr, 'VariableNames', {'Normality', 'Avg_Diff', 'Stdev_Diff'}));

% Centrality
centStats = groupsummary(data, 'Centrality_Label', {'mean', 'std'}, {'Avg_Diff_Percent', 'Stdev_Diff_Percent'});
disp('Performance by Centrality:');
disp(centStats);
centCorr = corr(table2array(data(:, {'Centrality', 'Avg_Diff_Percent', 'Stdev_Diff_Percent'})));
disp('Centrality Correlations:');
disp(array2table(centCorr, 'VariableNames', {'Centrality', 'Avg_Diff', 'Stdev_Diff'}));

% Width
widthStats = groupsummary(data, 'Width_Label', {'mean', 'std'}, {'Avg_Diff_Percent', 'Stdev_Diff_Percent'});
disp('Performance by Width:');
disp(widthStats);
widthCorr = corr(table2array(data(:, {'Width', 'Avg_Diff_Percent', 'Stdev_Diff_Percent'})));
disp('Width Correlations:');
disp(array2table(widthCorr, 'VariableNames', {'Width', 'Avg_Diff', 'Stdev_Diff'}));

% Step 8: Behavioral Category Analysis
behaviorStats = groupsummary(data, 'Behavior_Category', {'mean', 'std'}, {'Avg_Diff_Percent', 'Stdev_Diff_Percent'});
disp('Performance by Behavioral Category:');
disp(behaviorStats);

% Step 10: Top/Bottom Architectures with Threshold and Significance
threshold = 5; % Define significant impact as |Avg_Diff_Percent| > 5%
topImpactful = data(data.Avg_Diff_Percent > threshold, {'Arch_Name', 'Product', 'Nodes', 'Behavior_Category', 'Avg_Diff_Percent'});
bottomImpactful = data(data.Avg_Diff_Percent < -threshold, {'Arch_Name', 'Product', 'Nodes', 'Behavior_Category', 'Avg_Diff_Percent'});
disp(['Top Impactful Architectures (Avg_Diff_Percent > ' num2str(threshold) '%):']);
disp(topImpactful);
disp(['Bottom Impactful Architectures (Avg_Diff_Percent < -' num2str(threshold) '%):']);
disp(bottomImpactful);

% Test if top/bottom nodes differ significantly from overall mean
overallMeanNodes = mean(data.Nodes);
[hTop, pTop] = ttest2(topImpactful.Nodes, data.Nodes, 'Alpha', 0.05);
[hBottom, pBottom] = ttest2(bottomImpactful.Nodes, data.Nodes, 'Alpha', 0.05);
disp('Significance of Node Counts in Top/Bottom Architectures (vs. overall mean):');
fprintf('Top: p = %.4f, Significant if p < 0.05: %d\n', pTop, pTop < 0.05);
fprintf('Bottom: p = %.4f, Significant if p < 0.05: %d\n', pBottom, pBottom < 0.05);

% Step 11: Visualization Code (Run locally)
% Bar Chart: Mean Normality by Nodes
normByNodes = groupsummary(data, 'Nodes', 'mean', 'Normality');
figure;
bar(normByNodes.Nodes, normByNodes.mean_Normality);
title('Mean Normality by Nodes');
xlabel('Nodes'); ylabel('Mean Normality');
saveas(gcf, 'Normality_by_Nodes.png');

% Boxplot: Avg_Diff_Percent by Behavior Category
figure;
boxplot(data.Avg_Diff_Percent, data.Behavior_Category);
title('Avg_Diff_Percent by Behavior Category');
xlabel('Behavior Category'); ylabel('Avg_Diff_Percent');
xtickangle(45);
saveas(gcf, 'Avg_Diff_by_Behavior.png');

% Heatmap: Correlation Matrix
corrMatrix = corr(table2array(data(:, {'Nodes', 'Normality', 'Centrality', 'Width', 'Avg_Diff_Percent', 'Stdev_Diff_Percent'})));
figure;
heatmap(corrMatrix, 'XData', {'Nodes', 'Normality', 'Centrality', 'Width', 'Avg_Diff', 'Stdev_Diff'}, ...
    'YData', {'Nodes', 'Normality', 'Centrality', 'Width', 'Avg_Diff', 'Stdev_Diff'}, 'Colormap', parula);
title('Correlation Heatmap');
saveas(gcf, 'Correlation_Heatmap.png');