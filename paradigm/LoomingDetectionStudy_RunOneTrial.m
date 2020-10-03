
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


function [SStates, responseTime, bIncorrectResponse] = ...
  LoomingDetectionStudy_RunOneTrial(SConstants, SStates, STrial, bLogDataDuringTrial)

bDoDataLogging = SConstants.bLogData && bLogDataDuringTrial;


% get car base size in pixels
nCarBaseWidthInDotsOrPixels = size(SConstants.MCarImageRGBA, 2);
nCarBaseHeightInDotsOrPixels = size(SConstants.MCarImageRGBA, 1);

% max duration of trial (only relevant for catch trials with zero
% acceleration)
bIsCatchTrial = (STrial.accelerationLevel == 0) || (isnan(STrial.accelerationOnsetTime));
if bIsCatchTrial
  maxTrialDuration = SConstants.catchTrialDuration;
else
  maxTrialDuration = Inf;
end

% prepare struct with meta data about the trial, for logging
STrialMetaDataToLog.iBlock = STrial.iBlock;
STrialMetaDataToLog.iTrialInBlock = STrial.iTrialInBlock;
STrialMetaDataToLog.initialCarDistance = STrial.initialCarDistance;
STrialMetaDataToLog.accelerationLevel = STrial.accelerationLevel;
STrialMetaDataToLog.accelerationOnsetTime = STrial.accelerationOnsetTime;
STrialMetaDataToLog.iStimulusID = STrial.iStimulusID;

% prepare struct with response data to log if no response is made
STrialResponseDataToLog.bResponseMade = false;
STrialResponseDataToLog.trialTimeStampAtResponse = NaN;
STrialResponseDataToLog.carDistanceAtResponse = NaN;
STrialResponseDataToLog.carOpticalSizeAtResponse = NaN;
STrialResponseDataToLog.carOpticalExpansionRateAtResponse = NaN;
if bIsCatchTrial
  STrialResponseDataToLog.bIncorrectResponse = false;
else
  STrialResponseDataToLog.bIncorrectResponse = true;
end

% get horizontal and vertical camera noise
longTrialDuration = 30; % s
updateFrequency = 1 / SConstants.monitorFlipInterval; % Hz
nLongTrialSamples = ceil(longTrialDuration * updateFrequency);
VVerticalNoise = (2 * rand(nLongTrialSamples, 1) - 1);
VVerticalNoise = filter(SConstants.OVerticalNoiseFilter, VVerticalNoise);
VVerticalNoise = SConstants.verticalNoiseAmplitude * VVerticalNoise / prctile(abs(VVerticalNoise), 95);
VHorizontalNoise = (2 * rand(nLongTrialSamples, 1) - 1);
VHorizontalNoise = filter(SConstants.OHorizontalNoiseFilter, VHorizontalNoise);
VHorizontalNoise = SConstants.horizontalNoiseAmplitude * VHorizontalNoise / prctile(abs(VHorizontalNoise), 95);

% start the trial
trialTimeStamp = -SConstants.timeInTrialBeforeStimulusAppears;
carDistance = NaN;
prevCarOpticalSize = NaN;
carOpticalSize = NaN;
carOpticalExpansionRate = NaN;
bResponseMade = false;
trialTimeStampAtTimeOutAfterResponse = Inf;
bTrialComplete = false;
bCarOnScreen = false;
bCarLooming = false;
iSample = 0;
while ~bTrialComplete && ~SStates.bQuitStudy
  
  iSample = iSample + 1;
  
  % draw background
  Screen('FillRect', SConstants.pWindow, SConstants.VBGColor)
  
  % draw stimulus?
  if trialTimeStamp > 0
    
    if ~bCarOnScreen
      bCarOnScreen = true;
      % play beep to signal appearance of car image
      PlaySound(SConstants, SConstants.VStimulusOnsetBeep)
      % send EEG trig for trial start
      SStates = SendTrig(SConstants, SStates, 'TrialStart', STrial.iStimulusID);
    end
    
    % get current distance to car
    if bIsCatchTrial || trialTimeStamp <= STrial.accelerationOnsetTime
      carDistance = STrial.initialCarDistance;
    else
      timeSinceAccelerationOnset = ...
        trialTimeStamp - STrial.accelerationOnsetTime;
      carDistance = STrial.initialCarDistance - ...
        STrial.accelerationLevel * timeSinceAccelerationOnset^2 / 2;
      % send EEG trig for looming onset
      if ~bCarLooming
        bCarLooming = true;
        SStates = SendTrig(SConstants, SStates, 'LoomingStart', STrial.iStimulusID);
      end 
    end
    
    % get camera position with added noise
    cameraX = VHorizontalNoise(iSample);
    cameraY = VVerticalNoise(iSample);
    
%     cameraX = 0;
%     cameraY = 0;
%     for iFreq = 1:SConstants.nVerticalLFFrequencies
%       cameraY = cameraY + SConstants.verticalLFNoiseAmplitude / ...
%         SConstants.nVerticalLFFrequencies * ...
%         sin(2 * pi * SConstants.VVerticalLFFrequencies(iFreq) * SStates.vblTimeStamp);
%     end
%     for iFreq = 1:SConstants.nVerticalHFFrequencies
%       cameraY = cameraY + SConstants.verticalHFNoiseAmplitude / ...
%         SConstants.nVerticalHFFrequencies * ...
%         sin(2 * pi * SConstants.VVerticalHFFrequencies(iFreq) * SStates.vblTimeStamp);
%     end
%     for iFreq = 1:SConstants.nHorizontalLFFrequencies
%       cameraX = cameraX + + SConstants.horizontalLFNoiseAmplitude / ...
%         SConstants.nHorizontalLFFrequencies * ...
%         sin(2 * pi * SConstants.VHorizontalLFFrequencies(iFreq) * SStates.vblTimeStamp);
%     end
    
    % get car displacement on screen due to camera position
    carDeltaVertPosOnScreen = -SConstants.screenViewingDistance * cameraY / carDistance;
    carDeltaVertFractionOfScreen = carDeltaVertPosOnScreen / SConstants.screenHeight;
    carDeltaYPixels = carDeltaVertFractionOfScreen * SConstants.nScreenHeightPixels;
    carDeltaHorPosOnScreen = -SConstants.screenViewingDistance * cameraX / carDistance;
    carDeltaHorFractionOfScreen = carDeltaHorPosOnScreen / SConstants.screenWidth;
    carDeltaXPixels = carDeltaHorFractionOfScreen * SConstants.nScreenWidthPixels;
    
    % get car size on screen
    carOpticalSize = 2 * atan(SConstants.carWidth / (2 * carDistance));
    carWidthOnScreen = SConstants.screenViewingDistance * SConstants.carWidth / carDistance;
    carFractionOfScreenWidth = carWidthOnScreen / SConstants.screenWidth;
    carWidthPixels = carFractionOfScreenWidth * SConstants.nScreenWidthPixels;
    carScaling = carWidthPixels / nCarBaseWidthInDotsOrPixels;
    carHeightPixels = carScaling * nCarBaseHeightInDotsOrPixels;
    
    % get position on screen of top left corner of car
    carLeftX = SConstants.nScreenWidthPixels/2 + carDeltaXPixels - carWidthPixels/2;
    carTopY = SConstants.nScreenHeightPixels/2 + carDeltaYPixels - carHeightPixels/2;

    % draw car image
    % (..., rotationAngle = 0, filterMode = 3 ["trilinear filtering across mipmap levels"])
    Screen('DrawTexture', SConstants.pWindow, SConstants.iCarImageTexture, [], ...
      [carLeftX carTopY carLeftX + carWidthPixels carTopY + carHeightPixels], ...
      0, 3);

  end % if drawing stimulus
  
  % draw fixation point
  DrawFixationPointDot(SConstants, 0)
  
  % look for key presses
  [bAtLeastOneKeyDown, ~, VbKeysPressed] = KbCheck;
  if bAtLeastOneKeyDown
    if VbKeysPressed(KbName('ESCAPE'))
      SStates.bQuitStudy = true;
    end
    if VbKeysPressed(KbName('space')) && bCarOnScreen % only register responses if the car is visible
      if ~bResponseMade
        % response made
        bResponseMade = true;
        % send trig
        SStates = SendTrig(SConstants, SStates, 'Response');
        % store data about the response, for data logging
        STrialResponseDataToLog.bResponseMade = true;
        STrialResponseDataToLog.trialTimeStampAtResponse = trialTimeStamp;
        STrialResponseDataToLog.carDistanceAtResponse = carDistance;
        STrialResponseDataToLog.carOpticalSizeAtResponse = carOpticalSize;
        STrialResponseDataToLog.carOpticalExpansionRateAtResponse = carOpticalExpansionRate;
        STrialResponseDataToLog.bIncorrectResponse = ~(carOpticalExpansionRate > 0);
        % set timer to end trial some time after this response
        trialTimeStampAtTimeOutAfterResponse = ...
          trialTimeStamp + SConstants.timeAfterResponseBeforeEndingTrial;
        % make sure to wait for the prescribed time after response also if this is a catch trial
        maxTrialDuration = Inf;
        % play sound if incorrect response
        if STrialResponseDataToLog.bIncorrectResponse
          PlaySound(SConstants, SConstants.VIncorrectResponseBeep)
        end
      end % if ~bResponseMade
    end % if space bar was pressed
    if VbKeysPressed(KbName('s'))
      % save a screenshot
      MScreenShot = Screen('GetImage', SConstants.pWindow);
      imwrite(MScreenShot, 'LoomingDetectionScreenShot.png');
    end % if s key pressed
  end % if bAtLeastOneKeyDown
  
  % flip screen
  prevVBLTimeStamp = SStates.vblTimeStamp;
  SStates.vblTimeStamp = Screen('Flip', SConstants.pWindow, ...
    SStates.vblTimeStamp + (SConstants.nWaitFrames - 0.5) * SConstants.monitorFlipInterval);
  trialTimeStamp = trialTimeStamp + (SStates.vblTimeStamp - prevVBLTimeStamp);
  
  % clear trig port if needed
  SStates = ClearParallelPortIfNeeded(SConstants, SStates);
  
  % keep track of the car's optical expansion
  if ~isnan(prevCarOpticalSize)
    carOpticalExpansionRate = (carOpticalSize - prevCarOpticalSize) / ...
      (SStates.vblTimeStamp - prevVBLTimeStamp);
  else
    carOpticalExpansionRate = NaN;
  end
  prevCarOpticalSize = carOpticalSize;
  
  % time series data logging
  if bDoDataLogging
    STrialTimeSeriesDataToLog.vblTimeStamp = SStates.vblTimeStamp;
    STrialTimeSeriesDataToLog.trialTimeStamp = trialTimeStamp;
    STrialTimeSeriesDataToLog.carDistance = carDistance;
    STrialTimeSeriesDataToLog.carOpticalSize = carOpticalSize;
    STrialTimeSeriesDataToLog.carOpticalExpansionRate = carOpticalExpansionRate;
    STrialTimeSeriesDataToLog.bResponseMade = bResponseMade;
    WriteLogFileRow(SConstants.iTimeSeriesLogFileID, STrialMetaDataToLog, ...
      STrialTimeSeriesDataToLog)
  end
  
  % trial complete?
  bTrialComplete = trialTimeStamp > maxTrialDuration || ...
    trialTimeStamp > trialTimeStampAtTimeOutAfterResponse || ...
    carOpticalExpansionRate > SConstants.maxOpticalExpansionRate;
  
end % trial running while loop

% send trig for trial end
SStates = SendTrig(SConstants, SStates, 'TrialEnd');

% log response data
if bDoDataLogging
  WriteLogFileRow(SConstants.iResponseLogFileID, ...
    STrialMetaDataToLog, STrialResponseDataToLog)
end

% provide return values
responseTime = STrialResponseDataToLog.trialTimeStampAtResponse - ...
  STrial.accelerationOnsetTime;
bIncorrectResponse = STrialResponseDataToLog.bIncorrectResponse;




