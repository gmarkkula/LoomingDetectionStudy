
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


% Runs the behavioural ANOVA, testing for the hypothesised effects of
% initial distance and acceleration magnitude on (log-transformed) optical
% expansion rate at detection response. 

clearvars
close all force

SetLoomingDetectionStudyAnalysisConstants

% running the ANOVA also without the EOG-based trial and participant
% exclusion, to see whether or not this affects the conclusions (it
% doesn't)

for iExclusionApproach = 1:2
  
 
  load([c_sAnalysisResultsPath 'AllResponseData_WithExclusions.mat'])
  VbBasicExclusion = TResponses.iBlock <= 0 | ...
    TResponses.iStimulusID > 10 | ...
    isnan(TResponses.carOpticalExpansionRateAtResponse) | ...
    TResponses.bIncorrectResponse;
  
  switch iExclusionApproach
    case 1
      % only minimal exclusion
      sExclusionApproach = 'minimal exclusion';
      VbExcluded = VbBasicExclusion;
    case 2
      % also EOG exclusion, and resulting participant exclusion
      sExclusionApproach = 'complete exclusion';
      VbExcluded = VbBasicExclusion | ...
        TResponses.bTrialExcluded | TResponses.bParticipantExcluded;
  end
  TResponses(VbExcluded, :) = [];
  fprintf('******** Running ANOVA with %s: %d data points from %d participants.\n', ...
    sExclusionApproach, ...
    size(TResponses, 1), length(unique(TResponses.iParticipantCounter)))
  
  
  
  %% ANOVA
  
  c_sDependentVariable = 'carOpticalExpansionRateAtResponse';
  VDependentVariableData = TResponses.(c_sDependentVariable);
  c_CsPredictors = {'iBlock', 'initialCarDistance', 'accelerationLevel', ...
    'accelerationOnsetTime', 'iParticipantCounter'};
  c_nPredictors = length(c_CsPredictors);
  c_ViRandomEffectPredictors = [5];
  nIncluded = size(TResponses, 1);
  CVPredictors = cell(1, c_nPredictors);
  for iPredictor = 1:c_nPredictors
    CVPredictors{iPredictor} = TResponses.(c_CsPredictors{iPredictor});
  end
  
  [p, STable, SStats] = anovan(log(VDependentVariableData), ...
    CVPredictors, 'model', 2, 'random', c_ViRandomEffectPredictors, ...
    'varnames', c_CsPredictors);
  
  % get partial eta squared values
  VSumOfSquares = cell2mat({STable{2:end, 2}})';
  errorSS = VSumOfSquares(end-1);
  VFactorSS = VSumOfSquares(1:end-2);
  VPartialEtaSquared = VFactorSS ./ (VFactorSS + errorSS)
  
  % get per-block thetaDot averages
  for iBlock = 1:5
    VbRows = TResponses.iBlock == iBlock;
    fprintf('Average thetaDot at response in block %d: %.5f rad/s\n', iBlock, ...
      mean(TResponses.carOpticalExpansionRateAtResponse(VbRows)))
  end
  fprintf('Grand total average thetaDot at response: %.5f rad/s\n', iBlock, ...
      mean(TResponses.carOpticalExpansionRateAtResponse))
  
  
  
  %% interaction plots
  
  c_sPredictor2Colors = 'kgbmcr';
  c_nPredictor2Colors = length(c_sPredictor2Colors);
  c_scatterAlpha = 0.05;
  
  % loop through all two-way interactions
  iFigure = 100*iExclusionApproach;
  for iPredictor1 = 1:c_nPredictors-1
    VPredictor1Data = TResponses.(c_CsPredictors{iPredictor1});
    VPredictor1Values = unique(VPredictor1Data);
    nPredictor1Values = length(VPredictor1Values);
    for iPredictor2 = iPredictor1+1:c_nPredictors
      VPredictor2Data = TResponses.(c_CsPredictors{iPredictor2});
      VPredictor2Values = unique(VPredictor2Data);
      nPredictor2Values = length(VPredictor2Values);
      
      % open new figure window for this interaction
      iFigure = iFigure + 1;
      figure(iFigure)
      set(gcf, 'Name', [sExclusionApproach ' : ' c_CsPredictors{iPredictor1} ' x ' c_CsPredictors{iPredictor2}])
      clf
      hold on
      
      % loop through all combinations of values of the two predictors
      VhLine = zeros(nPredictor2Values, 1);
      CsPredictor1XTickInfo = cell(nPredictor1Values, 1);
      CsPredictor2LegendInfo = cell(nPredictor2Values, 1);
      for iPredictor2Value = 1:nPredictor2Values
        sPredictor2Color = c_sPredictor2Colors(...
          mod(iPredictor2Value-1, c_nPredictor2Colors)+1);
        VMeanValues = zeros(nPredictor1Values, 1);
        for iPredictor1Value = 1:nPredictor1Values
          
          % get the data points for this combination of predictor values
          VbIncluded = ...
            VPredictor1Data == VPredictor1Values(iPredictor1Value) & ...
            VPredictor2Data == VPredictor2Values(iPredictor2Value);
          nIncluded = length(find(VbIncluded));
          
          % do scatter plot showing all data points
          hScatter = ...
            scatter(iPredictor1Value * ones(nIncluded, 1), ...
            VDependentVariableData(VbIncluded), 10, '+', 'MarkerEdgeColor', sPredictor2Color);
          hScatter.MarkerEdgeAlpha = c_scatterAlpha;
          
          % store mean value
          VMeanValues(iPredictor1Value) = median(VDependentVariableData(VbIncluded));
          
          % store string for X tick label
          CsPredictor1XTickInfo{iPredictor1Value} = num2str(VPredictor1Values(iPredictor1Value));
          
        end % iPredictor1Value for loop
        
        % plot the means across predictor 1 values
        VhLine(iPredictor2Value) = plot(1:nPredictor1Values, VMeanValues, ...
          [sPredictor2Color 'o-'], 'LineWidth', 1.5);
        
        % store string for legend
        CsPredictor2LegendInfo{iPredictor2Value} = sprintf('%s = %s', ...
          c_CsPredictors{iPredictor2}, num2str(VPredictor2Values(iPredictor2Value)));
        
      end % iPredictor2Value for loop
      
      % finalise plot
      set(gca, 'XLim', [0 nPredictor1Values+1])
      set(gca, 'XTick', 1:nPredictor1Values)
      set(gca, 'XTickLabel', CsPredictor1XTickInfo)
      set(gca, 'YScale', 'log')
      xlabel(c_CsPredictors{iPredictor1})
      ylabel(c_sDependentVariable);
      legend(VhLine, CsPredictor2LegendInfo)
      
    end % iPredictor2 for loop
  end % iPredictor1 for loop
  
  
end % iExclusionApproach for loop



%% Check among included participants for responses in catch trials

VbValidCatchTrials = TResponses.iBlock >= 1 & ...
  TResponses.iStimulusID > 10 & ~TResponses.bParticipantExcluded;
VbValidCatchTrialsWithResponses = ...
  VbValidCatchTrials & TResponses.bResponseMade;

nValidCatchTrials = length(find(VbValidCatchTrials));
nValidCatchTrialsWithResponses = length(find(VbValidCatchTrialsWithResponses));
fprintf('Detection responses were made in %d (%.2f %%) out of the %d catch trials for participants included in the analyses.\n', ...
  nValidCatchTrialsWithResponses, ...
  100 * nValidCatchTrialsWithResponses / nValidCatchTrials, nValidCatchTrials)

