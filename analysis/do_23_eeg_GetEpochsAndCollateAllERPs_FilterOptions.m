
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


% Like do_8..., but skipping the ocular artifact ICA component removal step,
% to instead do epoching both on the data with original filtering and without
% the high-pass filtering. Like do_8..., this script creates a large struct
% SAllTrialData but saves this struct in AllTrialData_FilterVariants.mat

clearvars
close all

% constants
SetLoomingDetectionStudyAnalysisConstants
c_CsFilterVariants = {'LPHP', 'LP'};
c_nFilterVariants = length(c_CsFilterVariants);
c_bDoOnlyPlots = false; % don't redo the loading/analysing of data - just use previously saved results from this script
c_bSavePlots = true;
c_responseTimeMatchThreshold = 0.1; % s (threshold diff when matching RT between EEG and behavioural log files)

% manual inclusion (for rerunning if something went wrong; leave empty to run all)
c_CsOnlyProcessTheseParticipants = {};

% start EEGLAB
StartEEGLAB

if c_bDoOnlyPlots
  
  % load existing results
  fprintf('Loading previous results from this script...\n')
  load([c_sAnalysisResultsPath '\' c_sAllTrialDataFileName], ...
    'SAllTrialData')
  nFinalIncludedParticipants = ...
    length(SAllTrialData.CsFinalIncludedParticipantIDs);
  
else
  
  % get the response data table and remove excluded trials
  % -- load file
  load([c_sAnalysisResultsPath 'AllResponseData_WithExclusions.mat'])
  % -- remove excluded trials and participants
  VbExcluded = TResponses.bTrialExcluded | TResponses.bParticipantExcluded;
  TResponses(VbExcluded, :) = [];
  % -- get list of remaining participants
  CsFinalIncludedParticipantIDs = unique(TResponses.sParticipantID);
  nFinalIncludedParticipants = length(CsFinalIncludedParticipantIDs);
  nFinalIncludedTrials = size(TResponses, 1);
  
  % prepare structure for storing all trial data
  % -- transfer some data straight from the TResponses table
  SAllTrialData.ViFinalIncludedParticipantCounter = ...
    NaN * ones(nFinalIncludedTrials, 1);
  for iFinalIncludedParticipant = 1:nFinalIncludedParticipants
    VbParticipantRows = strcmp(CsFinalIncludedParticipantIDs{...
      iFinalIncludedParticipant}, TResponses.sParticipantID);
    SAllTrialData.ViFinalIncludedParticipantCounter(VbParticipantRows) = ...
      iFinalIncludedParticipant;
  end
  SAllTrialData.ViBlock = TResponses.iBlock;
  SAllTrialData.VPreLoomingWaitTime = TResponses.accelerationOnsetTime;
  SAllTrialData.ViStimulusID = TResponses.iStimulusID;
  SAllTrialData.VResponseTime = TResponses.trialTimeStampAtResponse - ...
    TResponses.accelerationOnsetTime;
  SAllTrialData.VThetaDotAtResponse = ...
    TResponses.carOpticalExpansionRateAtResponse;
  SAllTrialData.ViEEGLogEventNumber = TResponses.iEEGLogEventNumber;
  % -- allocate remaining fields, to be filled out below
  SAllTrialData.VidxResponseERPSample = NaN * ones(nFinalIncludedTrials, 1);
  c_nEpochExtractionSamples = c_epochExtractionDuration * c_nERPSampleRate;
  SAllTrialData.MEEGERP = NaN * ...
    ones(c_nFilterVariants, c_nAllEEGChannels, c_nEpochExtractionSamples, ...
    nFinalIncludedTrials, 'single');
  % -- store some other non-per-trial info
  SAllTrialData.CsFinalIncludedParticipantIDs = ...
    CsFinalIncludedParticipantIDs;
  
  clear TResponses
  
end


%%

% loop through participants
for iFinalIncludedParticipant = 1:nFinalIncludedParticipants
  sParticipantID = SAllTrialData.CsFinalIncludedParticipantIDs{...
    iFinalIncludedParticipant};
  fprintf('******** Participant %s ********\n', sParticipantID)
  
  % process?
  bProcess = isempty(c_CsOnlyProcessTheseParticipants) || ...
    ~isempty(find(strcmp(sParticipantID, ...
    c_CsOnlyProcessTheseParticipants), 1, 'first'));
  if ~bProcess
    fprintf('Not processing now.\n')
    continue
  end
  
  for iFilterVariant = 1:c_nFilterVariants
    sFilterVariant = c_CsFilterVariants{iFilterVariant};
    
    fprintf('*** Filter variant %d (%s)\n', iFilterVariant, sFilterVariant)
    
    if ~c_bDoOnlyPlots
      % load data (structure SEEGFiltered)
      switch iFilterVariant
        case 1
          sFileNameFormat = c_sFilteredFileNameFormat;
        case 2
          sFileNameFormat = c_sLPFilteredFileNameFormat;
      end
      sFileName = sprintf(sFileNameFormat, sParticipantID);
      fprintf('Loading EEG data MAT file %s...\n', sFileName)
      load([c_sEEGAnalysisDataPath sFileName])
      
      % downsample further
      fprintf('Downsampling further to %d Hz...\n', c_nERPSampleRate)
      SEEGFiltered = pop_resample(SEEGFiltered, c_nERPSampleRate);
      assert(length(SEEGFiltered.times) == size(SEEGFiltered.data, 2))
      
      % extract epochs
      fprintf('Extracting epochs...\n')
      % -- append some empty data at the end of log, to make sure also the last
      % -- epoch gets included (the empty data will be after the response, thus
      % -- will not be analysed in later steps)
      appendDuration = c_VEpochExtractionInterval(2); % s
      nAppendSamples = ceil(appendDuration * c_nERPSampleRate);
      c_erpTimeStep = 1 / c_nERPSampleRate;
      SEEGFiltered.data(:, end+1:end+nAppendSamples) = 0;
      SEEGFiltered.times(end+1:end+nAppendSamples) = ...
        SEEGFiltered.times(end) + c_erpTimeStep * (1:nAppendSamples);
      SEEGFiltered.pnts = length(SEEGFiltered.times);
      SEEGFiltered = eeg_checkset(SEEGFiltered);
      % -- call the EEGLAB epoching function
      SEEGEpoched = ...
        pop_epoch(SEEGFiltered, {'151'  '152'  '153'  '154'}, ...
        c_VEpochExtractionInterval, 'epochinfo', 'yes');
      % -- remove baseline
      SEEGEpoched = pop_rmbase(SEEGEpoched, c_VEpochBaselineInterval * 1000); % pop_rmbase wants the interval in ms
      SEEGEpoched = eeg_checkset(SEEGEpoched); % recompute ICA activations
      % -- get the original EEG log event number for the looming onset trig in
      % -- each epoch
      nParticipantEpochs = length(SEEGEpoched.epoch);
      ViEEGLogEventNumberPerEpoch = NaN * ones(nParticipantEpochs, 1);
      for iEpoch = 1:nParticipantEpochs
        ViEEGLogEventNumberPerEpoch(iEpoch) = ...
          SEEGEpoched.epoch(iEpoch).eventurevent{1};
      end
      % -- store the ERP time stamp (in seconds rather than ms)
      SAllTrialData.nERPSampleRate = c_nERPSampleRate;
      SAllTrialData.VERPTimeStamp = SEEGEpoched.times / 1000;
      
      % store the channel locations 
      SAllTrialData.SEEGChannelLocations = SEEGEpoched.chanlocs;
      
      % convert to single precision
      SEEGEpoched.data = single(SEEGEpoched.data);
      SEEGEpoched.icaact = single(SEEGEpoched.icaact);
      
      % loop through the included trials for this participant, find the
      % corresponding epoch for each, and store in the output structure
      VidxParticipantRows = find(...
        SAllTrialData.ViFinalIncludedParticipantCounter == ...
        iFinalIncludedParticipant);
      nParticipantRows = length(VidxParticipantRows);
      for iParticipantRow = 1:nParticipantRows
        % find the epoch for this trial
        idxThisRow = VidxParticipantRows(iParticipantRow);
        iThisEEGLogEventNumber = SAllTrialData.ViEEGLogEventNumber(idxThisRow);
        iThisEpoch = find(ViEEGLogEventNumberPerEpoch == iThisEEGLogEventNumber);
        assert(length(iThisEpoch) == 1)
        % double check that this is indeed the right epoch
        assert(SEEGEpoched.epoch(iThisEpoch).eventtype{1} == ...
          SAllTrialData.ViStimulusID(idxThisRow) + c_iLoomingOnsetTrigIDBase); % matching trial type?
        assert(SEEGEpoched.epoch(iThisEpoch).eventtype{2} == c_iResponseTrigID); % second event in epoch is response?
        epochResponseTime = SEEGEpoched.epoch(iThisEpoch).eventlatency{2} / 1000;
        assert(abs(epochResponseTime - SAllTrialData.VResponseTime(idxThisRow)) < ...
          c_responseTimeMatchThreshold); % matching response time?
        % store the info
        SAllTrialData.VidxResponseERPSample(idxThisRow) = ...
          find(SAllTrialData.VERPTimeStamp >= ...
          SAllTrialData.VResponseTime(idxThisRow), 1,'first');
        SAllTrialData.MEEGERP(iFilterVariant, :, :, idxThisRow) = ...
          SEEGEpoched.data(:, :, iThisEpoch);
      end % iParticipantRow for loop
      
    end % if ~c_bDoOnlyPlots
    
    % plotting
    VidxParticipantRows = find(...
      SAllTrialData.ViFinalIncludedParticipantCounter == ...
      iFinalIncludedParticipant);
    close all
    figure(1)
    c_CViEEGChannelsToPlot = {30 31 32 48};
    c_bPlotResponseLockedScalpMaps = true;
    set(gcf, 'Name', [sParticipantID ' : ' sFilterVariant])
    
    MakeERPOverviewFigure(SAllTrialData.VERPTimeStamp, c_nERPSampleRate, ...
      SAllTrialData.SEEGChannelLocations, c_nEEGDataChannels, ...
      [], [], ...
      squeeze(SAllTrialData.MEEGERP(iFilterVariant, :, :, VidxParticipantRows)), ...
      [], ...
      SAllTrialData.ViStimulusID(VidxParticipantRows), ...
      SAllTrialData.VResponseTime(VidxParticipantRows), ...
      SAllTrialData.VidxResponseERPSample(VidxParticipantRows), ...
      c_CViEEGChannelsToPlot, [], ...
      c_bPlotResponseLockedScalpMaps)
    if c_bSavePlots
      saveas(gcf, sprintf('%s\\ParticipantERPFiltVar_%s_Filt%d%s.png', ...
        c_sAnalysisPlotPath, sParticipantID, iFilterVariant, sFilterVariant))
    end
    
    if ~c_bSavePlots
      disp('Press any key to continue...')
      pause
    end
    
  end % iFilterVariant
  
end % iLogFile


%% make plot for all participants

VbIncluded = true * ones(length(SAllTrialData.VResponseTime), 1);
ViIncluded = find(VbIncluded);

for iFilterVariant = 1:c_nFilterVariants
  sFilterVariant = c_CsFilterVariants{iFilterVariant};
  figure(100 + iFilterVariant)
  clf
  c_CViEEGChannelsToPlot = {30 31 32 48 [30 31 32 20 57]};
  c_ViICAComponentsToPlot = [];
  c_bPlotResponseLockedScalpMaps = true;
  c_VERPPlotLimits = [-4 8];
  MakeERPOverviewFigure(SAllTrialData.VERPTimeStamp, c_nERPSampleRate, ...
    SAllTrialData.SEEGChannelLocations, c_nEEGDataChannels, ...
    [], [], ...
    squeeze(SAllTrialData.MEEGERP(iFilterVariant, :, :, ViIncluded)), ...
    [], ...
    SAllTrialData.ViStimulusID(ViIncluded), ...
    SAllTrialData.VResponseTime(ViIncluded), ...
    SAllTrialData.VidxResponseERPSample(ViIncluded), ...
    c_CViEEGChannelsToPlot, [], ...
    c_bPlotResponseLockedScalpMaps, c_VERPPlotLimits)
  if c_bSavePlots
    saveas(gcf, sprintf('%s\\AllERPs_FilterVariant%d%s.png', ...
      c_sAnalysisPlotPath, iFilterVariant, sFilterVariant))
  end
end % iFilterVariant

%%

if ~c_bDoOnlyPlots
  % save the ERP data from all participants
  fprintf('Saving file with all ERP data...\n')
  save([c_sAnalysisResultsPath c_sAllTrialDataFilterVariantsFileName], '-v7.3',  'SAllTrialData')
end


