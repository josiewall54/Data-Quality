% Wrapper function for assessing emg data quality - at the file level
%   loads data & computes DQ metrics
%
%   Inputs: fileName, serverFolder, workingFolder
%
%   Output: 
%       data - og data from file
%       labels - muscle labels
%       labelIdx - pointer from muscle labels to data positioning
%       monkey


function[dq] = dqFileWrapper(fileName, serverFolder, workingFolder, templates, params) %#ok<INUSL>

    [data, dq.labels, labelIdx, dq.monkey, dq.date, params.frequency] = loadFile(fileName, serverFolder, workingFolder); %download file from server, and find emg data
    dq.file = fileName;
    
    templateFlag = 0;
    % Compute Metrics
    if templateFlag
        load(templates) %#ok<LOAD>
        eval(['template = template' upper(dq.monkey(1)) lower(dq.monkey(2:end)) ';']);
    end
    
    for i = 1:length(dq.labels)
        
        %find template data
        if templateFlag
            muscleFound = 0;
            for j = 1:size(template.emgData,2)
                tName = deblank(template.muscleName{j});
                if(strcmpi(tName, dq.labels{i}) || strcmpi(tName, strcat('emg_',dq.labels{i})) || strcmpi(tName, strcat(dq.labels{i}, '_emg')))
                    templateData.power = template.power{j};
                    templateData.freq = template.freq{j};
                    muscleFound = 1;           
                    break
                end
            end     
            if ~muscleFound, error('Muscle template not found!'); end
        else
            templateData = 0;
        end
    
        dataIdx = labelIdx{i};
        dq.metrics(i).rawData = data(dataIdx,:);
        dq.metrics(i).templatePower = templateData;

        [dq.metrics(i).sixtyNoise, dq.metrics(i).SNR, dq.metrics(i).baseNoise, dq.metrics(i).highAmp,...
            dq.metrics(i).shapeScore, dq.metrics(i).Pxx, dq.metrics(i).Fxx,...
            dq.metrics(i).normPower, dq.metrics(i).normTemplate] = getDQMetrics(data(dataIdx,:), params, templateData);
    end
end