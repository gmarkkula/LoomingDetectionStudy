
% Copyright 2020 Gustav Markkula
%
% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (the
% "Software"), to deal in the Software without restriction, including
% without limitation the rights to use, copy, modify, merge, publish,
% distribute, sublicense, and/or sell copies of the Software, and to permit
% persons to whom the Software is furnished to do so, subject to the
% following conditions:
%
% The above copyright notice and this permission notice shall be included
% in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
% CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
% TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
% SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%
%%%%%% 
%
% See README.md in the root folder of the Github repository linked below 
% for more information on how to use this code, and a link to the paper 
% describing the study for which the code was developed. If you use this 
% code for your research, please cite that paper.
%
% Github repository: https://github.com/gmarkkula/LoomingDetectionStudy
% Open Science Framework repository: https://doi.org/10.17605/OSF.IO/KU3H4
%



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
% -- location for plots and analysis results (intermediate and final)
c_sAnalysisPlotPath = 'analysis plots\';
c_sAnalysisResultsPath = 'analysis results\';

% file names
% -- EEG data
c_sResampledFileNameFormat = 'EEG_1_resampled_%s.mat';
c_VidxParticipantIDInResampledFileName = ...
  GetParticipantIDRangeInFileNameFormat(c_sResampledFileNameFormat);
c_sRereferencedFileNameFormat = 'EEG_2_rereferenced_%s.mat';
c_VidxParticipantIDInRereferencedFileName = ...
  GetParticipantIDRangeInFileNameFormat(c_sRereferencedFileNameFormat);
c_sFilteredFileNameFormat = 'EEG_3_filtered_%s.mat';
c_VidxParticipantIDInFilteredFileName = ...
  GetParticipantIDRangeInFileNameFormat(c_sFilteredFileNameFormat);
c_sICAFileNameFormat = 'EEG_4_ICAweights_%s.mat';
% -- reports
c_sPREPSummaryFileNameFormat = 'PREPSummary_%s.html';
c_sPREPReportFileNameFormat = 'PREPReport_%s.pdf';
% -- collated data sets
c_sAllTrialDataFileName = 'AllTrialData.mat';
c_sModelFittingDataFileName = 'ModelFittingData.mat';
% -- models
c_sLambleEtAlDerivedPriorsFileName = ...
  'UniformPriorsFromLambleEtAlStudyFits.mat';
c_sModelFitAnalysisResultsMATFileName = ...
  'LoomingDetectionModelFitAnalysisResults.mat';
c_sBayesFactorsMATFileName = 'BayesFactors.mat';
c_sABCPosteriorsMATFileName = 'ABCPosteriors.mat';
c_sCPPOnsetMATFileName = 'CPPOnsetResults.mat';
c_sMLFittingMATFileName = 'MLFittingResults.mat';
c_sLikelihoodTestsMATFileName = 'LikelihoodTestResults.mat';
c_sSimulationsForFigsMATFileName = 'MLESimulationsForFigures.mat';
c_sSimulationsForERPFigsMATFileName = 'MLESimulationsForERPFigures.mat';
c_sABCSimulationsForFigsMATFileName = 'ABCSimulationsForFigures.mat';
c_sCPPRelOnsetDiffsMATFileName = 'CPPRelOnsetDiffs.mat';
c_sResponseLockedERPMATFileName = 'ResponseLockedERPs.mat';

% general stuff
c_CsExcludedParticipantIDs = {'azec'}; % excluded before any analysis whatsoever
c_nIncludedParticipants = 25; % original inclusion, going into analyses
c_nAllEEGChannels = 70;
c_nEEGDataChannels = 64;
c_iUpperEOGChannel = 67;
c_iLowerEOGChannel = 68;
c_nAnalysisSampleRate = 512;
c_nERPSampleRate = 128;

% car
c_carWidth = 1.85;

% trial and block definitions
c_iCarAppearanceTrigIDBase = 100;
c_iLoomingOnsetTrigIDBase = 150;
c_nStimulusTypes = 4;
c_ViTrialCarAppearanceTrigIDs = c_iCarAppearanceTrigIDBase + (1:c_nStimulusTypes);
c_ViTrialTrigIDs = c_iLoomingOnsetTrigIDBase + (1:c_nStimulusTypes);
c_iFirstExperimentBlockStartTrigId = 201;
c_iResponseTrigID = 1;
c_VTrialInitialDistances = [20 20 40 40]; % m
c_VTrialDecelerations = [0.35 0.7 0.35 0.7]; % m/s^2
c_nTrialTypes = length(c_ViTrialTrigIDs);
c_VPreLoomingWaitTimes = [1.5 2 2.5 3 3.5]; % s
c_nPreLoomingWaitTimes = length(c_VPreLoomingWaitTimes);
c_nPreLoomingWaitTimeRepeatsPerTrialTypeInBlock = 2;
c_nTrialRepetitionsPerBlock = ...
  c_nPreLoomingWaitTimeRepeatsPerTrialTypeInBlock * c_nPreLoomingWaitTimes;
c_nBlocksPerParticipant = 5;
c_nTrialsPerParticipant = c_nTrialTypes * c_nTrialRepetitionsPerBlock * c_nBlocksPerParticipant;
c_timeAfterResponseBeforeEndingTrial = 0.5;
c_maxOpticalExpansionRate = 0.03; % rad/s

% simple ocular artifact exclusion (a stricter version of O'Connell et
% al, 2012)
c_maxVerticalEOG = 100; % uV

% required number of trials per condition for retaining a participant
c_nMinTrialsPerConditionForParticipantInclusion = 30;

% ICA
c_nICAComponents = 32;
c_nICAComponentsToAnalyse = 16;

% EEG/ERP epochs
c_VEpochExtractionInterval = [-1 8]; % s
c_epochExtractionDuration = c_VEpochExtractionInterval(2) - c_VEpochExtractionInterval(1);
c_VEpochBaselineInterval = [-0.2 0]; % s

% ERP signal for model fitting
c_CsElectrodesForModelFitting = {'CPz', 'Pz', 'POz', 'P1', 'P2'};

% trial averaging for CPP onset estimation
c_nTrialsPerAverageForCPPOnset = 5;
c_probeTimeForCPPEffectSizeThreshold = -0.5;
c_requiredERPPeakCohensDForCPPAnalysis = 0.3;

% different response types models can be fitted to
c_nResponseTypes = 2;
c_iOvertResponse = 1;
c_iCPPOnset = 2;
c_CsResponseTypeFieldNames = {'VResponseTime', 'VCPPOnsetTime'};

% criteria for defining ABC distance threshold per model and participant
c_sModelDefiningABCThreshold = 'T';
c_nRetainedSamplesDefiningABCThreshold = 100;

% 
c_CsABCRTDistanceMetrics = {...
  'RTPercentile__10', ...
  'RTPercentile__30', ...
  'RTPercentile__50', ...
  'RTPercentile__70', ...
  'RTPercentile__90'};


