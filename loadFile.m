%1. connect to server
%2. locate & download file
%3. find emg data, muscle names, sampling freq, etc - will need regex

function [data, labels, labelIdx, monkey] = loadFile(fileName, serverLocation, workingFolder)

    copyfile([serverLocation fileName], workingFolder);
    
    
    if exist([workingFolder, fileName], 'file') ~= 2
        error('There was an issue copying the file from the server. Check server connection and file path')
    end
    
    NS3 = openNSx(strcat(workingFolder, fileName));
    
    %find emg data
    %usually NS3.Data or NS3.Data{1,2}
    %need some way to specify where data is - could 
    %                   1. throw an error
    %                   2. quarantine weird files
    if size(NS3.Data,1) > 5, data = NS3.Data;
    else
        data = input('Where is the data?');
    end
    
    %find emg labels
    [labels, labelIdx] = getLabels(NS3.ElectrodesInfo);
    
    %orient emg data
    if size(data,1) > size(data,2), data = data.'; end
    
    %get monkey name
    nameParts = strsplit(fileName, '_');
    monkey = deblank(nameParts{1});
    
    %remove from working folder
    delete(strcat(workingFolder, fileName))
end


function [labels, labelIdx] = getLabels(electrodeInfo)

    count = 0;
    for i = 1:length(electrodeInfo)
        if ~strcmp(electrodeInfo(i).Label(1:4),'elec')
            count = count + 1;
            labels{count} = deblank(electrodeInfo(i).Label); %#ok<AGROW>
            labelIdx{count} = i; %#ok<AGROW>
        end
    end
    
end