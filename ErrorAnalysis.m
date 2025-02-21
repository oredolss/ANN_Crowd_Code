function [ testErrors, Errors, Prediction ] = ErrorAnalysis( outputSet,partName,target )
%ERRORANALYSIS Summary of this function goes here
%   Detailed explanation goes here
    %% Calculate the mean prediction and percent error for test parts
    r = 6; %specify the number of rows you need
    Prediction = zeros(r,length(partName)); %empty cell array for predictions
    testErrors = zeros(r+1,length(partName)+1); %empty cell array for excel output
    testErrors = num2cell(testErrors);
    for n = 1:length(partName)
        Prediction(1,n) = target(1,n);  %target
        Prediction(2,n) = mean(outputSet(:,n)); %prediction
        Prediction(3,n) = Prediction(2,n)- target(1,n); %residual
        Prediction(4,n) = abs(Prediction(2,n)- target(1,n))/target(1,n);    %std error
        Prediction(5,n) = abs(Prediction(2,n)- target(1,n))^2/abs(target(1,n)*Prediction(2,n)); %norm error
    end
    for n = 1:length(partName)
        Prediction(6,n) = colorCodes( Prediction,target,1,n );  %color
    end
    testErrors(1,[2:end]) = partName;
    testErrors([2:end],1) = {'Target';'Prediction';'Residual';'Standard E';'Normalized E';'Color'};
    Prediction = num2cell(Prediction);
    testErrors([2:end],[2:end]) = Prediction;

end

