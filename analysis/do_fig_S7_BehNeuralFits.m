
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


clearvars
close all force

SetLoomingDetectionStudyAnalysisConstants
SetPlottingConstants

% load data
fprintf('Loading data...\n')
% - empirical RT data
[c_SObservations, c_SExperiment.CsDataSets] = ...
  GetLoomingDetectionStudyObservationsAndParticipantIDs;
% - info about ABC posteriors
load([c_sAnalysisResultsPath c_sABCPosteriorsMATFileName])
% - simulation results for ABC-fitted models
load([c_sAnalysisResultsPath c_sABCSimulationsForFigsMATFileName])
% - CPP onset results
load([c_sAnalysisResultsPath c_sCPPOnsetMATFileName])


%%


c_CsModelsToPlot = {'AVL'};
c_ViABCFitTypesToPlot = [c_iRTFitFixedThreshLow c_iRTFixLowERPFit ...
  c_iRTFitFixedThreshHigh c_iRTFixHighERPFit];
c_nABCFitTypesToPlot = length(c_ViABCFitTypesToPlot);

fprintf('Plotting...\n')
for iModel = 1:length(c_CsModelsToPlot)
  sModel = c_CsModelsToPlot{iModel};
  
  figure(iModel)
  clf
  set(gcf, 'Name', sprintf('Model %s', sModel))
  set(gcf, 'Position', [133         239        c_nFullWidthFigure_px         400])
  
  ViParticipantsToPlot = ...
    unique(SSimResults.(sModel).SSimulatedData(c_iRTFixLowERPFit).ViDataSet);
  ViParticipantsToPlot = ...
    intersect(ViParticipantsToPlot, SCPPOnsetResults.ViIncludedParticipants);
  
  for iABCFitTypeToPlot = 1:c_nABCFitTypesToPlot
    iABCFitType = c_ViABCFitTypesToPlot(iABCFitTypeToPlot);
    
    for iCondition = 1:c_nTrialTypes
      
      for iSource = 1:2 % empirical data and model fit
        
        if iSource == 1
          % empirical data
          VQuantilesToGet = c_VObservedRTCDFQuantiles;
          SData = c_SObservations;
          sLineSpec = c_sRTCDFEmpiricalSymbol;
          cdfLineWidth = c_rtCDFEmpiricalLineWidth;
          erpLineWidth = c_stdLineWidth * 1.5;
          erpAlpha = 0.3;
        else
          % model fit
          VQuantilesToGet = c_VModelRTCDFQuantiles;
          SData = SSimResults.(sModel).SSimulatedData(iABCFitType);
          sLineSpec = '-';
          cdfLineWidth = c_stdLineWidth;
          erpLineWidth = c_stdLineWidth;
          erpAlpha = 1;
        end
        
        % RT CDF
        VhPanels(1, iABCFitTypeToPlot) = ...
          subplotGM(2, c_nABCFitTypesToPlot, 1, iABCFitTypeToPlot);
        set(gca, 'FontName', c_sFontName)
        set(gca, 'FontSize', c_stdFontSize)
        VRTQuantiles = VincentiseResponseTimes(SData, iCondition, ...
          VQuantilesToGet, ViParticipantsToPlot);
        plot(VRTQuantiles, VQuantilesToGet, sLineSpec, ...
          'Color', c_CMConditionRGB{iCondition}, 'MarkerSize', c_rtCDFMarkerSize, ...
          'LineWidth', cdfLineWidth)
        hold on
        
        if iCondition == c_nTrialTypes
          set(gca, 'XLim', c_VRTCDFXLim)
          set(gca, 'YLim', c_VRTCDFYLim)
          set(gca, 'box', 'off')
          VTickLength = get(gca, 'TickLength');
          VhTopLegend(iSource) = plot([0 1], [-1 -1], sLineSpec, ...
            'Color', [1 1 1] * 0.5, 'MarkerSize', c_rtCDFMarkerSize, ...
            'LineWidth', cdfLineWidth);
          set(gca, 'TickLength', VTickLength * 1.5)
          if iABCFitTypeToPlot == 1
            ylabel('CDF', 'FontSize', c_annotationFontSize)
          end
          if iABCFitTypeToPlot == 1 && iSource == 2
            hTopLegend = legend(VhTopLegend, {'Observed', 'Model'});
          end
        end
        
        % ERP
        VhPanels(2, iABCFitTypeToPlot) = ...
          subplotGM(2, c_nABCFitTypesToPlot, 2, iABCFitTypeToPlot);
        set(gca, 'FontName', c_sFontName)
        set(gca, 'FontSize', c_stdFontSize)
        VbRowsAllConditions = ismember(SData.ViDataSet, ViParticipantsToPlot);
        VbRowsThisCondition = VbRowsAllConditions & ...
          SData.ViCondition == iCondition;
        meanERPAtResponseAllConditions = mean(SData.SResponseERP.MERPs(...
          VbRowsAllConditions, c_SSettings.SResponseERP.idxResponseSample));
        VMeanConditionERP = ...
          mean(SData.SResponseERP.MERPs(VbRowsThisCondition, :), 1);
        VNormalisedMeanConditionERP = ...
          VMeanConditionERP / meanERPAtResponseAllConditions;
        hPlot = plot(c_SSettings.SResponseERP.VTimeStamp, VNormalisedMeanConditionERP, ...
          '-', 'Color', c_CMConditionRGB{iCondition}, ...
          'LineWidth', erpLineWidth);
        hPlot.Color(4) = erpAlpha;
        hold on
        
        if iCondition == c_nTrialTypes
          set(gca, 'XLim', [-1.1 0.1])
          set(gca, 'YLim', [-.4 1.4])
          set(gca, 'box', 'off')
          VTickLength = get(gca, 'TickLength');
          set(gca, 'TickLength', VTickLength * 1.5)
          VhBottomLegend(iSource) = plot([0 1], [-1 -1], '-', 'LineWidth', ...
            erpLineWidth, 'Color', [1 1 1] * 0.5);
          VhBottomLegend(iSource).Color(4) = erpAlpha;
          if iABCFitTypeToPlot == 1
            ylabel('Normalised units', 'FontSize', c_annotationFontSize)
          end
          if iABCFitTypeToPlot == 1 && iSource == 2
            hBottomLegend = legend(VhBottomLegend, {'Observed (ERP)', 'Model (E)'});
          end
        end
        
      end % iSource for loop
      
      
    end % iCondition for loop
    
    
  end % iABCFitTypeToPlot for loop
  
  
  for iABCFitTypeToPlot = 1:c_nABCFitTypesToPlot
    panelX = 0.06 + 0.22 * (iABCFitTypeToPlot - 1);
    if iABCFitTypeToPlot > 2
      panelX = panelX + 0.06;
    end
    VhPanels(1, iABCFitTypeToPlot).Position = [panelX 0.55 0.16 0.27];
    VhPanels(2, iABCFitTypeToPlot).Position = [panelX 0.10 0.16 0.27];
  end % iABCFitTypeToPlot for loop
  
  % x labels
  annotation('textbox',...
    [0 0.45 1 0.06], 'String',{'Detection response time (s)'},...
    'FitBoxToText','off', 'FontSize', c_annotationFontSize, ...
    'HorizontalAlignment', 'center', 'FontName', c_sFontName, 'EdgeColor', 'none');
  annotation('textbox',...
    [0 0 1 0.06], 'String',{'Time relative response (s)'},...
    'FitBoxToText','off', 'FontSize', c_annotationFontSize, ...
    'HorizontalAlignment', 'center', 'FontName', c_sFontName, 'EdgeColor', 'none');
  
  % top-level titles
  annotation('textbox',...
    [0 0.96 .5 0.06], 'String',{'\epsilon_{RT} = 0.4 s'},...
    'FitBoxToText','off', 'FontSize', c_annotationFontSize, ...
    'HorizontalAlignment', 'center', 'FontName', c_sFontName, 'EdgeColor', 'none');
  annotation('textbox',...
    [0.5 0.96 .5 0.06], 'String',{'\epsilon_{RT} = 0.8 s'},...
    'FitBoxToText','off', 'FontSize', c_annotationFontSize, ...
    'HorizontalAlignment', 'center', 'FontName', c_sFontName, 'EdgeColor', 'none');
  
  % sub-titles
  annotation('textbox',...
    [0.015 0.9 .25 0.06], 'String',{'\epsilon_{f} = \infty'},...
    'FitBoxToText','off', 'FontSize', c_annotationFontSize, ...
    'HorizontalAlignment', 'center', 'FontName', c_sFontName, 'EdgeColor', 'none');
  annotation('textbox',...
    [0.235 0.9 .25 0.06], 'String',{'\epsilon_{f} minimized'},...
    'FitBoxToText','off', 'FontSize', c_annotationFontSize, ...
    'HorizontalAlignment', 'center', 'FontName', c_sFontName, 'EdgeColor', 'none');
  annotation('textbox',...
    [0.515 0.9 .25 0.06], 'String',{'\epsilon_{f} = \infty'},...
    'FitBoxToText','off', 'FontSize', c_annotationFontSize, ...
    'HorizontalAlignment', 'center', 'FontName', c_sFontName, 'EdgeColor', 'none');
  annotation('textbox',...
    [0.735 0.9 .25 0.06], 'String',{'\epsilon_{f} minimized'},...
    'FitBoxToText','off', 'FontSize', c_annotationFontSize, ...
    'HorizontalAlignment', 'center', 'FontName', c_sFontName, 'EdgeColor', 'none');
  
  % legends
  hTopLegend.Position = [0.1424 0.5854 0.0964 0.0962];
  hBottomLegend.Position = [0.0665 0.3304 0.1245 0.0962];
  
end % iModel for loop


