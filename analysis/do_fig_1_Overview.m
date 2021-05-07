
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



% constants for when tweaking the plots
c_bDoBasicInit = true;
c_bHideAxes = true;
c_bSaveEPS = true;

if c_bDoBasicInit
  clearvars -except c_bHideAxes c_bSaveEPS
  close all force
  
  % general constants
  SetLoomingDetectionStudyAnalysisConstants
  
  % model fitting constants
  c_SSettings = GetLoomingDetectionStudyModelFittingConstants;
  
  % experiment constants
  c_SExperiment = GetLoomingDetectionStudyExperimentConstants(c_SSettings);
  
  % figure constants
  SetPlottingConstants
  
  % loading
  fprintf('Loading data...\n')
  % - empirical data
  [c_SObservations, c_SExperiment.CsDataSets] = ...
    GetLoomingDetectionStudyObservationsAndParticipantIDs;
  % - simulated data from fitted models
  load([c_sAnalysisResultsPath c_sSimulationsForFigsMATFileName])
end


% constants for making partial versions - set all to true to generate the
% figure as shown in the paper
c_bShowPanelLabels = true;
c_bShowAVModelFits = true;
c_bShowThetaDotArea = true;
c_bShowModelIllustration = true;
c_bShowLDTFit = true;


%%

fprintf('Plotting...\n')

close all force

c_VLambleEtAlThresholdPerCondition = [NaN  0.0037  NaN 0.00215]; % rad/s

c_nParadigmPanels = 3;
c_nPanels = 5 + c_SExperiment.nConditions + c_nParadigmPanels;
c_minThetaDot = -0.001;
c_maxThetaDot = 0.008;
c_maxThetaDotForTrace = 0.006;
c_iFittingMethodToPlot = c_iMLEFitting;
c_sModelToPlot = 'AV';
c_humanRTBinSize = 0.05;
c_modelRTBinSize = 0.02;
c_thetaDotBinSize = 0.0001;
c_loomingTraceMaxTime = 5;
c_VTimeTicks = 0:1:c_loomingTraceMaxTime;
c_avThetaDotRGB = c_VExtraColor2RGB;
c_avThetaDotAlpha = 0.8;
c_avThetaDotLW = c_stdLineWidth * 1.5;
c_modelLineWidth = c_stdLineWidth * 1.25;


SSimulatedData = ...
  SSimResults(c_iFittingMethodToPlot).(c_sModelToPlot).SSimulatedData(c_iOvertResponse);

averageThetaDotAtResp = mean(c_SObservations.VThetaDotAtResponse);

% looming trace panel
c_area = 0.001;
hLoomingTracePanel = subplot(1, c_nPanels, 1);
set(gca, 'FontSize', c_stdFontSize, 'FontName', c_sFontName)
hold on
if c_bShowLDTFit
  h = plot([0 c_loomingTraceMaxTime], [1 1] * averageThetaDotAtResp, ':', ...
    'Color', c_avThetaDotRGB, 'LineWidth', c_avThetaDotLW);
  h.Color(4) = c_avThetaDotAlpha;
  hold on
end
for iCondition = 1:c_SExperiment.nConditions
  SLoomingTrace = ...
    c_SExperiment.SLoomingTraces(iCondition).SPreLoomingWaitTime(1);
  plot(SLoomingTrace.VTimeStamp, SLoomingTrace.VThetaDot, '-', ...
    'Color', c_CMConditionRGB{iCondition}, 'LineWidth', c_stdLineWidth * .75)
  VConventionalRT(iCondition) = SLoomingTrace.VTimeStamp(...
    find(SLoomingTrace.VThetaDot >= averageThetaDotAtResp, 1, 'first'));
    % shading
    VArea = cumtrapz(SLoomingTrace.VTimeStamp, SLoomingTrace.VThetaDot);
    iAreaTime = find(VArea >= c_area, 1, 'first');
    areaTime = SLoomingTrace.VTimeStamp(iAreaTime);
    if c_bShowThetaDotArea
      hFill = fill(SLoomingTrace.VTimeStamp([1:iAreaTime iAreaTime]), ...
        [SLoomingTrace.VThetaDot(1:iAreaTime) 0], 'k', 'EdgeColor', 'none', ...
        'FaceAlpha', 0.1);
      uistack(hFill, 'bottom')
    end
end
plot([0 0], [-0 0.005], '-', 'Color', [1 1 1] * 0.7, 'LineWidth', c_stdLineWidth *.5)
set(gca, 'YLim', [c_minThetaDot c_maxThetaDotForTrace])
set(gca, 'XLim', [0 c_loomingTraceMaxTime])
set(gca, 'YAxisLocation', 'right')
set(gca, 'Box', 'off')
set(gca, 'XTick', c_VTimeTicks)
if c_bHideAxes
  set(gca, 'XColor', 'none')
  set(gca, 'YColor', 'none')
end
%xlabel('Time relative looming onset (s)', 'FontSize', c_annotationFontSize, ...
%  'FontName', c_sFontName)


% looming axes panel
hLoomingAxesPanel = subplot(1, c_nPanels, 2);
set(gca, 'FontSize', c_stdFontSize, 'FontName', c_sFontName)
hold on
set(gca, 'YLim', [0 c_maxThetaDot - 0.001])
set(gca, 'YAxisLocation', 'right')
set(gca, 'TickDir', 'both')
text(1.5, 0.008, sprintf('d\\theta/dt\n (rad/s)'), ...
  'FontSize', c_annotationFontSize, 'FontName', c_sFontName, ...
  'HorizontalAlignment', 'center')
set(gca, 'YTick', 0:0.001:0.007)
set(gca, 'YTickLabel', {'0' '' '0.002' '' '0.004' '' '0.006' ''})
set(gca, 'TickLength', [0.015 0.04])
if c_bHideAxes
  set(gca, 'XColor', 'none')
end


% response time (inset panel - upper)
hRTPanel = subplot(1, c_nPanels, 3);
c_VHumanRTBinEdges = c_humanRTBinSize/2:c_humanRTBinSize:c_loomingTraceMaxTime;
c_VModelRTBinEdges = c_modelRTBinSize/2:c_modelRTBinSize:c_loomingTraceMaxTime;
c_VModelRTBinCentres = c_VModelRTBinEdges(1:end-1) + c_modelRTBinSize/2;
c_ViHighlightedConditions = c_ViConditionUrgencyOrder([1 end]);
hold on
for iCondition = c_ViHighlightedConditions
  for iSource = 1:2
    if iSource == 1
      SData = c_SObservations;
    else
      SData = SSimulatedData;
    end
    VbConditionRows = SData.ViCondition == iCondition;
    VResponseTimes = SData.VResponseTime(VbConditionRows);
    if iSource == 1
      h = histogram(VResponseTimes, c_VHumanRTBinEdges, ...
        'LineStyle', 'none', 'FaceColor', c_CMConditionRGB{iCondition}, 'FaceAlpha', 0.5);
      nEmpiricalResponses = length(VResponseTimes);
        uistack(h, 'top')
    else
      VnBinValues = histcounts(VResponseTimes, c_VModelRTBinEdges);
      nModelResponses = length(VResponseTimes);
      VnBinValues = VnBinValues * nEmpiricalResponses * c_humanRTBinSize / (nModelResponses * c_modelRTBinSize);
      if c_bShowAVModelFits
        h = plot(c_VModelRTBinCentres, VnBinValues, '-', 'Color', c_CMConditionRGB{iCondition}, ...
          'LineWidth', c_modelLineWidth);
        uistack(h, 'bottom')
      end
      if iCondition == 2
        c_rtYLim = max(VnBinValues) * 1.1;
        set(gca, 'YLim', [0 c_rtYLim])
      end
    end
  end % iSource for loop
  if c_bShowLDTFit
    plot(VConventionalRT(iCondition), 0.08 * c_rtYLim, '^', 'Color', ...
      c_CMConditionRGB{iCondition}, 'MarkerFaceColor', c_avThetaDotRGB, ...
      'MarkerSize', 8, 'LineWidth', c_stdLineWidth)
  end
%   c_avThetaDotRGB = [.4 1 .4];
% c_avThetaDotAlpha = 0.5;
end % iCondition for loop
if c_bHideAxes
  set(gca, 'XColor', 'none')
  set(gca, 'YColor', 'none')
end
% annotations
annotation('textarrow',[0.255454545454545 0.283636363636364],...
  [0.95 0.93],'String',{'Data '}, ...
  'FontName', c_sFontName, 'FontSize', c_stdFontSize, ...
  'HeadLength', 0, 'HeadWidth', 0, 'Color', [1 1 1] * 0.5);
annotation('textarrow',[0.329090909090909 0.293363636363636],...
  [0.9715 0.96],'String',{'Model'}, ...
  'FontName', c_sFontName, 'FontSize', c_stdFontSize, ...
  'HeadLength', 0, 'HeadWidth', 0, 'Color', [1 1 1] * 0.3);



% accumulation illustration (inset panel - lower)
hAccPanel = subplot(1, c_nPanels, 4);
if c_bShowModelIllustration
  c_SParameters = ...
    DrawModelParameterSetFromPrior_LoomingDetectionStudy('A', c_SSettings);
  c_SParameters.alpha_ND = 1;
  c_SParameters.K = 1000;
  c_SParameters.T_ND = 0.2;
  c_SParameters.sigma = 0.2;
  c_SParameters.sigma_K = 0.35;
  c_nNoisyTracesPerCond = 5;
  c_noisyTracesAlpha = 0.3;
  plot([0 c_loomingTraceMaxTime], [1 1], '-', 'Color', [1 1 1] * 0.8)
  hold on
  rng(0)
  for iCondition = c_ViHighlightedConditions
    SLoomingTrace = ...
      c_SExperiment.SLoomingTraces(iCondition).SPreLoomingWaitTime(1);
    VIntegratedThetaDot = cumtrapz(SLoomingTrace.VTimeStamp, SLoomingTrace.VThetaDot);
    VAccumulatedEvidence = c_SParameters.K * VIntegratedThetaDot;
    for i = 1:c_nNoisyTracesPerCond
      [idxResponse, VActivation] = ...
        SimulateOneTrial_AccumulatorModel(SLoomingTrace.VTimeStamp, ...
        SLoomingTrace.VThetaDot, c_SParameters, c_SSettings);
      idxThresholdSample = find(VActivation >= 1, 1, 'first');
      h = plot(SLoomingTrace.VTimeStamp(1:idxThresholdSample), ...
        VActivation(1:idxThresholdSample), '-', 'Color', ...
        c_CMConditionRGB{iCondition}, 'LineWidth', c_stdLineWidth*1);
      h.Color(4) = c_noisyTracesAlpha;
      h = plot(SLoomingTrace.VTimeStamp(idxThresholdSample), 1, 'o', ...
        'MarkerFaceColor', c_CMConditionRGB{iCondition}, ...
        'MarkerEdgeColor', 'none', 'MarkerSize', 4);
      %h.MarkerFaceAlpha = c_noisyTracesAlpha;
    end
    %   plot(SLoomingTrace.VTimeStamp, VAccumulatedEvidence, '-', ...
    %     'Color', c_CMConditionRGB{iCondition}, 'LineWidth', c_stdLineWidth)
  end
  set(gca, 'XLim', [0 c_loomingTraceMaxTime])
  set(gca, 'YLim', [0 1.2])
  set(gca, 'XTick', c_VTimeTicks)
  if c_bHideAxes
    set(gca, 'XColor', 'none')
    set(gca, 'YColor', 'none')
  end
  set(gca, 'XTickLabel', [])
  set(gca, 'box', 'off')
else
  hAccPanel.Visible = 'off';
end



% looming threshold panel
c_VThetaDotBinEdges = 0:c_thetaDotBinSize:c_maxThetaDot;
c_VThetaDotBinCentres = c_VThetaDotBinEdges(1:end-1) + c_thetaDotBinSize/2;
c_maxX = 150;
c_grayTextColor = [1 1 1] * 0.6;
for iUrgency = 1:c_SExperiment.nConditions
  VhThetaDotPanels(iUrgency) = subplot(1, c_nPanels, 4 + iUrgency);
  iCondition = c_ViConditionUrgencyOrder(iUrgency);
  hold on
  for iSource = 1:2
    if iSource == 1
      SData = c_SObservations;
    else
      SData = SSimulatedData;
    end
    VbConditionRows = SData.ViCondition == iCondition;
    VThetaDot = SData.VThetaDotAtResponse(VbConditionRows);
    if iSource == 1
      h = histogram(VThetaDot, c_VThetaDotBinEdges, 'Orientation', 'horizontal', ...
        'LineStyle', 'none', 'FaceColor', c_CMConditionRGB{iCondition}, 'FaceAlpha', 0.5);   
      nEmpiricalResponses = length(VThetaDot);
      upperY = prctile(VThetaDot, 97) + 0.001;
%       text(0, upperY, ...
%         sprintf('  %d m', c_VTrialInitialDistances(iCondition)), ...
%         'FontSize', c_stdFontSize, 'Color', c_grayTextColor, ...
%         'VerticalAlignment', 'bottom')
%       text(0, upperY - 0.0006, ...
%         sprintf('  %.2g m/s^2', c_VTrialDecelerations(iCondition)), ...
%         'FontSize', c_stdFontSize, 'Color', c_grayTextColor, ...
%         'VerticalAlignment', 'bottom')
    else
      VnBinValues = histcounts(VThetaDot + randn(size(VThetaDot)) * 0.0001/2, c_VThetaDotBinEdges);
      nModelResponses = length(VThetaDot);
      VnBinValues = VnBinValues * nEmpiricalResponses / nModelResponses;
      VnBinValues(VnBinValues < 0.7) = NaN;
      if c_bShowAVModelFits
        h = plot(VnBinValues, c_VThetaDotBinCentres, '-', 'Color', c_CMConditionRGB{iCondition}, ...
          'LineWidth', c_modelLineWidth);
        uistack(h, 'bottom')
      end
      set(gca, 'XLim', [0 c_maxX])
    end
  end % iSource for loop
  set(gca, 'YLim', [c_minThetaDot c_maxThetaDot])
  if c_bHideAxes
    set(gca, 'XColor', 'none')
    set(gca, 'YColor', 'none')
  end
  if c_bShowLDTFit
    h = plot([0 0.5*c_maxX], [1 1] * averageThetaDotAtResp, ':', ...
      'Color', c_avThetaDotRGB, 'LineWidth', c_avThetaDotLW);
    h.Color(4) = c_avThetaDotAlpha;
  end
  plot(0, c_VLambleEtAlThresholdPerCondition(iCondition), 'kx', ...
    'LineWidth', c_stdLineWidth, 'MarkerSize', 8)
end % iUrgency for loop
% annotations
annotation('textarrow',[0.804545454545455 0.826363636363637],...
  [0.13 0.1575],'Color',[0.5 0.5 0.5],'String',{'Data '}, ...
  'FontName', c_sFontName, 'FontSize', c_stdFontSize, ...
  'HeadLength', 0, 'HeadWidth', 0, 'Color', [1 1 1] * 0.5);
annotation('textarrow',[0.842727272727273 0.840909090909091],...
  [0.0975 0.15],'Color',[0.3 0.3 0.3],'String',{'Model'}, ...
  'FontName', c_sFontName, 'FontSize', c_stdFontSize, ...
  'HeadLength', 0, 'HeadWidth', 0, 'Color', [1 1 1] * 0.3);



% paradigm panels
c_nudgeDown = 0.15;
for i = 1:c_nParadigmPanels
  VhParadigmPanel(i) = subplot(1, ...
    c_nPanels, 4 + c_SExperiment.nConditions + i);
  [MImage, MMap] = imread(sprintf('paradigm-%d.png', i));
  imshow(MImage, MMap)
  set(gca, 'XTick', [])
  set(gca, 'YTick', [])
  set(gca, 'box', 'on')
end
annotation('doublearrow',[0.0103092783505155 0.0800951625693894],...
  [0.47 0.4375]-c_nudgeDown);
annotation('doublearrow',[0.0856463124504362 0.15543219666931],...
  [0.4325 0.40]-c_nudgeDown);
annotation('textbox',...
  [0.0295487708168121 0.4075-c_nudgeDown 0.03 0.0550660792951543],...
  'String',{'3 s'},...
  'HorizontalAlignment','center',...
  'FitBoxToText','off',...
  'EdgeColor','none', ...
  'FontSize', c_stdFontSize, ...
  'FontName', c_sFontName);
annotation('textbox',...
  [0.082 0.355-c_nudgeDown 0.07 0.0550660792951542],...
  'String','1.5 - 3.5 s',...
  'HorizontalAlignment','center',...
  'FitBoxToText','off',...
  'EdgeColor','none', ...
  'FontSize', c_stdFontSize, ...
  'FontName', c_sFontName);
  


% time axes panel
hTimeAxesPanel = subplot(1, c_nPanels, c_nPanels);
set(gca, 'FontSize', c_stdFontSize, 'FontName', c_sFontName)
hold on
set(gca, 'XLim', [0 c_loomingTraceMaxTime])
set(gca, 'TickDir', 'both')
set(gca, 'Box', 'off')
set(gca, 'XTick', c_VTimeTicks)
text(2.7, 1.2, sprintf('Time relative looming onset (s)'), ...
  'FontSize', c_annotationFontSize, 'FontName', c_sFontName)
% set(gca, 'YTick', 0:0.001:0.007)
% set(gca, 'YTickLabel', {'0' '' '0.002' '' '0.004' '' '0.006' ''})
set(gca, 'TickLength', [0.01 0.02])
if c_bHideAxes
  set(gca, 'YColor', 'none')
end




% add legend
AddLoomingConditionLegend


% arrange the panels
set(gcf, 'Position', [50 100 c_nFullWidthFigure_px 400])
set(gcf, 'Color', 'w')

c_nudgeRight = 0.02;
set(hLoomingTracePanel, 'Position', [0.2109 0.1200-c_nudgeDown 0.3955 0.4950]);
set(hTimeAxesPanel, 'Position', [0.2109 0.65 0.3955 0.0400]);
set(hLoomingAxesPanel, 'Position', [0.6482+c_nudgeRight/2 0.1925-c_nudgeDown 0.0163 0.4875])
set(hAccPanel, 'Position', [0.2109 0.7550 0.3955 0.1150])
set(hRTPanel, 'Position', [0.2109 0.87 0.3955 0.1375])
c_firstX = 0.7391 + c_nudgeRight;
c_lastX = 0.9174 + c_nudgeRight;
for i = 1:c_SExperiment.nConditions
  x = c_firstX + ((i-1) / (c_SExperiment.nConditions - 1)) * ...
    (c_lastX - c_firstX);
  set(VhThetaDotPanels(i), 'Position', [x 0.1200-c_nudgeDown 0.0522 0.6338])
end
c_firstX = 0.0091;
c_lastX = 0.1609;
c_firstY = 0.49;
c_lastY = 0.41;
c_imageHToW = 5.5/7.8;
c_axesWidth = 0.1009;
c_axesHeight = c_axesWidth * c_imageHToW;
for i = 1:c_nParadigmPanels
  x = c_firstX + ((i-1) / (c_nParadigmPanels - 1)) * (c_lastX - c_firstX);
  y = c_firstY + ((i-1) / (c_nParadigmPanels - 1)) * (c_lastY - c_firstY);
  set(VhParadigmPanel(i), 'Position', [x y-c_nudgeDown 0.1009 0.2175])
end
%hConditionLegend.Position = [0.0364 0.1150-c_nudgeDown 0.1355 0.1800];
hConditionLegend.Position = [0.8082 0.7250 0.1355 0.1800];


if c_bShowPanelLabels
  % panel labels
  annotation('textbox',...
    [0.13 0.69-c_nudgeDown 0.0245036406892076 0.0770925093721189],...
    'String',{'A'},...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',c_panelLabelFontSize,...
    'FontName', c_sFontName,...
    'FitBoxToText','off',...
    'EdgeColor','none');
  annotation('textbox',...
    [0.178886525845289 0.90888986948251 0.0245036406892076 0.0770925093721186],...
    'String','B',...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FontSize',c_panelLabelFontSize,...
    'FontName', c_sFontName,...
    'FitBoxToText','off',...
    'EdgeColor','none');
  annotation('textbox',...
    [0.731 0.76-c_nudgeDown 0.0245036406892076 0.0770925093721186],...
    'String','C',...
    'HorizontalAlignment','left',...
    'FontWeight','bold',...
    'FontSize',c_panelLabelFontSize,...
    'FontName', c_sFontName,...
    'FitBoxToText','off',...
    'EdgeColor','none');
end


% save EPS
if c_bSaveEPS
  fprintf('Saving EPS...\n')
  SaveFigAsEPSPDF('Fig1.eps')
end