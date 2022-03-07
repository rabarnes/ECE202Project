close all; clc;

s = load("waveIntan.mat", "waveformArray");
intan =  s.waveformArray;
clear("s");
s = load("wavePong.mat", "waveformArray");
pong =  s.waveformArray;
clear("s");



% calcEngeryAvg calculates the average of magnitude within the frequency
% range bounded by lowBoundFreq and upBoundFreq.
% inputs:   sampleData - sample data
%           Fs - Sampling Frequency
%           lowBoundFreq - lower bound of frequency
%           upBoundFreq  - upper bound of frequency
% output:   avg - the average of magnitude of the frequency range 
%
function avg = calcEnergyAvg(sampleData, Fs, lowBoundFreq, upBoundFreq)
    L = size(sampleData, 1);
    Y = fft(sampleData);
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    bins = chooseBins(Fs, L, lowBoundFreq, upBoundFreq);
    avg = sum(P1(bins)) / size(bins,1);
end


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
        if(binFreq <= upBoundFreq && binFreq >= lowBoundFreq)
            bins = [bins, binNum];
        end
    end
    if(size(bins,1) == 0)
        fprintf("Not enough resolution for bins!")
    end
end




