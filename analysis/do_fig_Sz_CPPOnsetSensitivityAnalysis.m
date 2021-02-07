
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

disp('Loading data...')
load([c_sAnalysisResultsPath c_sModelFittingDataFileName]')
c_nParticipants = length(CsParticipantIDs);
load([c_sAnalysisResultsPath c_sCPPOnsetMATFileName])
SMainCPPOnsetResults = SCPPOnsetResults;
clear SCPPOnsetResults

c_VERPTimeStamp = c_SSettings.SResponseERP.VTimeStamp;
idxResponseSample = c_SSettings.SResponseERP.idxResponseSample;

%%

% parameters to vary for the CPP onset estimation
c_VnTrialsPerAverageForCPPOnset = [3 5 7];
c_VCPPOnsetERPFraction = [0.2 0.3 0.4];
c_VMinERPAtResponse = [1.5 2 2.5];
c_nTests = 3^3;
c_iMainTest = 14;

% plotting
c_nPlotRows = 6;
c_bDoParticipantPlots = false;

% loop through the CPP onset estimation parameter combinations
[VnTotalAveragedRTs, VnTotalExcluded, VnExcludedFromExclParticipants...
  VLargestCPPOnsetDiff, VGrandMeanCPPOnset] = deal(NaN * ones(c_nTests, 1));
iTest = 0;
for i = 1:length(c_VnTrialsPerAverageForCPPOnset)
  c_nTrialsPerAverageForCPPOnset = c_VnTrialsPerAverageForCPPOnset(i);
  for j = 1:length(c_VCPPOnsetERPFraction)
    c_cppOnsetERPFraction = c_VCPPOnsetERPFraction(j);
    for k = 1:length(c_VMinERPAtResponse)
      c_minERPAtResponse = c_VMinERPAtResponse(k);
      iTest = iTest + 1;
      
      fprintf('Estimating CPP onset with n_C = %d, f_C = %d %%, u_C = %.1f uV...\n\t', ...
        c_nTrialsPerAverageForCPPOnset, 100 * c_cppOnsetERPFraction, ...
        c_minERPAtResponse)
      
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
        if c_bDoParticipantPlots
          fprintf('.')
          figure(iParticipant)
          clf
        end
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
          if c_bDoParticipantPlots
            subplotGM(c_nPlotRows, c_nTrialTypes, 1, iCondition)
            hold on
          end
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
              if c_bDoParticipantPlots
                axis([-1 0 -5 20])
                plot(c_VERPTimeStamp(idxCPPOnset:idxResponseSample), ...
                  VAvResponseERP(idxCPPOnset:idxResponseSample), '-', 'Color', [1 1 1] * 0.8)
                plot(c_VERPTimeStamp(idxCPPOnset), VAvResponseERP(idxCPPOnset), 'm+')
                plot(c_VERPTimeStamp(idxResponseSample), VAvResponseERP(idxResponseSample), 'k+')
              end
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
          if c_bDoParticipantPlots
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
          end
          
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
      fprintf('Excluded %d (%.1f%%) out of %d averaged trials.\n', ...
        nTotalExcluded, 100*nTotalExcluded/nTotalAveragedRTs, nTotalAveragedRTs)
      
      VnTotalAveragedRTs(iTest) = nTotalAveragedRTs;
      VnTotalExcluded(iTest) = nTotalExcluded;
      
      
      %% how much of the exclusion came from the participants that were excluded in the main CPP onset estimation?
      [VnIncluded, VnExcluded] = deal(NaN * ones(c_nParticipants, 1));
      for iParticipant = 1:c_nParticipants
        VbParticipantRows = SCPPOnsetResults.ViDataSet == iParticipant;
        VnIncluded(iParticipant) = length(find(...
          SCPPOnsetResults.VbHasCPPOnsetTime(VbParticipantRows)));
        VnExcluded(iParticipant) = length(find(...
          ~SCPPOnsetResults.VbHasCPPOnsetTime(VbParticipantRows)));
      end
      %[(1:c_nParticipants)' VnIncluded' VnExcluded']
      
      nExcludedAvTrialsFromExclParticipants = ...
        sum(VnExcluded(SMainCPPOnsetResults.ViExcludedParticipants));
      fprintf('\tOut of the %d excluded trials, %d (%.1f %%) were from the %d excluded participants.\n', ...
        sum(VnExcluded), nExcludedAvTrialsFromExclParticipants, ...
        100 * nExcludedAvTrialsFromExclParticipants / sum(VnExcluded), ...
        length(SMainCPPOnsetResults.ViExcludedParticipants))
      
      VnExcludedFromExclParticipants(iTest) = nExcludedAvTrialsFromExclParticipants;
      
      nIncludedForIncludedPs = sum(VnIncluded(SMainCPPOnsetResults.ViIncludedParticipants));
      nExcludedForIncludedPs = sum(VnExcluded(SMainCPPOnsetResults.ViIncludedParticipants));
      nTotalForIncludedPs = nIncludedForIncludedPs + nExcludedForIncludedPs;
      fprintf('\tAmong the included participants, %d (%.1f %%) of the total %d averaged trials were excluded,\n\t\tleaving %d included trials.\n', ...
        nExcludedForIncludedPs, 100 * nExcludedForIncludedPs / nTotalForIncludedPs, ...
        nTotalForIncludedPs, nIncludedForIncludedPs)
      
      
        % provide a plot showing the CPP onset distributions
        figure(1000 + iTest)
        clf
        VConditionGrandMeans = NaN * ones(c_nTrialTypes, 1);
        sConditionGrandMeans = '';
        for iCondition = 1:c_nTrialTypes
          
          % get grand mean across participants for this condition
          VParticipantConditionMeans = NaN * ...
            ones(length(SMainCPPOnsetResults.ViIncludedParticipants), 1);
          for iIncludedParticipant = 1:length(SMainCPPOnsetResults.ViIncludedParticipants)
            iParticipant = SMainCPPOnsetResults.ViIncludedParticipants(iIncludedParticipant);
            VbRows = SCPPOnsetResults.ViCondition == iCondition & ...
              SCPPOnsetResults.VbHasCPPOnsetTime & ...
              SCPPOnsetResults.ViDataSet == iParticipant;
            VParticipantConditionMeans(iIncludedParticipant) = ...
              mean(SCPPOnsetResults.VCPPRelOnsetTime(VbRows));
          end
          VConditionGrandMeans(iCondition) = mean(VParticipantConditionMeans, 'omitnan');
          sConditionGrandMeans = sprintf('%s%.0f, ', sConditionGrandMeans, ...
            VConditionGrandMeans(iCondition) * 1000);
          
          % get means across entire dataset
          VbRows = SCPPOnsetResults.ViCondition == iCondition & ...
            SCPPOnsetResults.VbHasCPPOnsetTime & ...
            ismember(SCPPOnsetResults.ViDataSet, ...
            SMainCPPOnsetResults.ViIncludedParticipants);
          VThisConditionCPPRelOnsetTime = ...
            SCPPOnsetResults.VCPPRelOnsetTime(VbRows);
          VThisConditionLogNegCPPRelOnsetTime = log(-VThisConditionCPPRelOnsetTime);
          
          %
          subplotGM(c_nTrialTypes, 2, iCondition, 1)
          histogram(VThisConditionCPPRelOnsetTime, -.8:.025:0)
          hold on
          plot([1 1] * mean(VThisConditionCPPRelOnsetTime), get(gca, 'YLim'), 'r-')
          plot([1 1] * VConditionGrandMeans(iCondition), get(gca, 'YLim'), 'g-')
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
        
        
        % get the largest between-condition difference in CPP onset relative response
        VSortedConditionGrandMeans = sort(VConditionGrandMeans);
        VLargestCPPOnsetDiff(iTest) = VSortedConditionGrandMeans(end) - VSortedConditionGrandMeans(1);   
        fprintf('\tThe per-condition mean CPP onsets rel. response were (%s) ms,\n\t\twith largest difference of %.1f ms.\n', ...
          sConditionGrandMeans(1:end-2), VLargestCPPOnsetDiff(iTest) * 1000)
        
        % get the overall grand mean of CPP onset relative response
        VGrandMeanCPPOnset(iTest) = mean(VConditionGrandMeans);
        fprintf('\tThe overall grand mean of CPP onsets rel. response was %.0f ms.\n', 1000 * VGrandMeanCPPOnset(iTest))
        
        if c_bDoParticipantPlots
          disp('\tPress any key to continue...\n')
          pause
        end
      
      
    end % k for loop
  end % j for loop
end % i for loop



%% make figure

SetPlottingConstants
c_nMetrics = 3;
c_nBins = 10;
c_VYLim = [0 12];
figure(100)
set(gcf, 'Position', [100 150 c_nFullWidthFigure_px 300])
clf
for iMetric = 1:c_nMetrics
  subplot(1, c_nMetrics, iMetric)
  set(gca, 'FontSize', c_stdFontSize, 'FontName', c_sFontName)
  hold on
  switch iMetric
    case 1 % % of these excludsions from the excluded participants
      VMetric = 100 * VnExcludedFromExclParticipants ./ VnTotalExcluded;
      VXLim = [35 62];
      sLabel = sprintf('Fraction of exclusions from\nexcluded participants (%%)');
    case 2 % overall grand mean of CPP onset
      VMetric = 1000 * VGrandMeanCPPOnset;
      VXLim = [-205 -110];
      sLabel = sprintf('Grand average CPP onset\nrel. response (ms)');
    case 3 % max between-condition diff in average CPP onset
      VMetric = 1000 * VLargestCPPOnsetDiff;
      VXLim = [0 50];
      sLabel = sprintf('Max. abs. between-condition difference\nin CPP onset rel. response (ms)');
  end
  VBinEdges = linspace(VXLim(1), VXLim(2), c_nBins+1);
  histogram(VMetric, VBinEdges, 'LineStyle', 'none', 'FaceColor', [1 1 1] * .7)
  axis([VXLim c_VYLim])
  plot([1 1] * VMetric(c_iMainTest), c_VYLim, 'k-', 'LineWidth', c_stdLineWidth)
  if iMetric == 1
    ylabel(sprintf('Count (-)\n'), 'FontSize', c_annotationFontSize, 'FontName', c_sFontName)
  end
  xlabel(sLabel, 'FontSize', c_annotationFontSize, 'FontName', c_sFontName)
  text(VXLim(1), c_VYLim(2), ['   ' char(int8('A') + iMetric - 1)], ...
    'FontSize', c_panelLabelFontSize, 'FontName', c_sFontName, ...
    'FontWeight', 'bold', 'VerticalAlignment', 'middle')
end
      



