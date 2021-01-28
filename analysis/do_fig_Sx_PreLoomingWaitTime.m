
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
fprintf('Loading empirical data...\n')
load([c_sAnalysisResultsPath 'AllResponseData_WithExclusions.mat'])
fprintf('Loading model-simulated data...\n')
load([c_sAnalysisResultsPath c_sSimulationsForFigsMATFileName])


%%

% prepare empirical data
VbBasicExclusion = TResponses.iBlock <= 0 | ...
  TResponses.iStimulusID > 10 | ...
  isnan(TResponses.carOpticalExpansionRateAtResponse) | ...
  TResponses.bIncorrectResponse;
VbExcluded = VbBasicExclusion | ...
  TResponses.bTrialExcluded | TResponses.bParticipantExcluded;
TResponses(VbExcluded, :) = [];

%%

% prepare model-simulated data
SAVResponses = SSimResults(c_iMLEFitting).AV.SSimulatedData(c_iOvertResponse);


%% get the data

MAvThetaDotAtResponse = NaN * ones(2, c_nTrialTypes, c_nPreLoomingWaitTimes);
for iDataSource = 1:2
    
  for iPreLoomingWaitTime = 1:c_nPreLoomingWaitTimes
    
    VConditionAvThetaDotAtResponse = NaN * ones(c_nTrialTypes, 1);
    for iCondition = 1:c_nTrialTypes
      switch iDataSource
        case 1
          VbTrials = TResponses.accelerationOnsetTime == ...
            c_VPreLoomingWaitTimes(iPreLoomingWaitTime) & ...
            TResponses.iStimulusID == iCondition;
          MAvThetaDotAtResponse(iDataSource, iCondition, iPreLoomingWaitTime) = ...
            mean(TResponses.carOpticalExpansionRateAtResponse(VbTrials));
        case 2
          VbTrials = SAVResponses.ViPreLoomingWaitTime == iPreLoomingWaitTime & ...
            SAVResponses.ViCondition == iCondition;
          MAvThetaDotAtResponse(iDataSource, iCondition, iPreLoomingWaitTime) = ...
            mean(SAVResponses.VThetaDotAtResponse(VbTrials));
      end
    end % iCondition for loop
  
  end % iPreLoomingWaitTime for loop
  
end % iDataSource for loop


%%

c_sColors = 'kgbmc';
figure(1)
set(gcf, 'Position', [114          45        1091         358])
clf
for iDataSource = 1:2
  
  subplot(1, 2, iDataSource)
  
  CsPreLoomingWaitTimes = {};
  for iPreLoomingWaitTime = 1:c_nPreLoomingWaitTimes
    
    semilogy(1:c_nTrialTypes, MAvThetaDotAtResponse(iDataSource, ...
      c_ViConditionUrgencyOrder, iPreLoomingWaitTime), ...
      'o-', 'Color', c_sColors(iPreLoomingWaitTime))
    hold on
    axis([0 5 8e-4 4e-3])
    
    c_CsPreLoomingWaitTimes{iPreLoomingWaitTime} = ...
      sprintf('pre-looming time = %.1f s', c_VPreLoomingWaitTimes(iPreLoomingWaitTime));
    
  end % iPreLoomingWaitTime for loop
  
  if iDataSource == 2
    legend(c_CsPreLoomingWaitTimes)
  end
  
end % iDataSource for loop


%%

figure(2)
set(gcf, 'Position', [150 100 0.7*c_nFullWidthFigure_px 270])
clf
VAxisLimits = [1 4 -1.5e-4 2e-4];
c_CsDataSource = {'Data', 'Model'};
for iDataSource = 1:2
  
  subplot(1, 2, iDataSource)
  set(gca, 'FontSize', c_stdFontSize, 'FontName', c_sFontName)
  hold on
  
  for iCondition = fliplr(c_ViConditionUrgencyOrder)
    avThetaDotAtResponseInCondition = mean(MAvThetaDotAtResponse(...
      iDataSource, iCondition, :));
    avThetaDotAtResponesDeviationFromConditionAv = ...
      squeeze(MAvThetaDotAtResponse(iDataSource, iCondition, :)) - ...
      avThetaDotAtResponseInCondition;
    plot(c_VPreLoomingWaitTimes, avThetaDotAtResponesDeviationFromConditionAv, ...
      '-', 'Color', c_CMConditionRGB{iCondition}, 'LineWidth', c_stdLineWidth)
    
  end % iCondition for loop
  
  axis(VAxisLimits)
  text(3, 0.3e-4, c_CsDataSource{iDataSource}, ...
    'FontSize', c_annotationFontSize, 'FontName', c_sFontName, ...
    'VerticalAlignment', 'bottom')
  xlabel('Pre-looming wait time (s)')
  if iDataSource == 1
    ylabel(sprintf('Deviation from condition\naverage d\\theta/dt at response (rad/s)\n'))
  end
  
end % iDataSource for loop


AddLoomingConditionLegend
hConditionLegend.Position = [0.7675    0.7519    0.2141    0.2102];
