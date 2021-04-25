9
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



c_bDoLoadingAndVincentising = true;

if c_bDoLoadingAndVincentising
  
  clearvars
  close all force
  
  % general constants
  SetLoomingDetectionStudyAnalysisConstants
  
  % figure constants
  SetPlottingConstants
  
  for iFilterVariant = 1:2 % main approach in paper vs without HP filtering
    
    % load data
    fprintf('Loading data...\n')
    switch iFilterVariant
      case 1
        % -- CPP onset results
        load([c_sAnalysisResultsPath c_sCPPOnsetMATFileName])
        % - ML fitting results
        load([c_sAnalysisResultsPath c_sMLFittingMATFileName], ...
          'c_CsModels', 'SResults', 'c_VContaminantFractions')
      case 2
        % -- CPP onset results
        load([c_sAnalysisResultsPath c_sCPPOnsetFilterVariantsMATFileName])
        SCPPOnsetResults = SCPPOnsetResults(2);
        % - ML fitting results
        load([c_sAnalysisResultsPath c_sMLFittingFilterVariantsMATFileName], ...
          'c_CsModels', 'SResults', 'c_VContaminantFractions')
    end
    assert(all(strcmp(c_CCsModelsFitted{c_iMLEFitting}(1:length(c_CsModels)), ...
      c_CsModels))) % verifying that the models come in the expected order in the results MAT file
    clear c_CsModels
    c_iContaminantFractionToPlot = ...
      find(c_VContaminantFractions == c_mleContaminantFractionToPlot);
    assert(length(c_iContaminantFractionToPlot) == 1)
    % -- model simulation results incl CPP onset predictions
    load([c_sAnalysisResultsPath c_sSimulationsForFigsMATFileName])
    
    
    % do the Vincentising
    
    fprintf('Doing the Vincentising...\n')
    
    c_CsPlotModels = {'T', 'A', 'AV'};
    c_nPlotModels = length(c_CsPlotModels);
    c_VnPlotModelFreeParams = [3 3 4];
    
    c_ViVincentizingParticipants = SCPPOnsetResults.ViIncludedParticipants;
    c_nVincentizingParticipants = length(c_ViVincentizingParticipants);
    
    for iModel = 1:c_nPlotModels
      sModel = c_CsPlotModels{iModel};
      
      for iCondition = 1:c_nTrialTypes
        
        for iSource = 1:2 % empirical data and model fit
          
          if iSource == 1
            VQuantilesToGet = .1:.2:.9;
            SData = SCPPOnsetResults;
            VResponseTimeData = SCPPOnsetResults.VCPPOnsetTime;
            VbExtraCondition = SCPPOnsetResults.VbHasCPPOnsetTime;
          else
            VQuantilesToGet = .025:.025:.975;
            SData = SSimResults(c_iMLEFitting).(sModel).SSimulatedData(c_iCPPOnset);
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
          
          SVincentisedCDFs(iFilterVariant, iModel, iCondition, iSource).VComputedQuantiles = ...
            VQuantilesToGet;
          SVincentisedCDFs(iFilterVariant, iModel, iCondition, iSource).VRTQuantiles = ...
            VRTQuantiles;
          
        end % iSource for loop
        
      end % iCondition for loop
      
      % get AIC
      iFittedModel = find(strcmp(c_CCsModelsFitted{c_iMLEFitting}, sModel), 1, 'first');
      logLikelihoodSum = sum(squeeze(SResults.MMaxLogLikelihood(...
        c_ViVincentizingParticipants, iFittedModel, ...
        c_iContaminantFractionToPlot, c_iCPPOnset)));
      MAIC(iFilterVariant, iModel) = 2 * c_VnPlotModelFreeParams(iModel) * c_nVincentizingParticipants ...
        - 2 * logLikelihoodSum;
      
    end % iModel for loop
    
  end % iFilterVariants for loop
  
else
  SetPlottingConstants
end


%% do the plotting

figure(1)
clf
set(gcf, 'Position', [100 150 0.7 * c_nFullWidthFigure_px 400])
c_VRTCDFXLim = [0.2 3.5];
c_cppCDFMarkerSize = c_rtCDFMarkerSize + 1;

for iFilterVariant = 1:2 % main approach in paper vs without HP filtering
  
  for iModel = 1:c_nPlotModels
    sModel = c_CsPlotModels{iModel};
    subplotGM(2, c_nPlotModels, iFilterVariant, iModel)
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
        plot(SVincentisedCDFs(iFilterVariant, iModel, iCondition, iSource).VRTQuantiles, ...
          SVincentisedCDFs(iFilterVariant, iModel, iCondition, iSource).VComputedQuantiles, ...
          sLineSpec, 'Color', c_CMConditionRGB{iCondition}, ...
          'MarkerSize', c_cppCDFMarkerSize, 'LineWidth', lineWidth)
        hold on
        
      end % iSource for loop
    end % iCondition for loop
    
    
    text(c_VRTCDFXLim(2), c_VRTCDFYLim(1), sprintf('\\SigmaAIC = %.1f          \n\n', ...
      MAIC(iFilterVariant, iModel)), ...
      'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center', ...
      'FontSize', c_annotationFontSize, 'FontName', c_sFontName)
    
    text(c_VRTCDFXLim(1), c_VRTCDFYLim(2), ['  ' sModel], 'VerticalAlignment', ...
      'top', 'FontSize', c_largeAnnotationFontSize, 'FontName', c_sFontName)
    set(gca, 'XLim', c_VRTCDFXLim)
    set(gca, 'YLim', c_VRTCDFYLim)
    set(gca, 'Box', 'off')
    if iModel == 1
      ylabel(sprintf('CDF\n'), 'FontSize', c_annotationFontSize, ...
        'FontName', c_sFontName)
    elseif iModel == 2 && iFilterVariant == 2
      xlabel(sprintf('\nCPP onset time relative stimulus (s)'), ...
        'FontSize', c_annotationFontSize, 'FontName', c_sFontName)
    elseif iModel == c_nPlotModels && iFilterVariant == 1
      Vh(1) = plot(-1, -1, c_sRTCDFEmpiricalSymbol, ...
        'Color', c_VRTCDFLegendIllustrationRGB, 'MarkerSize', c_cppCDFMarkerSize, ...
        'LineWidth', c_rtCDFEmpiricalLineWidth);
      Vh(2) = plot(-1, -1, '-', 'Color', c_VRTCDFLegendIllustrationRGB, ...
        'LineWidth', c_stdLineWidth);
      hCDFLegend = legend(Vh, {'Data', 'Model'}, ...
        'FontSize', c_annotationFontSize, 'FontName', c_sFontName);
      hCDFLegend.Position = [0.8469 0.5175 0.1285 0.1459];
    end
    
  end % iModel for loop
  
end % iFilterVariant for loop
