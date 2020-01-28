ecuRawData= dqAnalysis{1,1}.metrics(5).rawData;
ecuTime = 0:0.0005:(length(ecuRawData) - 1) * 0.0005;

threshold = std(double(ecuRawData)) * 5;
avg = mean(double(ecuRawData));

ecuClean = ecuRawData;
ecuClean(ecuClean > threshold) = avg;
ecuClean(ecuClean < -1 * threshold) = avg;

[Pxx,Fxx] = pwelch(double(ecuClean), 1000, [], [], 2000);

figure
subplot(2, 2, 1)
plot(dqAnalysis{1,1}.metrics(5).Fxx, dqAnalysis{1,1}.metrics(5).Pxx)
title('original signal - power spectrum')

subplot(2,2,2)
plot(ecuTime, ecuRawData)
title('original signal - data')

subplot(2,2,3)
plot(Fxx, Pxx)
title('cleaned signal - power spectrum')

subplot(2,2,4)
plot(ecuTime, ecuClean)
title('cleaned signal - data')



