
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


function [SConstants, SStates] = ...
  LoomingDetectionStudy_InitBeforeStartingPTB(SConstants)

% init empty states struct
SStates = struct;

% load car image
c_sCarImageFilePath = ...
  'V60_transparent.png';
[MCarImage, ~, MCarImageAlpha] = imread(c_sCarImageFilePath);
SConstants.MCarImageRGBA = zeros(size(MCarImage, 1), size(MCarImage, 2), 4);
SConstants.MCarImageRGBA(:, :, 1:3) = MCarImage;
SConstants.MCarImageRGBA(:, :, 4) = MCarImageAlpha;

% log file init
if SConstants.bLogData
  % -- get log file names
  SConstants.sTimeSeriesLogFile = sprintf('TimeSeriesData_%s.csv', SConstants.sParticipantID);
  SConstants.sResponseLogFile = sprintf('Responses_%s.csv', SConstants.sParticipantID);
  % -- provide a warning if the log files exist already
  bTimeSeriesLogFileExists = exist(SConstants.sTimeSeriesLogFile, 'file');
  bResponseLogFileExists = exist(SConstants.sResponseLogFile, 'file');
  if bTimeSeriesLogFileExists || bResponseLogFileExists
    disp('----- The following log file(s) already exist(s) and will be overwritten:')
    if bTimeSeriesLogFileExists
      fprintf('* %s\n', SConstants.sTimeSeriesLogFile);
    end
    if bResponseLogFileExists
      fprintf('* %s\n', SConstants.sResponseLogFile);
    end
    disp('----- Are you sure you want to continue? If yes, press any key. If no, press Ctrl-C.')
    pause
  end
  % -- time series data logging
  SConstants.iTimeSeriesLogFileID = fopen(SConstants.sTimeSeriesLogFile, 'w');
  if SConstants.iTimeSeriesLogFileID == -1
    error('Could not open time series data log file for writing: %s', ...
      SConstants.sTimeSeriesLogFile)
  end
  % -- response data logging
  SConstants.iResponseLogFileID = fopen(SConstants.sResponseLogFile, 'w');
  if SConstants.iResponseLogFileID == -1
    error('Could not open response data log file for writing: %s', ...
      SConstants.sResponseLogFile)
  end
end

% parallel port init
global cogent
SConstants.iEEGTrigAddress = hex2dec('E020');
if SConstants.bSendParallelPortTrigs
  config_io
  iIOStatus = cogent.io.status;
  if iIOStatus ~= 0
    error('IO error: %d', iIOStatus)
  end
  SStates.bParallelPortCleared = false;
  SStates = ClearParallelPortIfNeeded(SConstants, SStates);
end
% trig messages
CvTrigs = {...
  'RecordingStart'  254
  'RecordingEnd'    126
  'BlockStart'      200
  'BlockEnd'        199
  'TrialStart'      100 % car appears on screen
  'LoomingStart'    150
  'TrialEnd'        99
  'Response'        1};
SConstants.STrigs = cell2struct(CvTrigs, {'sTrigMessage', 'iTrigBaseID'}, 2);
clear CvTrigs;


% various constants

SConstants.VBGColor = round(255 * [0.4664    0.4447    0.4377] / 2); % half of the average color of the car

SConstants.nWaitFrames = 1; % - (run PsychToolbox at max screen refresh rate)

SConstants.timeInTrialBeforeStimulusAppears = 3; % s
SConstants.timeAfterResponseBeforeEndingTrial = 0.5; % s
SConstants.catchTrialDuration = 7;

% SConstants.iDotSize = 3; % pixels
% SConstants.dotSpacingInDotWidths = 1.5; % -
SConstants.iPTBDotType = 2; % "high-quality antialising" of dots with the Screen('DrawDots') command

SConstants.iFixationDotSize = 6; % pixels
SConstants.VFixationDotColor = [255 0 0];

SConstants.screenWidth = 0.53; % m
SConstants.screenViewingDistance = 1; % m

SConstants.carWidth = 1.85; % m

% SConstants.VGazeEccentricities = [0 8] * pi / 180; % radians
% SConstants.nGazeEccentricities = length(SConstants.VGazeEccentricities);
% SConstants.VEccentricityDirections = [1 -1];
% SConstants.nEccentricityDirections = length(SConstants.VEccentricityDirections);

% SConstants.nStimulusTypes = 2;
% SConstants.iPhotoStimulus = 1;
% SConstants.iDotArrayStimulus = 2;

SConstants.VInitialCarDistances = [20 40]; % m
SConstants.nInitialCarDistances = length(SConstants.VInitialCarDistances);

if SConstants.bRunFullSetOfTrials
  SConstants.VAccelerationLevels = [0.35 0.7]; % m/s^2
  SConstants.VAccelerationOnsetTimes = [NaN 1.5 2 2.5 3 3.5]; % s
  SConstants.nUniqueStimulusRepetitionsPerBlock = 2;
  SConstants.nBlocks = 5;
  SConstants.VAccelerationOnsetTimesForPractice = [NaN 1.5 3.5]; % s
  SConstants.nUniqueStimulusRepetitionsPerBlockForPractice = 1;
  SConstants.VAccelerationOnsetTimesForDemonstration = [2.5]; % s
  SConstants.nUniqueStimulusRepetitionsPerBlockForDemonstration = 1;
else
  SConstants.VAccelerationLevels = [0.35 0.7]; % m/s^2
  SConstants.VAccelerationOnsetTimes = [NaN 1.5 3.5]; % s
  SConstants.nUniqueStimulusRepetitionsPerBlock = 1;
  SConstants.nBlocks = 2;
  SConstants.VAccelerationOnsetTimesForPractice = [NaN 2.5]; % s
  SConstants.nUniqueStimulusRepetitionsPerBlockForPractice = 1;
  SConstants.VAccelerationOnsetTimesForDemonstration = [2.5]; % s
  SConstants.nUniqueStimulusRepetitionsPerBlockForDemonstration = 1;
end
SConstants.nAccelerationLevels = length(SConstants.VAccelerationLevels);

SConstants.SFeedbackStimulus.initialCarDistance = 20;
SConstants.SFeedbackStimulus.accelerationLevel = 0.7;

SConstants.maxOpticalExpansionRate = 0.03; % rad/s

% camera noise constants
% SConstants.verticalLFNoiseAmplitude = 0.01; % m
% SConstants.VVerticalLFFrequencies = [0.986 0.843 0.771]; % Hz
% SConstants.nVerticalLFFrequencies = length(SConstants.VVerticalLFFrequencies);
% SConstants.verticalHFNoiseAmplitude = 0.01; % m
% SConstants.VVerticalHFFrequencies = [6.79 4.12 3.23]; % Hz
% SConstants.nVerticalHFFrequencies = length(SConstants.VVerticalHFFrequencies);
% SConstants.horizontalLFNoiseAmplitude = 0.01; % m
% SConstants.VHorizontalLFFrequencies = [0.366 0.514]; % Hz
% SConstants.nHorizontalLFFrequencies = length(SConstants.VHorizontalLFFrequencies);
% -- Based on (Qiu and Griffin, 2004):
SConstants.OVerticalNoiseFilter = designfilt('bandpassiir', 'StopbandFrequency1', 0.25, 'PassbandFrequency1', 0.5, 'PassbandFrequency2', 4, 'StopbandFrequency2', 5, 'StopbandAttenuation1', 10, 'PassbandRipple', 1, 'StopbandAttenuation2', 10, 'SampleRate', 60);
% -- Based on (Ostlund et al, 2005):
SConstants.OHorizontalNoiseFilter = designfilt('bandpassiir', 'StopbandFrequency1', 0.025, 'PassbandFrequency1', 0.05, 'PassbandFrequency2', 0.2, 'StopbandFrequency2', 0.5, 'StopbandAttenuation1', 20, 'PassbandRipple', 1, 'StopbandAttenuation2', 20, 'SampleRate', 60);
% -- These amplitudes were manually tuned until subjectively satisfactory 
SConstants.verticalNoiseAmplitude = 0.01; % m
SConstants.horizontalNoiseAmplitude = 0.02; % m



