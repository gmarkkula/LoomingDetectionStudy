
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


% For each model, goes through the ABC sample distance metrics generated
% for the Lamble et al data in the do_9... step, and uses these fits to
% derive uniform priors for the main ABC fits (to our own data), saving the
% results in UniformPriorsFromLambleEtAlStudyFits.mat. This script also 
% does an optional more extensive analysis of the Lamble et al ABC fits, 
% across a range of ABC distance thresholds, and saves plots showing the 
% results of this analysis.

%% init
clearvars
close all force

SetLoomingDetectionStudyAnalysisConstants

c_CsModels = {'T' 'A' 'AG' 'AL' 'AV' 'AGL' 'AVG' 'AVL' 'AVGL'};
c_nModels = length(c_CsModels);

% settings for the more complete ABC fit analysis (set to false and switch
% to the shorter commented-out vectors to only calculate the uniform
% priors)
c_bDoFullDistanceThresholdAndModelComparison = true;
c_VMaxAbsResponseDistancesToPlot = 0.05:0.05:0.8;
% c_VMaxAbsResponseDistancesToPlot = 0.5;
c_VMaxNonResponseFractionsToPlot = [0.025 0.05 1];
% c_VMaxNonResponseFractionsToPlot = 0.05;

c_nResponseDistanceThresholds = length(c_VMaxAbsResponseDistancesToPlot);
c_nResponseFractionThresholds = length(c_VMaxNonResponseFractionsToPlot);

% settings for what to save
c_bSavePlots = true;
c_bSaveAnalysisResults = true;

% settings for generating the uniform priors for the main model fits
c_bDeriveUniformPriors = true;
c_maxAbsResponseDistanceForPrior = 0.5;
c_maxNonResponseFractionForPrior = 0.05;
c_credibleIntervalExpansionFactorForPrior = 0.5;
% -- limits for clipping unreasonably large prior bounds
c_SMaxPriorBounds.T_ND.VBounds = [0 1];
c_SMaxPriorBounds.sigma.VBounds = [0 25]; % 25 gives a CDF of 0.55 at 1 for a 0.1 s time step, i.e. there is a 45% chance that the noise is above the threshold after 0.1 s
c_SMaxPriorBounds.thetaDot_d.VBounds = [0 Inf];
c_SMaxPriorBounds.K.VBounds = [0 100000]; % 100000, gives accumulation to threshold 1 in 0.1 s at 0.0001 rad/s over sensation threshold (which may be zero, dep on model)
c_SMaxPriorBounds.sigma_K.VBounds = [0 Inf];
c_SMaxPriorBounds.thetaDot_s.VBounds = [0 0.006]; % double the typical _detection_ threshold from literature
c_SMaxPriorBounds.T_L.VBounds = [0.1 20]; % at 20 s, leakage is essentially negligible in the looming detection paradigm

% settings for the GetModelFitFromABCSamples function
c_bKernelSmoothingAllowed = false;
c_SPlotOptions.bMakeScatterPlots = false;
c_SPlotOptions.bMakeHeatMaps = false;
c_SPlotOptions.bMakePosteriorPredictiveCheckFromModeOfPosterior = false;
c_SPlotOptions.bMakePosteriorPredictiveCheckFromMixOfPosteriorSamples = false;
c_SPlotOptions.fVisualisePosteriorPredictiveCheck = ...
  @VisualisePosteriorPredictiveCheckForLambleEtAlStudy;

c_CsDistanceMetricsInFit = {...
  'NormalisedMeanThetaDotAtResponse'
  'NormalisedThetaDotCI_GroupMean'
  'FractionEarlyResponses'};

c_nMeshPointsPerDimensionForKernelSmoothing = 10; % high values here lead to long computations for models with many parameters

c_sExperimentName = 'LambleEtAlStudy';
c_sLambleEtAlObservations = GetLambleEtAlObservations;
c_iLambleEtAlDataSet = 1;
c_ViLambleEtAlConditionsInFit = [1 2];


if c_bDeriveUniformPriors
  % load any existing results
  if exist([c_sAnalysisResultsPath c_sLambleEtAlDerivedPriorsFileName], 'file')
    fprintf('Loading existing uniform priors...\n')
    load([c_sAnalysisResultsPath c_sLambleEtAlDerivedPriorsFileName])
  end
end

%% analyse
MnRetainedParameterSets = NaN * ones(c_nModels, ...
  c_nResponseFractionThresholds, c_nResponseDistanceThresholds);
for iModel = 1:c_nModels
  
  % load ABC sample results
  sModel = c_CsModels{iModel};
  fprintf('Loading ABC samples for model %s...\n', sModel)
  SFileConstants = GetFileConstants(c_sExperimentName, sModel);
  SOut = LoadABCSamples(SFileConstants.sResultsMATFile);
  
  for iResponseFractionThreshold = 1:c_nResponseFractionThresholds
    for iResponseDistanceThreshold = 1:c_nResponseDistanceThresholds
      
      % get model fit for this ABC distance threshold
      thisMaxAbsResponseDistance = ...
        c_VMaxAbsResponseDistancesToPlot(iResponseDistanceThreshold);
      thisMaxNonResponseFraction = ...
        c_VMaxNonResponseFractionsToPlot(iResponseFractionThreshold);
      fprintf('\tGetting fit/plots for f = %.3f, d = %.3f...\n', ...
        thisMaxNonResponseFraction, thisMaxAbsResponseDistance)
      c_SPlotOptions.iBaseFigureNumber = iModel * 100;
      [MnRetainedParameterSets(iModel, iResponseFractionThreshold, ...
        iResponseDistanceThreshold), ...
        CsFreeParameterNames, SFreeParameterCredibleIntervals, ...
        SPosteriorMeanParameterSet, SPosteriorModeParameterSet] = ...
        GetModelFitFromABCSamples(SOut, c_sLambleEtAlObservations, ...
        c_iLambleEtAlDataSet, ...
        c_CsDistanceMetricsInFit, [thisMaxAbsResponseDistance * [1 1] thisMaxNonResponseFraction], ...
        c_ViLambleEtAlConditionsInFit, ...
        c_nMeshPointsPerDimensionForKernelSmoothing, c_SPlotOptions, ...
        c_bKernelSmoothingAllowed);
      drawnow
      
      if iResponseDistanceThreshold == 1 && ...
          iResponseFractionThreshold == 1
        nFreeParameters = length(CsFreeParameterNames);
        [MFreeParametersMean, MFreeParametersMode, ...
          MFreeParametersSmallestCredible, ...
          MFreeParametersLargestCredible] = ...
          deal(NaN * ones(c_nResponseFractionThresholds, ...
          c_nResponseDistanceThresholds, nFreeParameters));
      end
      
      MFreeParametersMean(iResponseFractionThreshold, iResponseDistanceThreshold, :) = ...
        SPosteriorMeanParameterSet.VFreeParameters;
      MFreeParametersMode(iResponseFractionThreshold, iResponseDistanceThreshold, :) = ...
        SPosteriorModeParameterSet.VFreeParameters;
      MFreeParametersSmallestCredible(iResponseFractionThreshold, iResponseDistanceThreshold, :) = ...
        SFreeParameterCredibleIntervals.MAllIntervals(:, 1);
      MFreeParametersLargestCredible(iResponseFractionThreshold, iResponseDistanceThreshold, :) = ...
        SFreeParameterCredibleIntervals.MAllIntervals(:, 2);
      
      if c_bDeriveUniformPriors && ...
          thisMaxAbsResponseDistance == c_maxAbsResponseDistanceForPrior && ...
          thisMaxNonResponseFraction == c_maxNonResponseFractionForPrior
        % delete any existing prior bounds for this model
        if exist('SUniformPriorBounds', 'var') && ...
            isfield(SUniformPriorBounds, sModel)
          SUniformPriorBounds = rmfield(SUniformPriorBounds, sModel);
        end
        % get bounds for uniform priors for fitting of these models to our
        % dataset
        VCredibleIntervalWidths = ...
          SFreeParameterCredibleIntervals.MAllIntervals(:, 2) - ...
          SFreeParameterCredibleIntervals.MAllIntervals(:, 1);
        VExpansions = c_credibleIntervalExpansionFactorForPrior * ...
          VCredibleIntervalWidths;
        VPriorLowerBounds = ...
          SFreeParameterCredibleIntervals.MAllIntervals(:, 1) - VExpansions;
        VPriorUpperBounds = ...
          SFreeParameterCredibleIntervals.MAllIntervals(:, 2) + VExpansions;
        for iParam = 1:nFreeParameters
          sThisParam = CsFreeParameterNames{iParam};
%           SFreeParameterCredibleIntervals.MAllIntervals(iParam, :)
          VMaxPriorBounds = c_SMaxPriorBounds.(sThisParam).VBounds;
          lowerBound =  max(VMaxPriorBounds(1), VPriorLowerBounds(iParam));
          upperBound = min(VMaxPriorBounds(2), VPriorUpperBounds(iParam));
          SUniformPriorBounds.(sModel).(sThisParam).VBounds = ...
            [lowerBound upperBound];
        end
      end
      
    end % iDistanceThreshold for loop
  end % iResponseFractionThreshold for loop
  
  
  % doing full analysis across distance thresholds and models?
  if c_bDoFullDistanceThresholdAndModelComparison
    
    MbSamplesRetainedForDistance = ...
      squeeze(MnRetainedParameterSets(iModel, :, :) > 0);
    SModelParameterBounds = SOut.SModelParameterBounds;
    clear SOut
    if c_bSaveAnalysisResults
      save(sprintf('%sLambleEtAlModelFitAnalysisResults_%s.mat', c_sAnalysisResultsPath, sModel))
    end
    
    %%
    % plots showing parameter estimates as function of distance threshold
    figure(iModel)
    set(gcf, 'Position', [149   145   772   519])
    clf
    set(gcf, 'Name', sprintf('Model %s', sModel))
    nPlotRowCols = ceil(sqrt(nFreeParameters));
    for iParam = 1:nFreeParameters
      subplot(nPlotRowCols, nPlotRowCols, iParam)
      for iMaxNonResponseFraction = c_nResponseFractionThresholds:-1:1
        iLineWidth = (c_nResponseFractionThresholds - ...
          iMaxNonResponseFraction + 0.5);
        VbSamplesRetainedForFractionAndDistance = MbSamplesRetainedForDistance(...
          iMaxNonResponseFraction, :);
        VResponseDistancesWithRetainedSamples = ...
          c_VMaxAbsResponseDistancesToPlot(VbSamplesRetainedForFractionAndDistance);
        fill([VResponseDistancesWithRetainedSamples ...
          fliplr(VResponseDistancesWithRetainedSamples)], ...
          [MFreeParametersSmallestCredible(iMaxNonResponseFraction, ...
          VbSamplesRetainedForFractionAndDistance, iParam) ...
          fliplr(MFreeParametersLargestCredible(iMaxNonResponseFraction, ...
          VbSamplesRetainedForFractionAndDistance, iParam))], [1 1 1] * 0.5, ...
          'LineStyle', 'none', 'FaceAlpha', 0.3)
        hold on
        plot(c_VMaxAbsResponseDistancesToPlot, MFreeParametersMode(...
          iMaxNonResponseFraction, :, iParam), 'kx-', 'LineWidth', iLineWidth)
        plot(c_VMaxAbsResponseDistancesToPlot, MFreeParametersMean(...
          iMaxNonResponseFraction, :, iParam), 'ko-', 'LineWidth', iLineWidth)
        set(gca, 'YLim', SModelParameterBounds.(CsFreeParameterNames{iParam}).VBounds);
      end % iMaxNonResponseFraction for loop
      title(CsFreeParameterNames{iParam})
    end % iParam for loop
    drawnow
    if c_bSavePlots
      saveas(gcf, sprintf('%sEstimatedParametersPerABCDistance_%s_Model%s.png', ...
        SFileConstants.sAnalysisPlotsPath, c_sExperimentName, sModel))
    end
    
    % plot comparing no of retained samples across models
    figure(10)
    c_sModelColour = 'rgbcmyk';
    set(gcf, 'Position', [ 38         246        1187         420])
    for iMaxNonResponseFraction = 1:c_nResponseFractionThresholds
      subplot(1, c_nResponseFractionThresholds, iMaxNonResponseFraction)
      sPlotColour = c_sModelColour(mod(iModel-1, length(c_sModelColour))+1);
      iLineWidth = 1 + floor((iModel-1)/length(c_sModelColour));
      semilogy(c_VMaxAbsResponseDistancesToPlot, ...
        squeeze(MnRetainedParameterSets(iModel, iMaxNonResponseFraction, :)), ...
        '-', 'Color', sPlotColour, 'LineWidth', iLineWidth)
      MPlotXLim(iMaxNonResponseFraction, :) = get(gca, 'XLim');
      MPlotYLim(iMaxNonResponseFraction, :) = get(gca, 'YLim');
      hold on
      xlabel('d')
      if iMaxNonResponseFraction == 1
        ylabel('Retained ABC samples')
      end
    end % iMaxNonResponseFraction for loop
    
  end % if c_bDoDistanceThresholdAndModelComparison
  
  drawnow
  
end % iModel for loop


%%
if c_bDoFullDistanceThresholdAndModelComparison
  figure(10)
  VXLim = [min(MPlotXLim(:, 1)) max(MPlotXLim(:, 2))];
  VYLim = [min(MPlotYLim(:, 1)) max(MPlotYLim(:, 2))];
  for iMaxNonResponseFraction = 1:c_nResponseFractionThresholds
    subplot(1, c_nResponseFractionThresholds, iMaxNonResponseFraction)
    axis([VXLim VYLim])
    title(sprintf('f = %.3f', ...
      c_VMaxNonResponseFractionsToPlot(iMaxNonResponseFraction)))
  end
  legend(c_CsModels, 'Location', 'SouthEast')
  if c_bSavePlots
    saveas(gcf, sprintf('%sRetainedABCSamplesPerModel_%s.png', ...
      SFileConstants.sAnalysisPlotsPath, c_sExperimentName))
  end
end

if c_bDeriveUniformPriors
  fprintf('Saving uniform priors...\n')
  save([c_sAnalysisResultsPath c_sLambleEtAlDerivedPriorsFileName], 'SUniformPriorBounds')
end



