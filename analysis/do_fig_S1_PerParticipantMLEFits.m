
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



c_bDoBasicInit = true;
c_bSaveEPS = true;

if c_bDoBasicInit
  
  clearvars -except c_bSaveEPS
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
end

%%

c_CsModelsToPlot = {'T', 'A', 'AV'};
c_VnPlotModelFreeParams = [3 3 4];
c_nModelsToPlot = length(c_CsModelsToPlot);
c_ViPreselectedParticipants = [13];
c_nParticipantsToPlot = 5;
c_nParticipantsToRandomlyDraw = ...
  c_nParticipantsToPlot - length(c_ViPreselectedParticipants);

% randomly select the rest of the participants to plot
rng(0)
c_ViAllParticipants = 1:c_nFinalIncludedParticipants;
c_ViParticipantsToDrawFrom = ...
  setdiff(c_ViAllParticipants, c_ViPreselectedParticipants);
c_ViRandomlyDrawnParticipants = c_ViParticipantsToDrawFrom(...
  randperm(length(c_ViParticipantsToDrawFrom), c_nParticipantsToRandomlyDraw));
c_ViParticipantsToPlot = ...
  [c_ViRandomlyDrawnParticipants(:); c_ViPreselectedParticipants(:)];

c_rtCDFMarkerSizeHere = c_rtCDFMarkerSize - 2;
c_lwScaling = 0.75;
figure(1)
set(gcf, 'Position', [150 100 c_nFullWidthFigure_px 450])
clf
for iPlotModel = 1:c_nModelsToPlot
  sModel = c_CsModelsToPlot{iPlotModel};
  for iCondition = 1:c_nTrialTypes
    for iSource = 1:2 % observed and model
      if iSource == 1
        VRTQuantilesToGet = c_VObservedRTCDFQuantiles;
        SData = c_SObservations;
        sLineSpec = c_sRTCDFEmpiricalSymbol;
        lineWidth = c_rtCDFEmpiricalLineWidth*c_lwScaling;
      else
        VRTQuantilesToGet = c_VModelRTCDFQuantiles;
        SData = SSimResults(c_iMLEFitting).(sModel).SSimulatedData(c_iOvertResponse);
        sLineSpec = '-';
        lineWidth = c_stdLineWidth*c_lwScaling;
      end
      for iPlotParticipant = 1:c_nParticipantsToPlot
        subplotGM(c_nModelsToPlot, c_nParticipantsToPlot, iPlotModel, iPlotParticipant)
        set(gca, 'FontSize', c_stdFontSize, 'FontName', c_sFontName)
        hold on
        iParticipant = c_ViParticipantsToPlot(iPlotParticipant);
        %         sParticipantID = c_SExperiment.CsDataSets{iParticipant};
        VbRows = SData.ViDataSet == iParticipant & ...
          SData.ViCondition == iCondition;
        VRTData = SData.VResponseTime(VbRows);
        VRTQuantiles = quantile(VRTData, VRTQuantilesToGet);
        plot(VRTQuantiles, VRTQuantilesToGet, ...
          sLineSpec, 'Color', c_CMConditionRGB{iCondition}, ...
          'MarkerSize', c_rtCDFMarkerSizeHere, ...
          'LineWidth', lineWidth)
        hold on
      end % iPlotParticipant
    end % iSource for loop
  end % iCondition for loop
end % iModel for loop


%%

% go through the panels again and finish off
for iPlotModel = 1:c_nModelsToPlot
  sModel = c_CsModelsToPlot{iPlotModel};
  for iPlotParticipant = 1:c_nParticipantsToPlot
    VhSubplot(iPlotModel, iPlotParticipant) = ...
      subplotGM(c_nModelsToPlot, c_nParticipantsToPlot, iPlotModel, iPlotParticipant);
    iParticipant = c_ViParticipantsToPlot(iPlotParticipant);
    
    text(0, c_VRTCDFYLim(2), ['  ' sModel], 'VerticalAlignment', ...
      'top', 'FontSize', c_largeAnnotationFontSize, 'FontName', c_sFontName)
    
    maxX = quantile(c_SObservations.VResponseTime(c_SObservations.ViDataSet == iParticipant), 0.995) + 0.5;
    set(gca, 'XLim', [0 maxX])
    set(gca, 'YLim', c_VRTCDFYLim)
    set(gca, 'box', 'off')
    
    iFittedModel = find(strcmp(c_CCsModelsFitted{c_iMLEFitting}, sModel), 1, 'first');
    logLikelihood = SResults.MMaxLogLikelihood(iParticipant, iFittedModel, ...
      c_iContaminantFractionToPlot, c_iOvertResponse);
    aic = 2 * c_VnPlotModelFreeParams(iPlotModel) - 2 * logLikelihood;
    text(maxX, c_VRTCDFYLim(1), sprintf('AIC = %.1f          \n\n', aic), ...
      'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center', ...
      'FontSize', c_stdFontSize, 'FontName', c_sFontName)
    
    if iPlotModel == 1
      title(sprintf('Participant %s\n', c_SExperiment.CsDataSets{iParticipant}), 'FontWeight', 'normal')
    end
    if iPlotModel == 1 && iPlotParticipant == c_nParticipantsToPlot
      Vh(1) = plot(-1, -1, c_sRTCDFEmpiricalSymbol, 'Color', c_VRTCDFLegendIllustrationRGB, ...
        'LineWidth', c_rtCDFEmpiricalLineWidth*c_lwScaling, 'MarkerSize', 5);
      Vh(2) = plot(-1, -1, '-', 'Color', c_VRTCDFLegendIllustrationRGB, ...
        'LineWidth', c_stdLineWidth*c_lwScaling);
      hLegend = legend(Vh, {'Data', 'Model'}, 'FontSize', c_stdFontSize);
      hLegend.Position = [0.9147 0.8626 0.0791 0.0856];
    end
    if iPlotModel == c_nModelsToPlot && iPlotParticipant == 3
      xlabel(sprintf('\nDetection response time (s)'))
    end
    if iPlotModel == 2 && iPlotParticipant == 1 
      ylabel(sprintf('CDF (-)\n'))
    end
  end
  
end


% save EPS
if c_bSaveEPS
  fprintf('Saving EPS...\n')
  SaveFigAsEPSPDF('FigS1.eps')
end


