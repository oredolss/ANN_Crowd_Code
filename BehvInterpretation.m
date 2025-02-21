%BehvInterpretation This script will take the numeric coding for behaviors
%and output understandable interpretations
% 
% 
clear; clc;
%% Request input file and check the required files
[file, path, ~] = uigetfile('*.xlsx', 'Pick an excel file with arch interpretations');
inputFile = strcat(path, file);
% Define sheet to read
sheetName = 'AM-AT';
% Read raw data into a table
rawData = readtable(inputFile, 'Sheet', sheetName);
% Get variable names from the read table to create column headers that can be used for filtering/trimming the table.
varNamesAll = rawData.Properties.VariableNames; %all vars
varNamesMetaData = varNamesAll(1:5); %just properties and product name
varNamesData = varNamesAll(6:end); %just architecture behavior data
% Import property data from Excel file
% Since we need to use "readtable" function, we will need to create an options structure to specify how to import the file
numVars = 9; %number of variables
varType = {'categorical', 'int8', 'int8', 'categorical', 'categorical', 'int8', 'int8', 'int8', 'double'};
dataStartLoc = 'A2';
opts = spreadsheetImportOptions('Sheet',sheetName, 'DataRange', dataStartLoc,...
    'NumVariables',numVars, 'VariableNames', varNamesAll, 'VariableTypes', varType);
% Import Excel data using readtable
behvData = readtable(inputFile,opts);
%% Apply interpretation to each row in behavior data
for p = 1:height(behvData)
    normality(p,1) = {evaluateNormality(behvData.Normality(p))};
    centrality(p,1) = {evaluateCentrality(behvData.Centrality(p),behvData.CrowdError(p))};
    width(p,1) = {evaluateWidth(behvData.Width(p))};
end
