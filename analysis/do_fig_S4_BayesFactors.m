
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
load([c_sAnalysisResultsPath c_sBayesFactorsMATFileName])

%%

c_minParticipantsInComparison = 15;

MGeomMeanGroupBayesFactorsWithNRequirement = MGeomMeanGroupBayesFactors;
MGeomMeanGroupBayesFactorsWithNRequirement(...
  MnParticipantsWithDataInComparisons < c_minParticipantsInComparison) = NaN;

c_iInfThreshold = find(c_VThresholds == Inf, 1, 'first');
assert(length(c_iInfThreshold) == 1)

c_CsModelLineSpecs = {':', '--', '--o', '--', '-', '--o', '-o', '-', '-o'};
c_ViModelColors = [1 1 1 2 1 2 1 2 2];
c_CvModelColors = {'k' c_VExtraColor1RGB};
c_ViModelLineWidths = [1 1 2 2 2 3 3 3 4] * c_stdLineWidth/2;

figure(1)
clf
set(gcf, 'Position', [403   274   662   392])
for iModel = 1:length(c_CsModels)
  vColor = c_CvModelColors{c_ViModelColors(iModel)};
  VGeomMeanBayesFactors = ...
    1./MGeomMeanGroupBayesFactorsWithNRequirement(iModel, 1:end-1, c_iInfThreshold);
  VhLine(iModel) = semilogy(c_VThresholds(1:end-1), VGeomMeanBayesFactors, ...
    c_CsModelLineSpecs{iModel}, 'LineWidth', c_ViModelLineWidths(iModel), ...
    'MarkerSize', 6, 'Color', vColor, 'MarkerFaceColor', vColor);
  uistack(VhLine(iModel), 'bottom')
  hold on
  set(gca, 'FontSize', c_stdFontSize, 'FontName', c_sFontName)
  
end % iModel for loop

set(gca, 'XLim', [0.22 0.88])
set(gca, 'YLim', [0.5 600])
hLegend = legend(VhLine, c_CsModels, 'FontSize', c_stdFontSize);
hLegend.Position = [0.8381 0.4613 0.1269 0.4337];
xlabel('\epsilon_{RT} (s)', 'FontSize', c_annotationFontSize)
ylabel('gBF_{A,m} (-)', 'FontSize', c_annotationFontSize)