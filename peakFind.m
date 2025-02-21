function [peaks, peakLoc, tolCount, numNgbr] = peakFind(histBins, tolerance)
%peakFind This function will check the bin counts of a histogram to look for peaks.
%   Detailed explanation goes here
%   
%   histBins must be a 1-D horizontal array
%   tolerance must be a number between 0 and 1
%   
%% Pre-processing the list of bin counts
% Count number of bins (we must add to the number of bins for strating and trailing zeros). This is to allow for us to
% check if the first or last bins are peaks.
ngbrTol = 0.05; %define the tolerance you want to use for caclulating neighbor counts
numNgbr = ceil(ngbrTol*length(histBins)/2); %calculate the number of neighbors on each side.
numBins = 2*numNgbr + length(histBins); %increase the number of bins to account for padding zeros 
% find the max bin count and calculate tolerance value
maxCount = max(histBins);
tolCount = round(maxCount*tolerance);
% calculate a threshold for noteworthy bins
noteCount = round(0.2*maxCount);
% Pad the bin counts with zeros at both ends
padBins = [zeros(1,numNgbr),histBins,zeros(1,numNgbr)];
%% Scroll through the bin counts to check if any are peaks
peaks = 0; %initialize peak count
peakLoc = zeros([1,length(histBins)]);
for n = 1+numNgbr:numBins-(numNgbr) %loop over all entries of histBins
    if padBins(n) <= tolCount %if bin height is not greater than tolerance value, skip bin
        continue
    else %if bin height is above tolerance, compare to neighborhood
        hood = padBins(n-numNgbr:n+numNgbr); %define neighborhood around the current bin
        if padBins(n) == max(histBins) %if current bin is tallest in the histogram, check previous bin status
            if peakLoc(n-numNgbr-1) == 1 %if previous bin was called peak, move on to next bin
                continue
            elseif padBins(n) == max(hood) %if current bin is tallest in the neighborhood, mark peak
                peaks = peaks + 1; %increment the number of peaks
                peakLoc(n-numNgbr) = 1; %identify current location as a peak
            end
        elseif padBins(n) >= noteCount %if bin height is noteworthy but not max, do tolerance check
            hoodMax2 = maxk(hood,2); %find top 2 values in neighborhood 
            if padBins(n) - hoodMax2(2) > tolCount %if current bin is taller than next by tolerance, mark peak
                peaks = peaks + 1; %increment the number of peaks
                peakLoc(n-numNgbr) = 1; %identify current location as a peak
            else
                continue
            end
        else %if bin height is not noteworthy, check if bin is prominent in neighborhood
            hoodMax2 = maxk(hood,2); %find top 2 values in neighborhood
            if padBins(n) >= max([1.5*hoodMax2(2),4]) %we add the four to prevent small counts from being marked as peak
                peaks = peaks + 1; %increment the number of peaks
                peakLoc(n-numNgbr) = 1; %identify current location as a peak
            end
        end
    end
    clear hood
end