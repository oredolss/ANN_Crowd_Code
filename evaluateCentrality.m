% Function to evaluate Centrality (considering crowd average error direction)
function [centrality] = evaluateCentrality(centralityValue, crowdError)
  if crowdError > 0  % Positive crowd error
    if centralityValue == -1
      centrality = 'Good';
    elseif centralityValue == 0
      centrality = 'Neutral';
    else
      centrality = 'Bad';
    end
  elseif crowdError < 0  % Negative crowd error
    if centralityValue == -1
      centrality = 'Bad';
    elseif centralityValue == 0
      centrality = 'Neutral';
    else
      centrality = 'Good';
    end
  else  % Crowd error is 0 (special case)
    if centralityValue == -1 || centralityValue == 1
      centrality = 'Neutral';
    else
      centrality = 'Good';  
    end
  end
end
 