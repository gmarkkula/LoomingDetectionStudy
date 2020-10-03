
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


% Analyses the response-locked CPP signal (as stored in the 
% ModelFittingData.mat file) to find time of CPP onset per trial,
% identifies participants for which this analysis is not reliable, and
% saves the results in CPPOnsetResults.mat. Also generates various plots
% illustrating the CPP onset calculations, and a number of ANOVAs checking
% for any biasing effects of the CPP onset exclusions (no such biasing
% effects were identified) as well as the effect of looming condition on
% CPP onset relative the detection response.

clearvars
close all force

SetLoomingDetectionStudyAnalysisConstants
c_SSettings = GetLoomingDetectionStudyModelFittingConstants;

load([c_sAnalysisResultsPath c_sModelFittingDataFileName]')
c_nParticipants = length(CsParticipantIDs);


%%
c_cppOnsetERPFraction = 0.3;
c_minERPAtResponse = 2;
c_nPlotRows = 6;

c_VERPTimeStamp = c_SSettings.SResponseERP.VTimeStamp;
idxResponseSample = c_SSettings.SResponseERP.idxResponseSample;

% prepare output vectors
SCPPOnsetResults.ViDataSet = NaN * ones(size(SObservations.VResponseTime));
SCPPOnsetResults.ViCondition = NaN * ones(size(SObservations.VResponseTime));
SCPPOnsetResults.VCPPRelOnsetTime = NaN * ones(size(SObservations.VResponseTime));
SCPPOnsetResults.VCPPOnsetTime = NaN * ones(size(SObservations.VResponseTime));
SCPPOnsetResults.VbHasCPPOnsetTime = NaN * ones(size(SObservations.VResponseTime));
SCPPOnsetResults.VAveragedResponseTime = NaN * ones(size(SObservations.VResponseTime));
SCPPOnsetResults.VAveragedThetaDotAtResp = NaN * ones(size(SObservations.VResponseTime));

% loop through participants and conditions
nTotalAveragedRTs = 0;
for iParticipant = 1:c_nParticipants
  fprintf('.')
  figure(iParticipant)
  clf
  for iCondition = 1:c_nTrialTypes
    VidxTrialRows = find(SObservations.ViDataSet == iParticipant & ...
      SObservations.ViCondition == iCondition);
    nTrials = length(VidxTrialRows);
    nAveragedTrials = floor(nTrials / c_nTrialsPerAverageForCPPOnset);
    MTrialERPs = SObservations.SResponseERP.MERPs(VidxTrialRows, :);
    VTrialRTs = SObservations.VResponseTime(VidxTrialRows);
    VTrialThetaDotsAtResp = SObservations.VThetaDotAtResponse(VidxTrialRows);
    % sort the data for this participant and condition on response time
    [VSortedRTs, VidxRTSorting] = sort(VTrialRTs);
    MRTSortedERPs = MTrialERPs(VidxRTSorting, :);
    VRTSortedThetaDotsAtResp = VTrialThetaDotsAtResp(VidxRTSorting);
    subplotGM(c_nPlotRows, c_nTrialTypes, 1, iCondition)
    hold on
    % go through the data and construct averaged trials from groups of
    % trials with similar response time
    VCPPRelOnsetTime = NaN * ones(nAveragedTrials, 1);
    VAvRT = NaN * ones(nAveragedTrials, 1);
    VAvThetaDotAtResponse = NaN * ones(nAveragedTrials, 1);
    for iAvTrial = 1:nAveragedTrials
      % get the trials (referring to the sorted list) to include in this
      % averaged trial
      ViRTSortedTrialsForAv = ...
        [1:c_nTrialsPerAverageForCPPOnset] + (iAvTrial-1)*c_nTrialsPerAverageForCPPOnset;
      % get the average response time and thetadot at response
      VAvRT(iAvTrial) = mean(VSortedRTs(ViRTSortedTrialsForAv));
      VAvThetaDotAtResponse(iAvTrial) = ...
        mean(VRTSortedThetaDotsAtResp(ViRTSortedTrialsForAv));
      % get the average response-locked ERP
      MAvResponseERPs = MRTSortedERPs(ViRTSortedTrialsForAv, :);
      VAvResponseERP = mean(MAvResponseERPs, 1);
      % estimate the onset of the pre-decision positivity by finding the
      % last point where the averaged response-locked ERP was less than a
      % given fraction of the ERP at response
      erpAtResponse = VAvResponseERP(idxResponseSample);
      cppOnsetERPThreshold = c_cppOnsetERPFraction * erpAtResponse;
      idxCPPOnset = find(VAvResponseERP(1:idxResponseSample) < cppOnsetERPThreshold, 1, 'last');
      % only record an estimated onset for this averaged trial if one could
      % be found within the response-locked ERP data, and the ERP at
      % response was larger than a given threshold
      if ~isempty(idxCPPOnset) && erpAtResponse > c_minERPAtResponse
        axis([-1 0 -5 20])
        plot(c_VERPTimeStamp(idxCPPOnset:idxResponseSample), ...
          VAvResponseERP(idxCPPOnset:idxResponseSample), '-', 'Color', [1 1 1] * 0.8)
        plot(c_VERPTimeStamp(idxCPPOnset), VAvResponseERP(idxCPPOnset), 'm+')
        plot(c_VERPTimeStamp(idxResponseSample), VAvResponseERP(idxResponseSample), 'k+')
        VCPPRelOnsetTime(iAvTrial) = c_VERPTimeStamp(idxCPPOnset);
      end
    end % iTrial for loop
    
    VCPPOnsetTimes = VAvRT + VCPPRelOnsetTime;
    
    % append results for this participant and condition to output vectors
    VbAvRTsWithCPPOnsets = ~isnan(VCPPRelOnsetTime);
    VidxRange = (nTotalAveragedRTs + [1:nAveragedTrials]);
    SCPPOnsetResults.ViDataSet(VidxRange) = iParticipant;
    SCPPOnsetResults.ViCondition(VidxRange) = iCondition;
    SCPPOnsetResults.VCPPRelOnsetTime(VidxRange) = VCPPRelOnsetTime;
    SCPPOnsetResults.VCPPOnsetTime(VidxRange) = VCPPOnsetTimes;
    SCPPOnsetResults.VbHasCPPOnsetTime(VidxRange) = VbAvRTsWithCPPOnsets;
    SCPPOnsetResults.VAveragedResponseTime(VidxRange) = VAvRT;
    SCPPOnsetResults.VAveragedThetaDotAtResp(VidxRange) = VAvThetaDotAtResponse;
    nTotalAveragedRTs = nTotalAveragedRTs + nAveragedTrials;
    
    % plotting
    nAvRTsWithoutCPPOnsets = length(find(~VbAvRTsWithCPPOnsets));
    if nAvRTsWithoutCPPOnsets > 0
      title(sprintf('%d averaged trials with missing CPP onsets', nAvRTsWithoutCPPOnsets))
    end
    subplotGM(c_nPlotRows, c_nTrialTypes, 2, iCondition)
    histogram(VCPPRelOnsetTime, -1:0.05:0)
    subplotGM(c_nPlotRows, c_nTrialTypes, 3, iCondition)
    plot(VAvRT, VCPPRelOnsetTime, 'kx')
    subplotGM(c_nPlotRows, c_nTrialTypes, 4, iCondition)
    histogram(VCPPOnsetTimes, 0:0.2:4)
    subplotGM(c_nPlotRows, c_nTrialTypes, 5, iCondition)
    histogram(VAvRT(VbAvRTsWithCPPOnsets), 0:0.2:4)
    subplotGM(c_nPlotRows, c_nTrialTypes, 6, iCondition)
    histogram(VAvRT(~VbAvRTsWithCPPOnsets), 0:0.2:4)
    
  end % iCondition for loop
end % iParticipant for loop

%% finalise output vectors

SCPPOnsetResults.ViDataSet(nTotalAveragedRTs+1:end) = [];
SCPPOnsetResults.ViCondition(nTotalAveragedRTs+1:end) = [];
SCPPOnsetResults.VCPPRelOnsetTime(nTotalAveragedRTs+1:end) = [];
SCPPOnsetResults.VCPPOnsetTime(nTotalAveragedRTs+1:end) = [];
SCPPOnsetResults.VbHasCPPOnsetTime(nTotalAveragedRTs+1:end) = [];
SCPPOnsetResults.VAveragedResponseTime(nTotalAveragedRTs+1:end) = [];
SCPPOnsetResults.VAveragedThetaDotAtResp(nTotalAveragedRTs+1:end) = [];

%%

nTotalExcluded = length(find(~SCPPOnsetResults.VbHasCPPOnsetTime));
fprintf('\nExcluded %d (%.1f%%) out of %d averaged trials.\n', ...
  nTotalExcluded, 100*nTotalExcluded/nTotalAveragedRTs, nTotalAveragedRTs)


%%

SCPPOnsetResults.ViParticipantsWithCPPOnsetsInAllConditions = [];
for iParticipant = 1:c_nParticipants
  VbValid = SCPPOnsetResults.ViDataSet == iParticipant & ...
    SCPPOnsetResults.VbHasCPPOnsetTime;
  ViValidConditions = unique(SCPPOnsetResults.ViCondition(VbValid));
  if length(ViValidConditions) == c_nTrialTypes
    SCPPOnsetResults.ViParticipantsWithCPPOnsetsInAllConditions(end+1) = ...
      iParticipant;
  end
  for iCondition = 1:c_nTrialTypes
    MnIncludedAvTrialsPerPAndC(iParticipant, iCondition) = length(find(...
      SCPPOnsetResults.ViDataSet == iParticipant & ...
      SCPPOnsetResults.ViCondition == iCondition & ...
      SCPPOnsetResults.VbHasCPPOnsetTime));
  end
end
fprintf('Included averaged trials per participant and condition:\n')
[(1:c_nParticipants)' MnIncludedAvTrialsPerPAndC]

%% Quantify whether each participant shows an ERP peak at response by calculating 
%  a Cohen's d effect size comparing the ERP 0.5 s before response to ERP
%  at response.

idxEarlySample = find(c_VERPTimeStamp >= c_probeTimeForCPPEffectSizeThreshold, 1, 'first');
idxPeakSample = find(c_VERPTimeStamp >= 0, 1, 'first');
for iParticipant = 1:c_nParticipants
  VEarlyValues = SObservations.SResponseERP.MERPs(...
    SObservations.ViDataSet == iParticipant, idxEarlySample);
  VPeakValues = SObservations.SResponseERP.MERPs(...
    SObservations.ViDataSet == iParticipant, idxPeakSample);
  VpValues(iParticipant) = signrank(VEarlyValues, VPeakValues);
  VdValues(iParticipant) = CalculateCohensDForIndependentSamples(VEarlyValues, VPeakValues);
end
fprintf('Per-participant p-values and d-values when comparing ERP 0.5 s before peak to ERP at peak:\n')
[(1:c_nParticipants)' VpValues' VdValues']
SCPPOnsetResults.VCohensDForPeak = VdValues;

%% get participants to retain for further analysis

ViParticipantsWithDOverThreshold = find(SCPPOnsetResults.VCohensDForPeak > c_requiredERPPeakCohensDForCPPAnalysis);
ViIncludedParticipants = ...
  intersect(SCPPOnsetResults.ViParticipantsWithCPPOnsetsInAllConditions, ...
  ViParticipantsWithDOverThreshold);
ViExcludedParticipants = setdiff(1:c_nParticipants, ViIncludedParticipants);
SCPPOnsetResults.ViIncludedParticipants = ViIncludedParticipants;
SCPPOnsetResults.ViExcludedParticipants = ViExcludedParticipants;

%% save results before continuing

fprintf('Saving results...\n')
save([c_sAnalysisResultsPath c_sCPPOnsetMATFileName], 'c_*', 'SCPPOnsetResults')

%% load saved results

load([c_sAnalysisResultsPath c_sCPPOnsetMATFileName])



%% how much of the exclusion came from the excluded participants?
for iParticipant = 1:c_nParticipants
  VbParticipantRows = SCPPOnsetResults.ViDataSet == iParticipant;
  VnIncluded(iParticipant) = length(find(...
    SCPPOnsetResults.VbHasCPPOnsetTime(VbParticipantRows)));
  VnExcluded(iParticipant) = length(find(...
    ~SCPPOnsetResults.VbHasCPPOnsetTime(VbParticipantRows)));
end
[(1:c_nParticipants)' VnIncluded' VnExcluded']

fprintf('Out of the %d excluded trials, %d were from the %d excluded participants.\n', ...
  sum(VnExcluded), sum(VnExcluded(ViExcludedParticipants)), ...
  length(ViExcludedParticipants))

nIncludedForIncludedPs = sum(VnIncluded(ViIncludedParticipants));
nExcludedForIncludedPs = sum(VnExcluded(ViIncludedParticipants));
nTotalForIncludedPs = nIncludedForIncludedPs + nExcludedForIncludedPs;
fprintf('Among the included participants, %d (%.1f %%) of the total %d averaged trials were excluded, leaving %d included trials.\n', ...
  nExcludedForIncludedPs, 100 * nExcludedForIncludedPs / nTotalForIncludedPs, ...
  nTotalForIncludedPs, nIncludedForIncludedPs)



%% do ANOVAs to investigate effects of exclusions

% Do the distance and acceleration effects on optical expansion rate at
% detection persist when averaging and excluding trials? (If the exclusion
% removed the effect, this could be an indication of the exclusions biasing
% the dataset.)

VInitialCarDistance = c_VTrialInitialDistances(SCPPOnsetResults.ViCondition);
VAccelerationLevel = c_VTrialDecelerations(SCPPOnsetResults.ViCondition);
VbRows = ismember(SCPPOnsetResults.ViDataSet, ...
  ViIncludedParticipants);
c_CsPredictors = {'iParticipant', 'initialCarDistance', 'accelerationLevel'};
CVPredictors = {SCPPOnsetResults.ViDataSet(VbRows) VInitialCarDistance(VbRows) ...
  VAccelerationLevel(VbRows)};
disp('ANOVA for AveragedThetaDotAtResp, all averaged trials')
[p, STable, SStats] = anovan(log(SCPPOnsetResults.VAveragedThetaDotAtResp(VbRows)), ...
  CVPredictors, 'model', 2, 'random', 1, 'varnames', c_CsPredictors);

VbRows = VbRows & logical(SCPPOnsetResults.VbHasCPPOnsetTime);
CVPredictors = {SCPPOnsetResults.ViDataSet(VbRows) ...
  VInitialCarDistance(VbRows) VAccelerationLevel(VbRows)};
disp('ANOVA for AveragedThetaDotAtResp, excluding averaged trials without CPP onset')
[p, STable, SStats] = anovan(log(SCPPOnsetResults.VAveragedThetaDotAtResp(VbRows)), ...
  CVPredictors, 'model', 2, 'random', 1, 'varnames', c_CsPredictors);

% is there an effect of looming condition on CPP onset relative overt
% response? 

CVPredictors = {SCPPOnsetResults.ViDataSet(VbRows) SCPPOnsetResults.ViCondition(VbRows)};
c_CsPredictors = {'iParticipant', 'iCondition'};
disp('ANOVA for CPPRelOnsetTime, excluding averaged trials without CPP onset')
[p, STable, SStats] = anovan(log(-SCPPOnsetResults.VCPPRelOnsetTime(VbRows)), ...
  CVPredictors, 'model', 2, 'random', 1, 'varnames', c_CsPredictors);

% to further check for any biasing effects of the exclusion, check each
% condition separately, only including those participants who have both
% inclusions and exclusions in that condition, and check whether exclusion
% affects detection response time or optical expansion rate at response

c_CsDepVar = {'VAveragedThetaDotAtResp', 'VAveragedResponseTime'};
for iDepVar = 1:length(c_CsDepVar)
  for iCondition = 1:c_nTrialTypes
    % find the participants with both inclusions and exclusions for this condition
    VbThisConditionExclusions = ...
      (SCPPOnsetResults.ViCondition == iCondition & ~SCPPOnsetResults.VbHasCPPOnsetTime);
    ViParticipantsWithExclusions = ...
      unique(SCPPOnsetResults.ViDataSet(VbThisConditionExclusions));
    VbThisConditionInclusions = ...
      (SCPPOnsetResults.ViCondition == iCondition & SCPPOnsetResults.VbHasCPPOnsetTime);
    ViParticipantsWithInclusions = ...
      unique(SCPPOnsetResults.ViDataSet(VbThisConditionInclusions));
    ViParticipantsWithBoth = ...
      intersect(ViParticipantsWithExclusions, ViParticipantsWithInclusions);
    ViParticipantsWithBoth = intersect(ViParticipantsWithBoth, ...
      ViIncludedParticipants);
    % do ANOVA just for those participants, in this condition
    VbRows = SCPPOnsetResults.ViCondition == iCondition & ...
      ismember(SCPPOnsetResults.ViDataSet, ViParticipantsWithBoth);
    CVPredictors = {SCPPOnsetResults.ViDataSet(VbRows) ...
      SCPPOnsetResults.VbHasCPPOnsetTime(VbRows)};
    c_CsPredictors = {'iParticipant', 'bHasCPPOnset'};
    [p, STable, SStats] = anovan(log(SCPPOnsetResults.(c_CsDepVar{iDepVar})(VbRows)), ...
      CVPredictors, 'model', 2, 'random', 1, 'varnames', c_CsPredictors);
    fprintf('ANOVA for %s in condition %d\n', c_CsDepVar{iDepVar}(2:end), iCondition)
    
    sFigName = sprintf('%s: d = %d m; a = %.2f m/s^2', c_CsDepVar{iDepVar}(2:end), ...
      c_VTrialInitialDistances(iCondition), c_VTrialDecelerations(iCondition));
    figure(100*iDepVar + iCondition)
    set(gcf, 'Name', sFigName)
    for iNotExclExcl = 1:2
      for iNotLogLog = 1:2
        subplotGM(2, 2, iNotExclExcl, iNotLogLog)
        VData = SCPPOnsetResults.(c_CsDepVar{iDepVar});
        if iDepVar == 1
          VXLim = [1e-4 1e-2];
        else
          VXLim = [0.3 6];
        end
        if iNotLogLog == 2
          VData = log(VData);
          VXLim = log(VXLim);
        end
        if iNotExclExcl == 1
          VbPlotRows = VbRows & logical(SCPPOnsetResults.VbHasCPPOnsetTime);
        else
          VbPlotRows = VbRows & ~logical(SCPPOnsetResults.VbHasCPPOnsetTime);
        end
        histogram(VData(VbPlotRows), linspace(VXLim(1), VXLim(2), 11))
        hold on
        plot([1 1] * mean(VData(VbPlotRows)), get(gca, 'YLim'), 'r-', 'LineWidth', 2)
      end
    end
  end % iCondition for loop
end % iDepVar



%% provide a plot showing the CPP onset distributions

figure(1000)
clf
for iCondition = 1:c_nTrialTypes
  VbRows = SCPPOnsetResults.ViCondition == iCondition & ...
    SCPPOnsetResults.VbHasCPPOnsetTime;
  VThisConditionCPPRelOnsetTime = ...
    SCPPOnsetResults.VCPPRelOnsetTime(VbRows);
  VThisConditionLogNegCPPRelOnsetTime = log(-VThisConditionCPPRelOnsetTime);
  %
  subplotGM(c_nTrialTypes, 2, iCondition, 1)
  histogram(VThisConditionCPPRelOnsetTime, -.8:.025:0)
  hold on
  plot([1 1] * mean(VThisConditionCPPRelOnsetTime), get(gca, 'YLim'), 'r-')
  if iCondition == c_nTrialTypes
    xlabel('CPP onset relative to response (s)')
  end
  sCondition = sprintf('d = %d m; a = %.2f m/s^2', ...
    c_VTrialInitialDistances(iCondition), c_VTrialDecelerations(iCondition));
  title(sCondition)
  %
  subplotGM(c_nTrialTypes, 2, iCondition, 2)
  histogram(VThisConditionLogNegCPPRelOnsetTime, -6:0.2:0)
  hold on
  plot([1 1] * mean(VThisConditionLogNegCPPRelOnsetTime), get(gca, 'YLim'), 'r-')
  if iCondition == c_nTrialTypes
    xlabel('negative logarithm of the same (-)')
  end
  title(sCondition)
end % iCondition for loop