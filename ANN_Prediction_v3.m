%ANN_PREDICTION_V3 This script will be used to train an ANN using given
%inputs and targets, followed by predicting targets for new inputs. 
%
%
%
clear; clc;
%% Request input file and inspect for required sheets 
[file,path,~]=uigetfile('*.xlsx','Pick an excel file with inputs and targets');
inputFile = strcat(path,file);
% Read all sheet names
sheets = sheetnames(inputFile);
% Check for "Input Vectors" sheet
if ~ismember(sheets,'Input Vectors')
    error('Input file is missing "Input Vectors" sheet.')
end
% Check for "Targets" sheet
if ~ismember(sheets,'Targets')
    error('Input file is missing "Targets" sheet.')
end
% debugging message
disp('Sheets found!')
% If no errors are found, move to next step and read each sheet for releavnt data.
%% Extract input data from Excel file
% Create an "options" structure to tell "readTable" how to read from the excel file
inputVars = 30; %number of input variables
inputVarNames = {'vecName','cMet_01', 'cMet_02', 'cMet_03', 'cMet_04', 'cMet_05', 'cMet_06', 'cMet_07', 'cMet_08',...
    'cMet_09', 'cMet_10', 'cMet_11', 'cMet_12', 'cMet_13', 'cMet_14', 'cMet_15', 'cMet_16', ...
    'cMet_17', 'cMet_18', 'cMet_19', 'cMet_20', 'cMet_21', 'cMet_22', 'cMet_23', 'cMet_24', ...
    'cMet_25', 'cMet_26', 'cMet_27', 'cMet_28', 'cMet_29'}; %names of input variables
inputVarType = {'char', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double',...
    'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double',...
    'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'}; %input variable types
inputSheet = 'Input Vectors'; %name of sheet that holds input variables
inputDataLoc = 'A2'; %cell address where the data starts
% Combine above parts to create the options structure
inputOpts = spreadsheetImportOptions('Sheet',inputSheet, 'DataRange', inputDataLoc,...
    'NumVariables',inputVars, 'VariableNames', inputVarNames, 'VariableTypes', inputVarType);
% Read inputs from the input sheet
rawInputData = readtable(inputFile, inputOpts);
% debugging message
disp('Inputs read!')
%% Extract target data from Excel file
% Update the following based on target types
targetVarNames = {'vecName', 'Target'};
targetVarType = {'char', 'double'};
targetSheet = 'Targets'; %name of sheet that holds target data
targetDataLoc = 'A2';
targetOpts = spreadsheetImportOptions('Sheet',targetSheet, 'DataRange', targetDataLoc, ...
    'NumVariables',2, 'VariableNames', targetVarNames, 'VariableTypes', targetVarType);
rawTargetData = readtable(inputFile, targetOpts);
% Check if all inputs have targets
if height(rawInputData) ~= height(rawTargetData)
    error('The number of "Input Vectors" does not match the number of "Targets" given.')
end
% debugging message
disp('Targets read!')
%% Generate training and test sets based on k-fold selection
kFoldNum = 10; %number of k-fold replications
% Create modified rawInputData
modInputData = [rawInputData; rawInputData([1,2],:)]; %this needs to be updated based on number of k-Folds
% Generate test sets for 10 kfolds based on cascade forward method
for j=1:2:kFoldNum*2
    start = j;
    stop = j+3;
    testSetArray(:,(j+1)/2) = modInputData{[start:stop],1};
end
% Generate the training sets for 10 kfolds based on test sets
for d = 1:kFoldNum %d for Daniel
    trainSetPrep = {}; %generate an empty testSetPrep vector
    for p = 1:20 %loop over every product
        % generate a comparison vector
        % the comparison vector has results for comparing each product in the test set with the current product in the list
        % of products.
        comparison = [~strcmp(testSetArray(1,d),rawInputData{p,1}),...
            ~strcmp(testSetArray{2,d},rawInputData{p,1}),...
            ~strcmp(testSetArray(3,d),rawInputData{p,1}),...
            ~strcmp(testSetArray(4,d),rawInputData{p,1})];
        % if all test products do NOT match, then we add to the training set
        if all(comparison)
            trainSetPrep = [trainSetPrep;rawInputData{p,1}];
        else
            continue
        end
    end
    % now we can create a training set for the current k-fold
    trainSetArray(:,d) = trainSetPrep; %assign product names to train set
    clear trainSetPrep %clear recycled variables
end
%% Create data tables for prediction
% Create an array with complexity metric names; these must be the same as variables names in inputVarNames
cMetNames = {'cMet_01', 'cMet_02', 'cMet_03', 'cMet_04', 'cMet_05', 'cMet_06', 'cMet_07', 'cMet_08',...
    'cMet_09', 'cMet_10', 'cMet_11', 'cMet_12', 'cMet_13', 'cMet_14', 'cMet_15', 'cMet_16', ...
    'cMet_17', 'cMet_18', 'cMet_19', 'cMet_20', 'cMet_21', 'cMet_22', 'cMet_23', 'cMet_24', ...
    'cMet_25', 'cMet_26', 'cMet_27', 'cMet_28', 'cMet_29'};
for d = 1:kFoldNum %loop for each k-fold
    % Convert training and test cell arrays into tables
    testSet = table(testSetArray(:,d),'VariableNames',{'vecName'});
    trainSet = table(trainSetArray(:,d),'VariableNames',{'vecName'});
    % Create an input array with complexity metrics and training targets
    for i = 1:height(trainSet) %loop over train set
        trainVecName = trainSet.vecName{i}; %
        for j = 1:height(rawInputData) %loop over raw data
            trainInputs(i,:) = rawInputData(strcmp(rawInputData.vecName,trainVecName),cMetNames);
            trainTargets(i,:) = rawTargetData(strcmp(rawTargetData.vecName,trainVecName),"Target");
        end
        clear trainVecName
    end
    % Create an test input arry with complexity metrics and test targets
    for i = 1:height(testSet) %loop over train set
        testVecName = testSet.vecName{i}; %
        for j = 1:height(rawInputData) %loop over raw data
            testInputs(i,:) = rawInputData(strcmp(rawInputData.vecName,testVecName),cMetNames);
            testTargets(i,:) = rawTargetData(strcmp(rawTargetData.vecName,testVecName),"Target");
        end
        clear testVecName
    end
    % debugging message
    disp('Vectors created!')
    % Train ANN structures with given input vectors and training targets
    % create an output file name
    outFileName = strcat(file(1:end-5),'_kFold_',num2str(d),'_OUTPUT.xlsx');
    % generate a train input and target vector
    trainInputVec = trainInputs{:,:};
    trainTargetVec = trainTargets{:,:};
    % run training function to generate ANN structure
    [tNet] = trainArchPop_v5_batch(trainInputVec, trainTargetVec);
    % Analyze ANN structures with test vectors and targets
    % generate a test input and target vectors
    testInputVec = testInputs{:,:};
    % testTargetVec = testTargets{:,:};
    % Test ANN structures created earlier
    [outTrainSet, outTestSet] = analyzeANN_v5_batch(trainInputVec, testInputVec, tNet);
    writematrix(outTrainSet, outFileName, 'Sheet', 'Train'); %write training predictions
    writematrix(outTestSet, outFileName, 'Sheet', 'Test'); %write test predictions
    % clear recycled variables
    clear testSet trainSet %from creating training and test tables
    clear outFileName trainTargetVec trainInputVec tNet %training the ANN
    clear testInputVec outTestSet outTrainSet %analysing the ANN
    % debugging message
    disp('ANN predictions for current k-fold complete!')
end