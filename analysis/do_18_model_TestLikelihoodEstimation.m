
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


% as a verification of the MLE fitting approach, this script takes the MLE
% fits obtained by the do_17... script and re-estimates model likelihood
% for these fits across a range of different simulation sizes, to verify
% that the variability in likelihood is sufficiently low for the model AIC 
% comparisons to make sense (it is)

clearvars
close all

c_bDoSimulationSizeTests = true; % set to false if saved results from this script already exist

SetLoomingDetectionStudyAnalysisConstants
fprintf('Loading ML fitting results...\n')
load([c_sAnalysisResultsPath c_sMLFittingMATFileName])
c_VnSimulationsPerCondition = 200:100:3000;
c_nSimulationSizes = length(c_VnSimulationsPerCondition);

c_contaminantFractionToTest = 0.01;
c_iContaminantFraction = ...
  find(c_VContaminantFractions == c_contaminantFractionToTest);
assert(length(c_iContaminantFraction) == 1)

c_nModelsToAnalyse = 2; % T and A

%% get log likelihoods for all models, all participants, all response
%  types (RT and CPP onset), and all simulation sizes

if c_bDoSimulationSizeTests
  
  fprintf('Doing simulation size tests:\n')
  MAllLogLikelihoods = NaN * ones(c_nModelsToAnalyse, c_nParticipantsToAnalyse, ...
    c_nSimulationSizes, c_nResponseTypes);
  for iModel = 1:c_nModelsToAnalyse
    sModel = c_CsModels{iModel};
    fprintf('\t%s', sModel)
    SBaseParameterSet = ...
      DrawModelParameterSetFromPrior_LoomingDetectionStudy(sModel, c_SSettings);
    SBaseParameterSet.alpha_ND = 1;
    for iParticipant = 1:c_nParticipantsToAnalyse
      fprintf('.')
      for iResponseType = 1:c_nResponseTypes
        SBestParameterSetForParticipantAndResponseType = ...
          SResults.(sModel).SModelParameterisations(...
          SResults.MiBestParameterisation(iParticipant, iModel, ...
          c_iContaminantFraction, iResponseType));
        SBestParameterSetForParticipantAndResponseType = ...
          SetStructFieldsFromOtherStruct(...
          SBaseParameterSet, SBestParameterSetForParticipantAndResponseType);
        VLogLikelihoods = NaN * ones(c_nSimulationSizes, 1);
        for iSimulationSize = 1:c_nSimulationSizes
          nSimulationsPerCondition = c_VnSimulationsPerCondition(iSimulationSize);
          c_SSimulatedExperiment.nRepetitionsPerTrialTypeInDataSet = ...
            nSimulationsPerCondition / length(c_SExperiment.VPreLoomingWaitTimes);
          SSimulatedDataSet = ...
            SimulateDataSetFromModel(c_SSimulatedExperiment, sModel, ...
            SBestParameterSetForParticipantAndResponseType, c_SSettings);
          MLogLiks = GetParticipantLogLikelihoods(nSimulationsPerCondition, ...
            c_VContaminantFractions, c_nResponseTypes, c_SExperiment, ...
            c_SConditionRTBins, c_SParticipantResponsesPerConditionRTBin, ...
            SSimulatedDataSet, iParticipant);
          MAllLogLikelihoods(iModel, iParticipant, iSimulationSize, :) = ...
            MLogLiks(c_iContaminantFraction, :);
        end % iSimulationSize for loop
      end % iResponseType for loop
    end % iParticipant for loop
    fprintf('\n')
  end % iModel for loop
  
  fprintf('Saving results...\n')
  save([c_sAnalysisResultsPath c_sLikelihoodTestsMATFileName], ...
    'c_*', 'MAllLogLikelihoods')
  
else
  
  load([c_sAnalysisResultsPath c_sLikelihoodTestsMATFileName])
  
end


%% make and save figures

c_nPlotRows = 4;
c_nPlotCols = 6;
c_MModelColours = [0 0 0; 0 0 1];
c_MLightModelColours = 0.5 * (c_MModelColours + 1);
c_toleranceLLRadius = 1;
c_iAveragingIntervalStart = ceil(c_nSimulationSizes / 2);

MLogLikDevFromLargeSimSizeAverage = ...
  NaN * ones(c_nModelsToAnalyse, c_nParticipantsToAnalyse, c_nResponseTypes, c_nSimulationSizes);
for iResponseType = 1:c_nResponseTypes
  sResponseType = c_CsResponseTypeFieldNames{iResponseType}(2:end);
  figure(iResponseType)
  clf
  set(gcf, 'Position', [194    66   954   542])
  set(gcf, 'Name', sResponseType)
  for iParticipant = 1:c_nParticipantsToAnalyse
    subplot(c_nPlotRows, c_nPlotCols, iParticipant)
    hold on
    for iModel = 1:c_nModelsToAnalyse
      sModel = c_CsModels{iModel};
      bestLogLikFromFitting = ...
        SResults.MMaxLogLikelihood(iParticipant, iModel, iResponseType);
      VLogLiksPerSimSize = ...
        squeeze(MAllLogLikelihoods(iModel, iParticipant, :, iResponseType));
      averageLogLikLargeSimSizes = ...
        mean(VLogLiksPerSimSize(c_iAveragingIntervalStart:end));
      MLogLikDevFromLargeSimSizeAverage(iModel, iParticipant, iResponseType, :) = ...
        VLogLiksPerSimSize - averageLogLikLargeSimSizes;
      hFill = fill(c_VnSimulationsPerCondition([1 end end 1]), ...
        averageLogLikLargeSimSizes + [-1 -1 1 1] * c_toleranceLLRadius, ...
        c_MLightModelColours(iModel, :), 'EdgeColor', 'none');
      uistack(hFill, 'bottom')
      plot(c_VnSimulationsPerCondition([1 end]), bestLogLikFromFitting * [1 1], ...
        '--', 'Color', c_MModelColours(iModel, :), 'LineWidth', 0.5)
      VhModelPlot = plot(c_VnSimulationsPerCondition, VLogLiksPerSimSize, ...
        '-', 'Color', c_MModelColours(iModel, :), 'LineWidth', 1.5);
      hold on
    end
  end
  saveas(gcf, sprintf('%sLogLikOverSimSizes_%s.png', ...
    c_sAnalysisPlotPath, sResponseType))
end

figure(10)
clf
for iModel = 1:c_nModelsToAnalyse
  for iResponseType = 1:c_nResponseTypes
    subplotGM(c_nResponseTypes, c_nModelsToAnalyse, iResponseType, iModel)
    MLogLikDevsHere = ...
      squeeze(MLogLikDevFromLargeSimSizeAverage(iModel, :, iResponseType, :));
    VLogLikDevStdDev = std(MLogLikDevsHere); % across dim 1 i.e. participants
    plot(c_VnSimulationsPerCondition, VLogLikDevStdDev, 'k-')
    title(sprintf('Model %s, %s', c_CsModels{iModel}, ...
      c_CsResponseTypeFieldNames{iResponseType}(2:end)))
  end
end