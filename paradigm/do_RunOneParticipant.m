
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


clearvars
close all

% debug settings
SStudyConstants.bSendParallelPortTrigs = true;
SStudyConstants.bLogData = true;
SStudyConstants.bRunFullSetOfTrials = true;
if ~(SStudyConstants.bSendParallelPortTrigs && ...
    SStudyConstants.bLogData && SStudyConstants.bRunFullSetOfTrials)
  disp('----- You seem to be running this code in debug mode:')
  if ~SStudyConstants.bSendParallelPortTrigs
    disp('* Not sending parallel port trigs to BioSemi.')
  end
  if ~SStudyConstants.bLogData
    disp('* Not logging data.')
  end
  if ~SStudyConstants.bRunFullSetOfTrials
    disp('* Not running full set of trials.')
  end
  disp('----- Are you sure you want to continue? If yes, press any key. If no, press Ctrl-C.')
  pause
end


if SStudyConstants.bLogData
  % get participant ID string
  SStudyConstants.sParticipantID = input('Enter participant ID string > ', 's');
end


try
 
  
  % init
  % -- init before starting PsychToolbox
  [SStudyConstants, SStudyStates] = ...
    LoomingDetectionStudy_InitBeforeStartingPTB(SStudyConstants);
  % -- start PsychToolbox
  [SStudyConstants, SStudyStates] = ...
    LoomingDetectionStudy_StartPsychToolbox(SStudyConstants, SStudyStates);
  % -- init after starting PsychToolbox
  [SStudyConstants, SStudyStates] = ...
    LoomingDetectionStudy_InitAfterStartingPTB(SStudyConstants, SStudyStates);
  
  
  % show just the fixation dot
  Screen('FillRect', SStudyConstants.pWindow, SStudyConstants.VBGColor)
  DrawFixationPointDot(SStudyConstants, 0)
  Screen('Flip', SStudyConstants.pWindow)
  KbPressWait;
  KbReleaseWait;
  
   
  
  % run demonstration block
  sBlockName = 'demonstration block';
  SStudyStates = LoomingDetectionStudy_RunOneBlock(...
    SStudyConstants, SStudyStates, -1, sBlockName, ...
    SStudyConstants.VAccelerationOnsetTimesForDemonstration, ...
    SStudyConstants.nUniqueStimulusRepetitionsPerBlockForDemonstration, false);
  
  
  % send trig for EEG data recording start
  SStudyStates = SendTrigAndClearPortShortlyAfter(...
    SStudyConstants, SStudyStates, 'RecordingStart');
   
  
  % run practice block
  sBlockName = 'practice block';
  SStudyStates = LoomingDetectionStudy_RunOneBlock(...
    SStudyConstants, SStudyStates, 0, sBlockName, ...
    SStudyConstants.VAccelerationOnsetTimesForPractice, ...
    SStudyConstants.nUniqueStimulusRepetitionsPerBlockForPractice, true);

  
  % run experimental blocks
  for iBlock = 1:SStudyConstants.nBlocks
    
    sBlockName = sprintf('experiment block %d of %d', iBlock, SStudyConstants.nBlocks);
    SStudyStates = LoomingDetectionStudy_RunOneBlock(...
      SStudyConstants, SStudyStates, iBlock, sBlockName, ...
      SStudyConstants.VAccelerationOnsetTimes, ...
      SStudyConstants.nUniqueStimulusRepetitionsPerBlock, true);
    
    if SStudyStates.bQuitStudy
      break
    end
      
  end % iBlock for loop
  
  
  % send trig for EEG data recording end
  SStudyStates = SendTrigAndClearPortShortlyAfter(...
    SStudyConstants, SStudyStates, 'RecordingEnd');
  
  
  if ~SStudyStates.bQuitStudy
    % inform the participant that all blocks are done
    DrawTextMessage(SStudyConstants, 'All blocks done!')
    Screen('Flip', SStudyConstants.pWindow);
    KbPressWait;
    KbReleaseWait;
  end
  
  
catch
  LoomingDetectionStudy_Cleanup(SStudyConstants)
  rethrow(psychlasterror)
end

LoomingDetectionStudy_Cleanup(SStudyConstants)



