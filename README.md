# Data-Quality
Automatic data quality metrics for EMG

This repo is for automatically evaluating the quality of EMG signals, written for .nsX files. 
'dqFolderWrapper.m' will run the following metrics on all files in a designated folder.


Metrics
------------------------------------------------------------------------------------------------------------------------------
      
      sixtyNoise: the max power around 60 Hz & harmonics
      SNR: ratio between power in signal band and power in noise band
      baseNoise: min value of rectified, filtered, & binned signal
      highAmp: percentage of data that lies outside of N std devs
      shapeScore: *disregard* old metric from template-maching
      
      
Parameters
------------------------------------------------------------------------------------------------------------------------------
     
     signalBand: frequencies between which to look for power of signal
      noiseBand: frequencies between which to look for power of noise
      filterWindow: window size for computing power spectrum (spectrum is then used to compute SNR and sixtyNoise)
      highPass: only used for baseNoise
      lowPass: only used for baseNoise
      stdDevs: number of std devs that define a high amp artifact
      harmonicWindowSize: half of the window around sixty-harmonics. Defines where to look for power around harmonics


Plotting
------------------------------------------------------------------------------------------------------------------------------

    - 'plotDQ_noTemplates.m' plots a specified subset of the output from 'dqFolderWrapper.m'
    - this will show the power spectra and data-quality metrics for each signal




Josie Wallner | October 9, 2019
