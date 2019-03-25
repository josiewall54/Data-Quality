%Data Quality - EMG

%For each muscle:
%   1. Start one minute into the data file
%   2. Run the following analyses on full dataset:
%           high amplitude artifact
%   3. Run the following analyses on 30 secs (?) of the dataset:
%           SNR
%           cross-channel
%------------------------------------------------------------------------
%To store the information:
%   how granular do we want this information?
%   top level - boil down to a single DQ number for a file
%       things to consider here
%                    number of "good" muscles - all 3 metrics over thresh
%                    quality of "good" muscles - average metrics
%   mid level - ability to identify what is affecting the DQ score
%       thoughts:
%           1. what if the single muscle we want is actually great?
%           2. how much 60 Hz noise & harmonics? could look at power ~60
%           compared to neighboring frequencies
%           3. 
%% File Location

fileName = '20181005_Greyson_isoWF_002.ns3';
folder = '/Users/josephinewallner/Desktop/LabWork/Miller Lab/Data Quality/EMG Data';

%% Load in Data

addpath('/Users/josephinewallner/Desktop/LabWork/Miller Lab/ClassyDataAnalysis/lib/NPMK');
addpath('/Users/josephinewallner/Desktop/LabWork/Miller Lab/Data Quality/EMG Data');
fullFilePath = [folder '/' fileName];
NS3 = openNSx(fullFilePath);
%emgData = NS3.Data{1,2};
emgData = NS3.Data;
numSigs = size(emgData,1);

%% Set Parameters

STD_DEVS = 2; %define high-amp artifact
ANALYSIS_LENGTH = 30; % in seconds
ANALYSIS_START = 60; % in seconds
MAX_SIGS = 6;

%% For new wireless system
rawNames = cell(32,1);
channelNames = cell(32,1);
for i = 1:32
    %split = strsplit(name, '_');
    rawNames{i} = amplifier_channels(i).custom_channel_name;
    temp = strsplit(rawNames{i},'_');
    channelNames{i} = temp{1};
end

uniqueNames = unique(channelNames);

%subtract differentials
emgData = zeros(length(uniqueNames), length(amplifier_data));
for i = 1:length(uniqueNames)
    name = uniqueNames{i};
    if strcmp(name,'ECR')
        idx1 = find(strcmp(rawNames, [name '_2']));
        idx2 = find(strcmp(rawNames, [name '_3']));
    else
        idx1 = find(strcmp(rawNames, [name '_1']));
        idx2 = find(strcmp(rawNames, [name '_2']));      
    end
    emgData(i,:) = amplifier_data(idx2,:) - amplifier_data(idx1,:);
end

numSigs = size(emgData,1);
%% Power ratio - SNR?
%double check in Steph's code - does this look similar?

%preallocate
power = cell(numSigs, length(emgData)); 
frequency = power;
maxAround200 = cell(1,numSigs);
maxAround10 = maxAround200;
SNR = maxAround10;

for i = 1:numSigs
    [Pxx,Fxx] = pwelch(double(emgData(i,:)), 20000, [], [], 2000);
    
    %remove 60 & harmonics, find peak
%     freq = [58:62, 118:122, 178:182, 238:242];
     ind = find((Fxx >= 58 & Fxx <= 62) ); %|...
%                 (Fxx >= 118 & Fxx <= 122) |...
%                 (Fxx >= 178 & Fxx <= 182)|...
%                 (Fxx >= 242 & Fxx <= 238));
     PxxNew = Pxx;
     PxxNew(ind) = 0;
     power{i} = PxxNew; frequency{i} = Fxx;
%    power{i} = Pxx; frequency{i} = Fxx;
    
    maxAround200{i} = max(Pxx(Fxx <= 202 & Fxx >= 198));
    maxAround10{i} = max(Pxx(Fxx <= 12 & Fxx >= 8));

    SNR{i} = maxAround200{i} / maxAround10{i}; %is this SNR?
        
end
%% visualize spectra
displayAcross = 2;
displayDown = ceil(MAX_SIGS / displayAcross); 

figure %not finished!!
hold on
for i = 1:MAX_SIGS
    subplot(displayDown, displayAcross, i);
    plot(frequency{i},power{i})
    %title(uniqueNames{i}); %for .rhd files
    
    title(deblank(NS3.ElectrodesInfo(i).Label)); %for .ns3 files
    
    axis tight
    xlim([0 600]);
    
    %scatter(Fxx(Pxx == maxAround200{i}),maxAround200{i},'r','*');
    %scatter(Fxx(Pxx == maxAround10{i}),maxAround10{i},'r','*');
end

%try low pass filter - what do the plots look like after?

%% baseline -- is envelope min noisy?

%check min - should this be an absolute value, or a propotion?
envelopes = zeros(size(emgData));
minEnv = zeros(size(emgData,1),1);

[B,A] = butter(2, 300/1000, 'high');
[D,C] = butter(2, 10/1000, 'low');

for i = 1:numSigs
    sig = double(emgData(i,:));
    envelopes(i,:) = filtfilt(D, C, abs(filtfilt(B,A,sig)));
    
    minEnv(i) = min(abs(envelopes(i,:)));
end

%% High amp artifact

prctHighAmp = zeros(1, numSigs);
dataLength = length(emgData);
for i = 1:numSigs
    stdDev = std(double(emgData(i,:)));
    highAmp = find(emgData(i,:) > stdDev * STD_DEVS);
    prctHighAmp(i) = length(highAmp) / dataLength;
end
  
%% Visualize Signals

displayAcross = 2;
displayDown = ceil(MAX_SIGS / displayAcross);

%get emg labels
muscles = cell(1, size(emgData,1));
for i = 1:numSigs
    muscles{i} = NS3.ElectrodesInfo(i).Label;
end
muscles = regexprep(muscles, '\W', '');

%plot signals
figure
for i = 1:MAX_SIGS
    subplot(displayDown,displayAcross,i);
    plot(emgData(i,:));
    title([strrep(muscles{i},'EMG_','') newline 'HA:', num2str(round(prctHighAmp(i)*100)) '%' ...
                          ' ; SNR: ', num2str(round(SNR{i}*100)/100)...
                          '; BN: ' num2str(minEnv(i))]);
    axis tight;
end

%% Visualize Signals - simple

displayAcross = 2;
displayDown = ceil(numSigs / displayAcross);
time = 0:0.0005:(length(emgData) - 1)*0.0005;

figure
for i = 1:numSigs
    subplot(displayDown,displayAcross,i);
    plot(time(1000:20000), emgData(i,1000:20000));
    %xlim([1000 1500])
    %title(uniqueNames(i)); %for wireless .rhd files
    title(deblank(NS3.ElectrodesInfo(i).Label)); %for .ns3 files
    axis tight
end

%% Combo Plots

displayAcross = 3;
time = 0:0.0005:(length(emgData) - 1) * 0.0005;
sigsOfInterest = [1 3 4 5 8 9 15];

figure
for i = 1:length(sigsOfInterest)
    [Pxx,Fxx] = pwelch(double(emgData(sigsOfInterest(i),:)), 1000, [], [], 2000);
    power{i} = Pxx; frequency{i} = Fxx;
    
    %remove 60 & harmonics   
    ind = find((Fxx >= 55 & Fxx <= 65)); PxxNew = Pxx; PxxNew(ind) = 0;

    snr = max(Pxx(Fxx <= 402 & Fxx >= 198)) / max(Pxx(Fxx <= 12 & Fxx >= 8)); %is this SNR?
    
    subplot(length(sigsOfInterest), displayAcross, 3*i - 2);
    plot(Fxx,PxxNew); axis tight
    hold on
    idx = find(Fxx <= 400);
    %p = polyfit(Fxx(idx),PxxNew(idx),4); y = polyval(p,Fxx(idx));
    %plot(Fxx(idx), y(idx), 'r-')
    %title(num2str(round(snr*100)/100))
    
    subplot(length(sigsOfInterest), displayAcross, 3*i - 1);
    plot(time, emgData(sigsOfInterest(i),:)); axis tight
    xlim([500 510])
    titleRaw = strsplit(deblank(NS3.ElectrodesInfo(sigsOfInterest(i)).Label), '_');
    title([titleRaw{2} ' (' num2str(round(snr*100)/100) ')'])
    %title(uniqueNames(sigsOfInterest(i)))
    
    subplot(length(sigsOfInterest), displayAcross, 3*i);
    plot(time, emgData(sigsOfInterest(i),:)); axis tight   
end

for i = 1:4
    badSigs.filename{i} = 'Han_20171201_EMGextra_COactpas_001.ns3';
end
