%% Set Parameters
params.signalBand = [198 402];
params.noiseBand = [8 27];
params.filterWindow = 1000;
params.highPass = 300;
params.lowPass = 10;
params.frequency = 2000; %should read from file
params.stdDevs = 2; %defines high-amp artifact
params.harmonicWindowSize = 8;

serverFolder = '/Users/josephinewallner/Desktop/Data2Process/';
workingFolder = '/Users/josephinewallner/Desktop/LabWork/Miller Lab/Data Quality/working/';
templates = '/Users/josephinewallner/Desktop/LabWork/Miller Lab/Data Quality/templateSpectra.mat';
addpath('/Users/josephinewallner/Desktop/LabWork/Miller Lab/Data Quality/EMG Data')
addpath('/Users/josephinewallner/Desktop/LabWork/Miller Lab/Data Quality/my functions')
addpath('/Users/josephinewallner/Desktop/LabWork/Miller Lab/ClassyDataAnalysis/lib/NPMK/')
load(templates)

%% Get folder contents
contents = dir(serverFolder);
count = 0;
for i = 1:length(contents)   
    nameParts = strsplit(contents(1).name, '.');
    if strcmp(nameParts{2}, 'ns3')
        count = count + 1;
        files{count} = contents(i).name; %#ok<*SAGROW>
    end  
end

%% Process each file in folder
for i = 1:length(files)  
    fileName = files{i};
    try
        dqAnalysis{i} = dqFileWrapper(fileName, serverFolder, workingFolder);
    catch
        display(['mission aborted for ' fileName])
        %create entry in DJ error table, and continue processing
    end
end
    
