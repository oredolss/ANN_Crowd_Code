
%ArchBehavior This script will be used to train an ANN using given
% inputs and targets, followed by predicting targets for new inputs. 
%
%
%
clear; clc;
%% Request input file and inspect for required sheets 
[file,path,~] = uigetfile('*.xlsx','Pick an excel file with inputs and targets');
inputFile = strcat(path,file);
% [num,text,raw] = xlsread(inputFile,'Arch Data');
% Define sheet to read
sheetName = 'AM-AT';
% Read raw data into a table
rawData = readtable(inputFile, 'Sheet', sheetName);
% Get variable names from the read table to create column headers that can be used for filtering/trimming the table.
varNamesAll = rawData.Properties.VariableNames; %all vars
varNamesProps = varNamesAll(1:5); %just properties
varNamesData = varNamesAll(6:end); %just product data
% Create a trimmed table that includes only data
errData = rawData(:,varNamesData); %error data
% Import property data from Excel file
% Since we need to use "readtable" function, we will need to create an options structure to specify how to import the file
numVars = 5; %number of variables
varType = {'categorical', 'int32', 'int32', 'int32', 'categorical'};
dataStartLoc = 'A2';
opts = spreadsheetImportOptions('Sheet',sheetName, 'DataRange', dataStartLoc,...
    'NumVariables',numVars, 'VariableNames', varNamesProps, 'VariableTypes', varType);
% Import Excel data using readtable
prpData = readtable(inputFile,opts);
% Create a list of unique architectures
A = prpData.Architecture(:);
for prod = 1:189
    % increment indicies such that i corresponds to 1,101,201,301...
    archList(prod,1) = A((prod-1)*100 + 1, 1);
end
% Define variables for the product table
prodVarNames = ["Mean", "Median", "Variance", "Minimum", "Maximum", "Range", "Peaks"];
prodVarTypes = ["double", "double", "double", "double", "double", "double", "int16"];
numProd = 40; %define the number of products you want to analyze
varTypesData = [];
varTypesDataCell = [];
for v = 1:numProd
    varTypesData = [varTypesData, "double"];
    varTypesDataCell = [varTypesDataCell, "cell"];
end
%% Create tables to hold the prediction error values
errTbl = table('Size', [189 numProd], 'VariableNames', string(varNamesData(1:numProd)),...
    'VariableTypes', varTypesDataCell); %table for errors, separated by architectures
prodTbl = table('Size', [numProd 7], 'VariableNames', prodVarNames,...
    'VariableTypes', prodVarTypes); %table for product data
meanTbl = table('Size', [189 numProd], 'VariableNames', string(varNamesData(1:numProd)),...
    'VariableTypes', varTypesData); %table for means error values
medianTbl = table('Size', [189 numProd], 'VariableNames', string(varNamesData(1:numProd)),...
    'VariableTypes', varTypesData); %table for median error values
varTbl = table('Size', [189 numProd], 'VariableNames', string(varNamesData(1:numProd)),...
    'VariableTypes', varTypesData); %table for variance in errors
minTbl = table('Size', [189 numProd], 'VariableNames', string(varNamesData(1:numProd)),...
    'VariableTypes', varTypesData); %table for minmum error values
maxTbl = table('Size', [189 numProd], 'VariableNames', string(varNamesData(1:numProd)),...
    'VariableTypes', varTypesData); %table for maximum error values
rangeTbl = table('Size', [189 numProd], 'VariableNames', string(varNamesData(1:numProd)),...
    'VariableTypes', varTypesData); %table for range of error values
diffTbl = table('Size', [189 numProd], 'VariableNames', string(varNamesData(1:numProd)),...
    'VariableTypes', varTypesData); %table for difference in overall prediction error vs architecture error
archPeaks = table('Size', [189 numProd], 'VariableNames', string(varNamesData(1:numProd)),...
    'VariableTypes', varTypesData); %table for number of peaks in architecture
%% Filter table with products and architectures to compute descriptive statistics
for prod = 1:numProd
    % compute descriptive statistics
    prodTbl(prod, "Mean") = {mean(errData{:,prod})}; %calculate mean error
    prodTbl(prod, "Median") = {median(errData{:,prod})}; %calculate median error
    prodTbl(prod, "Variance") = {var(errData{:,prod})}; % calculate variance in error
    prodTbl(prod, "Minimum") = {min(errData{:,prod})}; %find min error
    prodTbl(prod, "Maximum") = {max(errData{:,prod})}; %find max error
    prodTbl(prod, "Range") = {prodTbl{prod, "Maximum"} - prodTbl{prod, "Minimum"}}; %compute range of errors
    % determine the number of peaks in overall ANN
    [prodCount, ~] = histcounts(errData{:,prod}, 189);
    [prodPeaks, ~, ~, ~] = peakFind(prodCount, 0.01);
    prodTbl(prod, "Peaks") = {prodPeaks};
    % compute descriptive statistics for each architecture
    for arch = 1:189 %loop over each architecture
        % extract architecture data to work with
        archData = errData{prpData.Architecture == archList(arch), prod};
        % put data in tables
        errTbl(arch,prod) = {archData};
        % compute descriptive statistics
        meanTbl(arch,prod) = {mean(archData)}; %calculate mean error
        medianTbl(arch,prod) = {median(archData)}; %calculate median error
        varTbl(arch,prod) = {var(archData)}; %calculate variance in error
        minTbl(arch,prod) = {min(archData)}; %find mean error
        maxTbl(arch,prod) = {max(archData)}; %find max error
        rangeTbl(arch,prod) = {maxTbl{arch,prod} - minTbl{arch,prod}}; %compute range of error
        diffTbl(arch,prod) = {prodTbl{prod, "Mean"} - meanTbl{arch,prod}}; %calculate diff between arch and overall
        % Check for the number of peaks
        [archCount, ~] = histcounts(archData,10);
        [archPeakVal, ~, ~, ~] = peakFind(archCount, 0.05);
        archPeaks(arch,prod) = {archPeakVal};
        % clear recycled variable
        clear archData archCount archPeakVal
    end
    clear prodData prodCount prodPeaks
end
%% Compute normality metrics (comparing peaks, normality test?)
normData = zeros([189,numProd]); %empty matrix for normality data
for prod = 1:numProd %loop over products
    currProdPeak = prodTbl.Peaks(prod); %get number of peaks in this product from table
    for arch = 1:189 %loop over architectures
        % compare number of peaks in product vs architecture
        currArchPeak = archPeaks.(varNamesData{prod})(arch); %get number of peaks in architecture
        if currArchPeak == currProdPeak %if number of peaks match between prod and arch
            normData(arch,prod) = 1; %set normality behavior to 1
        end
        clear currArchPeak
    end
    clear currProdPeak
end
%% Compute centrality metric (left, right, center)
centData = zeros([189, numProd]); %empty matrix for centrality data
centTol = 0.05; %tolerance for centrality
for prod = 1:numProd %loop over products
    currProdMean = prodTbl.Mean(prod); %get product mean from table
    currProdMedian = prodTbl.Median(prod); %get product median from table
    for arch = 1:189 %loop over architectures
        archErrs = errTbl.(varNamesData{prod}){arch}; %arch error values
        currArchMean = meanTbl.(varNamesData{prod})(arch); %get arch mean from table
        currArchMedian = medianTbl.(varNamesData{prod})(arch); %get arch median from table
        % calculate difference in means and medians
        meanDiff = abs(currProdMean - currArchMean);
        medianDiff = abs(currProdMedian - currArchMedian);
        % conduct t-test to compare arch data to product data
        [h_t(arch,prod), pVal_t(arch, prod)] = ttest2(archErrs, errData{:,prod}, "Alpha", 0.05, "Vartype", "unequal");
        [pVal_r(arch,prod), h_r(arch, prod)] = ranksum(archErrs, errData{:,prod}, "Alpha", 0.05);
        % If t-test fails to reject, check if difference between medians is within tolerance
        if h_t(arch,prod) == 0 %if t-test fails to reject null
            if medianDiff < centTol*currProdMedian
                centData(arch,prod) = 0; %arch are prod are similar
            else %if mean diff is greater, check if left or right
                if currProdMedian > currArchMedian
                    centData(arch,prod) = -1; %arch is left of prod
                else
                    centData(arch,prod) = 1; %arch is right of prod
                end
            end
        elseif h_t(arch,prod) > 0 %if t-test rejects null
            if currProdMedian > currArchMedian
                centData(arch,prod) = -1;
            else
                centData(arch,prod) = 1;
            end
        end
    end
end
%% Compute width metric
wdTol = 0.2; %tolerance for width
widthData = zeros(189, numProd); %empty matrix to hold width data
widthData2 = zeros(189, numProd); %empty matrix for width data using range
for prod = 1:numProd %loop over products
    currProdVar = prodTbl.Variance(prod); %get product variance from table
    currProdRange = prodTbl.Range(prod); %get product range from table
    for arch = 1:189 %loop over architectures
        currArchVar = varTbl.(varNamesData{prod})(arch); %get arch variance from table
        currArchRange = rangeTbl.(varNamesData{prod})(arch); %get arch range from table
        % compute width coding using variance
        varDiff = currProdVar - currArchVar; %diff between prod var and arch var
        if varDiff < (-1)*wdTol*currProdVar %if difference in variance is below threshold
            widthData(arch,prod) = -1;
        elseif varDiff > wdTol*currProdVar %if difference in variance is above threshold
            widthData(arch,prod) = 1;
        else %if product varaiance is within tolerance
            widthData(arch,prod) = 0;
        end
        % compute width coding using range
        rangeDiff = currProdRange - currArchRange; %diff between prod range and arch range
        if rangeDiff < (-1)*wdTol*currProdVar %if difference between prod range and arch range is below threshold
            widthData2(arch,prod) = -1;
        elseif rangeDiff > wdTol*currProdRange %if diff between prod range and arch range is above threshold
            widthData2(arch,prod) = 1;
        else %if product variance is within tolerance
            widthData2(arch,prod) = 0;
        end
        clear varDiff rangeDiff
    end
    clear currProdVar currProdRange
end