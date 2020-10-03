
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
% - MLE-fit simulation results with model "ERPs"
load([c_sAnalysisResultsPath c_sSimulationsForERPFigsMATFileName])
SModelSimulationsWithERP = SSimResultsWithERP.AV.SSimulatedData;
% - empirical ERP data
[c_SObservations, c_SExperiment.CsDataSets] = ...
  GetLoomingDetectionStudyObservationsAndParticipantIDs;

c_SSettings = GetLoomingDetectionStudyModelFittingConstants;

VERPTimeStamp_ms = c_SSettings.SResponseERP.VTimeStamp * 1000;

%%

fSigmoid = @(x) 1 ./ (1 + exp(-20 * (x - 1)));
figure(100)
VX = linspace(-2, 2, 100);
plot(VX, fSigmoid(VX))
grid on

figure(1)
set(gcf, 'Position', [403   407   c_nFullWidthFigure_px/2   259])

minX = -0.8;

for iSource = 1:2
  
  for iCondition = 1:c_nTrialTypes    
    
    if iSource == 1
      % empirical data
      SData = c_SObservations;
      erpLineWidth = c_stdLineWidth * 1.5;
      erpAlpha = 0.3;
      MERPs = SData.SResponseERP.MERPs;
      delta = 1;
      sText = 'Observed ERP';
    else
      % model fit
      SData = SModelSimulationsWithERP;
      erpLineWidth = c_stdLineWidth;
      erpAlpha = 1;
      MStage1Evidence = SData.SResponseERP.MERPs;
      MStage2Input = fSigmoid(MStage1Evidence);
      MERPs = cumsum(MStage2Input, 2);
      delta = 0;
      sText = ['Model AV E' char(39) '(t)'];
    end
    
    VbRowsAllConditions = ismember(SData.ViDataSet, 1:22);
    VbRowsThisCondition = VbRowsAllConditions & ...
      SData.ViCondition == iCondition;
    meanERPAtResponseAllConditions = mean(MERPs(...
      VbRowsAllConditions, c_SSettings.SResponseERP.idxResponseSample));
    VMeanConditionERP = ...
      mean(MERPs(VbRowsThisCondition, :), 1);
    VNormalisedMeanConditionERP = ...
      VMeanConditionERP / meanERPAtResponseAllConditions;
    hPlot = plot(c_SSettings.SResponseERP.VTimeStamp * 1000, ...
      VNormalisedMeanConditionERP + delta, ...
      '-', 'Color', c_CMConditionRGB{iCondition}, ...
      'LineWidth', erpLineWidth);
    hPlot.Color(4) = erpAlpha;
 
    hold on
    
  end % Condition for loop
  
  text(minX*1000, delta, sprintf('    %s\n\n', sText), 'FontName', c_sFontName, ...
    'FontSize', c_annotationFontSize, 'VerticalAlignment', 'middle')
  
end % iSource for loop

set(gca, 'XLim', [minX*1000 0])
set(gca, 'Box', 'off')
set(gca, 'YLim', [-.5 2.5])
set(gca, 'YColor', 'none')

xlabel('Time relative response (ms)')

