
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
  DistanceMetric_LambleEtAlStudy_NormalisedThetaDotCI_GroupMean(...
  SSimulatedDataSet, SObservations, ~, iCondition, ~ , ~, ~, SSettings, ~, varargin)

VThetaDot_Simulated = GetThetaDotAtResponseForConditionInclErrors(...
  SSimulatedDataSet, iCondition, SSettings);
thetaDotCI_Simulated = GetHalf95CIOfMean(VThetaDot_Simulated);

% adjust for sample size different than actual experiment (should only be
% for visualisation purposes)
nDataPoints = length(VThetaDot_Simulated);
c_nDataPointsInExperiment = 48;
thetaDotCI_Simulated = thetaDotCI_Simulated * sqrt(nDataPoints) / ...
  sqrt(c_nDataPointsInExperiment);

thetaDotCI_Observed = ...
  SObservations.VErrorBarsForThetaDotAtResponse(iCondition);

distanceMetricValue = (thetaDotCI_Simulated - thetaDotCI_Observed) / ...
  thetaDotCI_Observed;


% debug plotting?
[bPlot, bPlotInNewWindow] = GetDebugPlottingSettings(SSettings, varargin);
if bPlot
  
  meanThetaDot_Simulated = mean(VThetaDot_Simulated);
  %   meanThetaDot_Observed = SObservations.VMeanThetaDotAtResponse(iCondition);
  
  if bPlotInNewWindow
    figure(100 + iCondition)
  end
  
  hold on
  midYPoint = mean(get(gca, 'YLim'));
  hPlot = plot([-1 1] * thetaDotCI_Simulated + meanThetaDot_Simulated, 0.3 * midYPoint * [1 1], 'r-');
  text(hPlot.XData(2), hPlot.YData(2), num2str(distanceMetricValue), 'Color', 'r')
  
end


