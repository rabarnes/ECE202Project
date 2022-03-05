close all; clc;

Fs = 8000
L = 4000


Y = fft(amplifier_data(8,1:L));
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:(L/2))/L;
plot(f, P1)

bins = chooseBins(Fs, L, 10, 13);




% chooseBins returns the bins in which the frequencies
% bounded by lowBoundFreq and upBoundFreq contains, with
% given sampling frequency Fs and Sample size L.
% inputs:   Fs - Sampling Frequency
%           L  - Sample Size
%           lowBoundFreq - lower bound of frequency
%           upBoundFreq  - upper bound of frequency
% output:   bins - array of int indicating the bin number 
%                  (matlab index)
%
function bins = chooseBins(Fs, L, lowBoundFreq, upBoundFreq)
    bins = [];
    for binNum = 1:L/2
        binFreq = Fs/(2*L)*(2*(binNum-1));
        if(binFreq < upBoundFreq && binFreq > lowBoundFreq)
            bins = [bins, binNum];
        end
    end
    if(size(bins,1) == 0)
        fprintf("Not enough resolution for bins!")
    end
end




