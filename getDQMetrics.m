% write a quick summary header
function [sixtyNoise, SNR, baseNoise, highAmp, shapeScore, Pxx, Fxx, normPower, normTemplate] = getDQMetrics(emgData, params, templateCurves)
    
    [Pxx,Fxx] = pwelch(double(emgData), params.filterWindow, [], [], 2000);
    
    SNR = getSNR(params, Pxx, Fxx);
    baseNoise = getBaseNoise(emgData, params);
    highAmp = getHighAmp(emgData, params);
    [shapeScore, normPower, normTemplate] = getShapeScore(Pxx, Fxx, templateCurves);
    sixtyNoise = getSixtyNoise(Pxx, Fxx, params.harmonicWindowSize);

end

function [sixtyNoise] = getSixtyNoise(power, freq, windowSize)

    sixtyNoise = 1;
    
    for i = [60 120 180 240 300 360 420]       
        noiseMax = max(power(freq > i - windowSize & freq < i + windowSize));        
        powBelow = power(find(freq < i - windowSize, 1, 'last'));
        powAbove = power(find(freq > i + windowSize, 1, 'first'));
        surroundingSignal = (powBelow + powAbove) / 2;
     
        thisSixtyNoise = noiseMax / surroundingSignal;
        sixtyNoise = max(sixtyNoise, thisSixtyNoise);
    end
    
end


function [SNR] = getSNR(params, Pxx, Fxx)
    
    noiseMax = max(Pxx(Fxx <= params.noiseBand(2) & Fxx >= params.noiseBand(1)));
    
    %find signalMax, ignoring 60 harmonics
    harmonics = [60 120 180 240 300 360 420];
    inRange = find(harmonics >= params.signalBand(1) & harmonics <= params.signalBand(2));
    
    firstStart = params.signalBand(1);
    firstStop = harmonics(inRange(1)) - 10;
    signalMax = max(Pxx(Fxx >= firstStart & Fxx <= firstStop));
    
    for i = inRange(1:end-1)
        start = harmonics(i) + 10;
        stop = harmonics(i+1) - 10;
        thisMax = max(Pxx(Fxx >= start & Fxx <= stop));
        signalMax = max(thisMax, signalMax);        
    end
    lastStart = harmonics(inRange(end)) + 10;
    lastStop = params.signalBand(2);
    signalMax = max(max(Pxx(Fxx >= lastStart & Fxx <= lastStop)), signalMax);

    SNR = signalMax / noiseMax; %consider other calcs for SNR
    
end


function [baseNoise] = getBaseNoise(emgData, params)

    [B,A] = butter(2, params.highPass/params.frequency*2, 'high');
    [D,C] = butter(2, params.lowPass/params.frequency*2, 'low');

    envelopes = filtfilt(D, C, abs(filtfilt(B,A,double(emgData))));
    baseNoise = min(abs(envelopes));
end


function [highAmp] = getHighAmp(emgData, params)

    stdDev = std(double(emgData));
    highAmpIdx = find(emgData > stdDev * params.stdDevs);
    highAmp = length(highAmpIdx) / length(emgData);
    
end

function [shapeScore, normPower, normTemplate] = getShapeScore(Pxx, Fxx, template)
    
    %normalize
    normPower = normalizeSpectrum(Fxx, Pxx);
    normTemplate = normalizeSpectrum(template.freq, template.power);
    
    deltaSignal = abs(normPower - normTemplate);
    meanPrctDiff =  nanmean(deltaSignal ./ normTemplate);
    
    shapeScore = meanPrctDiff;
    
end

function [normalizedPower] = normalizeSpectrum(Fxx, Pxx)
    
    %pre-allocate
    power = zeros(size(Pxx));
    
    %need 2 chunks: 1-actual data; 2-forced continuities
    start = 1;
    for i = 1:6
        
        %compute for 60*i Hz
        startIdx = find(Fxx > 60*i - 7 & Fxx < 60*i -5);
        endIdx = find(Fxx > 60*i + 5 & Fxx < 60*i + 7);
        xStart = Fxx(startIdx); yStart = max(Pxx(startIdx));
        xEnd = Fxx(endIdx); yEnd = max(Pxx(endIdx));
        coeffs = polyfit([xStart,xEnd], [yStart,yEnd], 1);
                 
        %add in actual data
        power(start:startIdx-1) = Pxx(start:startIdx-1);
         
        %estimate & add in forced continuities
        currentStretch = coeffs(1) * Fxx(startIdx:endIdx) + coeffs(2);
        power(startIdx:endIdx) = currentStretch;
        
        if i == 6, power(endIdx,end) = Pxx(endIdx,end); end % add last chunk
         
        start = endIdx + 1; %update start
    end    
    normalizedPower = power / norm(power);   
end