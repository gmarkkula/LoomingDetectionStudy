
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
if c_bDoBasicInit
  
  clearvars
  close all force
  
  % general constants
  SetLoomingDetectionStudyAnalysisConstants
  
  % figure constants
  SetPlottingConstants
  
  % load EEG data across all electrodes
  fprintf('Loading data...\n')
  load([c_sAnalysisResultsPath c_sAllTrialDataFileName])
  load([c_sAnalysisResultsPath c_sCPPOnsetMATFileName])
  
end

%%

c_ViPlotParticipants = 1:22;
c_nPlotParticipants = length(c_ViPlotParticipants);
c_nPlotRows = 4;
c_nPlotCols = 6;
c_VERPXLim_ms = [-1200 500];
c_VERPYLim = [-4 13];
c_iAxisParticipant = 19;


ViElectrodes = GetElectrodeIndices(...
  SAllTrialData.SEEGChannelLocations, c_CsElectrodesForModelFitting);

% constants for response-locking
c_responseERPMinTime = -1;
c_responseERPMaxTime = 0.4;
c_nPreResponsePlotSamples = round(-c_responseERPMinTime * c_nERPSampleRate);
c_nPostResponsePlotSamples = round(c_responseERPMaxTime * c_nERPSampleRate);
c_VidxDataRangeAroundResponse = [-c_nPreResponsePlotSamples+1:c_nPostResponsePlotSamples];
c_nResponseLockedPlotSamples = length(c_VidxDataRangeAroundResponse);
c_VResponseLockedTimes_ms = c_VidxDataRangeAroundResponse * (1000/c_nERPSampleRate);

idxEarlySample = find(c_VResponseLockedTimes_ms >= ...
  c_probeTimeForCPPEffectSizeThreshold * 1000, 1, 'first');
idxPeakSample = find(c_VResponseLockedTimes_ms >= 0, 1, 'first');

% get response-locked ERPs averaged over the targeted
% electrodes
fprintf('Averaging over targeted electrodes...\n')
nEpochs = size(SAllTrialData.MEEGERP, 3);
MResponseERP = NaN * ones(nEpochs, c_nResponseLockedPlotSamples);
for iEpoch = 1:nEpochs
  MStimulusERP(iEpoch, :) = ...
    squeeze(mean(SAllTrialData.MEEGERP(ViElectrodes, :, iEpoch), 1));
  idxEpochResponseSample = SAllTrialData.VidxResponseERPSample(iEpoch);
  MResponseERP(iEpoch, :) = squeeze(mean(SAllTrialData.MEEGERP(ViElectrodes, ...
    idxEpochResponseSample + c_VidxDataRangeAroundResponse, iEpoch), 1));
end % iEpoch for loop


% plot
fprintf('Plotting...\n')
figure(1)
set(gcf, 'Position', [100 100 c_nFullWidthFigure_px 540])
clf
for iPlotParticipant = 1:c_nPlotParticipants
  
  subplot(c_nPlotRows, c_nPlotCols, iPlotParticipant)
  set(gca, 'FontSize', c_stdFontSize, 'FontName', c_sFontName)
  hold on
  
  iParticipant = c_ViPlotParticipants(iPlotParticipant);
  
  %% plot the response locked ERPs 
  for iCondition = 1:c_nTrialTypes
    
    ViConditionEpochs = find(...
      SAllTrialData.ViFinalIncludedParticipantCounter == iParticipant & ...
      SAllTrialData.ViStimulusID == iCondition);
    
    sLabel = 'response';
    VERPData = mean(MResponseERP(ViConditionEpochs, :));
    
    hLine = plot(c_VResponseLockedTimes_ms, VERPData, ...
      '-', 'LineWidth', c_stdLineWidth, 'Color', c_CMConditionRGB{iCondition});
    if iCondition == c_nTrialTypes
      % display effect size
      ViParticipantEpochs = find(...
        SAllTrialData.ViFinalIncludedParticipantCounter == iParticipant);
      VEarlyValues = MResponseERP(ViParticipantEpochs, idxEarlySample);
      VPeakValues = MResponseERP(ViParticipantEpochs, idxPeakSample);
      effectSize = CalculateCohensDForIndependentSamples(VEarlyValues, VPeakValues);
      text(c_VERPXLim_ms(1), c_VERPYLim(2), sprintf('  %s\n  d = %.2f', ...
        SAllTrialData.CsFinalIncludedParticipantIDs{iParticipant}, effectSize), ...
        'FontSize', c_annotationFontSize, 'VerticalAlignment', 'middle', ...
        'FontName', c_sFontName)
      % finish off plot
      set(gca, 'XLim', c_VERPXLim_ms)
      set(gca, 'YLim', c_VERPYLim)
      h = plot([0 0], get(gca, 'YLim'), '-', 'Color', [1 1 1] * .5, ...
        'LineWidth', c_stdLineWidth);
      uistack(h, 'bottom')
      VTickLength = get(gca, 'TickLength');
      set(gca, 'TickLength', VTickLength * 2)
    end
    
    if iPlotParticipant == c_iAxisParticipant
      xlabel(sprintf('Time relative %s (ms)', sLabel), ...
        'FontSize', c_annotationFontSize, 'FontName', c_sFontName)
      ylabel('ERP (\muV)', 'FontSize', c_annotationFontSize, ...
        'FontName', c_sFontName)
    else
      set(gca, 'XTickLabel', {})
      set(gca, 'YTickLabel', {})
    end
    
    if ismember(iPlotParticipant, SCPPOnsetResults.ViExcludedParticipants)
      hFill = fill3(c_VERPXLim_ms([1 2 2 1]), c_VERPYLim([1 1 2 2]), ...
        [1 1 1 1] * -1, [.8 .8 .8], 'EdgeColor', 'none', 'Clipping', 'off');
      uistack(hFill, 'bottom')
      hAxes = gca;
      hAxes.Layer = 'top';
    end
    
  end % Condition for loop
  
end % iPlotParticipant
