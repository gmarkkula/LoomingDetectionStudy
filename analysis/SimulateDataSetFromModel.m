
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


function SSimulatedDataSet = SimulateDataSetFromModel(...
  SExperiment, sModel, SParameterSet, SSettings)

% Input
% =====
%
% SExperiment.
%   nConditions (the number of different lead vehicle scenarios, not counting pre-looming wait times)
%   nRepetitionsPerTrialTypeInDataSet (reps per combination of lead vehicle scenario and pre-looming wait time)
%   VPreLoomingWaitTimes
%   SLoomingTraces
%   bERPIncluded
%
% sModel
%
% SParameterSet
%
%
% Output
% ======
%
% SSimulatedDataSet.
%   ViCondition
%   ViPreLoomingWaitTime
%   VResponseTime
%   VThetaDotAtResponse
%   MnEarlyResponsesPerCondition (row vector 1 x no of conditions)
%   MnNonResponsesPerCondition (row vector 1 x no of conditions)
%   SStimulusERP
%     MERPs [one ERP in each row]
%     VidxResponseSample
%   SResponseERP
%     MERPs [one ERP in each row]


% get some constants
c_nPreLoomingWaitTimes = length(SExperiment.VPreLoomingWaitTimes);
c_nTrialsPerDataSet = SExperiment.nConditions * c_nPreLoomingWaitTimes * ...
  SExperiment.nRepetitionsPerTrialTypeInDataSet;

% % need to upsample?
% bUpSample = contains(sModel, 'WW');
% nWWUpSamplingRatio = SSettings.modelSimulationTimeStep / ...
%   SSettings.wwModelSimulationTimeStep;

% model
switch sModel
  case {'T', 'T0'}
    fModelFunction = @SimulateOneTrial_ThresholdModel;
  case {'A', 'AG', 'AL', 'AV', 'AGL' ,'AVG', 'AVL', 'AVGL', 'pAG', 'pAL'}
    fModelFunction = @SimulateOneTrial_AccumulatorModel;
    SParameterSet = SetDefaultValuesForAnyMissingAccumulatorModelParameters(SParameterSet);
  case {'WG', 'WVG', 'WGS'}
    fModelFunction = @SimulateOneTrial_WongAndWangModel;
  otherwise
    error('Unexpected model identifier %s.', sModel)
end % sModel switch

% loop through conditions etc to generate simulated data set
% -- preallocate variables
nOKTrials = 0;
[SSimulatedDataSet.ViCondition, ...
  SSimulatedDataSet.ViPreLoomingWaitTime, ...
  SSimulatedDataSet.VResponseTime, ...
  SSimulatedDataSet.VThetaDotAtResponse] = ...
  deal(NaN * ones(c_nTrialsPerDataSet, 1));
[SSimulatedDataSet.MnEarlyResponsesPerCondition, ...
  SSimulatedDataSet.MnNonResponsesPerCondition] = ...
  deal(zeros(1, SExperiment.nConditions));
if SExperiment.bERPIncluded
  SSimulatedDataSet.SStimulusERP.MERPs = ...
    zeros(c_nTrialsPerDataSet, length(SSettings.SStimulusERP.VTimeStamp));
  SSimulatedDataSet.SStimulusERP.VidxResponseSample = ...
    NaN * ones(c_nTrialsPerDataSet, 1);
end
% -- loop
for iCondition = 1:SExperiment.nConditions
  for iPreLoomingWaitTime = 1:c_nPreLoomingWaitTimes
    STrial = SExperiment.SLoomingTraces(...
      iCondition).SPreLoomingWaitTime(iPreLoomingWaitTime);
    
    for iRepetition = 1:SExperiment.nRepetitionsPerTrialTypeInDataSet
      
      % run model once
      [idxModelResponse, VModelERP] = feval(fModelFunction, ...
        STrial.VTimeStamp, STrial.VThetaDot, SParameterSet, SSettings);  
      
      
      % trial to be excluded?
      if isinf(idxModelResponse)
        % no response before hitting max optical expansion rate in trial
        SSimulatedDataSet.MnNonResponsesPerCondition(1, iCondition) = ...
          SSimulatedDataSet.MnNonResponsesPerCondition(1, iCondition) + 1;
        continue
      end
      if STrial.VTimeStamp(idxModelResponse) < 0
        % response before looming onset
        SSimulatedDataSet.MnEarlyResponsesPerCondition(1, iCondition) = ...
          SSimulatedDataSet.MnEarlyResponsesPerCondition(1, iCondition) + 1;
        continue
      end
      nOKTrials = nOKTrials + 1;
      
      % store results from OK trial
      SSimulatedDataSet.ViCondition(nOKTrials) = iCondition;
      SSimulatedDataSet.ViPreLoomingWaitTime(nOKTrials) = iPreLoomingWaitTime;
      %       if isinf(idxModelResponse)
      %         SSimulatedDataSet.VResponseTime(nOKTrials) = Inf;
      %         SSimulatedDataSet.VThetaDotAtResponse(nOKTrials) = Inf;
      %       else
      SSimulatedDataSet.VResponseTime(nOKTrials) = ...
        STrial.VTimeStamp(idxModelResponse);
      SSimulatedDataSet.VThetaDotAtResponse(nOKTrials) = ...
        STrial.VThetaDot(idxModelResponse);
      %       end
      
      if SSettings.bSaveTrialActivation
        % save the model activation (time stamped as the original looming
        % scenario, not according to the special ERP time stamping)
        SSimulatedDataSet.STrialERPs(nOKTrials).VERP = VModelERP;
      end
      if SExperiment.bERPIncluded
        % get ERP samples to extract - from start of stimulus-locked
        % interval to response
        idxFirstExtractedModelERPSample = find(STrial.VTimeStamp == ...
          SSettings.SStimulusERP.VTimeStamp(1), 1, 'first');
        assert(length(idxFirstExtractedModelERPSample) == 1)
        nExtractedModelERPSamples = ...
          idxModelResponse - idxFirstExtractedModelERPSample + 1;
        % get the ERP samples
        SSimulatedDataSet.SStimulusERP.MERPs(...
          nOKTrials, 1:nExtractedModelERPSamples) = ...
          VModelERP(idxFirstExtractedModelERPSample:idxModelResponse);
        % subtract baseline
        trialERPBaseline = ...
          mean(SSimulatedDataSet.SStimulusERP.MERPs(nOKTrials, ...
          SSettings.SStimulusERP.VidxBaselineInterval));
        SSimulatedDataSet.SStimulusERP.MERPs(nOKTrials, :) = ...
          SSimulatedDataSet.SStimulusERP.MERPs(nOKTrials, :) - ...
          trialERPBaseline;
        % store the sample at which the response was made
        %         if isinf(idxModelResponse)
        %           SSimulatedDataSet.SStimulusERP.VidxResponseSample(nOKTrials) = Inf;
        %         else
        SSimulatedDataSet.SStimulusERP.VidxResponseSample(nOKTrials) = ...
          nExtractedModelERPSamples;
        %         end
      end % if SExperiment.bERPIncluded
      
    end % iRepetition for loop
  end % iPreLoomingWaitTime for loop
  
  %   if false
  %     figure(200)
  %     set(gcf, 'Name', GetModelParameterisationString(STrueParameters))
  %     set(gcf, 'Position', [139         322        1013         344])
  %     subplotGM(2, c_nTrialTypes, 1, iCondition)
  %     histogram(SSimulatedDataSet.TTrials.responseTime(SSimulatedDataSet.TTrials.iTrialType == iCondition), 0:0.25:6)
  %     title(sprintf('Mean: %.2f; Std dev: %.2f', VSimulatedParticipantRTAveragesPerTrialType(iCondition), ...
  %       VSimulatedParticipantRTStdDevsPerTrialType(iCondition)))
  %     subplotGM(2, c_nTrialTypes, 2, iCondition)
  %     histogram(SSimulatedDataSet.TTrials.thetaDotAtResponse(SSimulatedDataSet.TTrials.iTrialType == iCondition), linspace(0, 6e-3, 20))
  %   end
  
end % iCondition for loop

% remove unused elements in output arrays
if nOKTrials < c_nTrialsPerDataSet
  SSimulatedDataSet.ViCondition(nOKTrials+1:end) = [];
  SSimulatedDataSet.ViPreLoomingWaitTime(nOKTrials+1:end) = [];
  SSimulatedDataSet.VResponseTime(nOKTrials+1:end) = [];
  SSimulatedDataSet.VThetaDotAtResponse(nOKTrials+1:end) = [];
  if SExperiment.bERPIncluded
    SSimulatedDataSet.SStimulusERP.MERPs(nOKTrials+1:end, :) = [];
    SSimulatedDataSet.SStimulusERP.VidxResponseSample(nOKTrials+1:end) = [];
  end
end


if SExperiment.bERPIncluded
  % add response-locked ERPs
  SSimulatedDataSet = ...
    AddResponseLockedERPsToStruct(SSimulatedDataSet, SSettings);
  % if responses after the epoch extraction interval were extracted,
  % truncate the stimulus-locked ERP back to the intended length
  SSimulatedDataSet.SStimulusERP.MERPs = ...
    SSimulatedDataSet.SStimulusERP.MERPs(:, ...
    1:length(SSettings.SStimulusERP.VTimeStamp));
end
