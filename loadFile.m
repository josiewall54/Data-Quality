%1. connect to server
%2. locate & download file
%3. find emg data, muscle names, sampling freq, etc - will need regex

function [data, labels, labelIdx, monkey, date, frequency] = loadFile(fileName, serverLocation, workingFolder)

    try
        copyfile([serverLocation fileName], workingFolder);
    catch
        disp('There was an issue copying the file from the server. Check server connection and file path')
    end
        
    
    if exist([workingFolder, fileName], 'file') ~= 2
        error('There was an issue copying the file from the server. Check server connection and file path')
    end

    NS3 = openNSx(strcat(workingFolder, fileName));
    frequency = NS3.MetaTags.SamplingFreq;
    
    %find emg data
    %usually NS3.Data or NS3.Data{1,2}
    if size(NS3.Data,1) > 5, data = NS3.Data;
    else
        disp(['NS3.Data: ' num2str(size(NS3.Data))]);
        for i = 1:length(NS3.Data)
            disp(['NS3.Data{' num2str(i) '} : ' num2str(size(NS3.Data{i}))])
        end
        data = input('Where is the data?');
    end
    
    %find emg labels
    [labels, labelIdx] = getLabels(NS3.ElectrodesInfo);
    
    %orient emg data
    if size(data,1) > size(data,2), data = data.'; end
    
    %get file info
    [monkey, date] = getTrialInfo(fileName);
    
    %remove from working folder
    delete(strcat(workingFolder, fileName))
end


function [labels, labelIdx] = getLabels(electrodeInfo)
    count = 0;
    for i = 1:length(electrodeInfo)
        if ~ (strcmp(electrodeInfo(i).Label(1:4), 'elec') || contains(electrodeInfo(i).Label, 'force', 'IgnoreCase', true))
            count = count + 1;
            labels{count} = deblank(electrodeInfo(i).Label); %#ok<AGROW>
            labelIdx{count} = i; %#ok<AGROW>
        end
    end    
end

function [monkey, date] = getTrialInfo(fileName)  

    monkeyNames = {'greyson', 'han', 'butter', 'crackle', 'jango', 'kevin', 'snap', 'arthur', 'fitz', 'pop'}; %obvi complete this, could pull from database table?
    nameParts = strsplit(fileName, '_');
    
    monkey = 'unknown'; date = 'unknown';
    for i = 1:length(nameParts)
        if max(ismember(monkeyNames, lower(nameParts{i}))) == 1
            monkey = nameParts{i};
        end
        
        if(regexp(nameParts{i}, '[0-9]{7,8}') == 1)
            date = nameParts{i};
        end          
    end  
end