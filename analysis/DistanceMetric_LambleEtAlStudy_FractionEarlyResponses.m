
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


function distanceMetricValue = ...
  DistanceMetric_LambleEtAlStudy_FractionEarlyResponses(...
  SSimulatedDataSet, SObservations, ~, iCondition, ~, ~, ~, SSettings, ~, varargin)

% we are assuming zero early responses in Lamble et al dataset
nThisConditionEarlyResponses = ...
  SSimulatedDataSet.MnEarlyResponsesPerCondition(iCondition);
nThisConditionNonResponses = ...
  SSimulatedDataSet.MnNonResponsesPerCondition(iCondition);
nThisConditionTrials = ...
  nThisConditionEarlyResponses + nThisConditionNonResponses + ...
  length(find(SSimulatedDataSet.ViCondition == iCondition));
distanceMetricValue = ...
  nThisConditionEarlyResponses / nThisConditionTrials;


% % debug plotting?
% [bPlot, bPlotInNewWindow] = GetDebugPlottingSettings(SSettings, varargin);
% if bPlot
%   
%   if bPlotInNewWindow
%     figure(100 + iCondition)
%     clf
%   end
%   
%   c_VEdges = linspace(0, 1e-2, 20);
%   histogram(VThetaDot_Simulated, ...
%     c_VEdges, 'FaceColor', [1 .5 .5], 'EdgeColor', 'none')
%   hold on
%   plot([1 1] * meanThetaDot_Observed, get(gca, 'YLim'), 'k-')
%   xlabel('d\theta / dt (rad/s)')
%   
%   hPlot = plot([1 1] * meanThetaDot_Simulated, get(gca, 'YLim'), 'r-');
%   text(hPlot.XData(1), 1.5 * mean(hPlot.YData), num2str(distanceMetricValue), 'Color', 'r')
%   
% end


