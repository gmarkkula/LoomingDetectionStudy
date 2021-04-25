
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
close all

SetLoomingDetectionStudyAnalysisConstants
SetPlottingConstants

c_nFilterVariants = 2;

c_bDoANOVA = true;
c_bHideAxes = true;

%%

disp('Loading data...')
load([c_sAnalysisResultsPath c_sAllTrialDataFilterVariantsFileName])
load([c_sAnalysisResultsPath c_sCPPOnsetFilterVariantsMATFileName])
load([c_sAnalysisResultsPath c_sCPPRelOnsetDiffsFilterVariantsMATFileName])


%%

% get the electrodes used to estimate CPP
ViElectrodes = GetElectrodeIndices(...
  SAllTrialData.SEEGChannelLocations, c_CsElectrodesForModelFitting);

nEpochs = size(SAllTrialData.MEEGERP, 4);


% get stimulus-locked and response-locked average ERPs


% get stimulus- and response-locked ERPs averaged over the targeted
% electrodes
nStimulusLockedPlotSamples = size(SAllTrialData.MEEGERP, 3);
MStimulusERP = NaN * ones(c_nFilterVariants, nEpochs, nStimulusLockedPlotSamples);
MResponseERP = NaN * ones(c_nFilterVariants, nEpochs, c_nResponseLockedPlotSamples);


for iFilterVariant = 1:c_nFilterVariants
  
  for iEpoch = 1:nEpochs
    MStimulusERP(iFilterVariant, iEpoch, :) = ...
      squeeze(mean(SAllTrialData.MEEGERP(...
      iFilterVariant, ViElectrodes, :, iEpoch), 2));
    idxEpochResponseSample = SAllTrialData.VidxResponseERPSample(iEpoch);
    MResponseERP(iFilterVariant, iEpoch, :) = ...
      squeeze(mean(SAllTrialData.MEEGERP(iFilterVariant, ViElectrodes, ...
      idxEpochResponseSample + c_VidxDataRangeAroundResponse, iEpoch), 2));
  end % iEpoch for loop
  
end % iFilterVariant for loop


% do ANOVAs on response-locked ERP to test for effect of condition
c_VTestTimeStamps_ms = -500 : 20 : 300;
c_nTests = length(c_VTestTimeStamps_ms);
CVPredictors = {SAllTrialData.ViStimulusID SAllTrialData.ViFinalIncludedParticipantCounter};
c_ViRandomEffectPredictors = 2;
c_CsPredictors = {'Condition' 'Participant'};
VConditionP = NaN * ones(c_nFilterVariants, c_nTests);

if c_bDoANOVA
  fprintf('Testing for difference in response-locked ERP between conditions...\n')
  for iFilterVariant = 1:c_nFilterVariants
    for iTest = 1:length(c_VTestTimeStamps_ms)
      
      fprintf('.')
      
      testTime_ms = c_VTestTimeStamps_ms(iTest);
      idxTestSample = find(c_VResponseLockedTimes_ms >= testTime_ms, 1, 'first');
      VERPDataAtTestSample = squeeze(MResponseERP(iFilterVariant, :, idxTestSample));
      
      [p, STable, SStats] = anovan(VERPDataAtTestSample, ...
        CVPredictors, 'model', 2, 'random', c_ViRandomEffectPredictors, ...
        'varnames', c_CsPredictors, 'display', 'off');
      
      %     fprintf('t = %.0f ms:\n\tp(Condition) = %.3f\n\tp(Participant) = %.3f\n\tp(interaction) = %.3f\n', ...
      %       testTime_ms, p(1), p(2), p(3))
      
      VConditionP(iFilterVariant, iTest) = p(1);
      
    end % iTest for loop
    fprintf('\n')
    
  end % iFilterVariant for loop
end


%% plot the stimulus and response locked ERPs

figure(1)
clf
set(gcf, 'Position', [100 150 c_nFullWidthFigure_px 480])

for iFilterVariant = 1:c_nFilterVariants
  
  for iCondition = 1:c_nTrialTypes
    
    ViConditionEpochs = find(SAllTrialData.ViStimulusID == iCondition);
    
    for iLock = 1:2 % plot stimulus- and response-locked ERP
      
      switch iLock
        case 1
          sLabel = 'stimulus';
          VXLim = [-500 3000];
          VERPTimeStamp_ms = SAllTrialData.VERPTimeStamp * 1000;
          VERPData = squeeze(mean(MStimulusERP(iFilterVariant, ViConditionEpochs, :), 2));
        case 2
          sLabel = 'response';
          VXLim = c_VResponseERPXLim_ms;
          VERPTimeStamp_ms = c_VResponseLockedTimes_ms;
          VERPData = squeeze(mean(MResponseERP(iFilterVariant, ViConditionEpochs, :), 2));
          MERPData(iCondition, :) = VERPData;
      end
      
      VhPlot(iFilterVariant, iLock) = ...
        subplotGM(c_nFilterVariants, 3, iFilterVariant, iLock);
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
          VTestPlotY(squeeze(VConditionP(iFilterVariant, :) > 0.05)) = NaN;
          plot(c_VTestTimeStamps_ms, VTestPlotY, 'k.')
%           if c_bHideAxes
%             set(gca, 'YColor', 'none')
%           end
        end
        
        set(gca, 'XLim', VXLim)
        set(gca, 'YLim', c_VERPYLim + [-1 2])
        h = plot([0 0], get(gca, 'YLim'), 'k-', 'LineWidth', c_stdLineWidth/2);
        uistack(h, 'bottom')
        if iFilterVariant == 1
          xlabel(sprintf('\nTime relative %s (ms)', sLabel), ...
            'FontSize', c_annotationFontSize, 'FontName', c_sFontName)
        end
      end
      ylabel(sprintf('ERP (\\muV)'), 'FontSize', c_annotationFontSize, ...
        'FontName', c_sFontName)
      
      
    end % iLock for loop
    
  end % Condition for loop
  
end % iFilterVariant for loop




%% plot estimated CPP onsets relative to the response

for iFilterVariant = 1:c_nFilterVariants
  
  VhPlot(iFilterVariant, 3) = ...
    subplotGM(c_nFilterVariants, 3, iFilterVariant, 3);
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
    VbRows = SCPPOnsetResults(iFilterVariant).ViCondition == iCondition & ...
      ismember(SCPPOnsetResults(iFilterVariant).ViDataSet, SCPPOnsetResults(iFilterVariant).ViIncludedParticipants) & ...
      SCPPOnsetResults(iFilterVariant).VbHasCPPOnsetTime;
    VRelCPPOnsets_ms = SCPPOnsetResults(iFilterVariant).VCPPRelOnsetTime(VbRows) * 1000;
    VnBinCounts = histcounts(VRelCPPOnsets_ms, c_VCPPBinEdges_ms);
    VnBinDensities = VnBinCounts / sum(VnBinCounts);
    scatterBaseY = iUrgency * c_unitDistance * 2;
    pdfBaseY = scatterBaseY + 0.5 * c_unitDistance;
    [VDensity, VDensityPoints] = ksdensity(VRelCPPOnsets_ms, 'support', [-1000 0]);
    hLine = fill(VDensityPoints, pdfBaseY + VDensity / c_unitDistance, ...
      '-', 'LineWidth', c_stdLineWidth/2, 'EdgeColor', 0.8 * c_CMConditionRGB{iCondition}, ...
      'FaceColor', c_CMConditionRGB{iCondition}, 'FaceAlpha', 0.8);
    
    scatter(VRelCPPOnsets_ms + randn(size(VRelCPPOnsets_ms)) * c_jitterX,  ...
      scatterBaseY + randn(size(VRelCPPOnsets_ms)) * c_jitterY, ...
      5, 'MarkerEdgeColor', 'none', 'MarkerFaceColor', c_CMConditionRGB{iCondition}, ...
      'MarkerFaceAlpha', 0.5)
    plot(SCPPRelOnsetResults(iFilterVariant).VCondAvCPPRelOnsets(iCondition) * 1000 * [1 1], ...
      pdfBaseY + [-1 1] * c_unitDistance / 4, 'k-', ...
      'LineWidth', c_stdLineWidth)
    
  end % Condition for loop
  
  VObservedRange = ...
    [SCPPRelOnsetResults(iFilterVariant).minCPPRelOnset ...
    SCPPRelOnsetResults(iFilterVariant).maxCPPRelOnset];
  VUpper95CIEdgeRange = ...
    (mean(VObservedRange) + [-.5 .5] * ...
    SCPPRelOnsetResults(iFilterVariant).VMaxAbsCondDiff95CIEdges(2));
  plot(1000 * VUpper95CIEdgeRange, ...
    [1 1] * c_unitDistance * .7, '-', 'LineWidth', c_stdLineWidth, ...
    'Color', [1 1 1] * .6)
  plot(VObservedRange * 1000, ...
    [1 1] * c_unitDistance * .7, 'k-', 'LineWidth', c_stdLineWidth * 3)
  
  if iFilterVariant == 1
    xlabel(sprintf('\nCPP onset time rel. response (ms)'))
  end
  set(gca, 'XLim', [-1000 50])
  set(gca, 'YLim', [-.25 10] * c_unitDistance)
  if c_bHideAxes
    set(gca, 'YColor', 'none')
  end
  
end


%% panel position and labels
for iFilterVariant = 1:c_nFilterVariants
  for iLock = 1:3
    VhPlot(iFilterVariant, iLock).Position = ...
      [0.10 + (iLock-1) * 0.30  0.18 + (iFilterVariant-1) * 0.48  0.21  0.28];
    annotation('textbox',...
      [0.05 + (iLock-1) * 0.30  0.89 - (iFilterVariant-1) * 0.48  0.07 0.12],...
      'String', char(int8('A') + iLock-1 + 3*(iFilterVariant-1)), ...
      'FontSize', c_panelLabelFontSize, 'FontName', c_sFontName, ...
      'FontWeight', 'bold', 'EdgeColor', 'none');
  end
end
% 
% % panel labels
% % A
% annotation('textbox',...
%   [0.01 0.89 0.07 0.12],...
%   'String', 'A', 'FontSize', c_panelLabelFontSize, 'FontName', c_sFontName, ...
%   'FontWeight', 'bold', 'EdgeColor', 'none');
% % B
% annotation('textbox',...
%   [0.01 0.89-0.48 0.07 0.12],...
%   'String', 'B', 'FontSize', c_panelLabelFontSize, 'FontName', c_sFontName, ...
%   'FontWeight', 'bold', 'EdgeColor', 'none');

