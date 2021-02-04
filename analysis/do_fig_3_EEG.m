
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



close all force

% settings for when working on and tweaking plots
c_bDoBasicInit = true;
c_bDoScalpMaps = true;
c_bDoParticipantERPs = true;
c_bSaveEPS = true;

% set to false to double check that hidden axes have correct scaling
c_bHideAxes = true;

if c_bDoBasicInit
  
  clearvars -except c_bDoScalpMaps c_bDoParticipantERPs c_bSaveEPS c_bHideAxes
  close all force
  
  % general constants
  SetLoomingDetectionStudyAnalysisConstants
  
  % model fitting settings
  c_SSettings = GetLoomingDetectionStudyModelFittingConstants;
  
  % figure constants
  SetPlottingConstants
  
  % start EEG Lab
  StartEEGLAB
  
  % load data
  fprintf('Loading data...\n')
  % - EEG data across all electrodes
  load([c_sAnalysisResultsPath c_sAllTrialDataFileName])
  % -- model simulation results incl CPP onset predictions
  load([c_sAnalysisResultsPath c_sSimulationsForFigsMATFileName])
  % -- model simulation results incl model "ERPs"
  load([c_sAnalysisResultsPath c_sSimulationsForERPFigsMATFileName])
  SModelSimulationsWithERP = SSimResultsWithERP.AV.SSimulatedData;
  clear SSimResultsWithERP
  % -- CPP onset results
  load([c_sAnalysisResultsPath c_sCPPOnsetMATFileName])
  load([c_sAnalysisResultsPath c_sCPPRelOnsetDiffsMATFileName])
  % - ML fitting results
  load([c_sAnalysisResultsPath c_sMLFittingMATFileName], ...
    'c_CsModels', 'SResults', 'c_VContaminantFractions')
  assert(all(strcmp(c_CCsModelsFitted{c_iMLEFitting}, c_CsModels))) % verifying that the models come in the expected order in the results MAT file
  clear c_CsModels
  c_iContaminantFractionToPlot = ...
    find(c_VContaminantFractions == c_mleContaminantFractionToPlot);
  assert(length(c_iContaminantFractionToPlot) == 1)
 
else
  SetPlottingConstants
end 


%%

figure(10)
clf
set(gcf, 'Position', [100 150 c_nFullWidthFigure_px 520])

c_nSubplotRows = 4;
c_nSubplotCols = 3;


% get the electrodes used to estimate the CPP
ViElectrodes = GetElectrodeIndices(...
  SAllTrialData.SEEGChannelLocations, c_CsElectrodesForModelFitting);



%% scalp maps


if c_bDoScalpMaps
  
  c_VScalpMapLatencies_ms = [-250 0 250];
  c_VERPPlotLimits = [-5 5];
  
  nEpochs = size(SAllTrialData.MEEGERP, 3);
  
  for iLatency = 1:length(c_VScalpMapLatencies_ms)
    MEpochChannelDataAtLatency = NaN * ones(nEpochs, c_nEEGDataChannels);
    for iEpoch = 1:nEpochs
      idxThisEpochLatencySample = ...
        find(SAllTrialData.VERPTimeStamp*1000 >= ...
        SAllTrialData.VResponseTime(iEpoch)*1000 ...
        + c_VScalpMapLatencies_ms(iLatency), 1, 'first');
      MEpochChannelDataAtLatency(iEpoch, :) = ...
        SAllTrialData.MEEGERP(1:c_nEEGDataChannels, idxThisEpochLatencySample, iEpoch);
    end
    VhScalpMap(iLatency) = ...
      subplotGM(c_nSubplotRows, c_nSubplotCols, iLatency, 1);
    cla
    topoplot(mean(MEpochChannelDataAtLatency), ...
      SAllTrialData.SEEGChannelLocations, ...
      'maplimits', c_VERPPlotLimits, 'conv', 'on', 'whitebk', 'on', ...
      'electrodes', 'on', 'emarker', {'.', 'k', 3, 1}, ...
      'emarker2', {ViElectrodes '.', 'k', 6, 1});
    VXLim = get(gca, 'XLim');
    VYLim = get(gca, 'YLim');
    h = text(VXLim(2) - diff(VXLim)*.15, VYLim(2), sprintf('%d ms', ...
      c_VScalpMapLatencies_ms(iLatency)), 'HorizontalAlignment', 'left', ...
      'VerticalAlignment', 'top', 'FontSize', c_annotationFontSize, ...
      'FontName', c_sFontName);
    uistack(h, 'top')
    if ~c_bHideAxes
      axis on
    end
    colormap(c_MScalpMapColors)
%     brighten(0.3)
  end % iLatency for loop
  hColorBar = colorbar('EastOutside');
  hColorBar.Position = [0.1393 0.7411 0.0117 0.1713];
  hColorBar.Label.String = '\muV';
  hColorBar.FontName = c_sFontName;
  hColorBar.FontSize = c_stdFontSize;
  hColorBar.Label.FontSize = c_annotationFontSize;
  
end % if c_bDoScalpMaps


%% participant ERP plots

if c_bDoParticipantERPs
  
  %% get stimulus-locked and response-locked average ERPs, and do ANOVAs on
  %  response-locked ERP to test for effect of condition
  
  % get stimulus- and response-locked ERPs averaged over the targeted
  % electrodes
  nStimulusLockedPlotSamples = size(SAllTrialData.MEEGERP, 2);
  MStimulusERP = NaN * ones(nEpochs, nStimulusLockedPlotSamples);
  MResponseERP = NaN * ones(nEpochs, c_nResponseLockedPlotSamples);
  for iEpoch = 1:nEpochs
    MStimulusERP(iEpoch, :) = ...
      squeeze(mean(SAllTrialData.MEEGERP(ViElectrodes, :, iEpoch), 1));
    idxEpochResponseSample = SAllTrialData.VidxResponseERPSample(iEpoch);
    MResponseERP(iEpoch, :) = squeeze(mean(SAllTrialData.MEEGERP(ViElectrodes, ...
      idxEpochResponseSample + c_VidxDataRangeAroundResponse, iEpoch), 1));
  end % iEpoch for loop
  
  
  % ANOVA
  c_VTestTimeStamps_ms = -500 : 20 : 300;
  c_nTests = length(c_VTestTimeStamps_ms);
  CVPredictors = {SAllTrialData.ViStimulusID SAllTrialData.ViFinalIncludedParticipantCounter};
  c_ViRandomEffectPredictors = 2;
  c_CsPredictors = {'Condition' 'Participant'};
  VConditionP = NaN * ones(c_nTests, 1);
  fprintf('Testing for difference in response-locked ERP between conditions')
  for iTest = 1:length(c_VTestTimeStamps_ms)
    
    fprintf('.')
    
    testTime_ms = c_VTestTimeStamps_ms(iTest);
    idxTestSample = find(c_VResponseLockedTimes_ms >= testTime_ms, 1, 'first');
    VERPDataAtTestSample = MResponseERP(:, idxTestSample);
    
    [p, STable, SStats] = anovan(VERPDataAtTestSample, ...
      CVPredictors, 'model', 2, 'random', c_ViRandomEffectPredictors, ...
      'varnames', c_CsPredictors, 'display', 'off');
    
%     fprintf('t = %.0f ms:\n\tp(Condition) = %.3f\n\tp(Participant) = %.3f\n\tp(interaction) = %.3f\n', ...
%       testTime_ms, p(1), p(2), p(3))

    VConditionP(iTest) = p(1);
    
  end % iTest for loop
  fprintf('\n')
  
  
  %% plot the stimulus and response locked ERPs
    
  for iCondition = 1:c_nTrialTypes
    
    ViConditionEpochs = find(SAllTrialData.ViStimulusID == iCondition);
    
    for iLock = 1:2 % stimulus vs response-locked
      
      switch iLock
        case 1
          sLabel = 'stimulus';
          VXLim = [-500 3000];
          VERPTimeStamp_ms = SAllTrialData.VERPTimeStamp * 1000;
          VERPData = mean(MStimulusERP(ViConditionEpochs, :));
          iSubplotRow = 4;
          iSubplotCol = 1;
        case 2
          sLabel = 'response';
          VXLim = c_VResponseERPXLim_ms;
          VERPTimeStamp_ms = c_VResponseLockedTimes_ms;
          VERPData = mean(MResponseERP(ViConditionEpochs, :));
          MERPData(iCondition, :) = VERPData;
          iSubplotRow = 1;
          iSubplotCol = 2;
      end
      
      VhParticipantERP(iLock) = ...
        subplotGM(c_nSubplotRows, c_nSubplotCols, iSubplotRow, iSubplotCol);
      if iCondition == 1
        cla
      end
      set(gca, 'FontSize', c_stdFontSize, 'FontName', c_sFontName)
      hold on
      hLine = plot(VERPTimeStamp_ms, VERPData, ...
        '-', 'LineWidth', c_stdLineWidth, 'Color', c_CMConditionRGB{iCondition});
      %     hLine.Color(4) = 0.5;
      if iCondition == c_nTrialTypes
        
        if iLock == 2
          % show the results of the ANOVAs
          VTestPlotY = -1.5 * ones(size(c_VTestTimeStamps_ms));
          VTestPlotY(VConditionP > 0.05) = NaN;
          plot(c_VTestTimeStamps_ms, VTestPlotY, 'k.')
          if c_bHideAxes
            set(gca, 'XColor', 'none')
          end
        end
        
        set(gca, 'XLim', VXLim)
        set(gca, 'YLim', c_VERPYLim)
        h = plot([0 0], get(gca, 'YLim'), 'k-', 'LineWidth', c_stdLineWidth/2);
        uistack(h, 'bottom')
        xlabel(sprintf('Time relative %s (ms)', sLabel), ...
          'FontSize', c_annotationFontSize, 'FontName', c_sFontName)
        ylabel('ERP (\muV)', 'FontSize', c_annotationFontSize, ...
          'FontName', c_sFontName)
      end
      
      
    end % iLock for loop
    
  end % Condition for loop
  
  
end % if c_bDoParticipantERPs

save([c_sAnalysisResultsPath c_sResponseLockedERPMATFileName], ...
  'MERPData', 'VERPTimeStamp_ms')


%% model response-locked ERPs

hModelERP = subplotGM(c_nSubplotRows, c_nSubplotCols, 2, 2);
cla
set(gca, 'FontSize', c_stdFontSize, 'FontName', c_sFontName)
hold on

VERPTimeStamp_ms = c_SSettings.SResponseERP.VTimeStamp * 1000;
for iCondition = 1:c_nTrialTypes
  ViConditionEpochs = find(SModelSimulationsWithERP.ViCondition == iCondition);
  VERPData = mean(SModelSimulationsWithERP.SResponseERP.MERPs(ViConditionEpochs, :));
  hLine = plot(VERPTimeStamp_ms, VERPData, ...
    '-', 'LineWidth', c_stdLineWidth, 'Color', c_CMConditionRGB{iCondition});
end % Condition for loop

xlabel('Time relative response (ms)')
ylabel('E (-)')
set(gca, 'XLim', c_VResponseERPXLim_ms)
set(gca, 'YLim', [-.3 1.6])
h = plot([0 0], get(gca, 'YLim'), 'k-', 'LineWidth', c_stdLineWidth/2);
uistack(h, 'bottom')



%% pre-decision positivity onsets relative response

hPDPRelOnset = subplotGM(c_nSubplotRows, c_nSubplotCols, 3, 2);
cla
set(gca, 'FontSize', c_stdFontSize, 'FontName', c_sFontName)
hold on

c_cppBinSize_ms = 50;
c_VCPPBinEdges_ms = -800:c_cppBinSize_ms:0;
c_VCPPBinCentres_ms = c_VCPPBinEdges_ms(1:end-1) + c_cppBinSize_ms / 2;
c_unitDistance = 0.1;
c_jitterX = 5;
c_jitterY = c_unitDistance/6;
for iUrgency = 1:c_nTrialTypes
  
  iCondition = c_ViConditionUrgencyOrder(iUrgency);
  VbRows = SCPPOnsetResults.ViCondition == iCondition & ...
    ismember(SCPPOnsetResults.ViDataSet, SCPPOnsetResults.ViIncludedParticipants) & ...
    SCPPOnsetResults.VbHasCPPOnsetTime;
  VRelCPPOnsets_ms = SCPPOnsetResults.VCPPRelOnsetTime(VbRows) * 1000;
  VnBinCounts = histcounts(VRelCPPOnsets_ms, c_VCPPBinEdges_ms);
  VnBinDensities = VnBinCounts / sum(VnBinCounts);
  scatterBaseY = iUrgency * c_unitDistance * 2;
  pdfBaseY = scatterBaseY + 0.5 * c_unitDistance;
  [VDensity, VDensityPoints] = ksdensity(VRelCPPOnsets_ms, 'support', [-800 0]);
  hLine = fill(VDensityPoints, pdfBaseY + VDensity / c_unitDistance, ...
    '-', 'LineWidth', c_stdLineWidth/2, 'EdgeColor', 0.8 * c_CMConditionRGB{iCondition}, ...
    'FaceColor', c_CMConditionRGB{iCondition}, 'FaceAlpha', 0.8);
  
  scatter(VRelCPPOnsets_ms + randn(size(VRelCPPOnsets_ms)) * c_jitterX,  ...
    scatterBaseY + randn(size(VRelCPPOnsets_ms)) * c_jitterY, ...
    5, 'MarkerEdgeColor', 'none', 'MarkerFaceColor', c_CMConditionRGB{iCondition}, ...
    'MarkerFaceAlpha', 0.5)
  plot(SCPPRelOnsetResults.VCondAvCPPRelOnsets(iCondition) * 1000 * [1 1], ...
    pdfBaseY + [-1 1] * c_unitDistance / 4, 'k-', ...
    'LineWidth', c_stdLineWidth)
  
end % Condition for loop

VObservedRange = ...
  [SCPPRelOnsetResults.minCPPRelOnset SCPPRelOnsetResults.maxCPPRelOnset];
VUpper95CIEdgeRange = ...
  (mean(VObservedRange) + [-.5 .5] * SCPPRelOnsetResults.VMaxAbsCondDiff95CIEdges(2));
plot(1000 * VUpper95CIEdgeRange, ...
  [1 1] * c_unitDistance * .7, '-', 'LineWidth', c_stdLineWidth, ...
  'Color', [1 1 1] * .6)
plot(VObservedRange * 1000, ...
  [1 1] * c_unitDistance * .7, 'k-', 'LineWidth', c_stdLineWidth * 3)

xlabel('CPP onset time rel. response (ms)')
% ylabel('A (-)')
set(gca, 'XLim', [-800 50])
set(gca, 'YLim', [-.25 10] * c_unitDistance)
if c_bHideAxes
  set(gca, 'YColor', 'none')
end


%% CDFs for pre-decision positivity onsets, data and model

%% do the Vincentising

fprintf('Doing the Vincentising...\n')

c_CsPlotModels = {'AV'};
c_nPlotModels = length(c_CsPlotModels);
c_iResponseType = c_iOvertResponse;

c_ViVincentizingParticipants = SCPPOnsetResults.ViIncludedParticipants;
c_nVincentizingParticipants = length(c_ViVincentizingParticipants);


for iCondition = 1:c_nTrialTypes
  
  for iSource = 1:2 % empirical data and model fit
    
    if iSource == 1
      VQuantilesToGet = .1:.2:.9;
      SData = SCPPOnsetResults;
      VResponseTimeData = SCPPOnsetResults.VCPPOnsetTime;
      VbExtraCondition = SCPPOnsetResults.VbHasCPPOnsetTime;
    else
      VQuantilesToGet = .025:.025:.975;
      SData = SSimResults(c_iMLEFitting).AV.SSimulatedData(c_iCPPOnset);
      VResponseTimeData = SData.VResponseTime;
      VbExtraCondition = ones(size(VResponseTimeData));
    end
    nQuantiles = length(VQuantilesToGet);
    MParticipantRTQuantiles = NaN * ones(c_nVincentizingParticipants, nQuantiles);
    for iVincentizingParticipant = 1:c_nVincentizingParticipants
      iParticipant = c_ViVincentizingParticipants(iVincentizingParticipant);
      VbRows = SData.ViDataSet == iParticipant & ...
        SData.ViCondition == iCondition & VbExtraCondition;
      VResponseTimes = VResponseTimeData(VbRows);
      MParticipantRTQuantiles(iVincentizingParticipant, :) = quantile(VResponseTimes, VQuantilesToGet);
    end % iParticipant for loop
    VRTQuantiles = mean(MParticipantRTQuantiles);
    
    SVincentisedCDFs(iCondition, iSource).VComputedQuantiles = ...
      VQuantilesToGet;
    SVincentisedCDFs(iCondition, iSource).VRTQuantiles = ...
      VRTQuantiles;
    
  end % iSource for loop
  
end % iCondition for loop


%% do the plotting


hCDFs = subplotGM(c_nSubplotRows, c_nSubplotCols, 4, 2);
cla
set(gca, 'FontSize', c_stdFontSize, 'FontName', c_sFontName)
hold on
c_VRTCDFXLim = [0.2 3.5];
c_cppCDFMarkerSize = c_rtCDFMarkerSize + 1;

for iCondition = 1:c_nTrialTypes
  for iSource = 1:2 % empirical data and model fit
    
    if iSource == 1
      sLineSpec = c_sRTCDFEmpiricalSymbol;
      lineWidth = c_rtCDFEmpiricalLineWidth;
    else
      sLineSpec = '-';
      lineWidth = c_stdLineWidth;
    end
    plot(SVincentisedCDFs(iCondition, iSource).VRTQuantiles, ...
      SVincentisedCDFs(iCondition, iSource).VComputedQuantiles, ...
      sLineSpec, 'Color', c_CMConditionRGB{iCondition}, 'MarkerSize', ...
      c_cppCDFMarkerSize, 'LineWidth', lineWidth)
    hold on
    
  end % iSource for loop
end % iCondition for loop

text(c_VRTCDFXLim(1), c_VRTCDFYLim(2), ['  AV'], 'VerticalAlignment', ...
  'top', 'FontSize', c_largeAnnotationFontSize, 'FontName', c_sFontName)
set(gca, 'XLim', c_VRTCDFXLim)
set(gca, 'YLim', c_VRTCDFYLim)
set(gca, 'Box', 'off')
ylabel(sprintf('CDF'), 'FontSize', c_annotationFontSize, 'FontName', c_sFontName)
xlabel(sprintf('CPP onset time rel. stimulus (s)'), ...
  'FontSize', c_annotationFontSize, 'FontName', c_sFontName)
Vh(1) = plot(-1, -1, c_sRTCDFEmpiricalSymbol, 'Color', c_VRTCDFLegendIllustrationRGB, ...
  'LineWidth', c_rtCDFEmpiricalLineWidth, 'MarkerSize', c_cppCDFMarkerSize);
Vh(2) = plot(-1, -1, '-', 'Color', c_VRTCDFLegendIllustrationRGB, ...
  'LineWidth', c_stdLineWidth);
hCDFLegend = legend(Vh, {'Data', 'Model'}, 'FontSize', c_stdFontSize, ...
  'FontName', c_sFontName);



%% AIC diffs per participant

for iModelComparison = 1:2
  
  VhDeltaAIC(iModelComparison) = ...
    subplotGM(c_nSubplotRows, c_nSubplotCols, iModelComparison, 3);
  cla
  set(gca, 'FontSize', c_stdFontSize, 'FontName', c_sFontName)
  hold on
    
  c_CsModelComparison = c_CCsModelComparisons{iModelComparison};
  sBaseModel = c_CsModelComparison{1};
  sAlternativeModel = c_CsModelComparison{2};
  
  iBaseModel = find(strcmp(c_CCsModelsFitted{c_iMLEFitting}, sBaseModel));
  assert(length(iBaseModel) == 1)
  iAlternativeModel = find(strcmp(c_CCsModelsFitted{c_iMLEFitting}, sAlternativeModel));
  assert(length(iAlternativeModel) == 1)
  
  
  % get delta AICs
  VBaseModelLogLik = SResults.MMaxLogLikelihood(...
    SCPPOnsetResults.ViIncludedParticipants, iBaseModel, ...
    c_iContaminantFractionToPlot, c_iCPPOnset);
  VAltModelLogLik = SResults.MMaxLogLikelihood(...
    SCPPOnsetResults.ViIncludedParticipants, iAlternativeModel, ...
    c_iContaminantFractionToPlot, c_iCPPOnset);
  MDeltaAIC(:, iModelComparison) = ...
    2 * c_VnParamIncreaseInModelComparisons(iModelComparison) ...
    - 2 * (VAltModelLogLik - VBaseModelLogLik);
  c_plotYRange = 40;
  c_sYLabel = '\DeltaAIC';
  
  
  
  % plot
  c_zeroYLocation = 0.5;
  thisZeroYLocation = 1 - c_zeroYLocation;
  VPlotYLim = [-thisZeroYLocation  (1-thisZeroYLocation)] * c_plotYRange;
  VerticalRainCloudPlot(MDeltaAIC(:, iModelComparison), VPlotYLim, ...
    c_CMModelComparisonRGB{iModelComparison}, c_stdLineWidth/2)
  h = plot(get(gca, 'XLim'), [0 0], '-', 'Color', [1 1 1] * 0.7, ...
    'LineWidth', c_stdLineWidth/2);
  uistack(h, 'bottom')
  
  % hide unwanted box/axis outlines
  set(gca, 'Box', 'off')
  if c_bHideAxes
    set(gca, 'XColor', 'none')
    if iModelComparison > 1
      set(gca, 'YColor', 'none')
    end
  end
  
  % y axis
  ylabel(c_sYLabel, 'FontSize', c_annotationFontSize, 'FontName', c_sFontName)
  
  % model comparison annotation
  textY = VPlotYLim(2);
  text(0, textY, ['  ' sBaseModel ' \rightarrow ' sAlternativeModel], ...
    'VerticalAlignment', 'top', 'FontSize', c_largeAnnotationFontSize, ...
    'FontName', c_sFontName, 'HorizontalAlignment', 'center')
  
  % run bootstrap
  c_nBootstrapSamples = 100000;
  VBootStrapSumOfDeltaAICs = NaN * ones(c_nBootstrapSamples, 1);
  c_nDeltaAICs = length(MDeltaAIC(:, iModelComparison));
  for iBootstrapSample = 1:c_nBootstrapSamples
    % draw a bootstrap sample at random (with replacement)
    ViBootstrapSample = randi(c_nDeltaAICs, c_nDeltaAICs, 1);
    VBootstrapSampleDeltaAICs = MDeltaAIC(ViBootstrapSample, iModelComparison);
    % get and store the sum of DeltaAICs in this bootstrap sample
    VBootStrapSumOfDeltaAICs(iBootstrapSample) = sum(VBootstrapSampleDeltaAICs);
  end % iBootstrapSample for loop
  
  observedSumOfDeltaAICs = sum(MDeltaAIC(:, iModelComparison));
  VSumOfDeltaAIC95CI(1) = prctile(VBootStrapSumOfDeltaAICs, 2.5);
  VSumOfDeltaAIC95CI(2) = prctile(VBootStrapSumOfDeltaAICs, 97.5);
  
  fprintf('Comparison %s --> %s:\n\tObserved sum of DeltaAIC = %.1f\n\tBootstrap 95%% CI: [%.1f, %.1f]\n', ...
    sBaseModel, sAlternativeModel, observedSumOfDeltaAICs, ...
    VSumOfDeltaAIC95CI(1), VSumOfDeltaAIC95CI(2))
  
  % plot
  VhSumOfDeltaAIC(iModelComparison) = ...
    subplotGM(c_nSubplotRows, c_nSubplotCols, 2+iModelComparison, 3);
  cla
  set(gca, 'FontSize', c_stdFontSize, 'FontName', c_sFontName)
  hold on
  plot([0 0], VSumOfDeltaAIC95CI, '-', 'LineWidth', c_stdLineWidth, ...
    'Color', c_CMModelComparisonRGB{iModelComparison});
  hold on
  plot(0, observedSumOfDeltaAICs, '+', 'LineWidth', c_stdLineWidth, ...
    'Color', c_CMModelComparisonRGB{iModelComparison});
  h = plot([-10 10], [0 0], '-', 'Color', [1 1 1] * 0.7, ...
    'LineWidth', c_stdLineWidth/2);
  uistack(h, 'bottom')
  if c_bHideAxes
    set(gca, 'XColor', 'none')
    if iModelComparison > 1
      set(gca, 'YColor', 'none')
    end
  end
  set(gca, 'box', 'off')
  set(gca, 'YLim', [-140 10])
  ylabel('\Sigma\DeltaAIC', 'FontSize', c_annotationFontSize, ...
    'FontName', c_sFontName)
  
  
end


%% condition legend

AddLoomingConditionLegend


%% panel labels and positions

if exist('VhPanelLabels', 'var')
  try
    delete(VhPanelLabels)
  end
end
VhPanelLabels = [];

% A
VhPanelLabels(end+1) = annotation('textbox',...
  [0.03 0.87 0.07 0.12],...
  'String', 'A', 'FontSize', c_panelLabelFontSize, 'FontName', c_sFontName, ...
  'FontWeight', 'bold', 'EdgeColor', 'none');
hColorBar.Position = [0.06 0.6538 0.0162 0.1847];
c_scale = 1.2;
for iLatency = 1:3
  y = 0.7769 - (iLatency-1) * 0.22;
  VhScalpMap(iLatency).Position = [0.015 y 0.2134*c_scale 0.1577*c_scale];
end

% B
VhPanelLabels(end+1) = annotation('textbox',...
  [0.03 0.24 0.07 0.12],...
  'String', 'B', 'FontSize', c_panelLabelFontSize, 'FontName', c_sFontName, ...
  'FontWeight', 'bold', 'EdgeColor', 'none');
VhParticipantERP(1).Position = [0.0718 0.0885 0.1973 0.1873];

% C
VhPanelLabels(end+1) = annotation('textbox',...
  [0.28 0.87 0.07 0.12],...
  'String', 'C', 'FontSize', c_panelLabelFontSize, 'FontName', c_sFontName, ...
  'FontWeight', 'bold', 'EdgeColor', 'none');
VhParticipantERP(2).Position = [0.3464 0.7392 0.2697 0.2000];
hModelERP.Position = [0.3464 0.5065 0.2697 0.2000];

% D
VhPanelLabels(end+1) = annotation('textbox',...
  [0.39 0.24 0.07 0.12],...
  'String', 'D', 'FontSize', c_panelLabelFontSize, 'FontName', c_sFontName, ...
  'FontWeight', 'bold', 'EdgeColor', 'none');
hPDPRelOnset.Position = [0.40 0.0885 0.2274 0.27];

% E
VhPanelLabels(end+1) = annotation('textbox',...
  [0.68 0.87 0.07 0.12],...
  'String', 'E', 'FontSize', c_panelLabelFontSize, 'FontName', c_sFontName, ...
  'FontWeight', 'bold', 'EdgeColor', 'none');
hCDFs.Position = [0.74 0.7115 0.1806 0.2370];
hCDFLegend.Position = [0.8745 0.7623 0.0836 0.0856];
hCDFLegend.Box = 'off';


% F
VhPanelLabels(end+1) = annotation('textbox',...
  [0.68 0.48 0.07 0.12],...
  'String', 'F', 'FontSize', c_panelLabelFontSize, 'FontName', c_sFontName, ...
  'FontWeight', 'bold', 'EdgeColor', 'none');
for i = 1:2
  x = 0.73 + (i-1) * 0.10;
  VhDeltaAIC(i).Position = [x 0.2400 0.1357 0.3038];
  x = 0.75 + (i-1) * 0.09;
  VhSumOfDeltaAIC(i).Position = [x 0.04 0.09 0.1567];
  VhSumOfDeltaAIC(i).XLim = [-1 1.5-(i-1)*0.4];
end

% condition legend
hConditionLegend.Position = [0.2291    0.2465    0.1486    0.1458];


% save EPS
if c_bSaveEPS
  fprintf('Saving EPS...\n')
  SaveFigAsEPSPDF('Fig3.eps')
end