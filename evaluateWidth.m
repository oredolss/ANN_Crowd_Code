% Function to evaluate Width
function [width] = evaluateWidth(widthValue)
  if widthValue == 1
    width = 'Narrow';
  elseif widthValue == -1
    width = 'Wide';
  else
    width = 'Same';
  end
end