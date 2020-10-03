
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


% load the filtered per-participant EEG data, runs EEGLAB's independent
% component analysis, and saves in new per-participant .MAT files - also
% saves figures showing the ICA components per participant

clearvars
close all

% constants
SetLoomingDetectionStudyAnalysisConstants

% manual inclusion (for rerunning if something went wrong; leave empty to run all)
c_CsOnlyProcessTheseParticipants = {};

% load the response data table with trial inclusion info
load([c_sAnalysisResultsPath 'AllResponseData_WithExclusions.mat'])

% get participants that have been excluded as part of data cleaning
CsExcludedParticipants = ...
  unique({TResponses.sParticipantID{find(TResponses.bParticipantExcluded)}});

% start EEGLAB
StartEEGLAB

% get list of participant log files
SEEGFiles = dir([c_sEEGAnalysisDataPath sprintf(c_sFilteredFileNameFormat, '*')]);


% loop through log files
for iEEGFile = 1:length(SEEGFiles)
  sEEGFileName = SEEGFiles(iEEGFile).name;
  sParticipantID = sEEGFileName(c_VidxParticipantIDInFilteredFileName);
  fprintf('******** Participant %s ********\n', sParticipantID)
  
  % include?
  bInclude = ~StringIsInCellArray(sParticipantID, CsExcludedParticipants) && ... % not excluded in data cleaning
    (isempty(c_CsOnlyProcessTheseParticipants) || ...                            % and (processing all or is in list of those to process)
    StringIsInCellArray(sParticipantID, c_CsOnlyProcessTheseParticipants));
  if ~bInclude
    fprintf('Excluded.\n')
    continue
  end
  
  % load EEG data (structure SEEGRereferenced)
  fprintf('Loading MAT file...\n')
  load([c_sEEGAnalysisDataPath sEEGFileName])
  
  % make reduced dataset only including EEG from decision intervals in
  % non-excluded trials
  fprintf('Making reduced dataset...\n')
  % -- make copy
  SEEGReduced = SEEGFiltered;
  % -- loop through the non-excluded trials in the response data table for
  % -- this participant, and get the decision intervals
  VidxRowsWithIncludedTrials = find(strcmp(sParticipantID, TResponses.sParticipantID) & ...
    ~TResponses.bTrialExcluded);
  VidxRowsWithIncludedTrials = reshape(VidxRowsWithIncludedTrials, 1, []); % ensure row vector
  nIncludedTrials = length(VidxRowsWithIncludedTrials);
  MidxDecisionIntervals = zeros(nIncludedTrials, 2);
  fprintf('\tGetting decision intervals from %d included trials...\n', nIncludedTrials)
  for iIncludedTrial = 1:nIncludedTrials
    % get the EEG log event number for this trial
    idxThisRow = VidxRowsWithIncludedTrials(iIncludedTrial);
    idxEEGLogEvent = TResponses.iEEGLogEventNumber(idxThisRow);
    % for a non-excluded trial, this event should be a looming onset event,
    % and the next one should be a response - double check that this is the
    % case
    assert(ismember(SEEGReduced.event(idxEEGLogEvent).type, c_ViTrialTrigIDs))
    assert(SEEGReduced.event(idxEEGLogEvent+1).type == c_iResponseTrigID)
    % store this decision interval
    MidxDecisionIntervals(iIncludedTrial, :) = ...
      [SEEGReduced.event(idxEEGLogEvent).latency ...
      SEEGReduced.event(idxEEGLogEvent+1).latency];
  end % iRow for loop
  % -- retain only the decision intervals
  SEEGReduced = pop_select(SEEGReduced, 'point', MidxDecisionIntervals);
  
  % do ICA on reduced dataset
  fprintf('Running ICA...\n')
  SEEGReduced = pop_runica(SEEGReduced, 'pca', c_nICAComponents);
  
  % save ICA and sphering weights
  SICAResults.icaweights = SEEGReduced.icaweights;
  SICAResults.icasphere = SEEGReduced.icasphere;
  
  % plot ICA components
  fprintf('Plotting/saving figure...\n')
  pop_topoplot(SEEGReduced, 0, 1:c_nICAComponents, sParticipantID, ...
    [1 1] * ceil(sqrt(c_nICAComponents)), 0, 'electrodes','off');
  saveas(gcf, [c_sAnalysisPlotPath sprintf('ParticipantICAComponents_%s.png', ...
    sParticipantID)])
  
  % save .mat file
  fprintf('Saving MAT file...\n')
  save([c_sEEGAnalysisDataPath sprintf(c_sICAFileNameFormat, sParticipantID)], 'SICAResults')
  
end % iLogFile

