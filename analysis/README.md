This is MATLAB code for analysing behavioural and EEG data obtained using the looming detection paradigm described in the `README.md` files in the root of this repository, and in the paper linked from there. The paper also provides a full description of the analyses implemented here.

Parts of the analysis code makes use of EEGLAB functions (the code is verified to work with v14.1.1b); for EEGLAB download and installation instructions see here: https://sccn.ucsd.edu/eeglab/index.php

# Example use cases of this analysis code

## To recreate the figures in the paper

Download the contents of the `intermediate analysis results` folder of this OSF repository: https://doi.org/10.17605/OSF.IO/KU3H4, and put these files in the `analysis results` subfolder of this analysis repository. 

Then run any of the `do_fig_*.m` scripts. 

The figure script `do_fig_3_[...].m` uses EEGLAB functions, and therefore runs the `StartEEGLAB.m` script to add the EEGLAB directory to the MATLAB path and start EEGLAB to also put the EEGLAB functions on the MATLAB path. For this to work, you need to provide the path to your EEGLAB installation in the `c_SEEGLABPath` variable in `SetLoomingDetectionStudyAnalysisConstants.m`. Alternatively, if you have installed EEGLAB in such a way that all its functions are already on the MATLAB path, you can comment out the contents of `StartEEGLAB.m`.


## To run the entire analysis from scratch

Download the raw EEG and behavioural data in the `raw data` folder of the OSF repository linked in the previous section, to some location on your computer. Then edit the following lines of `SetLoomingDetectionStudyAnalysisConstants.m` to point to the right places on your computer (but see the note in the previous section about the EEGLAB path):

```matlab
% paths
% -- EEGLAB installation
c_SEEGLABPath = 'C:\EEGLAB\eeglab14_1_1b';
% -- locations of raw data from the study
c_sRawDataBasePath = 'D:\Looming detection study data\'; 
c_sResponseLogFilePath = [c_sRawDataBasePath 'behaviour\']; % raw response data files
c_sBioSemiLogFilePath = [c_sRawDataBasePath 'eeg biosemi\']; % raw Biosemi files
% -- location for intermediate EEG processing steps (quite large files)
c_sEEGAnalysisDataPath = 'C:\DATA\WT ISSF\2 Looming detection study\eeg analysis steps\';
c_sPREPReportPath = [c_sEEGAnalysisDataPath 'PREP reports\'];
```

The last two paths need to point to some existing location on your computer, to which intermediate processing steps will be saved during the EEG data postprocessing. 

Then run the scripts `do_1_[...].m`, `do_2_[...].m` and so on. After running all of those scripts (which should take about a week or two in total, on a typical computer), intermediate analysis results data will have been saved in the `analysis results` subfolder (and also a large number of intermediate results plots in the `analysis plots` subfolder), such that it is again possible to run the `do_fig_*.m` scripts to generate the figures in the paper.

