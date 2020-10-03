
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


function MLogLikelihoods = GetParticipantLogLikelihoods(...
  c_nSimulatedTrialsPerCondition, c_VContaminantFractions, c_nResponseTypes, ...
  c_SExperiment, c_SConditionRTBins, c_SParticipantResponsesPerConditionRTBin, ...
  SSimulatedDataSet, iParticipant)

c_bPlot = false;
if c_bPlot
  figure(999)
  clf
  set(gcf, 'Name', sprintf('%d simulated trials per condition', c_nSimulatedTrialsPerCondition))
end

c_nContaminantFractions = length(c_VContaminantFractions);
MLogLikelihoods = zeros(c_nContaminantFractions, c_nResponseTypes);
for iCondition = 1:c_SExperiment.nConditions
  % get model-predicted probability of each RT bin
  VnModelBinResponses = ...
    GetRTBinCountsForDataSetAndCondition(...
    SSimulatedDataSet, c_SConditionRTBins, [], iCondition);
  % loop over contaminant response fractions
  for iContaminantFraction = 1:c_nContaminantFractions
    % add contaminant responses as uniform distribution over the trial
    % duration
    thisContaminantFraction = c_VContaminantFractions(iContaminantFraction);
    c_ratioOfContaminantToNonContaminant = thisContaminantFraction / ...
      (1 - thisContaminantFraction);
    nContaminantResponsesPerCondition = ...
      c_ratioOfContaminantToNonContaminant * c_nSimulatedTrialsPerCondition;
    VnAdjustedModelBinResponses = VnModelBinResponses + ...
      nContaminantResponsesPerCondition/length(VnModelBinResponses);
    % get model probabilities across RT bins
    VModelBinProbabilities = VnAdjustedModelBinResponses / ...
      sum(VnAdjustedModelBinResponses);
    % calculate log likelihood for this condition (and this
    % parameterisation) - for all response types
    for iResponseType = 1:c_nResponseTypes
      % get log likelihood contribution per response bin
      VBinContributionsToConditionLogLikelihood = ...
        c_SParticipantResponsesPerConditionRTBin(...
        iParticipant, iCondition, iResponseType).VnResponses .* ...
        log(VModelBinProbabilities);
      % sum to get log likelihood for this condition
      conditionLogLikelihood = ...
        sum(VBinContributionsToConditionLogLikelihood);
      % add to total log likelihood for this participant (and this
      % parameterisation)
      MLogLikelihoods(iContaminantFraction, iResponseType) = ...
        MLogLikelihoods(iContaminantFraction, iResponseType) + conditionLogLikelihood;
      % plot?
      if c_bPlot
        subplotGM(c_nResponseTypes, c_SExperiment.nConditions, iResponseType, iCondition)
        hold on
        plot(c_SConditionRTBins(iCondition).VRTBinCentres, ...
          VModelBinProbabilities * sum(c_SParticipantResponsesPerConditionRTBin(...
          iParticipant, iCondition, iResponseType).VnResponses), ...
          'k-', 'LineWidth', iContaminantFraction)
      end % if c_bPlot
    end % iResponseType for loop
  end % iContaminantFraction for loop
end % iCondition for loop

if c_bPlot
  for iCondition = 1:c_SExperiment.nConditions
    for iResponseType = 1:c_nResponseTypes
      subplotGM(c_nResponseTypes, c_SExperiment.nConditions, iResponseType, iCondition)
      hBar = bar(c_SConditionRTBins(iCondition).VRTBinCentres, ...
        c_SParticipantResponsesPerConditionRTBin(...
        iParticipant, iCondition, iResponseType).VnResponses, ...
        'EdgeColor', 'none', 'FaceColor', [.5 .5 1]);
      uistack(hBar, 'bottom')
      set(gca, 'XLim',  [c_SConditionRTBins(iCondition).VRTBins(1) 6])
    end
  end
  pause
end