
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


function [nRetainedABCSamples, CsFreeParameterNames, ...
  SFreeParameterCredibleIntervals, SPosteriorMeanParameterSet, ...
  SPosteriorModeParameterSet, SFigureHandles, ...
  MFreeParametersInRetainedSamples, MFreeParameterBounds, SABCSamples] = ...
  GetModelFitFromABCSamples(SABCSamples, SObservations, c_iDataSet, ...
  c_CsDistanceMetricsInFit, c_VMaxAbsDistances, c_ViConditionsInFit, ...
  c_nMeshPointsPerDimensionForKernelSmoothing, c_SPlotOptions, varargin)


% initialise figure handle struct output
SFigureHandles = struct;

if ~isempty(varargin)
  bKernelSmoothingAllowed = varargin{1};
else
  bKernelSmoothingAllowed = true;
end

% need to get mode of posterior?
bGetModeOfPosterior = bKernelSmoothingAllowed && ...
  (nargout >= 5) || (isfield(c_SPlotOptions, ...
  'bMakePosteriorPredictiveCheckFromModeOfPosterior') && ...
  c_SPlotOptions.bMakePosteriorPredictiveCheckFromModeOfPosterior);
if ~bGetModeOfPosterior
  SPosteriorModeParameterSet.VFreeParameters = NaN;
end

% hide figures?
if ~isfield(c_SPlotOptions, 'bHideFigures')
  c_SPlotOptions.bHideFigures = false;
end

% do ABC thresholding basics
[nFreeParameters, CsFreeParameterNames, MFreeParameterBounds, ...
  VbABCSampleRetained, nRetainedABCSamples, MFreeParametersInRetainedSamples, ...
  SPosteriorMeanParameterSet, SFreeParameterCredibleIntervals, SABCSamples] = ...
  DoABCThresholdingBasicsForModel(SABCSamples, c_iDataSet, ...
  c_CsDistanceMetricsInFit, c_VMaxAbsDistances, c_ViConditionsInFit);
ViRetainedABCSamples = find(VbABCSampleRetained);

% % find indices of distance metrics to include
% c_nDistanceMetricsInFit = length(c_CsDistanceMetricsInFit);
% ViDistanceMetricsInFit = NaN * ones(1, c_nDistanceMetricsInFit);
% for iDistanceMetricInFit = 1:c_nDistanceMetricsInFit
%   iDistanceMetric = ...
%     find(strcmp(c_CsDistanceMetricsInFit{iDistanceMetricInFit}, ...
%     SABCSamples.CsDistanceMetrics));
%   assert(length(iDistanceMetric) == 1)
%   ViDistanceMetricsInFit(iDistanceMetricInFit) = iDistanceMetric;
% end
% 
% % get parameter sets as matrix
% SParameterSet = SABCSamples.SModelParameterSets(1); % just to get parameter names
% CsParameterNames = fieldnames(SParameterSet);
% nParameters = length(CsParameterNames);
% MParameterSets = NaN * ones(SABCSamples.SSettings.nABCSamples, nParameters);
% for iParam = 1:nParameters
%   for iABCSample = 1:SABCSamples.SSettings.nABCSamples
%     MParameterSets(iABCSample, iParam) = ...
%       SABCSamples.SModelParameterSets(iABCSample).(CsParameterNames{iParam});
%   end % iABCSample for loop
% end % iParam for loop
% 
% % identify free parameters, and remove fixed parameters from parameter set
% % matrix
% nFreeParameters = 0;
% clear CsFreeParameterNames
% for iParam = nParameters:-1:1
%   if all(MParameterSets(:, iParam) == MParameterSets(1, iParam))
%     MParameterSets(:, iParam) = [];
%   else
%     nFreeParameters = nFreeParameters + 1;
%     CsFreeParameterNames{nFreeParameters} = CsParameterNames{iParam};
%   end
% end
% CsFreeParameterNames = flip(CsFreeParameterNames);
% 
% % get bounds of free parameters
% if ~isfield(SABCSamples, 'SModelParameterBounds')
%   warning('Using dummy draw from prior to get parameter bounds.')
%   c_SFileConstants = ...
%     GetFileConstants(SABCSamples.SExperiment.sName, SABCSamples.sModel);
%   [~, SABCSamples.SModelParameterBounds] = ...
%     feval(c_SFileConstants.sDrawModelParameterSetFunctionName, ...
%     SABCSamples.sModel, SABCSamples.SSettings);
% end
% MFreeParameterBounds = NaN * ones(nFreeParameters, 2);
% for iFreeParameter = 1:nFreeParameters
%   MFreeParameterBounds(iFreeParameter, :) = ...
%     SABCSamples.SModelParameterBounds.(...
%     CsFreeParameterNames{iFreeParameter}).VBounds;
% end
% 
% % identify ABC samples to retain
% VbRetainABCSample = true * ones(SABCSamples.SSettings.nABCSamples, 1);
% for iDistanceMetric = ViDistanceMetricsInFit
%   if length(c_VMaxAbsDistances) == 1
%     thisMetricMaxAbsDistance = c_VMaxAbsDistances(1);
%   else
%     thisMetricMaxAbsDistance = c_VMaxAbsDistances(iDistanceMetric);
%   end
%   for iCondition = c_ViConditionsInFit
%     VbRetainABCSample = ...
%       VbRetainABCSample & ...
%       abs(SABCSamples.MDistanceMetricValues(...
%       :, iDistanceMetric, c_iDataSet, iCondition)) < ...
%       thisMetricMaxAbsDistance;
%   end % iCondition for loop
% end % iDistanceMetric for loop
% MRetainedParameterSets = MParameterSets(VbRetainABCSample, :);
% ViRetainedABCSamples = find(VbRetainABCSample);
% nRetainedParameterSets = length(ViRetainedABCSamples);
% 
% % find credible intervals and means of free parameters
% SFreeParameterCredibleIntervals.MAllIntervals = ...
%   NaN * ones(nFreeParameters, 2);
% VPosteriorMeanFreeParameters = NaN * ones(nFreeParameters, 1);
% for iFreeParam = 1:nFreeParameters
%   VThisParamInRetainedSamples = MRetainedParameterSets(:, iFreeParam);
%   lowPercentile = prctile(VThisParamInRetainedSamples, 2.5);
%   highPercentile = prctile(VThisParamInRetainedSamples, 97.5);
%   VCredibleInterval = [lowPercentile highPercentile];
%   sThisFreeParameter = CsFreeParameterNames{iFreeParam};
%   SFreeParameterCredibleIntervals.(...
%     sThisFreeParameter).VInterval = VCredibleInterval;
%   SFreeParameterCredibleIntervals.MAllIntervals(iFreeParam, :) = ...
%     VCredibleInterval;
%   thisParameterMean = mean(VThisParamInRetainedSamples);
%   VPosteriorMeanFreeParameters(iFreeParam) = thisParameterMean;
%   SPosteriorMeanParameterSet.(sThisFreeParameter) = thisParameterMean;
% end
% SPosteriorMeanParameterSet.VFreeParameters = VPosteriorMeanFreeParameters;


% mode of posterior
if bGetModeOfPosterior
  if nRetainedABCSamples > 0
    
    % get kernel-smoothed posterior
    fprintf('\t\tGetting kernel-smoothed posterior...\n')
    [MParameterMesh, VPosteriorValues, SMeshGrids] = ...
      GetKernelSmoothedPosterior(MFreeParametersInRetainedSamples, ...
      MFreeParameterBounds', c_nMeshPointsPerDimensionForKernelSmoothing);
    
    % find mode of posterior
    [~, idxPosteriorMode] = max(VPosteriorValues);
    VPosteriorModeFreeParameters = MParameterMesh(idxPosteriorMode, :);
    SFreeParametersAtPosteriorMode = GetVectorAsStructFields(...
      VPosteriorModeFreeParameters, CsFreeParameterNames);
    SPosteriorModeParameterSet = SABCSamples.SModelParameterSets(1);
    SPosteriorModeParameterSet = SetStructFieldsFromOtherStruct(...
      SPosteriorModeParameterSet, SFreeParametersAtPosteriorMode);
    
  else
    VPosteriorModeFreeParameters = NaN * ones(1, nFreeParameters);
  end % if zero retained ABC
  SPosteriorModeParameterSet.VFreeParameters = VPosteriorModeFreeParameters;
end % if bGetModeOfPosterior

% scatter plots
if isfield(c_SPlotOptions, 'bMakeScatterPlots') && c_SPlotOptions.bMakeScatterPlots
  fprintf('\t\tMaking scatter plots...\n')
  SFigureHandles.iScatterPlot = c_SPlotOptions.iBaseFigureNumber;
  figure(SFigureHandles.iScatterPlot)
  if c_SPlotOptions.bHideFigures
    set(gcf, 'Visible', 'off')
  end
  set(gcf, 'Name', sprintf('Model %s; %d samples retained', ...
    SABCSamples.sModel, nRetainedABCSamples))
  clf
  for iXParam = 1:nFreeParameters
    for iYParam = 1:nFreeParameters
      subplotGM(nFreeParameters, nFreeParameters, iYParam, iXParam)
      if iXParam == iYParam
        histogram(MFreeParametersInRetainedSamples(:, iXParam));
        set(gca, 'XLim', MFreeParameterBounds(iXParam, :))
        hold on
        plot(SPosteriorMeanParameterSet.VFreeParameters(iXParam) * [1 1], ...
          get(gca, 'YLim'), 'r--')
        if bGetModeOfPosterior
          plot(VPosteriorModeFreeParameters(iXParam) * [1 1], ...
            get(gca, 'YLim'), 'r-')
        end
        plot(SFreeParameterCredibleIntervals.MAllIntervals(iXParam, 1) * [1 1], ...
          get(gca, 'YLim'), 'c-')
        plot(SFreeParameterCredibleIntervals.MAllIntervals(iXParam, 2) * [1 1], ...
          get(gca, 'YLim'), 'c-')
      else
        scatter(MFreeParametersInRetainedSamples(:, iXParam), ...
          MFreeParametersInRetainedSamples(:, iYParam))
        set(gca, 'XLim', MFreeParameterBounds(iXParam, :))
        set(gca, 'YLim', MFreeParameterBounds(iYParam, :))
        hold on
        plot(SPosteriorMeanParameterSet.VFreeParameters(iXParam), ...
          SPosteriorMeanParameterSet.VFreeParameters(iYParam), 'ro')
        if bGetModeOfPosterior
          plot(VPosteriorModeFreeParameters(iXParam), ...
            VPosteriorModeFreeParameters(iYParam), 'r+')
        end
      end
      if iXParam == 1
        ylabel(CsFreeParameterNames{iYParam})
      end
      if iYParam == nFreeParameters
        xlabel(CsFreeParameterNames{iXParam})
      end
    end % iXParam for loop
  end % iYParam for loop
end % if make scatter plots

% heat maps
if isfield(c_SPlotOptions, 'bMakeHeatMaps') && c_SPlotOptions.bMakeHeatMaps
  
  fprintf('\t\tMaking heat map plots...\n')
  SFigureHandles.iHeatMap = c_SPlotOptions.iBaseFigureNumber + 1;
  figure(SFigureHandles.iHeatMap)
  if c_SPlotOptions.bHideFigures
    set(gcf, 'Visible', 'off')
  end
  set(gcf, 'Name', sprintf('Model %s; %d samples retained', ...
    SABCSamples.sModel, nRetainedABCSamples))
  clf
  % generate plots and keep track of max plot amplitude
  maxAmplitude = -Inf;
  for iXParam = 1:nFreeParameters
    for iYParam = 1:nFreeParameters
      subplotGM(nFreeParameters, nFreeParameters, iYParam, iXParam)
      if iXParam == iYParam
        histogram(MFreeParametersInRetainedSamples(:, iXParam));
        set(gca, 'XLim', MFreeParameterBounds(iXParam, :))
        hold on
        if bGetModeOfPosterior
          plot(VPosteriorModeFreeParameters(iXParam) * [1 1], ...
            get(gca, 'YLim'), 'r-')
        end
      else
        if nRetainedABCSamples > 0
          ViOtherParams = setdiff(1:nFreeParameters, [iXParam iYParam]);
          MXMeshGrid = SMeshGrids.SParameter(iXParam).MGrid;
          MYMeshGrid = SMeshGrids.SParameter(iYParam).MGrid;
          MXYMarginalPosterior = SMeshGrids.MPosterior;
          % remove dimensions not included in plot
          for iOtherParam = ViOtherParams
            % mesh grid locations (identical across all not-plotted
            % dimensions so could just use any one element, but taking mean
            % across all of them is easier)
            MXMeshGrid = mean(MXMeshGrid, iOtherParam);
            MYMeshGrid = mean(MYMeshGrid, iOtherParam);
            % sum posterior across not-plotted dimensions, to get marginal
            % posterior
            MXYMarginalPosterior = sum(MXYMarginalPosterior, iOtherParam);
          end
          [~, VhContour(iXParam, iYParam)] = ...
            contourf(squeeze(MXMeshGrid), squeeze(MYMeshGrid), ...
            squeeze(MXYMarginalPosterior), 'LineStyle', 'none');
          set(gca, 'XLim', MFreeParameterBounds(iXParam, :))
          set(gca, 'YLim', MFreeParameterBounds(iYParam, :))
          maxAmplitude = ...
            max(maxAmplitude, max(VhContour(iXParam, iYParam).LevelList));
          hold on
          if bGetModeOfPosterior
            plot(VPosteriorModeFreeParameters(iXParam), ...
              VPosteriorModeFreeParameters(iYParam), 'r+')
          end
        end
      end
      if iXParam == 1
        ylabel(CsFreeParameterNames{iYParam})
      end
      if iYParam == nFreeParameters
        xlabel(CsFreeParameterNames{iXParam})
      end
    end % iXParam for loop
  end % iYParam for loop
  
  if nRetainedABCSamples > 1
    % loop through panels again and adjust to use same contour levels and
    % colour axis
    set(gcf, 'Color', 'w')
    set(gcf, 'InvertHardCopy', 'off')
    MColourMap = colormap;
    VBGColour = MColourMap(1, :);
    VContourLevelList = linspace(0, maxAmplitude, 10);
    for iXParam = 1:nFreeParameters
      for iYParam = 1:nFreeParameters
        subplotGM(nFreeParameters, nFreeParameters, iYParam, iXParam)
        if iXParam ~= iYParam
          VhContour(iXParam, iYParam).LevelList = VContourLevelList;
          caxis([0 maxAmplitude])
          set(gca, 'Color', VBGColour)
        end
      end % iXParam for loop
    end % iYParam for loop
  end
  
end % if c_bMakeHeatMaps


if nRetainedABCSamples > 0
  
  % posterior predictive checks
  c_SVisualisationExperiment = SABCSamples.SExperiment;
  c_SVisualisationSettings = SABCSamples.SSettings;
  c_SVisualisationSettings.bSaveTrialActivation = true;
  c_nExperimentsInVisualisation = 100;
  c_CsModelFitTypes = {'mode of posterior', 'model mix of posterior samples'};
  ViModelFitTypesToCheck = [];
  if isfield(c_SPlotOptions, ...
      'bMakePosteriorPredictiveCheckFromModeOfPosterior') && ...
      c_SPlotOptions.bMakePosteriorPredictiveCheckFromModeOfPosterior
    ViModelFitTypesToCheck = [ViModelFitTypesToCheck 1];
  end
  if isfield(c_SPlotOptions, ...
      'bMakePosteriorPredictiveCheckFromMixOfPosteriorSamples') && ...
      c_SPlotOptions.bMakePosteriorPredictiveCheckFromMixOfPosteriorSamples
    ViModelFitTypesToCheck = [ViModelFitTypesToCheck 2];
  end
  
  if ~isempty(ViModelFitTypesToCheck)
    
    for iModelFitType = ViModelFitTypesToCheck
      iPPCFigure = c_SPlotOptions.iBaseFigureNumber + iModelFitType*10;
      
      
      fprintf('\t\tMaking posterior predictive check plots - %s...\n', ...
        c_CsModelFitTypes{iModelFitType})
      
      % run model simulations
      SVisualisationDataSet = [];
      for iExperiment = 1:c_nExperimentsInVisualisation
        % get model parameterisation
        switch iModelFitType
          case 1
            % mode of posterior
            SThisParameterSet = SPosteriorModeParameterSet;
            SFigureHandles.iModePPC = iPPCFigure;
          case 2
            iThisRetainedParameterSet = randi(nRetainedABCSamples);
            iThisABCSample = ViRetainedABCSamples(iThisRetainedParameterSet);
            SThisParameterSet = SABCSamples.SModelParameterSets(iThisABCSample);
            SFigureHandles.iMixedPPC = iPPCFigure;
        end % iModelFitType switch
%         SThisParameterSet.alpha_ND = 1;
        % run simulation
        SThisSimulatedDataSet = SimulateDataSetFromModel(...
          c_SVisualisationExperiment, SABCSamples.sModel, SThisParameterSet, ...
          c_SVisualisationSettings);
        % store results
        SVisualisationDataSet = AppendTrials(SVisualisationDataSet, ...
          SThisSimulatedDataSet, c_SVisualisationSettings, c_SVisualisationExperiment);
%         if iExperiment == 1
%           SVisualisationDataSet = SThisSimulatedDataSet;
%         else
%           % append
%           nNewTrials = length(SThisSimulatedDataSet.VResponseTime);
%           nTrialsSoFar = length(SVisualisationDataSet.VResponseTime);
%           % -- trial activation
%           if c_SVisualisationSettings.bSaveTrialActivation
%             SVisualisationDataSet.STrialERPs(end+1:...
%               end+length(SThisSimulatedDataSet.STrialERPs)) = ...
%               SThisSimulatedDataSet.STrialERPs;
%           end
%           % -- ERPs
%           if c_SVisualisationExperiment.bERPIncluded
%             SVisualisationDataSet.SStimulusERP.MERPs(nTrialsSoFar+1:nTrialsSoFar+nNewTrials, :) = ...
%               SThisSimulatedDataSet.SStimulusERP.MERPs;
%             SVisualisationDataSet.SStimulusERP.VidxResponseSample(nTrialsSoFar+1:nTrialsSoFar+nNewTrials) = ...
%               SThisSimulatedDataSet.SStimulusERP.VidxResponseSample;
%             SVisualisationDataSet.SResponseERP.MERPs(nTrialsSoFar+1:nTrialsSoFar+nNewTrials, :) = ...
%               SThisSimulatedDataSet.SResponseERP.MERPs;
%           end
%           % -- error responses
%           SVisualisationDataSet.MnEarlyResponsesPerCondition = ...
%             SVisualisationDataSet.MnEarlyResponsesPerCondition + ...
%             SThisSimulatedDataSet.MnEarlyResponsesPerCondition;
%           SVisualisationDataSet.MnNonResponsesPerCondition = ...
%             SVisualisationDataSet.MnNonResponsesPerCondition + ...
%             SThisSimulatedDataSet.MnNonResponsesPerCondition;
%           % -- all other vectors
%           CsFields = fieldnames(SThisSimulatedDataSet);
%           for iField = 1:length(CsFields)
%             sField = CsFields{iField};
%             if ~ismember(sField, {'STrialERPs', 'SStimulusERP', 'SResponseERP', ...
%                 'MnEarlyResponsesPerCondition', 'MnNonResponsesPerCondition'})
%               SVisualisationDataSet.(sField)(end+1:end+nNewTrials, :) = ...
%                 SThisSimulatedDataSet.(sField);
%             end
%           end % iField for loop
%         end % if not first experiment in for loop
      end % iExperiment for loop
      
      % prepare figure window
      figure(iPPCFigure)
      if c_SPlotOptions.bHideFigures
        set(gcf, 'Visible', 'off')
      end
      set(gcf, 'Name', sprintf('Model %s; %s', ...
        SABCSamples.sModel, c_CsModelFitTypes{iModelFitType}))
      clf
      
      % call user-provided visualisation function
      c_SPlotOptions.fVisualisePosteriorPredictiveCheck(SABCSamples, ...
        SVisualisationDataSet, SObservations, c_iDataSet, c_SVisualisationSettings)
      
    end % iModelFitType loop
    
  end % if at least one model fit type to check
  
end % if at least one parameter set retained

% MRetainedParameterSets
