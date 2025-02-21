function [normality] = evaluateNormality(normalityValue)
% Assuming high confidence is coded as 1 and low confidence as 0
  if normalityValue == 1
    normality = 'High';
  else
    normality = 'Low';
  end

end