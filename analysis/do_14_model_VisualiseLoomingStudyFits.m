
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


% this script mostly generates figures illustrating the results from the
% do_13... script, but also calculates per-participant and group Bayes 
% factors for the fitted models, saving the results in BayesFactors.mat

clearvars
close all

% script configuration constants
c_bSavePlots = true;
c_bDoRetainedSamplesPlots = true;
c_bDoBayesFactorPlots = true;
c_bDoParameterValueThresholdSweepPlots = true;
c_bDoDistanceMetricThresholdSweepPlots = true;
c_bDoBestRTDistancesPlot = true;
c_bDoHeatMaps = true;

% constants
disp('Init...')
SetLoomingDetectionStudyAnalysisConstants
load([c_sAnalysisResultsPath c_sModelFitAnalysisResultsMATFileName])
c_iAllParticipants = 99;
c_ViParticipantsToAnalyseInclAll = ...
  [c_ViParticipantsToAnalyse c_iAllParticipants];

c_ViModelsToAnalyse = 1:c_nModels;

[~, c_CsParticipantIDs] = GetLoomingDetectionStudyObservationsAndParticipantIDs;
c_CsParticipantIDs{c_iAllParticipants} = 'ALL';

c_CsThresholdType = {'RT', 'ERP'};

c_sBayesFactorReferenceModel = 'A';

c_iNoHoldOut = 1;
c_iOneConditionHeldOut = 2;

% test some assumptions
assert(c_VRTThresholds(end) == Inf)
assert(c_VERPThresholds(end) == Inf)
assert(all(c_VRTThresholds == c_VERPThresholds))
c_VThresholds = c_VRTThresholds;
c_nThresholds = length(c_VThresholds);

c_InfPlotLocation = 1.1;
c_VPlotThresholds = c_VThresholds;
c_VPlotThresholds(end) = c_InfPlotLocation;
c_VPlotThresholdTicks = [0:0.5:c_VPlotThresholds(end-1) c_InfPlotLocation];

% for retained samples / Bayes factor plots
c_VCoarseSweepThresholds = [0.2 0.4 0.6 Inf];
c_nCoarseSweepThresholds = length(c_VCoarseSweepThresholds);
c_VThresholdPlotLimits = c_VPlotThresholdTicks([1 end]) + [-.2 .2];
c_VnRetainedSamplesPlotLimits = [1 1e6];
c_VBayesFactorPlotLimits = [1e-4 1e4];
c_VBayesFactorYTicks = 10.^(log10(c_VBayesFactorPlotLimits(1)):1:log10(c_VBayesFactorPlotLimits(2)));
c_nMinSamplesForBF = 100;

% for parameter value plots
c_VRTThresholdForERPSweep = 0.4;

% for heat maps
c_VHeatMapTickThresholds = [0.1 0.4 0.8 Inf];
for i = 1:length(c_VHeatMapTickThresholds)
  thisTickThreshold = c_VHeatMapTickThresholds(i);
  c_ViHeatMapTickLocations(i) = ...
    GetABCDistanceThresholdIndex(thisTickThreshold, c_VThresholds);
  c_CsHeatMapTickLabels{i} = num2str(thisTickThreshold);
end

c_VHeatMapCLim = [0 0.5];

if c_bDoBayesFactorPlots
  % get Bayes factors
  [MnRetainedSamplesForAllModels, MbBothModelsInComparisonHaveSamples, ...
    MBayesFactors, MBayesFactorsForAggregation] = ...
    deal(NaN * ones(max(c_ViParticipantsToAnalyse), c_nModels, ...
    c_nThresholds, c_nThresholds));
  [MnParticipantsWithDataInComparisons, MGroupBayesFactors, ...
    MGeomMeanGroupBayesFactors] = deal(...
    NaN * ones(c_nModels, c_nThresholds, c_nThresholds));
  MnRetainedSamplesForReferenceModel = squeeze(SResults(c_iNoHoldOut).(...
    c_sBayesFactorReferenceModel).MnRetainedSamples(...
    c_ViParticipantsToAnalyse, 1, :, :));
  for iModel = c_ViModelsToAnalyse
    sModel = c_CsModels{iModel};
    MnRetainedSamplesForAllModels(:, iModel, :, :) = ...
      squeeze(SResults(c_iNoHoldOut).(...
      sModel).MnRetainedSamples(:, 1, :, :));
    MbBothModelsInComparisonHaveSamples(:, iModel, :, :) = ...
      squeeze(MnRetainedSamplesForAllModels(:, iModel, :, :) > 0) & ...
      (MnRetainedSamplesForReferenceModel > c_nMinSamplesForBF);
    MBayesFactors(:, iModel, :, :) = ...
      squeeze(MnRetainedSamplesForAllModels(:, iModel, :, :)) ./ ...
      MnRetainedSamplesForReferenceModel;
  end
  MBayesFactors(~MbBothModelsInComparisonHaveSamples) = NaN;
  MBayesFactorsForAggregation = MBayesFactors;
  MBayesFactorsForAggregation(~MbBothModelsInComparisonHaveSamples) = 1;
  MGroupBayesFactors = squeeze(prod(MBayesFactorsForAggregation, 1));
  MnParticipantsWithDataInComparisons = ...
    squeeze(sum(MbBothModelsInComparisonHaveSamples, 1));
  MGeomMeanGroupBayesFactors = ...
    MGroupBayesFactors .^ (1./MnParticipantsWithDataInComparisons);
  save([c_sAnalysisResultsPath c_sBayesFactorsMATFileName], '*BayesFactors*', ...
    'c_CsModels', 'c_VThresholds', 'c_sBayesFactorReferenceModel', ...
    'MnRetainedSamplesForAllModels', 'MnParticipantsWithDataInComparisons')
  MGeomMeanGroupBayesFactorsWithNRequirement = MGeomMeanGroupBayesFactors;
  MGeomMeanGroupBayesFactorsWithNRequirement(...
    MnParticipantsWithDataInComparisons < 5) = NaN;
end


if c_bDoRetainedSamplesPlots || c_bDoBayesFactorPlots
  disp('Doing retained samples and/or Bayes factor plots...')
  % effect of ABC distance thresholds on retained samples / BFs
  
  ViIncludedPlotTypes = [];
  if c_bDoRetainedSamplesPlots
    ViIncludedPlotTypes = [ViIncludedPlotTypes 1];
  end
  if c_bDoBayesFactorPlots
    ViIncludedPlotTypes = [ViIncludedPlotTypes 2];
  end
  
  for iPlotType = ViIncludedPlotTypes % 1:2 retained samples vs BFs
    for iParticipant = c_ViParticipantsToAnalyseInclAll
      
      % prepare figure window
      figure(100 * (iPlotType-1) + iParticipant)
      set(gcf, 'Position', [75   126   962   540])
      set(gcf, 'Name', ...
        sprintf('Participant %d (%s)', iParticipant, c_CsParticipantIDs{iParticipant}))
      clf
      
      % loop through the subplots in the figure
      for iDetailedSweep = 1:2 % RTs vs ERPs
        for iCoarseSweepThreshold = 1:c_nCoarseSweepThresholds
          
          % determine what ABC thresholds to use for this subplot
          subplotGM(2, c_nCoarseSweepThresholds, iDetailedSweep, iCoarseSweepThreshold)
          thisCoarseSweepThreshold = ...
            c_VCoarseSweepThresholds(iCoarseSweepThreshold);
          idxCoarseSweepThreshold = ...
            GetABCDistanceThresholdIndex(thisCoarseSweepThreshold, c_VThresholds);
          switch iDetailedSweep
            case 1 % RTs
              VidxRTThresholds = 1:length(c_VThresholds);
              VidxERPThresholds = idxCoarseSweepThreshold;
            case 2 % ERPs
              VidxRTThresholds = idxCoarseSweepThreshold;
              VidxERPThresholds = 1:length(c_VThresholds);
          end
          
          % loop through models
          for iModel = c_ViModelsToAnalyse
            sModel = c_CsModels{iModel};
            % get the data to plot depending on plot type
            if iPlotType == 1
              if iParticipant == c_iAllParticipants
                % retained samples across all participants
                VPlotY = squeeze(sum(SResults(c_iNoHoldOut).(...
                  sModel).MnRetainedSamples(...
                  :, 1, VidxRTThresholds, VidxERPThresholds), 1));
              else
                % retained samples for one participant
                VPlotY = squeeze(SResults(c_iNoHoldOut).(...
                  sModel).MnRetainedSamples(...
                  iParticipant, 1, VidxRTThresholds, VidxERPThresholds));
              end
            else
              if iParticipant == c_iAllParticipants
                % geometrical mean group Bayes factor (i.e., across all
                % participants)
                VPlotY = squeeze(MGeomMeanGroupBayesFactorsWithNRequirement(iModel, ...
                  VidxRTThresholds, VidxERPThresholds));
              else
                % Bayes factor for one participant
                VPlotY = squeeze(MBayesFactors(iParticipant, iModel, ...
                  VidxRTThresholds, VidxERPThresholds));
              end
            end
            % plot
            VhModelPlots(iModel) = ...
              semilogy(c_VPlotThresholds(1:end-1), VPlotY(1:end-1), GetModelLineSpec(iModel));
            hold on
            semilogy(c_VPlotThresholds(end), VPlotY(end), GetModelLineSpec(iModel))
            set(gca, 'XLim', c_VThresholdPlotLimits)
            set(gca, 'XTick', c_VPlotThresholdTicks)
            CsPlotTickLabels = get(gca, 'XTickLabel');
            CsPlotTickLabels{end} = 'Inf';
            set(gca, 'XTickLabel', CsPlotTickLabels)
            
            switch iDetailedSweep
              case 1
                xlabel('d_{RT} (s)')
                title(sprintf('ERP threshold: %.2f', thisCoarseSweepThreshold))
              case 2
                xlabel('d_{ERP} (-)')
                title(sprintf('RT threshold: %.2f s', thisCoarseSweepThreshold))
            end
            
            switch iPlotType
              case 1
                set(gca, 'YLim', c_VnRetainedSamplesPlotLimits)
                if iCoarseSweepThreshold == 1
                  ylabel('ABC samples retained (-)')
                end
              case 2
                set(gca, 'YLim', c_VBayesFactorPlotLimits)
                set(gca, 'YTick', c_VBayesFactorYTicks)
                if iCoarseSweepThreshold == 1
                  ylabel('Bayes Factor (-)')
                end
            end
            
          end % iModel for loop
          
        end % iCoarseSweepThreshold for loop
      end % iDetailedSweep for loop
      
      legend(VhModelPlots(c_ViModelsToAnalyse), {c_CsModels{c_ViModelsToAnalyse}}, ...
        'Position',[0.889466390488715 0.35401235450933 0.0873180862957623 0.312037028206719]);
      
      if c_bSavePlots
        switch iPlotType
          case 1
            saveas(gcf, sprintf('%sRetainedABCSamplesPerModel_LoomingDetectionStudy_P%d_%s.png', ...
              c_sAnalysisPlotPath, iParticipant, c_CsParticipantIDs{iParticipant}))
          case 2
            saveas(gcf, sprintf('%sBayesFactorPerModel_LoomingDetectionStudy_P%d_%s.png', ...
              c_sAnalysisPlotPath, iParticipant, c_CsParticipantIDs{iParticipant}))
        end
      end % if c_bSavePlots
      
    end % iParticipant for loop
  end % iPlotType for loop
end % if c_DoRetainedSamplesPlot

% threshold sweep plots
if c_bDoParameterValueThresholdSweepPlots || c_bDoDistanceMetricThresholdSweepPlots
  disp('Doing threshold sweep plots for parameter values and/or distance metrics...')
  
  for iParticipant = c_ViParticipantsToAnalyseInclAll
    
    if c_bDoDistanceMetricThresholdSweepPlots
      % init figure for this participant
      iMetricSweepFigure = 20000 + iParticipant;
      figure(iMetricSweepFigure)
      clf
      set(gcf, 'Position', [75         126        1161         540])
      set(gcf, 'Name', sprintf('P%d (%s)', ...
        iParticipant, c_CsParticipantIDs{iParticipant}))
    end
    
    for iModel = c_ViModelsToAnalyse
      sModel = c_CsModels{iModel};
      
      % get info about the parameter fitting of this model
      nFreeParameters = SResults(c_iNoHoldOut).(sModel).nFreeParameters;
      CsFreeParameterNames = SResults(c_iNoHoldOut).(sModel).CsFreeParameterNames;
      MFreeParameterBounds = SResults(c_iNoHoldOut).(sModel).MFreeParameterBounds;
      
      for iThresholdSweep = 1:2 % RT vs ERP
        
        % get parameter values to plot
        switch iThresholdSweep
          case 1 % RT sweep
            nonSweepThreshold = Inf;
            VidxRTThresholds = 1:length(c_VThresholds);
            VidxERPThresholds = ...
              GetABCDistanceThresholdIndex(nonSweepThreshold, c_VThresholds);
          case 2 % ERP sweep
            nonSweepThreshold = c_VRTThresholdForERPSweep;
            VidxRTThresholds = GetABCDistanceThresholdIndex(...
              nonSweepThreshold, c_VThresholds);
            VidxERPThresholds = 1:length(c_VThresholds);
        end
        
        sNonSweepThresholdString = sprintf('d_{%s} = %.2f', ...
          c_CsThresholdType{3-iThresholdSweep}, nonSweepThreshold);
        
        % doing threshold sweep figure showing parameter values?
        if c_bDoParameterValueThresholdSweepPlots ...
            && iParticipant ~= c_iAllParticipants
        
          % get number of retained samples for this sweep
          VnRetainedSamples = ...
            squeeze(SResults(c_iNoHoldOut).(sModel).MnRetainedSamples(...
            iParticipant, 1, VidxRTThresholds, VidxERPThresholds));
          VbThresholdHasSamplesAndIsNotInf = ...
            (VnRetainedSamples(:) > 0) & ~isinf(c_VThresholds(:));
          
          % init figure
          iParameterSweepFigure = ...
            10000 + iModel*1000 + iThresholdSweep * 100 + iParticipant;
          figure(iParameterSweepFigure)
          clf
          set(gcf, 'Position', [75         126        1161         540])
          set(gcf, 'Name', sprintf('Model %s P%d (%s), %s', sModel, ...
            iParticipant, c_CsParticipantIDs{iParticipant}, sNonSweepThresholdString))
          
          % get fitted parameters for this sweep
          MFreeParameterCIMin = ...
            squeeze(SResults(c_iNoHoldOut).(sModel).MFreeParameterCIMin(...
            iParticipant, 1, VidxRTThresholds, VidxERPThresholds, :));
          MFreeParameterCIMax = ...
            squeeze(SResults(c_iNoHoldOut).(sModel).MFreeParameterCIMax(...
            iParticipant, 1, VidxRTThresholds, VidxERPThresholds, :));
          MFreeParameterPosteriorMean = ...
            squeeze(SResults(c_iNoHoldOut).(sModel).MFreeParameterPosteriorMean(...
            iParticipant, 1, VidxRTThresholds, VidxERPThresholds, :));
          MFreeParameterPosteriorMode = ...
            squeeze(SResults(c_iNoHoldOut).(sModel).MFreeParameterPosteriorMode(...
            iParticipant, 1, VidxRTThresholds, VidxERPThresholds, :));
          
          % make a subplot per parameter
          nPlotRowCols = ceil(sqrt(nFreeParameters));
          for iParam = 1:nFreeParameters
            subplot(nPlotRowCols, nPlotRowCols, iParam)
            
            % do fill and lines for non-Inf thresholds in the sweep
            VXValues = c_VPlotThresholds(VbThresholdHasSamplesAndIsNotInf);
            VCIMinYValues = ...
              MFreeParameterCIMin(VbThresholdHasSamplesAndIsNotInf, iParam);
            VCIMaxYValues = ...
              MFreeParameterCIMax(VbThresholdHasSamplesAndIsNotInf, iParam);
            VPosteriorMeanYValues = ...
              MFreeParameterPosteriorMean(VbThresholdHasSamplesAndIsNotInf, iParam);
            VPosteriorModeYValues = ...
              MFreeParameterPosteriorMode(VbThresholdHasSamplesAndIsNotInf, iParam);
            hCI = fill([VXValues fliplr(VXValues)], ...
              [VCIMinYValues' fliplr(VCIMaxYValues')], ...
              [1 1 1] * 0.8, 'LineStyle', 'none');
            hold on
            hMean = plot(VXValues, VPosteriorMeanYValues, 'kx--');
            hMode = plot(VXValues, VPosteriorModeYValues, 'ko-');
            % plot for Inf threshold
            plot(c_VPlotThresholds(end) * [1 1], ...
              [MFreeParameterCIMin(end, iParam) MFreeParameterCIMax(end, iParam)], ...
              '-', 'Color', [1 1 1] * 0.8, 'LineWidth', 2)
            plot(c_VPlotThresholds(end), MFreeParameterPosteriorMean(end, iParam), 'kx')
            % finish off plot
            set(gca, 'YLim', MFreeParameterBounds(iParam, :));
            set(gca, 'XLim', c_VThresholdPlotLimits)
            set(gca, 'XTick', c_VPlotThresholdTicks)
            CsPlotTickLabels = get(gca, 'XTickLabel');
            CsPlotTickLabels{end} = 'Inf';
            set(gca, 'XTickLabel', CsPlotTickLabels)
            xlabel(sprintf('d_{%s}', c_CsThresholdType{iThresholdSweep}))
            ylabel(CsFreeParameterNames{iParam})
            title(sNonSweepThresholdString)
            if iParam == 1
              if ~isempty(hMean) && ~isempty(hMode) && ~isempty(hCI)
                legend([hMean hMode hCI], {'Mean' 'Mode (approx.)' 'Credible interval'}, ...
                  'Position', [0.0612099934821404 0.884254476237151 0.118863046862358 0.0981481454990526])
              end
            end
          end % iParam for loop
          
          if c_bSavePlots
            saveas(gcf, sprintf('%sEstimatedParameters_LoomingDetectionStudy_Model%s_Sweep%d%s_P%d-%s.png', ...
              c_sAnalysisPlotPath, sModel, iThresholdSweep, c_CsThresholdType{iThresholdSweep}, ...
              iParticipant, c_CsParticipantIDs{iParticipant}))
          end
          
        end % if c_bDoParameterValueThresholdSweepPlots
        
        % doing threshold sweep figure showing distance metric values?
        if c_bDoDistanceMetricThresholdSweepPlots
          
          figure(iMetricSweepFigure)
          
          if iParticipant == c_iAllParticipants
            ViParticipantsInPlot = c_ViParticipantsToAnalyse;
          else
            ViParticipantsInPlot = iParticipant;
          end
            
          for iHoldOutApproach = [c_iNoHoldOut c_iOneConditionHeldOut]
            
            if iHoldOutApproach == c_iNoHoldOut
              sSetFieldName = 'STrainingSet';
              sSetDisplayName = 'all';
            else
              sSetFieldName = 'SValidationSet';
              sSetDisplayName = 'validation';
            end
            
            for iMetricToPlot = 1:2 % RT and ERP
              sMetricFieldName = sprintf('MAverageAbs%sError', ...
                c_CsThresholdType{iMetricToPlot});
              
              subplotGM(2, 4, iHoldOutApproach, (iMetricToPlot-1)*2 + iThresholdSweep)
 
              % average over folds (might be just one, if no holdout)
              MAverageMetricValuePerParticipantAndThreshold = ...
                mean(SResults(iHoldOutApproach).(...
                sModel).(sSetFieldName).(sMetricFieldName)(...
                ViParticipantsInPlot, :, VidxRTThresholds, VidxERPThresholds), 2);
              % average over participants (will most often be just one)
              VAverageMetricValuePerThreshold = ...
                squeeze(mean(MAverageMetricValuePerParticipantAndThreshold, 1));
              
              % plot
              VhModelPlots(iModel) = plot(c_VPlotThresholds(1:end-1), ...
                VAverageMetricValuePerThreshold(1:end-1), ...
                GetModelLineSpec(iModel));
              hold on
              plot(c_VPlotThresholds(end), ...
                VAverageMetricValuePerThreshold(end), ...
                GetModelLineSpec(iModel));
              set(gca, 'YLim', [0 1])
              set(gca, 'XLim', c_VThresholdPlotLimits)
              set(gca, 'XTick', c_VPlotThresholdTicks)
              CsPlotTickLabels = get(gca, 'XTickLabel');
              CsPlotTickLabels{end} = 'Inf';
              set(gca, 'XTickLabel', CsPlotTickLabels)
              xlabel(sprintf('d_{%s,thresh}', c_CsThresholdType{iThresholdSweep}))
              ylabel(sprintf('d_{%s,av} [%s]', ...
                c_CsThresholdType{iMetricToPlot}, sSetDisplayName))
              title(sNonSweepThresholdString)
              
            end % iMetricToPlot
          end % iHoldOutApproach for loop
          
        end % if c_bDoDistanceMetricThresholdSweepPlots
        
      end % iThresholdSweep for loop
      
    end % iModel for loop
            
    if c_bDoDistanceMetricThresholdSweepPlots  
      figure(iMetricSweepFigure)
      legend(VhModelPlots(c_ViModelsToAnalyse), {c_CsModels{c_ViModelsToAnalyse}}, ...
        'Position', [0.896066607109199 0.339814823645133 0.0723514203415361 0.312037028206719])
      if c_bSavePlots
        saveas(gcf, sprintf('%sDistanceMetrics_LoomingDetectionStudy_P%d-%s.png', ...
          c_sAnalysisPlotPath, ...
          iParticipant, c_CsParticipantIDs{iParticipant}))
      end
    end
    
  end % iParticipant for loop
  
end % if doing threshold sweep plots


if c_bDoBestRTDistancesPlot
  
  figure(1)
  set(gcf, 'Position', [85          42        1060         556])
 
  for iHoldOutApproach = [c_iNoHoldOut c_iOneConditionHeldOut]
    subplotGM(2, 2, 1, iHoldOutApproach)
    hold on
    for iParticipant = c_ViParticipantsToAnalyse
      for iModel = c_ViModelsToAnalyse
        sModel = c_CsModels{iModel};
        idxERPInfTreshold = GetABCDistanceThresholdIndex(Inf, c_VThresholds);
        
        % average over folds (might be just one, if no holdout)
        if iHoldOutApproach == c_iNoHoldOut
          sSetFieldName = 'STrainingSet';
          title('Performance when fitting to all data')
        else
          title('Cross-validation performance')
          sSetFieldName = 'SValidationSet';
        end
        VRTDistancesAcrossRTThresholds = ...
          mean(SResults(iHoldOutApproach).(...
          sModel).(sSetFieldName).MAverageAbsRTError(...
          iParticipant, :, :, idxERPInfTreshold), 2);
        MBestRTDistance(iParticipant, iModel) = min(VRTDistancesAcrossRTThresholds);
        
      end % iModel for loop
    end % iParticipant for loop
    
    VXTick = 1:size(MBestRTDistance, 2);
    VXLim = VXTick([1 end]) + [-1 1] * 0.5;
    
    boxplot(MBestRTDistance)
    set(gca, 'XLim', VXLim)
    set(gca, 'XTickLabel', c_CsModels)
    ylabel('d_{RT,av}')
    set(gca, 'YLim', [0 0.45])
    
    subplotGM(2, 2, 2, iHoldOutApproach)
    plot(MBestRTDistance')
    set(gca, 'XLim', VXLim)
    set(gca, 'XTick', VXTick)
    set(gca, 'XTickLabel', c_CsModels)
    ylabel('d_{RT,av}')
    set(gca, 'YLim', [0 0.45])
    
  end % iHoldOutApporach for loop
  
  if c_bSavePlots
    saveas(gcf, sprintf('%sBestRTDistancesPerModelAndParticipant.png', ...
      c_sAnalysisPlotPath))
  end
  
end % if c_bDoBestRTDistancesPlot


if c_bDoHeatMaps
  % distance metric value heat maps
  disp('Doing heat maps...')
  for iModel = c_ViModelsToAnalyse
    sModel = c_CsModels{iModel};
    for iParticipant = c_ViParticipantsToAnalyse
      for iSamplingType = 1:c_nSamplingTypes
        
        switch iSamplingType
          case 1
            sSamplingType = 'full';
          case 2
            sSamplingType = 'mode';
        end
        
        figure(100000 + iModel*1000 + iParticipant*10 + iSamplingType)
        set(gcf, 'Position', [75         126        1161         540])
        clf
        set(gcf, 'Name', sprintf('Model %s, participant %d (%s), %s', ...
          sModel, iParticipant, c_CsParticipantIDs{iParticipant}, sSamplingType))
        for iMetricType = 1:2 % RTs vs ERPs
          switch iMetricType
            case 1
              sMetricFieldName = 'MAverageAbsRTError';
              sMetricDisplayName = 'RT error';
            case 2
              sMetricFieldName = 'MAverageAbsERPError';
              sMetricDisplayName = 'ERP error';
          end
          
          for iSubsetType = 1:4 % all data vs training set vs validation set vs validation set alternative error measure
            subplotGM(2, 4, iMetricType, iSubsetType)
            switch iSubsetType
              case 1
                iHoldOutApproach = c_iNoHoldOut;
                sDataSet = 'STrainingSet';
                sDataSetDisplayName = 'all data';
              case 2
                iHoldOutApproach = c_iOneConditionHeldOut;
                sDataSet = 'STrainingSet';
                sDataSetDisplayName = 'training data';
              case 3
                iHoldOutApproach = c_iOneConditionHeldOut;
                sDataSet = 'SValidationSet';
                sDataSetDisplayName = 'validation data';
              case 4
                iHoldOutApproach = c_iOneConditionHeldOut;
                sDataSet = 'SValidationSet';
                sDataSetDisplayName = 'validation data';
                sMetricFieldName = [sMetricFieldName 'Alt'];
            end
            % get the error data in question
            MErrorData = SResults(iHoldOutApproach).(sModel).(sDataSet).(...
              sMetricFieldName)(iParticipant, :, :, :, iSamplingType);
            % take average across folds (dimension 2) and squeeze down to the two
            % distance threshold dimensions
            MErrorData = squeeze(mean(MErrorData, 2));
            % plot
            image(MErrorData, 'CDataMapping', 'scaled', 'AlphaData', ~isnan(MErrorData))
            set(gca, 'CLim', c_VHeatMapCLim)
            %         set(gca, 'YDir', 'reverse')
            set(gca, 'XTick', c_ViHeatMapTickLocations)
            set(gca, 'XTickLabel', c_CsHeatMapTickLabels)
            set(gca, 'YTick', c_ViHeatMapTickLocations)
            set(gca, 'YTickLabel', c_CsHeatMapTickLabels)
            xlabel('d_{ERP} (-)')
            ylabel('d_{RT} (s)')
            title(sprintf('%s - %s', sMetricDisplayName, sDataSetDisplayName))
            
          end % iSubsetType for loop
        end % iMetricType for loop
        
        if c_bSavePlots
          saveas(gcf, sprintf('%sDistanceMetricsOverRTAndERPThresholds_%s_P%d_%s_%s.png', ...
            c_sAnalysisPlotPath, sModel, iParticipant, c_CsParticipantIDs{iParticipant}, sSamplingType))
        end
        
      end % iSamplingType for loop
    end % iParticipant for loop
  end % iModel for loop
end % if c_bDoHeatMaps




function sLineSpec = GetModelLineSpec(iModel)
c_sModelColour = 'rgbcmyk';
c_sModelSymbol = 'ox';
sColour = c_sModelColour(mod(iModel-1, length(c_sModelColour))+1);
iSymbol = 1 + floor((iModel-1)/length(c_sModelColour));
sLineSpec = [sColour c_sModelSymbol(iSymbol) '-'];
end