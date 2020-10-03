
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


% Organises the behavioural and EEG data from AllTrialData.mat into a 
% smaller struct SObservations, better stuited for the ABC and MLE model 
% fitting, saving it in a file ModelFittingData.mat. The EEG
% data is reduced by downsampling further and only saving the ERPs 
% averaged over the five CPP electrodes (centred on Pz), also 
% precalculating response-locked versions of these ERPs. Compared to
% AllTrialData.mat, also information on non-responses and early responses 
% is included in the SObservations struct (read back in from 
% AllResponseData.mat).

clearvars 
close all

SetLoomingDetectionStudyAnalysisConstants
c_SSettings = GetLoomingDetectionStudyModelFittingConstants;

fprintf('Loading %s...\n', c_sAllTrialDataFileName)
load([c_sAnalysisResultsPath c_sAllTrialDataFileName])
nTrials = length(SAllTrialData.VResponseTime);

% get participant IDs
CsParticipantIDs = SAllTrialData.CsFinalIncludedParticipantIDs;

% get trial meta data
SObservations.ViDataSet = SAllTrialData.ViFinalIncludedParticipantCounter;
SObservations.ViBlock = SAllTrialData.ViBlock;
SObservations.ViCondition = SAllTrialData.ViStimulusID;
SObservations.ViPreLoomingWaitTime = NaN * ones(nTrials, 1);
for iPreLoomingWaitTime = 1:length(c_VPreLoomingWaitTimes)
  VbRows = SAllTrialData.VPreLoomingWaitTime == ...
    c_VPreLoomingWaitTimes(iPreLoomingWaitTime);
  SObservations.ViPreLoomingWaitTime(VbRows) = iPreLoomingWaitTime;
end

% get behavioural results
SObservations.VResponseTime = SAllTrialData.VResponseTime;
SObservations.VThetaDotAtResponse = SAllTrialData.VThetaDotAtResponse;

% get frequency of response errors per participant and condition
load([c_sAnalysisResultsPath 'AllResponseData.mat'])
nFinalIncludedParticipants = length(CsParticipantIDs);
for iFinalIncludedParticipant = 1:nFinalIncludedParticipants
  sParticipantID = CsParticipantIDs{iFinalIncludedParticipant};
  for iStimulusID = 1:c_nStimulusTypes
    VbResponseErrorInIncludedTrial = ...
      strcmp(TResponses.sParticipantID, sParticipantID) & ...
      TResponses.iBlock > 0 & ...
      TResponses.iStimulusID == iStimulusID & ...
      TResponses.bIncorrectResponse;
    SObservations.MnEarlyResponsesPerCondition(...
      iFinalIncludedParticipant, iStimulusID) = ...
      length(find(VbResponseErrorInIncludedTrial & TResponses.bResponseMade));
    SObservations.MnNonResponsesPerCondition(...
      iFinalIncludedParticipant, iStimulusID) = ...
      length(find(VbResponseErrorInIncludedTrial & ~TResponses.bResponseMade));
  end
end


% get ERPs
% -- find what electrodes to use
VidxElectrodes = GetElectrodeIndices(...
  SAllTrialData.SEEGChannelLocations, c_CsElectrodesForModelFitting);
% -- take the average of these electrodes, and store it as a matrix with
% -- ERP in each column
SObservations.SStimulusERP.MERPs = ...
  squeeze(mean(SAllTrialData.MEEGERP(VidxElectrodes, :, :), 1));
% -- resample to model simulation time stamp
SObservations.SStimulusERP.MERPs = interp1(...
  SAllTrialData.VERPTimeStamp, SObservations.SStimulusERP.MERPs, ...
  c_SSettings.SStimulusERP.VTimeStamp);
% -- transpose, to get each ERP in one row
SObservations.SStimulusERP.MERPs = SObservations.SStimulusERP.MERPs';
% -- get ERP sample at which response was made
SObservations.SStimulusERP.VidxResponseSample = NaN * ones(nTrials, 1);
for iTrial = 1:nTrials
  idxResponseSampleInTrial = find(c_SSettings.SStimulusERP.VTimeStamp >= ...
    SObservations.VResponseTime(iTrial), 1, 'first');
  assert(length(idxResponseSampleInTrial) == 1)
  SObservations.SStimulusERP.VidxResponseSample(iTrial) = ...
    idxResponseSampleInTrial;
end
% % -- get also response-locked version of the ERPs
SObservations = ...
  AddResponseLockedERPsToStruct(SObservations, c_SSettings);

% save 
fprintf('Saving %s...\n', c_sModelFittingDataFileName)
save([c_sAnalysisResultsPath c_sModelFittingDataFileName], ...
  'SObservations', 'CsParticipantIDs')


% provide a plot of the downslampled stimulus and response locked ERPs
figure(1)
clf

for iCondition = 1:4
  
  VbTrialRows = SObservations.ViCondition == iCondition;
  
  subplot(2, 1, 1)
  hold on
  plot(c_SSettings.SStimulusERP.VTimeStamp, ...
    mean(SObservations.SStimulusERP.MERPs(VbTrialRows, :)))
  grid on
  
  subplot(2, 1, 2)
  hold on
  plot(c_SSettings.SResponseERP.VTimeStamp, ...
    mean(SObservations.SResponseERP.MERPs(VbTrialRows, :)))
  grid on
  
  end



