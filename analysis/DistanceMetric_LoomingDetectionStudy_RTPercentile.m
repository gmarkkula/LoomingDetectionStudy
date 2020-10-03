
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
  DistanceMetric_LoomingDetectionStudy_RTPercentile(...
  SSimulatedDataSet, SObservations, iDataSet, iCondition, iDistanceMetric, ...
  SPreCalcResults_Observed, SPreCalcResults_Simulated, ...
  SSettings, rtPercentile, varargin)

distanceMetricValue = ...
  SPreCalcResults_Simulated.rtPercentileValue - ...
  SPreCalcResults_Observed.rtPercentileValue;


% do any debug plotting
if ~SSettings.bOptimiseForSpeed
  bPlot = DoDistanceMetricDebugPlottingBasics('responseTime', 'histogram', ...
    SSimulatedDataSet, SObservations, iDataSet, iCondition, iDistanceMetric, ...
    SSettings, varargin);
  if bPlot
    VPlotRGB = SSettings.CVConditionPlotRGBs{iCondition};
    plotY = GetPlotYValuesForSharedConditionPlot(0, 1, iCondition);
    plot(SPreCalcResults_Observed.rtPercentileValue, plotY, 's', ...
      'Color', VPlotRGB, 'MarkerSize', 10, 'LineWidth', 2)
    plot(SPreCalcResults_Simulated.rtPercentileValue, plotY, 'x', ...
      'Color', VPlotRGB, 'MarkerSize', 10, 'LineWidth', 2)
    OAxes = gca;
    textX = OAxes.XLim(2);
    text(textX, plotY, sprintf('%.3f', distanceMetricValue), ...
      'FontSize', 9, 'VerticalAlignment', 'bottom', 'Color', VPlotRGB)
  end
end


