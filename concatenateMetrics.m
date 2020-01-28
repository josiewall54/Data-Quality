function [sixtyConcat, snrConcat, baseConcat, highConcat] = concatenateMetrics(metrics)
    
    [sixtyConcat, snrConcat, baseConcat, highConcat] = deal(cell(length(metrics), 1));
   
    for i = 1:length(metrics)
        sixtyConcat{i} = num2str(round(metrics(i).sixtyNoise, 3));
        snrConcat{i} = num2str(round(metrics(i).SNR, 3));
        baseConcat{i} = num2str(round(metrics(i).baseNoise, 3));
        highConcat{i} = num2str(round(metrics(i).highAmp, 3));
    end
    
    sixtyConcat = strjoin(sixtyConcat, ',');
    snrConcat = strjoin(snrConcat, ',');
    baseConcat = strjoin(baseConcat, ',');
    highConcat = strjoin(highConcat, ',');
    
end
