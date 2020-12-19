
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



% settings for when working on and tweaking plots
c_bDoBasicInit = true;
c_bMakeCDFPlots = true;
c_bSaveEPS = true;

% set to false to double check that hidden axes have correct scaling
c_bHideAxes = true;
  

if c_bDoBasicInit
  
  clearvars -except c_bMakeCDFPlots c_bSaveEPS c_bHideAxes
  close all force
  
  % general constants
  SetLoomingDetectionStudyAnalysisConstants
  
  % figure constants
  SetPlottingConstants
  
  % loading
  fprintf('Loading data...\n')
  % - empirical RT data
  [c_SObservations, c_SExperiment.CsDataSets] = ...
    GetLoomingDetectionStudyObservationsAndParticipantIDs;
  % - simulated data from fitted models
  load([c_sAnalysisResultsPath c_sSimulationsForFigsMATFileName])
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
end % if c_bLoadData

%%

% figure basics
c_nSubplots = 5;
close all force
figure(1)
set(gcf, 'Position', [150 300 c_nFullWidthFigure_px 207])


if c_bMakeCDFPlots
  %% do the Vincentising
  
  fprintf('Doing the Vincentising...\n')
  
  c_CsPlotModels = {'T' 'A' 'AV'};
  c_nPlotModels = length(c_CsPlotModels);
  c_iResponseType = c_iOvertResponse;
  
  
  for iPlotModel = 1:c_nPlotModels
    
    for iCondition = 1:c_nTrialTypes
      
      for iSource = 1:2 % empirical data and model fit
        
        if iSource == 1
          VQuantilesToGet = c_VObservedRTCDFQuantiles;
          SData = c_SObservations;
          VResponseTimeData = c_SObservations.VResponseTime;
        else
          VQuantilesToGet = c_VModelRTCDFQuantiles;
          SData = SSimResults(c_iMLEFitting).(c_CsPlotModels{...
            iPlotModel}).SSimulatedData(c_iResponseType);
          VResponseTimeData = SData.VResponseTime;
        end
        VRTQuantiles = ...
          VincentiseResponseTimes(SData, iCondition, VQuantilesToGet);
        
        SVincentisedCDFs(iPlotModel, iCondition, iSource).VComputedQuantiles = ...
          VQuantilesToGet;
        SVincentisedCDFs(iPlotModel, iCondition, iSource).VRTQuantiles = ...
          VRTQuantiles;
        
      end % iSource for loop
      
    end % iCondition for loop
    
  end % iPlotModel for loop
  
  
  %% plot the CDFs
  
  for iPlotModel = 1:c_nPlotModels
    VhCDFs(iPlotModel) = subplot(1, c_nSubplots, iPlotModel);
    set(gca, 'FontSize', c_stdFontSize, 'FontName', c_sFontName)
    hold on
    for iCondition = 1:c_nTrialTypes
      for iSource = 1:2 % empirical data and model fit
        
        if iSource == 1
          sLineSpec = c_sRTCDFEmpiricalSymbol;
          lineWidth = c_rtCDFEmpiricalLineWidth;
        else
          sLineSpec = '-';
          lineWidth = c_stdLineWidth;
        end
        plot(SVincentisedCDFs(iPlotModel, iCondition, iSource).VRTQuantiles, ...
          SVincentisedCDFs(iPlotModel, iCondition, iSource).VComputedQuantiles, ...
          sLineSpec, 'Color', c_CMConditionRGB{iCondition}, 'MarkerSize', c_rtCDFMarkerSize, ...
          'LineWidth', lineWidth)
        hold on
        
      end % iSource for loop
    end % iUrgency for loop
    
    text(c_VRTCDFXLim(1), c_VRTCDFYLim(2), ['  ' c_CsPlotModels{iPlotModel}], 'VerticalAlignment', ...
      'top', 'FontSize', c_largeAnnotationFontSize, 'FontName', c_sFontName)
    set(gca, 'XLim', c_VRTCDFXLim)
    set(gca, 'YLim', c_VRTCDFYLim)
    set(gca, 'box', 'off')
    if iPlotModel == 1
      ylabel(sprintf('CDF\n\n'), 'FontSize', c_annotationFontSize, ...
        'FontName', c_sFontName, 'VerticalAlignment', 'middle')
    else
      if c_bHideAxes
        set(gca, 'YColor', 'none')
      end
      if iPlotModel == 2
        xlabel(sprintf('\n\nDetection response time (s)'), 'VerticalAlignment', ...
          'middle', 'FontSize', c_annotationFontSize, 'FontName', c_sFontName)
      end
    end
    
  end % iPlotModel for loop
  
  
  
end % if c_bMakeCDFPlots



%% plot the BD/DeltaLL distributions



c_zeroYLocation = 0.35;

for iModelComparison = 1:c_nModelComparisons
  
  c_CsModelComparison = c_CCsModelComparisons{iModelComparison};
  sBaseModel = c_CsModelComparison{1};
  sAlternativeModel = c_CsModelComparison{2};
  
  iBaseModel = find(strcmp(c_CCsModelsFitted{c_iMLEFitting}, sBaseModel));
  assert(length(iBaseModel) == 1)
  iAlternativeModel = find(strcmp(c_CCsModelsFitted{c_iMLEFitting}, sAlternativeModel));
  assert(length(iAlternativeModel) == 1)
  
  % get delta AICs
  VBaseModelLogLik = SResults.MMaxLogLikelihood(:, iBaseModel, ...
    c_iContaminantFractionToPlot, c_iOvertResponse);
  VAltModelLogLik = SResults.MMaxLogLikelihood(:, iAlternativeModel, ...
    c_iContaminantFractionToPlot, c_iOvertResponse);
  VDeltaAIC = 2 * c_VnParamIncreaseInModelComparisons(iModelComparison) ...
    - 2 * (VAltModelLogLik - VBaseModelLogLik);
  plotYRange = 170;
  sYDir = 'normal';
  thisZeroYLocation = 1 - c_zeroYLocation;
  sYLabel = '\DeltaAIC';
  
  % plot
  iPanel = 3 + iModelComparison;
  VhDeltaAICs(iModelComparison) = subplot(1, c_nSubplots, iPanel);
  set(gca, 'FontSize', c_stdFontSize, 'FontName', c_sFontName)
  hold on
  VPlotYLim = [-thisZeroYLocation  (1-thisZeroYLocation)] * plotYRange;
  VerticalRainCloudPlot(VDeltaAIC, VPlotYLim, ...
    c_CMModelComparisonRGB{iModelComparison}, c_stdLineWidth/2)
  set(gca, 'YDir', sYDir)
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
  ylabel(sYLabel, 'FontSize', c_annotationFontSize, 'FontName', c_sFontName)
  
  % model comparison annotation
  VXLim = get(gca, 'XLim');
  textY = VPlotYLim(2);
  text(0, textY, ['  ' sBaseModel ' \rightarrow ' sAlternativeModel], ...
    'VerticalAlignment', 'top', 'FontSize', c_largeAnnotationFontSize, ...
    'FontName', c_sFontName, 'HorizontalAlignment', 'center')
  
  % some results output
  meanDeltaAIC = mean(VDeltaAIC);
  if meanDeltaAIC < 0
    % alternative model preferred
    sPreferredModel = sAlternativeModel;
    sNonPreferredModel = sBaseModel;
    relativeLikelihood = exp(-meanDeltaAIC/2);
  else
    % base model preferred
    sPreferredModel = sBaseModel;
    sNonPreferredModel = sAlternativeModel;
    relativeLikelihood = exp(meanDeltaAIC/2);
  end
    
  fprintf('Model comparison: %s --> %s:\n', sBaseModel, sAlternativeModel)
  fprintf('\tAverage \\DeltaAIC: %.1f\n', meanDeltaAIC)
  fprintf('\tfor av. participant model %s is %.0g times  more likely than %s\n', ...
    sPreferredModel, relativeLikelihood, sNonPreferredModel)
  
  
end % iModelComparison for loop


%% add legend

AddLoomingConditionLegend
hConditionLegend.Box = 'off';
hConditionLegend.Color = 'none';
hConditionLegend.XColor = 'none';
hConditionLegend.YColor = 'none';
Vh(1) = plot(-1, -1, c_sRTCDFEmpiricalSymbol, 'Color', c_VRTCDFLegendIllustrationRGB, ...
  'LineWidth', c_rtCDFEmpiricalLineWidth);
Vh(2) = plot(-1, -1, '-', 'Color', c_VRTCDFLegendIllustrationRGB, ...
  'LineWidth', c_stdLineWidth);
hLegend = legend(Vh, {'Data', 'Model'}, 'FontSize', c_stdFontSize, ...
  'FontName', c_sFontName, 'EdgeColor', 'none', 'Color', 'none');


%% panel labels and positions

% remove any existing panel labels (if tweaking)
if exist('VhPanelLabels', 'var')
  try
    delete(VhPanelLabels)
  end
end
VhPanelLabels = [];

% A
VhPanelLabels(end+1) = annotation('textbox',...
  [0 0.89 0.0272727267308669 0.130434780161162],...
  'String', 'A', 'FontSize', c_panelLabelFontSize, 'FontWeight', 'bold', ...
  'FontName', c_sFontName, 'EdgeColor', 'none');
for i = 1:3
  x = 0.057 + (i-1) * 0.18;
  VhCDFs(i).Position = [x 0.35 0.16 0.56];
end


hConditionLegend.Position = [0.5355 0.5507 0.1342 0.3527];
hLegend.Position = [0.5588    0.3774    0.0857    0.1957];


% B
VhPanelLabels(end+1) = annotation('textbox',...
  [0.70 0.89 0.0272727267308669 0.130434780161162],...
  'String', 'B', 'FontSize', c_panelLabelFontSize, 'FontWeight', 'bold', ...
  'FontName', c_sFontName, 'EdgeColor', 'none');
for i = 1:2
  x = 0.77 + (i-1) * 0.1;
  VhDeltaAICs(i).Position = [x 0.1148 0.10 0.8150];
end


% save EPS
if c_bSaveEPS
  fprintf('Saving EPS...\n')
  SaveFigAsEPSPDF('Fig2.eps')
end