%plotting function for emg dq
%
%   inputs: 
%           dqAnalysis
%           plotIdx: indices of dqAnalysis
%
%   Josie Wallner - March 28, 2019 

function [] = plotDQ_noTemplates(dqAnalysis, plotIdx, runningMuscleCount)
    
    displayAcross = 2;
    numberOfPlots = length(plotIdx);

    figure
    ha = tight_subplot(numberOfPlots, displayAcross, [.05 .05], [.05 .05], [.05 .05]);

    for i = 1:numberOfPlots
        %figure out file number
        for j = 1:length(runningMuscleCount)
            if plotIdx(i) <= runningMuscleCount(j)
                fileNum = j;
                if j == 1
                    muscleNum = plotIdx(i);
                else
                    muscleNum = plotIdx(i) - runningMuscleCount(j-1);
                end
                break
            end
        end
        
        metrics = dqAnalysis{fileNum}.metrics(muscleNum);
       
        plotData  = metrics.rawData;
        label = dqAnalysis{fileNum}.labels{muscleNum};
        if strcmpi(label(1:4), 'EMG_')
            nameParts = strsplit(label, '_');
            label = nameParts{2};
        end
        monkey = dqAnalysis{fileNum}.monkey;
        
        time = 0:0.0005:(length(plotData) - 1) * 0.0005;
        Fxx = metrics.Fxx;
        Pxx = metrics.Pxx; normPxx = Pxx / norm(Pxx);

        axes(ha(2*i - 1)) %#ok<LAXES>    
        plot(Fxx, normPxx, 'k-'); hold on
        title([label ' ; ' monkey])
        axis tight; xlim([0 450])
        eval(['ylim([0 ' num2str(findYLim(normPxx, normPxx, Fxx)) '])'])

        axes(ha(2*i)) %#ok<LAXES> 
        plot(time, plotData);
        axis tight; xlim([100 110])
        title(['SNR: ' num2str(round(metrics.SNR*100)/100) ...
            '  baseNoise: ' num2str(round(metrics.baseNoise*100)/100) ...
            '  highAmp: ' num2str(round(metrics.highAmp*100)/100) ...
            '  sixtyNoise: ' num2str(round(metrics.sixtyNoise*100)/100)])
    end
    set(ha(1:end),'TickDir','out'); set(ha(1:end),'Box','off'); set(ha(1:end), 'YTickLabel', ''); set(ha(1:end), 'YTick', [])
end