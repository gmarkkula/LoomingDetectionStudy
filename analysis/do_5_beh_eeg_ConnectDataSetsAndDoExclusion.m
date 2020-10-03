
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


% Loads the filtered per-participant EEG data as well as the behavioural
% response data, makes the per-trial connection between the two datasets,
% identifies trials that are to be excluded due to no response, early
% (pre-looming) response, or large EOG trials. Identifies participants
% with too few non-excluded trials in one or more looming conditions, and
% marks those participants for complete exclusion. The exclusion
% information is added as new columns to the TResponses table, and this new 
% table is saved in AllResponseData_WithExclusions.mat.

clearvars
close all

% constants
SetLoomingDetectionStudyAnalysisConstants
c_bMakeEOGPlots = true;
c_VEOGPlotYLim = [-400 400]; % uV
c_bSavePlots = true;

c_bDebugInspection = false;
c_responseTimeMatchThreshold = 0.1; % s (threshold diff when matching RT between EEG and behavioural log files)

% load response data
load([c_sAnalysisResultsPath 'AllResponseData.mat'])
nResponseDataRows = size(TResponses, 1);

% prepared new columns for the response data table
[TResponses.iEEGLogEventNumber, TResponses.bMissingEEGResponseTrig, ...
  TResponses.bHasEOGArtifact, ...
  TResponses.bTrialExcluded, TResponses.bParticipantExcluded] = ...
  deal(NaN * ones(nResponseDataRows, 1));

% set default trial exclusion, considering all criteria except ocular
% artifacts
TResponses.bTrialExcluded = TResponses.iBlock <= 0 | ... % practice block
  TResponses.iStimulusID > 10 | ... % catch trials
  isnan(TResponses.carOpticalExpansionRateAtResponse) | ... % no response
  TResponses.bIncorrectResponse; % responding when no looming

% loop through rows in the response data table
sParticipantIDForLoadedEEGData = '';

%%
c_ViBehRowsToSkip = [...
  4033:4040 ... % EEG recording started halfway through practice block for participant #17 ncvv
  4789:4800];   % EEG recording started after practice block for participant #20 tgns
c_CViEEGLogEventsToSkip = cell(c_nIncludedParticipants, 1);
c_CViEEGLogEventsToSkip{8} = 74; % an unexpected looming onset trig - some paradigm programming error?
c_CViEEGLogEventsToSkip{15} = 1:14; % a restart of the practice block while EEG logging running

if c_bMakeEOGPlots
  figure(1)
end

iStartRow = 1;
iCurrEEGLogEvent = 0;
if iStartRow ~= 1 || iCurrEEGLogEvent ~= 0
  warning('Starting from debug position.')
end
nInspectCountDown = 0;
for iRow = iStartRow:nResponseDataRows
  
  if ismember(iRow, c_ViBehRowsToSkip)
    fprintf('Skipping beh. row #%d.\n', iRow)
    continue
  end
  
  % starting on new participant?
  sParticipantID = TResponses.sParticipantID{iRow};
  if ~strcmp(sParticipantID, sParticipantIDForLoadedEEGData)
    
    % manage EOG plotting/saving if needed
    if c_bMakeEOGPlots
      % is there a plot since before that needs saving/showing?
      if ~isempty(sParticipantIDForLoadedEEGData)
        set(gca, 'XLim', [c_VEpochBaselineInterval(1) c_VEpochExtractionInterval(2)])
        set(gca, 'YLim', c_VEOGPlotYLim)
        nTrialsWithEOGArtifacts = length(find(...
          TResponses.iParticipantCounter == iRowParticipantCounter & ... % (the row participant counter hasn't been updated yet)
          TResponses.bHasEOGArtifact == true));
        title(sprintf('Participant %s; %d trial(s) with EOG artifacts excluded', ...
          sParticipantIDForLoadedEEGData, nTrialsWithEOGArtifacts))
        if c_bSavePlots
          drawnow
          fprintf('Saving EOG plot...\n')
          saveas(gcf, [c_sAnalysisPlotPath ...
            sprintf('ParticipantEOG_%s.png', sParticipantIDForLoadedEEGData)])
        else
          pause
          disp 'Press any key to continue...'
        end
      end
      % prepare for plotting the new participant's EOG data
      clf
      hold on
    end
    
    % load EEG data set for new participant
    sEEGFileName = sprintf(c_sFilteredFileNameFormat, sParticipantID);
    fprintf('Loading EEG data MAT file %s...\n', sEEGFileName)
    load([c_sEEGAnalysisDataPath sEEGFileName])
    sParticipantIDForLoadedEEGData = sParticipantID;
    iCurrEEGLogEvent = 0;
  end
  
  % is this row in the response table for a non-catch trial with
  % non-response or response less than 0.5 s before looming onset or after it?
  %  - if yes, there will be an EEG trig for the looming onset to find
  iRowParticipantCounter = TResponses.iParticipantCounter(iRow);
  iRowStimulusID = TResponses.iStimulusID(iRow);
  rowResponseTime = TResponses.trialTimeStampAtResponse(iRow) - ...
    TResponses.accelerationOnsetTime(iRow);
  if ismember(iRowStimulusID, 1:c_nStimulusTypes) && ...
      (~TResponses.bResponseMade(iRow) || ...
      rowResponseTime > -(0.999 * c_timeAfterResponseBeforeEndingTrial)) % the 0.999 factor is needed because of some timing inaccuracies causing trouble with one specific trial
    % this is a non-catch trial, so find where it is in the EEG log
    fprintf('At beh. log row #%d - looking for: participant #%d %s; block %d; trial %d; stimulus ID %d...\n', ...
      iRow, iRowParticipantCounter, sParticipantID, ...
      TResponses.iBlock(iRow), TResponses.iTrialInBlock(iRow), iRowStimulusID)
    fprintf('Starting from EEG log event #%d: ', iCurrEEGLogEvent)
    
    bFoundEEGLogEvent = false;
    while ~bFoundEEGLogEvent
      bContinue = true;
      while bContinue
        iCurrEEGLogEvent = iCurrEEGLogEvent + 1;
        % is this EEG log event on the skip list?
        if ismember(iCurrEEGLogEvent, c_CViEEGLogEventsToSkip{iRowParticipantCounter})
          warning('Skipping EEG log event %d for participant %d...', ...
            iCurrEEGLogEvent, iRowParticipantCounter)
          nInspectCountDown = 3;
        else
          bContinue = false;
        end
      end % while bContinue
      iCurrEEGLogEventType = SEEGFiltered.event(iCurrEEGLogEvent).type;
      fprintf('[%d: %d] ', iCurrEEGLogEvent, iCurrEEGLogEventType)
      if iCurrEEGLogEventType == ...
          c_iLoomingOnsetTrigIDBase + iRowStimulusID
        % this might be the right event - double check with response time
        responseTimeInEEGLog = FindTrialResponseTimeForEEGLogEvent(...
          SEEGFiltered.event, iCurrEEGLogEvent, SEEGFiltered.times, true);
        fprintf('\n\tRT in EEG log: %.2f s\n\tRT in beh log: %.2f s\n', ...
          responseTimeInEEGLog, rowResponseTime)
        rtDiff = responseTimeInEEGLog - rowResponseTime;
        if abs(rtDiff) < c_responseTimeMatchThreshold || ...
            (isnan(responseTimeInEEGLog) && isnan(rowResponseTime))
          bFoundEEGLogEvent = true;
          TResponses.bMissingEEGResponseTrig(iRow) = false;
        elseif isnan(responseTimeInEEGLog) && ~isnan(rowResponseTime)
          % missing response time in EEG log - assume this can be
          % replaced with response from behavioural log
          bFoundEEGLogEvent = true;
          TResponses.bMissingEEGResponseTrig(iRow) = true;
          nInspectCountDown = 3;
          warning('Noting missing response trig in EEG log. Assuming the response in behavioural log can be used instead.')
        else
          error('RTs do not match.')
        end
      elseif ismember(iCurrEEGLogEventType, c_ViTrialTrigIDs)
        error('Found unexpected looming onset EEG event.')
      else
        % for any other event just keep looking
      end
      
    end % while ~bFoundEEGLogEvent
    
    % store the EEG log event number in the beh. log data table
    assert(bFoundEEGLogEvent)
    fprintf('\tConnecting this beh. log row with EEG event #%d.\n', iCurrEEGLogEvent)
    TResponses.iEEGLogEventNumber(iRow) = iCurrEEGLogEvent;
    
    % check EOG for artifacts for this trial (not needed if already excluded)
    if ~TResponses.bTrialExcluded(iRow)
      % -- find the decision interval (from baseline start to response)
      loomingOnsetTimeStamp = GetTimeStampForEEGLogEvent(...
        SEEGFiltered.event(iCurrEEGLogEvent), SEEGFiltered.times);
      baselineStartTimeStamp = loomingOnsetTimeStamp + c_VEpochBaselineInterval(1);
      idxBaselineStartSample = ...
        GetSampleForEEGLogTimeStamp(baselineStartTimeStamp, SEEGFiltered.times);
      responseTimeStamp = loomingOnsetTimeStamp + rowResponseTime;
      idxResponseSample = ...
        GetSampleForEEGLogTimeStamp(responseTimeStamp, SEEGFiltered.times);
      VidxDecisionInterval = idxBaselineStartSample:idxResponseSample;
      % -- get the vertical EOG
      VVerticalEOG = SEEGFiltered.data(c_iUpperEOGChannel, VidxDecisionInterval) - ...
        SEEGFiltered.data(c_iLowerEOGChannel, VidxDecisionInterval);
      % -- apply threshold
      TResponses.bHasEOGArtifact(iRow) = ...
        max(abs(VVerticalEOG)) > c_maxVerticalEOG;
      % -- exclude?
      if TResponses.bHasEOGArtifact(iRow)
        TResponses.bTrialExcluded(iRow) = true;
      end
      % -- plot?
      if c_bMakeEOGPlots
        VPlotTimeStamp = linspace(c_VEpochBaselineInterval(1), ...
          rowResponseTime, length(VidxDecisionInterval));
        if TResponses.bHasEOGArtifact(iRow)
          sLineSpec = 'r-';
        else
          sLineSpec = 'k-';
        end
        hPlot = plot(VPlotTimeStamp, VVerticalEOG, sLineSpec);
        hPlot.Color(4) = 0.1;
      end
    end
    
    % debug inspection of progress?
    if c_bDebugInspection && nInspectCountDown > 0
      fprintf('Inspecting %d more steps. Press any key to continue...\n', nInspectCountDown)
      pause
      nInspectCountDown = nInspectCountDown - 1;
    end
    
  end % if row in response table for non-catch trial
  
end % iRow for loop



%% go through all participants and exclude participants with too few
%  trials in one or more conditions

for iParticipantCounter = 1:c_nIncludedParticipants
  fprintf('Participant #%d: ', iParticipantCounter)
  bParticipantExcluded = false;
  VnIncludedTrials = NaN * ones(c_nStimulusTypes, 1);
  for iStimulusID = 1:c_nStimulusTypes
    nIncludedTrials = length(find(...
      TResponses.iParticipantCounter == iParticipantCounter & ...
      TResponses.iStimulusID == iStimulusID & ...
      ~TResponses.bTrialExcluded));
    fprintf('%d ', nIncludedTrials)
    if nIncludedTrials < c_nMinTrialsPerConditionForParticipantInclusion
      bParticipantExcluded = true;
    end
  end % iStimulusID for loop
  TResponses.bParticipantExcluded(...
    TResponses.iParticipantCounter == iParticipantCounter) = ...
    bParticipantExcluded;
  if bParticipantExcluded
    fprintf('EXCLUDED')
  end
  fprintf('\n')
end % iParticipantCounter for loop


save([c_sAnalysisResultsPath 'AllResponseData_WithExclusions.mat'], ...
  'TResponses')

% optional saving also as CSV file for inspection
% writetable(TResponses, ...
%   [c_sAnalysisResultsPath 'AllResponseData_WithExclusions.csv'])
  
