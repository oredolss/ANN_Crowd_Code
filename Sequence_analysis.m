% Sequence Analysis Script for ANN Crowd Diversity and Performance

% Step 1: Load Data
[file, path] = uigetfile('*.xlsx', 'Pick an excel file with SEQUENCE ANALYSIS');
inputFile = fullfile(path, file);
sheetName = 'FM-MV'; % Matches your test sheet
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

% Step 5: Descriptive Statistics by Product and Sequence
descStats = groupsummary(dataClean, {'Product', 'Sequence'}, {'mean', 'std'}, {'Avg_Diff_Percent', 'Stdev_Diff_Percent'});
disp('Descriptive Statistics by Product and Sequence (Avg_Diff_Percent = accuracy impact, Stdev_Diff_Percent = precision impact):');
disp(descStats);

% Step 6: Trend Analysis - Correlation of Sequence with Performance
[uniqueSeq, ~, seqIdx] = unique(dataClean.Sequence);
if length(uniqueSeq) > 1
    seqCorr = corr([seqIdx, table2array(dataClean(:, {'Avg_Diff_Percent', 'Stdev_Diff_Percent'}))], 'Rows', 'complete');
    disp('Correlation of Sequence with Performance (positive r = sequence variation improves):');
    disp(array2table(seqCorr, 'VariableNames', {'Sequence', 'Avg_Diff', 'Stdev_Diff'}));
else
    disp('No variation in Sequence within this subset; correlation analysis skipped.');
end

% Step 7: ANOVA - Effect of Sequence on Avg_Diff_Percent
if length(unique(dataClean.Sequence)) > 1
    [pAvg, tblAvg, statsAvg] = anova1(dataClean.Avg_Diff_Percent, dataClean.Sequence, 'off');
    disp('ANOVA Table (Avg_Diff_Percent by Sequence, alpha = 0.05):');
    fprintf('F = %.4f, p = %.4f, Significant effect of Sequence on accuracy if p < 0.05: %d\n', tblAvg{2,5}, pAvg, pAvg < 0.05);
else
    disp('No variation in Sequence within this subset; ANOVA for Avg_Diff_Percent skipped.');
end

% ANOVA - Effect of Sequence on Stdev_Diff_Percent
if length(unique(dataClean.Sequence)) > 1
    [pStdev, tblStdev, statsStdev] = anova1(dataClean.Stdev_Diff_Percent, dataClean.Sequence, 'off');
    disp('ANOVA Table (Stdev_Diff_Percent by Sequence, alpha = 0.05):');
    fprintf('F = %.4f, p = %.4f, Significant effect of Sequence on precision if p < 0.05: %d\n', tblStdev{2,5}, pStdev, pStdev < 0.05);
else
    disp('No variation in Sequence within this subset; ANOVA for Stdev_Diff_Percent skipped.');
end

% Step 7.5: Correlation, ANOVA, and Heatmap for Each Sequence
uniqueSeq = unique(dataClean.Sequence);
disp('Analysis for Each Sequence:');
for i = 1:length(uniqueSeq)
    seq = uniqueSeq{i};
    seqData = dataClean(strcmp(dataClean.Sequence, seq), :);
    if height(seqData) >= 2 % Require at least 2 data points for analysis
        % Correlation Analysis
        corrMatrix = corr(table2array(seqData(:, {'Normality', 'Centrality', 'Width', 'Avg_Diff_Percent', 'Stdev_Diff_Percent'})), 'Rows', 'complete');
        disp(['Correlation Matrix for Sequence ' seq ':']);
        disp(array2table(corrMatrix, 'VariableNames', {'Normality', 'Centrality', 'Width', 'Avg_Diff', 'Stdev_Diff'}, ...
            'RowNames', {'Normality', 'Centrality', 'Width', 'Avg_Diff', 'Stdev_Diff'}));

        % Heatmap: Correlation Matrix for this Sequence
        if all(isnan(corrMatrix(:)))
            disp(['Correlation matrix for Sequence ' seq ' contains only NaNs; heatmap cannot be displayed.']);
        else
            figure;
            heatmap(corrMatrix, 'XData', {'Normality', 'Centrality', 'Width', 'Avg_Diff', 'Stdev_Diff'}, ...
                'YData', {'Normality', 'Centrality', 'Width', 'Avg_Diff', 'Stdev_Diff'}, 'Colormap', parula);
            title(['Correlation Heatmap for Sequence ' seq]);
            % Clean sequence name for filename (replace invalid characters)
            seqClean = regexprep(seq, '[^\w\s-]', '_');
            saveas(gcf, ['Correlation_Heatmap_Sequence_' seqClean '.png']);
        end

        % ANOVA - Effect of Product on Avg_Diff_Percent
        if length(unique(seqData.Product)) > 1
            [pAvgSeq, tblAvgSeq, statsAvgSeq] = anova1(seqData.Avg_Diff_Percent, seqData.Product, 'off');
            disp(['ANOVA for Avg_Diff_Percent within Sequence ' seq ' (Effect of Product):']);
            fprintf('F = %.4f, p = %.4f, Significant if p < 0.05: %d\n', tblAvgSeq{2,5}, pAvgSeq, pAvgSeq < 0.05);
        else
            disp(['No sufficient Product variation for Sequence ' seq '; ANOVA for Avg_Diff_Percent skipped.']);
        end

        % ANOVA - Effect of Product on Stdev_Diff_Percent
        if length(unique(seqData.Product)) > 1
            [pStdevSeq, tblStdevSeq, statsStdevSeq] = anova1(seqData.Stdev_Diff_Percent, seqData.Product, 'off');
            disp(['ANOVA for Stdev_Diff_Percent within Sequence ' seq ' (Effect of Product):']);
            fprintf('F = %.4f, p = %.4f, Significant if p < 0.05: %d\n', tblStdevSeq{2,5}, pStdevSeq, pStdevSeq < 0.05);
        else
            disp(['No sufficient Product variation for Sequence ' seq '; ANOVA for Stdev_Diff_Percent skipped.']);
        end
    else
        disp(['Insufficient data (' num2str(height(seqData)) ' rows) for Sequence ' seq '; analysis skipped.']);
    end
end

% Step 8: Separate Behavior Analysis
% Normality
normStats = groupsummary(dataClean, 'Normality_Label', {'mean', 'std'}, {'Avg_Diff_Percent', 'Stdev_Diff_Percent'});
disp('Performance by Normality:');
disp(normStats);
normCorr = corr(table2array(dataClean(:, {'Normality', 'Avg_Diff_Percent', 'Stdev_Diff_Percent'})), 'Rows', 'complete');
disp('Normality Correlations:');
disp(array2table(normCorr, 'VariableNames', {'Normality', 'Avg_Diff', 'Stdev_Diff'}));

% Centrality
centStats = groupsummary(dataClean, 'Centrality_Label', {'mean', 'std'}, {'Avg_Diff_Percent', 'Stdev_Diff_Percent'});
disp('Performance by Centrality:');
disp(centStats);
centCorr = corr(table2array(dataClean(:, {'Centrality', 'Avg_Diff_Percent', 'Stdev_Diff_Percent'})), 'Rows', 'complete');
disp('Centrality Correlations:');
disp(array2table(centCorr, 'VariableNames', {'Centrality', 'Avg_Diff', 'Stdev_Diff'}));

% Width
widthStats = groupsummary(dataClean, 'Width_Label', {'mean', 'std'}, {'Avg_Diff_Percent', 'Stdev_Diff_Percent'});
disp('Performance by Width:');
disp(widthStats);
widthCorr = corr(table2array(dataClean(:, {'Width', 'Avg_Diff_Percent', 'Stdev_Diff_Percent'})), 'Rows', 'complete');
disp('Width Correlations:');
disp(array2table(widthCorr, 'VariableNames', {'Width', 'Avg_Diff', 'Stdev_Diff'}));

% Step 9: Behavioral Category Analysis
behaviorStats = groupsummary(dataClean, 'Behavior_Category', {'mean', 'std'}, {'Avg_Diff_Percent', 'Stdev_Diff_Percent'});
disp('Performance by Behavioral Category:');
disp(behaviorStats);

% Step 10: Top/Bottom Architectures with Threshold and Significance
threshold = 5; % Define significant impact as |Avg_Diff_Percent| > 5%
topImpactful = dataClean(dataClean.Avg_Diff_Percent > threshold, {'Arch_Name', 'Product', 'Sequence', 'Behavior_Category', 'Avg_Diff_Percent'});
bottomImpactful = dataClean(dataClean.Avg_Diff_Percent < -threshold, {'Arch_Name', 'Product', 'Sequence', 'Behavior_Category', 'Avg_Diff_Percent'});
disp(['Top Impactful Architectures (Avg_Diff_Percent > ' num2str(threshold) '%):']);
disp(topImpactful);
disp(['Bottom Impactful Architectures (Avg_Diff_Percent < -' num2str(threshold) '%):']);
disp(bottomImpactful);

% Test if top/bottom sequences differ significantly from overall distribution
if ~isempty(topImpactful) && length(unique(dataClean.Sequence)) > 1
    [hTop, pTop] = chi2gof(topImpactful.Sequence, 'Expected', histcounts(dataClean.Sequence, 'Normalization', 'probability'));
    disp('Significance of Sequence Distribution in Top Impactful Architectures (vs. overall, chi-square test):');
    fprintf('Top: p = %.4f, Significant if p < 0.05: %d\n', pTop, pTop < 0.05);
else
    disp('No top impactful architectures or no sequence variation; significance test skipped.');
end

if ~isempty(bottomImpactful) && length(unique(dataClean.Sequence)) > 1
    [hBottom, pBottom] = chi2gof(bottomImpactful.Sequence, 'Expected', histcounts(dataClean.Sequence, 'Normalization', 'probability'));
    disp('Significance of Sequence Distribution in Bottom Impactful Architectures (vs. overall, chi-square test):');
    fprintf('Bottom: p = %.4f, Significant if p < 0.05: %d\n', pBottom, pBottom < 0.05);
else
    disp('No bottom impactful architectures or no sequence variation; significance test skipped.');
end

% Step 11: Visualization Code (Run locally)
% Bar Chart: Mean Normality by Sequence
normBySeq = groupsummary(dataClean, 'Sequence', 'mean', 'Normality');
figure;
bar(categorical(normBySeq.Sequence), normBySeq.mean_Normality);
title('Mean Normality by Sequence');
xlabel('Sequence'); ylabel('Mean Normality');
if length(unique(dataClean.Sequence)) > 10
    xtickangle(45);
end
saveas(gcf, 'Normality_by_Sequence.png');

% Boxplot: Avg_Diff_Percent by Sequence
figure;
boxplot(dataClean.Avg_Diff_Percent, dataClean.Sequence);
title('Avg_Diff_Percent by Sequence');
xlabel('Sequence'); ylabel('Avg_Diff_Percent (%)');
xtickangle(45);
saveas(gcf, 'Avg_Diff_by_Sequence.png');

% Heatmap: Correlation Matrix (Original - Sequence vs. Other Metrics)
[uniqueSeq, ~, seqIdx] = unique(dataClean.Sequence); % Convert Sequence to numerical index
corrData = [seqIdx, table2array(dataClean(:, {'Normality', 'Centrality', 'Width', 'Avg_Diff_Percent'}))];
corrMatrix = corr(corrData, 'Rows', 'complete');
figure;
heatmap(corrMatrix, 'XData', {'Sequence', 'Normality', 'Centrality', 'Width', 'Avg_Diff'}, ...
    'YData', {'Sequence', 'Normality', 'Centrality', 'Width', 'Avg_Diff'}, 'Colormap', parula);
title('Correlation Heatmap (Sequence vs. Metrics)');
saveas(gcf, 'Correlation_Heatmap.png');

% Heatmap: Correlation Matrix Between All Sequences
% Pivot data to create a matrix with sequences as columns and products as rows
uniqueSeq = unique(dataClean.Sequence);
seqPivot = zeros(length(unique(dataClean.Product)), length(uniqueSeq));
products = unique(dataClean.Product);
for i = 1:length(products)
    for j = 1:length(uniqueSeq)
        subset = dataClean(strcmp(dataClean.Product, products{i}) & strcmp(dataClean.Sequence, uniqueSeq{j}), :);
        if ~isempty(subset)
            seqPivot(i, j) = mean(subset.Avg_Diff_Percent, 'omitnan'); % Mean if multiple entries (unlikely)
        else
            seqPivot(i, j) = NaN; % Missing data for this product-sequence pair
        end
    end
end

% Compute correlation matrix between sequences
seqCorrMatrix = corr(seqPivot, 'Rows', 'complete');
if all(isnan(seqCorrMatrix(:)))
    disp('Correlation matrix between sequences contains only NaNs; heatmap cannot be displayed.');
else
    figure;
    heatmap(seqCorrMatrix, 'XData', uniqueSeq, 'YData', uniqueSeq, 'Colormap', parula);
    title('Correlation Heatmap Between Sequences (Avg_Diff_Percent)');
    h = gca;
    h.XTickLabelRotation = 45;
    h.YTickLabelRotation = 45;
    saveas(gcf, 'Sequence_Correlation_Heatmap.png');
end
