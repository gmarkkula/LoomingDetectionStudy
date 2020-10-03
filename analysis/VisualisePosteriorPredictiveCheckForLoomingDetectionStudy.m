
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


function VisualisePosteriorPredictiveCheckForLoomingDetectionStudy(SABCSamples, ...
  SVisualisationDataSet, SObservations, iDataSet, SSettings)

c_minRT = 0;
c_maxRT = 4;
c_observedRTBinSize = 0.2;
c_VObservedRTBinEdges = c_minRT:c_observedRTBinSize:c_maxRT;
c_VObservedRTBinCentres = c_VObservedRTBinEdges(1:end-1) + c_observedRTBinSize/2;
c_modelRTBinSize = 0.1;
c_VModelRTBinEdges = c_minRT:c_modelRTBinSize:c_maxRT;
c_VModelRTBinCentres = c_VModelRTBinEdges(1:end-1) + c_modelRTBinSize/2;
c_nVisualisationActivationTraces = 20;

c_VPercentilesToPlot = 10:20:90;
c_nPercentilesToPlot = length(c_VPercentilesToPlot);

c_VPreAnchorTimes = [0.5 1];
c_VPostAnchorTimes = [3 0.5];

c_nPlotRows = 3;

for iCondition = 1:SABCSamples.SExperiment.nConditions
  
  % show RT distributions
  subplotGM(c_nPlotRows, SABCSamples.SExperiment.nConditions, 1, iCondition)
  % -- observed RTs
  VObservedRTsThisCondition = SObservations.VResponseTime(...
    SObservations.ViCondition == iCondition & ...
    SObservations.ViDataSet == iDataSet);
  histogram(VObservedRTsThisCondition, c_VObservedRTBinEdges, 'FaceAlpha', 0.5, ...
    'FaceColor', SSettings.CVConditionPlotRGBs{iCondition}, 'EdgeColor', 'none')
  hold on
  observedRTPlotArea = length(VObservedRTsThisCondition) * c_observedRTBinSize;
  for iPercentile = 1:length(c_VPercentilesToPlot)
    plotPercentile = c_VPercentilesToPlot(iPercentile);
    VHumanPlotPercentileValue(iPercentile) = ...
      prctile(VObservedRTsThisCondition, plotPercentile);
    plot([1 1] * VHumanPlotPercentileValue(iPercentile), get(gca, 'YLim') * 0.2, '-', ...
      'Color', SSettings.CVConditionPlotRGBs{iCondition})
  end
  % -- model RTs
  VModelRTsThisCondition = SVisualisationDataSet.VResponseTime(...
    SVisualisationDataSet.ViCondition == iCondition);
  VnModelBinCounts = histcounts(VModelRTsThisCondition, c_VModelRTBinEdges);
  modelRTArea = length(VModelRTsThisCondition) * c_modelRTBinSize;
  plot(c_VModelRTBinCentres, VnModelBinCounts * observedRTPlotArea / modelRTArea, 'k-')
  set(gca, 'XLim', [c_minRT c_maxRT])
  for iPercentile = 1:c_nPercentilesToPlot
    plotPercentile = c_VPercentilesToPlot(iPercentile);
    VModelPlotPercentileValue(iPercentile) = ...
      prctile(VModelRTsThisCondition, plotPercentile);
    plot(VModelPlotPercentileValue(iPercentile), 0, 'ko')
  end
  title(sprintf('|d| = %.3f', ...
    mean(abs(VModelPlotPercentileValue - VHumanPlotPercentileValue))))
  
  % show dstributions of percentile deviations in simulated datasets
  subplotGM(c_nPlotRows, SABCSamples.SExperiment.nConditions, 2, iCondition)
  c_percentileDeviationDistributionBinSize = 0.1;
  c_percentileDeviationDistributionMax = 0.8;
  c_VPercentileDeviationDistributionBinEdges = ...
    -c_percentileDeviationDistributionMax:...
    c_percentileDeviationDistributionBinSize:...
    c_percentileDeviationDistributionMax;
  c_VPercentileDistributionBinCentres = ...
    c_VPercentileDeviationDistributionBinEdges(1:end-1) + ...
    c_percentileDeviationDistributionBinSize/2;
  % -- find the individual simulated datasets
  ViConditionWithPrependix = [0; SVisualisationDataSet.ViCondition];
  ViConditionWithAppendix = [SVisualisationDataSet.ViCondition; 0];
  VidxFirstDataSetTrialsForCondition = ...
    find(diff(ViConditionWithPrependix) ~= 0 & ...
    SVisualisationDataSet.ViCondition == iCondition);
  VidxLastDataSetTrialsForCondition = ...
    find(diff(ViConditionWithAppendix) ~= 0 & ...
    SVisualisationDataSet.ViCondition == iCondition);
  nSimDataSets = length(VidxFirstDataSetTrialsForCondition);
  assert(nSimDataSets == length(VidxLastDataSetTrialsForCondition))
  % make a line plot showing distribution of deviations per percentile
  for iPercentile = 1:c_nPercentilesToPlot
    percentileValue = c_VPercentilesToPlot(iPercentile);
    thisPercentileForModelRTs = ...
      prctile(VModelRTsThisCondition, percentileValue);
    VPercentileDeviations = NaN * ones(nSimDataSets, 1);
    for iSimDataSet = 1:nSimDataSets
      VModelRTsThisConditionThisDataSet = ...
        SVisualisationDataSet.VResponseTime(...
        VidxFirstDataSetTrialsForCondition(iSimDataSet):...
        VidxLastDataSetTrialsForCondition(iSimDataSet));
      VPercentileDeviations(iSimDataSet) = ...
        prctile(VModelRTsThisConditionThisDataSet, percentileValue) - ...
        thisPercentileForModelRTs;
    end % iSimDataSet for loop
    VnPercentileDeviationBinCounts = histcounts(VPercentileDeviations, ...
      c_VPercentileDeviationDistributionBinEdges);
    hPlot = plot(c_VPercentileDistributionBinCentres, VnPercentileDeviationBinCounts, ...
      'k-', 'LineWidth', 1 + iPercentile/3);
    hPlot.Color(4) = 0.5;
    hold on
  end % iPercentile for loop
  
  
  %   % show example activation traces
  %   subplotGM(c_nPlotRows, SABCSamples.SExperiment.nConditions, 3, iCondition)
  %   ViThisConditionTrials = ...
  %     find(SVisualisationDataSet.ViCondition == iCondition);
  %   nThisConditionTrials = length(ViThisConditionTrials);
  %   for iERP = 1:c_nVisualisationActivationTraces
  %     iThisERPTrial = ViThisConditionTrials(randi(nThisConditionTrials));
  %     SThisERPTrial = SVisualisationDataSet.STrialERPs(iThisERPTrial);
  %     iThisERPTrialPreLoomingWaitTime = ...
  %       SVisualisationDataSet.ViPreLoomingWaitTime(iThisERPTrial);
  %     SThisERPTrialLoomingTrace = SABCSamples.SExperiment.SLoomingTraces(...
  %       iCondition).SPreLoomingWaitTime(iThisERPTrialPreLoomingWaitTime);
  %     hold on
  %     hPlot = plot(SThisERPTrialLoomingTrace.VTimeStamp, ...
  %       SThisERPTrial.VERP, 'k-');
  %     hPlot.Color(4) = 0.1;
  %   end % iERP for loop
  %   set(gca, 'YLim', [-.1 1.1])
  %   set(gca, 'XLim', [c_minRT c_maxRT])
  %   xlabel('Time (s)')
  
  
  % show average activation traces - both stimulus-locked and response-locked
  
  for iDataSource = 1:2
    for iTimeLockType = 1:2
      subplotGM(c_nPlotRows, SABCSamples.SExperiment.nConditions, ...
        [1 1] * 3, [1 2] + (iTimeLockType-1)*2)
      
      %     % figure out the pre/post anchor samples and time stamps
      %     nPreAnchorSamples = ceil(c_VPreAnchorTimes(iTimeLockType) / ...
      %       SABCSamples.SSettings.modelSimulationTimeStep);
      %     preAnchorTime = ...
      %       nPreAnchorSamples * SABCSamples.SSettings.modelSimulationTimeStep;
      %     nPostAnchorSamples = ceil(c_VPostAnchorTimes(iTimeLockType) / ...
      %       SABCSamples.SSettings.modelSimulationTimeStep) + 1;
      %     postAnchorTime = ...
      %       (nPostAnchorSamples-1) * SABCSamples.SSettings.modelSimulationTimeStep;
      %     VTimeLockedTimeStamp = -preAnchorTime:...
      %       SABCSamples.SSettings.modelSimulationTimeStep:postAnchorTime;
      %     nTimeLockedSamples = nPreAnchorSamples + nPostAnchorSamples;
      %     assert(length(VTimeLockedTimeStamp) == nTimeLockedSamples)
      %
      %     % get a matrix of appropriately anchored ERPs
      %     MTimeLockedERPs = NaN * ones(nTrialsThisCondition, nTimeLockedSamples);
      %     for idxidxTrial = 1:nTrialsThisCondition
      %       idxThisTrial = VidxTrialsThisCondition(idxidxTrial);
      %       SThisERPTrial = SVisualisationDataSet.STrialERPs(idxThisTrial);
      %       iThisERPTrialPreLoomingWaitTime = ...
      %         SVisualisationDataSet.ViPreLoomingWaitTime(idxThisTrial);
      %       SThisERPTrialLoomingTrace = SABCSamples.SExperiment.SLoomingTraces(...
      %         iCondition).SPreLoomingWaitTime(iThisERPTrialPreLoomingWaitTime);
      %       VThisERPTimeStamp = SThisERPTrialLoomingTrace.VTimeStamp;
      %       switch iTimeLockType
      %         case 1 % stimulus-locked
      %           idxAnchorSample = find(VThisERPTimeStamp >= 0, 1, 'first');
      %         case 2 % response-locked
      %           idxAnchorSample = SVisualisationDataSet.VidxResponse(idxThisTrial);
      %       end
      %       if isinf(idxAnchorSample)
      %         MTimeLockedERPs(idxidxTrial, :) = NaN;
      %       else
      %         MTimeLockedERPs(idxidxTrial, :) = GetERPDataAroundAnchor(...
      %           SThisERPTrial.VERP, idxAnchorSample, ...
      %           nPreAnchorSamples, nPostAnchorSamples);
      %       end
      %     end % iTrial for loop
      %
      %     MTimeLockedERPs(isnan(MTimeLockedERPs)) = [];
      
      if iDataSource == 1
        % human 
        SDataSet = SObservations;
        iLineWidth = 3;
        plotAlpha = 0.15;
        VbAllTrials = SObservations.ViDataSet == iDataSet;
        VbTrialsThisCondition = ...
          SObservations.ViDataSet == iDataSet & ...
          SObservations.ViCondition == iCondition;
      else
        % model
        SDataSet = SVisualisationDataSet;
        iLineWidth = 1;
        plotAlpha = 1;
        VbAllTrials = true * ones(size(SVisualisationDataSet.ViCondition));
        VbTrialsThisCondition = ...
          SVisualisationDataSet.ViCondition == iCondition;
      end      
        
      
      if iTimeLockType == 1
        % stimulus-locked
        VERPTimeStamp = SSettings.SStimulusERP.VTimeStamp;
        MTimeLockedERPs = ...
          SDataSet.SStimulusERP.MERPs(VbTrialsThisCondition, :);
      else
        % response-locked
        VERPTimeStamp = SSettings.SResponseERP.VTimeStamp;
        MTimeLockedERPs = ...
          SDataSet.SResponseERP.MERPs(VbTrialsThisCondition, :);
      end
      
      averagePeakResponseERPAcrossConditions = ...
        GetAveragePeakResponseERPForDataSubset(...
        SDataSet, VbAllTrials, SSettings);
      
      hPlot = plot(VERPTimeStamp, ...
        mean(MTimeLockedERPs, 1) / averagePeakResponseERPAcrossConditions, ...
        '-', 'Color', SSettings.CVConditionPlotRGBs{iCondition}, ...
        'LineWidth', iLineWidth);
      hPlot.Color(4) = plotAlpha;
      set(gca, 'XLim', VERPTimeStamp([1 end]))
      set(gca, 'YLim', [-.5 1.2])
      hold on
      
    end % iTimeLockType for loop
  end % iDataSet for loop
  
  
end % iCondition for loop








