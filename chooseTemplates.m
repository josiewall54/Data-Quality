%% Choose template spectra

% 1. start with matrix of emg data for 4 trial dates, close to implant date

% 2. plot 5 muscles at a time, display spectra from all 4 dates, pick best
% ones

% 3. compile chosen spectra and add to templateSpectra.mat

%% Load tempOptions

cd('/Users/josephinewallner/Desktop/LabWork/Miller Lab/Data Quality')
load('tempOptions')
monkey = 'Han';
eval(['tempOptions = tempOptions' monkey ';']);

numberOfMuscles = size(tempOptions.emgData,2);
numberOfDates = size(tempOptions.emgData,1);

choice = zeros(1,22);
for i = 1:numberOfMuscles
   figure
   for j = 1:numberOfDates
       data = tempOptions.emgData{j,i};
       subplot(numberOfDates, 1, j)
       time = 0:0.0005:(length(data) - 1) * 0.0005;
       plot(time,data)
       xlim([50 100])
   end
   choice(i) = input('Which one looks the best? ');
   close
end

%eval(['tempOptions' monkey '.choices = ' choice ';']);

%% Create the templates from data & choices

for i = 1:numberOfMuscles
    template.emgData{i} =  tempOptions.emgData{choice(i),i};
    template.muscleName{i} = tempOptions.muscleName{i};
    template.trialDate{i} = tempOptions.trialDate{choice(i)};
end

eval(['template' upper(monkey(1)) monkey(2:end) ' = template;'])