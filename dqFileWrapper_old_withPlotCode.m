%% Call quality measure functions, consolidate them onto summary plot & spit out reporta
function[dq] = dqFileWrapper()
    [data, labels, labelIdx, monkey] = loadFile(fileName, serverFolder, workingFolder); %download file from server, and find emg data
    %% Compute Metrics

    eval(['template = template' upper(monkey(1)) lower(monkey(2:end)) ';']); 
    dq.file = fileName;
    for i = 1:length(labels)

        %find template data   
        muscleFound = 0;
        for j = 1:size(template.emgData,2)
            if(strcmpi(deblank(template.muscleName{j}), labels{i}))
                templateData.power = template.power{j};
                templateData.freq = template.freq{j};
                muscleFound = 1;           
                break
            end
        end     
        if ~muscleFound, error('Muscle template not found!'); end

        dataIdx = labelIdx{i};
        dq.metrics(i).rawData = data(dataIdx,:);
        dq.monkey = monkey;
        dq.fileName = fileName;
        dq.metrics(i).templatePower = templateData;

        [dq.metrics(i).sixtyNoise, dq.metrics(i).SNR, dq.metrics(i).baseNoise, dq.metrics(i).highAmp,...
            dq.metrics(i).shapeScore, dq.metrics(i).Pxx, dq.metrics(i).Fxx,...
            dq.metrics(i).normPower, dq.metrics(i).normTemplate] = getDQMetrics(data(dataIdx,:), params, templateData);
    end

    %% Plot
    % add monkey name & date
    labels = dq.labels;
    
    displayAcross = 2;
    sigsOfInterest = 1:10;
    numberOfPlots = min(length(labels), length(sigsOfInterest));

    figure
    ha = tight_subplot(numberOfPlots, displayAcross, [.05 .05], [.05 .05], [.05 .05]);

    for i = 1:numberOfPlots
        plotData  = dq.metrics(sigsOfInterest(i)).rawData;
        label = labels{sigsOfInterest(i)};
        monkey = dq.monkey;
        time = 0:0.0005:(length(plotData) - 1) * 0.0005;
        Fxx = dq.metrics(sigsOfInterest(i)).Fxx; normPxx = dq.metrics(sigsOfInterest(i)).Pxx / norm(dq.metrics(sigsOfInterest(i)).Pxx);
        normTemplate = dq.metrics(sigsOfInterest(i)).templatePower.power / norm(dq.metrics(sigsOfInterest(i)).templatePower.power);

        axes(ha(2*i - 1)) %#ok<LAXES>    
        plot(Fxx, normPxx, 'k-'); hold on
        plot(Fxx, normTemplate, 'r-')
        title([label ' ; ' monkey])
        axis tight; xlim([0 450])
        eval(['ylim([0 ' num2str(findYLim(normPxx, normTemplate, Fxx)) '])'])

        eval(['template = template' upper(monkey(1)) lower(monkey(2:end)) ';']); 

        if i == 1
            h = zeros(2,1);
            h(1) = plot(NaN,NaN,'k');
            h(2) = plot(NaN,NaN,'r');
            legend(h, 'signal', 'template'); legend boxoff;
        end

        axes(ha(2*i)) %#ok<LAXES> 
        plot(time, plotData);
        axis tight; xlim([100 110])
        title(['SNR: ' num2str(round(dq.metrics(i).SNR*100)/100) ...
            '  shapeScore: ' num2str(round(dq.metrics(i).shapeScore*100)/100)...
            '  baseNoise: ' num2str(round(dq.metrics(i).baseNoise*100)/100) ...
            '  highAmp: ' num2str(round(dq.metrics(i).highAmp*100)/100) ...
            '  sixtyNoise: ' num2str(round(dq.metrics(i).sixtyNoise*100)/100)])
    end

    set(ha(1:end),'TickDir','out'); set(ha(1:end),'Box','off'); set(ha(1:end), 'YTickLabel', ''); set(ha(1:end), 'YTick', [])
end