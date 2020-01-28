% Compute data quality metrics
%       
%       sixtyNoise: the max power around 60 Hz & harmonics
%       SNR: ratio between power in signal band and power in noise band
%       baseNoise: min value of rectified, filtered, & binned signal
%       highAmp: percentage of data that lies outside of N std devs
%       shapeScore: *disregard* old metric from template-maching
%

function [sixtyNoise, SNR, baseNoise, highAmp, shapeScore, Pxx, Fxx, normPower, normTemplate] = getDQMetrics(emgData, params, templateCurves)
    
    %[Pxx,Fxx] = pwelch(double(emgData), params.filterWindow, [], [], 2000); %2000 should be dynamic
    [Pxx, Fxx] = pwelch(double(emgData), params.filterWindow, [], [], params.frequency);
   
    SNR = getSNR(params, Pxx, Fxx);
    baseNoise = getBaseNoise(emgData, params);
    highAmp = getHighAmp(emgData, params);
    sixtyNoise = getSixtyNoise(Pxx, Fxx, params.harmonicWindowSize);
    
    if exist('templateCurves', 'var') && templateCurves ~= 0
        [shapeScore, normPower, normTemplate] = getShapeScore(Pxx, Fxx, templateCurves);
    else
        shapeScore = 0;
        normPower = 0;
        normTemplate = 0;
    end
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

    SNR = signalMax / noiseMax;
end


function [baseNoise] = getBaseNoise(emgData, params)

    [B,A] = butter(2, params.highPass/params.frequency*2, 'high');
    [D,C] = butter(2, params.lowPass/params.frequency*2, 'low');

    envelopes = filtfilt(D, C, abs(filtfilt(B,A,double(emgData))));
    binnedEnv = binEmg(envelopes, 0.05);
    
    binnedEnv = sort(binnedEnv, 'ascend');
    baseNoise = mean(binnedEnv(1:10));
    %baseNoise = min(binnedEnv);
    
end


function binnedEmg = binEmg(emg, binSize)
    
    binnedTs = 1:binSize*30000:length(emg);
    emg = emg / norm(emg);
    binnedEmg = zeros(length(binnedTs) - 1, 1);

    for i = 1:length(binnedTs) - 1
        thisBin = emg(binnedTs(i):binnedTs(i+1));
        binnedEmg(i) = sum(thisBin);
        %binnedEmg(i) = mean(thisBin) * 100; %should this be a sum..?
    end
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