
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


function SStates = ...
  LoomingDetectionStudy_RunOneBlock(SConstants, SStates, iBlock, sBlockName, ...
  VAccelerationOnsetTimesInBlock, nUniqueStimulusRepetitionsInBlock, ...
  bLogDataDuringBlock)

% set up the trials included in the block
nLargeNumberOfTrials = 100;
SBlockTrials.ViInitialCarDistance = zeros(nLargeNumberOfTrials, 1);
SBlockTrials.ViAccelerationLevel = zeros(nLargeNumberOfTrials, 1);
SBlockTrials.ViAccelerationOnsetTime = zeros(nLargeNumberOfTrials, 1);
nTrialsInBlock = 0;
nAccelerationOnsetTimesInBlock = length(VAccelerationOnsetTimesInBlock);
for iInitialCarDistance = 1:SConstants.nInitialCarDistances
  for iAccelerationLevel = 1:SConstants.nAccelerationLevels
    for iAccelerationOnsetTime = 1:nAccelerationOnsetTimesInBlock
      for iUniqueStimulusRepetition = 1:nUniqueStimulusRepetitionsInBlock
        nTrialsInBlock = nTrialsInBlock + 1;
        SBlockTrials.ViInitialCarDistance(nTrialsInBlock) = iInitialCarDistance;
        SBlockTrials.ViAccelerationLevel(nTrialsInBlock) = iAccelerationLevel;
        SBlockTrials.ViAccelerationOnsetTime(nTrialsInBlock) = iAccelerationOnsetTime;
      end % iUniqueStimulusRepetition for loop
    end % iAccelerationOnsetTime for loop
  end % iAccelerationLevel for loop
end % iInitialCarDistance for loop
SBlockTrials.ViInitialCarDistance = SBlockTrials.ViInitialCarDistance(1:nTrialsInBlock);
SBlockTrials.ViAccelerationLevel = SBlockTrials.ViAccelerationLevel(1:nTrialsInBlock);
SBlockTrials.ViAccelerationOnsetTime = SBlockTrials.ViAccelerationOnsetTime(1:nTrialsInBlock);

if bLogDataDuringBlock
  % display instructions and wait for keypress
  sMessageToDisplay = ['Ready to begin ' sBlockName '.'];
  if iBlock >= 1
    sMessageToDisplay = [sMessageToDisplay ...
      '\n\n\nFeel free to take a short rest break now if needed, but please avoid too much movement.' ...
      '\nIf you need a drink of water or any other assistance, do not hesitate to ask the experimenter.'];
  end
  sMessageToDisplay = [sMessageToDisplay ...
    '\n\n\nWhen you are ready to start, please place your right index finger on the spacebar,' ...
    '\nand press it to begin.' ...
    '\n\n\nRemember: Please try to stay focused on the task, press the button as soon as you see the car coming closer,' ...
    '\nand try not to blink while the car is displayed on screen.'];
  DrawTextMessage(SConstants, sMessageToDisplay)
  Screen('Flip', SConstants.pWindow);
  % -- wait for keypress
  KbPressWait;
  SStates.vblTimeStamp = KbReleaseWait;
end

% send trig for block start
SStates = SendTrigAndClearPortShortlyAfter(...
  SConstants, SStates, 'BlockStart', iBlock);

% loop through trials in block
ViThisBlockTrialOrder = randperm(nTrialsInBlock);
VResponseTimesForFeedback = [];
nIncorrectResponses = 0;
for iTrial = 1:nTrialsInBlock
  
  iThisTrialID = ViThisBlockTrialOrder(iTrial);
  
  % set the parameters for this trial
  STrialParameters.iBlock = iBlock;
  STrialParameters.iTrialInBlock = iTrial;
  iThisTrialInitialCarDistance = ...
    SBlockTrials.ViInitialCarDistance(iThisTrialID);
  STrialParameters.initialCarDistance = ...
    SConstants.VInitialCarDistances(iThisTrialInitialCarDistance);
  STrialParameters.accelerationOnsetTime = ...
    VAccelerationOnsetTimesInBlock(...
    SBlockTrials.ViAccelerationOnsetTime(iThisTrialID));
  if isnan(STrialParameters.accelerationOnsetTime)
    % catch trial
    STrialParameters.accelerationLevel = 0;
    STrialParameters.iStimulusID = 11 + ...
      (iThisTrialInitialCarDistance-1) * SConstants.nAccelerationLevels;
  else
    % experimental trial
    iThisTrialAccelerationLevel = ...
      SBlockTrials.ViAccelerationLevel(iThisTrialID);
    STrialParameters.accelerationLevel = ...
      SConstants.VAccelerationLevels(iThisTrialAccelerationLevel);
    STrialParameters.iStimulusID = ...
      (iThisTrialInitialCarDistance-1) * SConstants.nAccelerationLevels + ...
      iThisTrialAccelerationLevel;   
  end
  
  % run the trial
  [SStates, trialResponseTime, bIncorrectTrialResponse] = ...
    LoomingDetectionStudy_RunOneTrial(...
    SConstants, SStates, STrialParameters, bLogDataDuringBlock);
  
  % user requested exit?
  if SStates.bQuitStudy
    return
  end
  
  % store data for feedback
  % -- store response correctness
  bIncorrectTrialResponse_VerifiedNonNaN = ...
    ~isnan(bIncorrectTrialResponse) && bIncorrectTrialResponse;
  if bIncorrectTrialResponse_VerifiedNonNaN;
    nIncorrectResponses = nIncorrectResponses + 1;
  end
  % -- store response time?
  if STrialParameters.initialCarDistance == ...
      SConstants.SFeedbackStimulus.initialCarDistance && ...
      STrialParameters.accelerationLevel == ...
      SConstants.SFeedbackStimulus.accelerationLevel && ...
      ~isnan(trialResponseTime) && ...
      ~bIncorrectTrialResponse_VerifiedNonNaN
    VResponseTimesForFeedback(end + 1) = trialResponseTime;
  end
  
end % iTrial for loop


% clear the last trial end trig
WaitSecs(0.1);
SStates = ClearParallelPortIfNeeded(SConstants, SStates);


% % send trig for block end
% SStates = SendTrigAndClearPortShortlyAfter(...
%   SConstants, SStates, 'BlockEnd', iBlock);

if bLogDataDuringBlock
  % give feedback on performance
  % -- add info from this block to overall feedback info
  if ~isfield(SStates, 'sPerformanceFeedback')
    SStates.sPerformanceFeedback = '';
  end
  sBlockNameWithCapitalFirstLetter = [upper(sBlockName(1)) sBlockName(2:end)];
  sBlockNameWithCapitalFirstLetterPadded = [sBlockNameWithCapitalFirstLetter ...
    repmat(' ', 1, 30 - length(sBlockNameWithCapitalFirstLetter))];
  SStates.sPerformanceFeedback = [SStates.sPerformanceFeedback ...
    sprintf('%s %.1f s   (%.0f %% correct responses)\n', ...
    sBlockNameWithCapitalFirstLetterPadded, mean(VResponseTimesForFeedback), ...
    (1 - nIncorrectResponses / nTrialsInBlock) * 100)];
  % -- show feedback info
  sFeedbackMessage = [sBlockNameWithCapitalFirstLetter ' done.\n\n\n' ...
    'Your results so far - indicative average response times:\n\n' ...
    SStates.sPerformanceFeedback '\n\n' ...
    'If response times are increasing, you may be losing focus, and might\n' ...
    'benefit from resting a minute or so before continuing.\n\n\n' ...
    'Press any key.'];
  DrawTextMessage(SConstants, sFeedbackMessage)
  Screen('Flip', SConstants.pWindow);
  % -- wait for keypress
  KbPressWait;
  KbReleaseWait;
end



