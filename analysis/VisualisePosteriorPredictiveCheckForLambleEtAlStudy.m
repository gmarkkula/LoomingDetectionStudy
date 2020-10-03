
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


function VisualisePosteriorPredictiveCheckForLambleEtAlStudy(SABCSamples, ...
  SVisualisationDataSet, SObservations, ~, c_SVisualisationSettings)


c_nVisualisationActivationTraces = 20;

for iCondition = 1:SABCSamples.SExperiment.nConditions
  
  ViThisConditionTrials = ...
    find(SVisualisationDataSet.ViCondition == iCondition);
  nThisConditionOKTrials = length(ViThisConditionTrials);
  nThisConditionEarlyResponses = ...
    SVisualisationDataSet.MnEarlyResponsesPerCondition(iCondition);
  nThisConditionNonResponses = ...
    SVisualisationDataSet.MnNonResponsesPerCondition(iCondition);
  nThisConditionTrials = nThisConditionOKTrials + ...
    nThisConditionEarlyResponses + nThisConditionNonResponses;
  
  % show distribution and metrics
  subplotGM(3, SABCSamples.SExperiment.nConditions, 1, iCondition)
  for iDistanceMetric = 1:length(SABCSamples.CsDistanceMetrics)
    sDistanceMetric = SABCSamples.CsDistanceMetrics{iDistanceMetric};
    % call the distance metric function just go create the plot
    feval(sprintf('DistanceMetric_LambleEtAlStudy_%s', sDistanceMetric), ...
      SVisualisationDataSet, SObservations, [], iCondition, ...
      [], [], [], c_SVisualisationSettings, [], true);
  end
  title(sprintf('%.1f %% early resp.; %.1f %% non-resp.', ...
    100 * nThisConditionEarlyResponses / nThisConditionTrials, ...
    100 * nThisConditionNonResponses / nThisConditionTrials))
  
  % show example activation traces for ok trials
  for iERP = 1:c_nVisualisationActivationTraces
    iThisERPTrial = ViThisConditionTrials(randi(nThisConditionOKTrials));
    SThisERPTrial = SVisualisationDataSet.STrialERPs(iThisERPTrial);
    iThisERPTrialPreLoomingWaitTime = ...
      SVisualisationDataSet.ViPreLoomingWaitTime(iThisERPTrial);
    SThisERPTrialLoomingTrace = SABCSamples.SExperiment.SLoomingTraces(...
      iCondition).SPreLoomingWaitTime(iThisERPTrialPreLoomingWaitTime);
    % as fcn of theta dot
    subplotGM(3, SABCSamples.SExperiment.nConditions, 2, iCondition)
    hold on
    hPlot = plot(SThisERPTrialLoomingTrace.VThetaDot, ...
      SThisERPTrial.VERP, 'k-');
    hPlot.Color(4) = 0.1;
    % as fcn of time
    subplotGM(3, SABCSamples.SExperiment.nConditions, 3, iCondition)
    hold on
    hPlot = plot(SThisERPTrialLoomingTrace.VTimeStamp, ...
      SThisERPTrial.VERP, 'k-');
    hPlot.Color(4) = 0.1;
  end % iERP for loop
  subplotGM(3, SABCSamples.SExperiment.nConditions, 2, iCondition)
%   axis([0 0.01 -.1 1.1])
  xlabel('d\theta / dt (rad/s)')
  subplotGM(3, SABCSamples.SExperiment.nConditions, 3, iCondition)
%   set(gca, 'YLim', [-.1 1.1])
  xlabel('Time (s)')
  
end % iCondition for loop