%Data Quality - Threshold Crossings
%This function looks at a 1 second segment of the data to analyze
%the file's quality.
% --------------------------------------------------------------------------
%The following DQ metrics are computed:
%    Cross Channel Artifact - any interval of X_CHAN_WINDOW length
%                             containing > MAX_NUM_CHAN threshold crossings
%
%    High Amplitude Artifact - any threshold crossing containing a waveform
%                              value > MAX_AMP
%
%           NOTE: this function does not alter the files


%Changes needed to interface with DB:
%       1. read data tables - need to figure out permissions and SQL
%          querying through Matlab
%       2. parse through server to locate files
%       3. download file (one at a time)
%       4. error redirection to prevent processing from stopping
%       5. 
%% Set Parameters

FILE_NAME = 'Butter_20190104_CO_cuneate_001.nev'; %extension needed here
DIRECTORY = '/Users/josephinewallner/Desktop/LabWork/Miller Lab/Data Quality/Spike Data';

MAX_NUM_CHAN = 29; 
X_CHAN_WINDOW = 1;
%INVALID_UNIT = 255;
MAX_AMP = 2500; % (1 mV) what is the rationale behind this cutoff?
ANALYSIS_WINDOW_LENGTH = 10000; %length of data to be analyzed - in ms
ANALYSIS_WINDOW_START = 60000; %start 1 minute in
SAMPLING_FREQ = 30000; %spikes always collected at 30k

%% Load Data

addpath('/Users/josephinewallner/Desktop/LabWork/Miller Lab/ClassyDataAnalysis/lib/NPMK');
fullPath = [DIRECTORY '/' FILE_NAME];

NEV = openNEV(fullPath,'read','nosave','nomat');

%% Cross Channel Artifact

numWindows = ANALYSIS_WINDOW_LENGTH / X_CHAN_WINDOW;
timeSeconds = NEV.Data.SerialDigitalIO.TimeStampSec;

% time = cast(NEV.Data.Spikes.TimeStamp,'double');
% timeSeconds = time / 30000;

numArtifacts = 0;
maxXChan = 0;
minXChan = 30;
windowCounts = zeros(numWindows,1);

tic
for i = 1:numWindows
    windowBegin = (ANALYSIS_WINDOW_START + X_CHAN_WINDOW * (i-1));
    windowEnd = (windowBegin + (X_CHAN_WINDOW));
    
    windowBegin = windowBegin /1000; %convert to seconds
    windowEnd = windowEnd / 1000;
    
    crossings = find(timeSeconds >= windowBegin & timeSeconds < windowEnd);
    windowCounts(i) = length(crossings);
    
    %within a window - get all threshold crossings. are there 30 or more?
    if length(crossings) > MAX_NUM_CHAN
        numArtifacts = numArtifacts + 1;
    end
    
    maxXChan = max(maxXChan,length(crossings));
    minXChan = min(minXChan,length(crossings));
end
toc

prctXChanArt = numArtifacts / numWindows;

%% High Amplitude Artifact

analysisWindowLength = 150000; %in ms
windowBegin = ANALYSIS_WINDOW_START;
windowEnd = ANALYSIS_WINDOW_START + analysisWindowLength;
windowBegin = windowBegin / 1000; windowEnd = windowEnd / 1000;
waveform = NEV.Data.Spikes.Waveform;

tic
crossings = find(timeSeconds >= windowBegin & timeSeconds < windowEnd);

highAmpCount = 0;
highAmpIndices = zeros(analysisWindowLength,1);
for i = 1:length(crossings)
    waveformInd = crossings(i);
    if max(waveform(:,waveformInd)) > 255
        highAmpCount = highAmpCount + 1;
        highAmpIndices(i) = max(waveform(:,waveformInd));
    end    
end
toc

prctHighAmpArt = highAmpCount / length(crossings);
