%{

Helper function for plotting emg spectra; returns limit for y-axis when
plotting raw spectra to avoid large 60-Hz peaks from obscuring the signal.
-------------------------------------------------------------------------
Inputs:
    normPxx: normalized raw spectra of signal being analyzed
    normTemplate: normalized raw spectra of template signal

Outputs:
    yLimit: the max normalized power of both signals that lies outside of
            60-Hx & harmonic bands

Written by Josephine Wallner on March 22, 2019

%}

function [yLimit] = findYLim(normPxx, normTemplate, Fxx)
    
    yLimit = 0;
    signalBands = [1 45; 75 105; 135 165; 195 225; 245 285; 315 345; 375 405; 435 length(normTemplate)];
    
    %find when Fxx is within signalBands
    for i = 1:length(signalBands)
        idx = find(Fxx >= signalBands(i,1) & Fxx <= signalBands(i,2));
        sigMax = max(normPxx(idx));
        tempMax = max(normTemplate(idx));
      
        thisMax = max(sigMax, tempMax);
        yLimit = max(yLimit, thisMax);
    end
    
   
end