% ------ Wrapper Function for EMG Data Quality --------
%   
%           This wrapper function runs through .ns3 files in a single
%           folder. Metrics are ran on each EMG signal and stored in a
%           single structure.
%
%           For speed and space reasons, I have designated a "server
%           folder" which stores the files you want to analyze, and a
%           "working folder" which is a temporary location on your computer
%           that each file willl get copied to before being analzyed.
%
%           Parameters explained:
%               signalBand - frequencies between which to look for power of signal
%               noiseBand - frequencies between which to look for power of noise
%               filterWindow - window size for computing power spectrum
%                           (spectrum is then used to compute SNR and sixtyNoise)
%               highPass - only used for baseNoise
%               lowPass - only used for baseNoise
%               stdDevs - number of std devs that define a high amp artifact
%               harmonicWindowSize - half of the window around
%                           sixty-harmonics. defines where to look 
%                           for power around harmonics
%
%   ** Can visualize the results using plotDQ_noTemplates.m **

%% Set Parameters
params.signalBand = [198 402];
params.noiseBand = [8 27];
params.filterWindow = 1000;
params.highPass = 10;
params.lowPass = 300;
params.stdDevs = 2; %defines high-amp artifact
params.harmonicWindowSize = 8;

addpath('C:\Users\jjw2788\Documents\GitHub\Data-Quality')
addpath('C:\Users\jjw2788\Documents\GitHub\ClassyDataAnalysis\lib\NPMK')
serverFolder = 'R:\Basic_Sciences\Phys\L_MillerLab\limblab\lab_folder\Projects\darpa\DS18(Jango_2015)\nev\';
%serverFolder = 'R:\Basic_Sciences\Phys\L_MillerLab\limblab\User_folders\Josie\Jango2015ns3\';
%serverFolder = 'R:\Basic_Sciences\Phys\L_MillerLab\limblab\lab_folder\Projects\darpa\Jango_2016\nev\temp\';
%serverFolder = 'R:\Basic_Sciences\Phys\L_MillerLab\limblab\lab_folder\Projects\darpa\DS24(Kevin_WF_2015)\nev\';
%serverFolder = 'R:\Basic_Sciences\Phys\L_MillerLab\limblab\User_folders\Josie\KO_ns3\';
workingFolder = 'C:\Users\jjw2788\Documents\working\';

%can ignore this
templates = 'R:\Basic_Sciences\Phys\L_MillerLab\limblab\User_folders\Josie\Data Quality\Templates\templateSpectra.mat';

%% Get folder contents
contents = dir(serverFolder);
count = 0;
%need some way to determine whether a file has emg or not -> might just
%have to open it up and look
for i = 1:length(contents)   
    nameParts = strsplit(contents(i).name, '.');
    if length(nameParts) > 1 && strcmp(nameParts{2}, 'ns4')
        count = count + 1;
        files{count} = contents(i).name; %#ok<*SAGROW>
    end  
end

%% Process each file in folder

for i = 1:length(files)  
    fileName = files{i};
    try
        dqAnalysis{i} = dqFileWrapper(fileName, serverFolder, workingFolder, templates, params); %consider loading templates at this level
    catch
        display(['mission aborted for ' fileName])
        %create entry in DJ error table, and continue processing
    end
end

%% Summary of Analyzed Files
runningIdx = 0;
for i = 1:length(dqAnalysis)
    muscleCount = length(dqAnalysis{1,i}.metrics);   
    for j = 1:muscleCount
        idx = runningIdx + j;
        summary{idx, 1} = idx;
        summary{idx, 2} = dqAnalysis{1,i}.monkey;
        summary{idx, 3} = dqAnalysis{1,i}.labels{j};
        summary{idx, 4} = dqAnalysis{1,i}.file;
        summary{idx, 5} = dqAnalysis{1,i}.metrics(j).sixtyNoise;
        summary{idx, 6} = dqAnalysis{1,i}.metrics(j).SNR;
        summary{idx, 7} = dqAnalysis{1,i}.metrics(j).baseNoise;
        summary{idx, 8} = dqAnalysis{1,i}.metrics(j).highAmp;
        summary{idx, 9} = flagMuscle(dqAnalysis{1,i}.metrics(j));
    end
    runningIdx = runningIdx + muscleCount;
    if i == 1
        runningMuscleCount(i) = muscleCount; 
    else
        runningMuscleCount(i) = runningMuscleCount(i-1) + muscleCount;
    end
end

summaryTable = array2table(summary);
summaryTable.Properties.VariableNames = {'Index', 'Monkey', 'Muscle', 'File', 'sixtyNoise', 'SNR', 'baseNoise', 'highAmp', 'flag'};

