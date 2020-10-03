
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


function bPlot = DoDistanceMetricDebugPlottingBasics(...
  sPlotQuantity, sPlotType, ...
  SSimulatedDataSet, SObservations, iDataSet, iCondition, iDistanceMetric, ...
  SSettings, CvExtraInputs)

[bPlot, bPlotInNewWindow] = ...
  GetDebugPlottingSettings(SSettings, CvExtraInputs);
if bPlot
  
  % get data rows
  VbRows_Observed = SObservations.ViCondition == iCondition & ...
    SObservations.ViDataSet == iDataSet;
  VbRows_Simulated = SSimulatedDataSet.ViCondition == iCondition;
  
  % get data
  switch sPlotQuantity
    case 'thetaDot'
      VData_Observed = SObservations.VThetaDotAtResponse(VbRows_Observed);
      VData_Simulated = SSimulatedDataSet.VThetaDotAtResponse(VbRows_Simulated);
      VBinEdges = linspace(0, 1e-2, 20);
      yScaling = 1/25;
    case 'responseTime'
      VData_Observed = SObservations.VResponseTime(VbRows_Observed);
      VData_Simulated = SSimulatedDataSet.VResponseTime(VbRows_Simulated);
      VBinEdges = linspace(0, 7, 20);
      yScaling = 1/25;
    case 'scaledResponseERP'
      VPlotX = SSettings.SResponseERP.VTimeInterval(1):0.1:...
        SSettings.SResponseERP.VTimeInterval(2);
      VYValues_Observed = GetScaledResponseERPForPlot(SObservations, ...
        VbRows_Observed, SSettings, VPlotX);
      VYValues_Simulated = GetScaledResponseERPForPlot(SSimulatedDataSet, ...
        VbRows_Simulated, SSettings, VPlotX);
      yScaling = 1;
    otherwise
      error('Unexpected plot quantity identifier: %s', sPlotQuantity)
  end
  
  % get plot colour to use
  VPlotRGB = SSettings.CVConditionPlotRGBs{iCondition};
  
  % set where to plot (if needed)
  if bPlotInNewWindow
    iFigureWindow = ...
      SSettings.iPerABCSampleDebugPlotBaseFigure + iDistanceMetric;
    figure(iFigureWindow)
    subplot(5, 5, iDataSet)
  end
  
  % plot
  hold on
%   c_alpha = 0.5;
  switch sPlotType
    case 'histogram'
      VPlotX = mean([VBinEdges(1:end-1); VBinEdges(2:end)], 1);
      VYValues_Observed = histcounts(VData_Observed, VBinEdges);
      VYValues_Simulated = histcounts(VData_Simulated, VBinEdges);
    case 'timeSeries'
      % all done
    otherwise
      error('Unexpected plot type identifier: %s', sPlotType)
  end
  VPlotYValues_Observed = GetPlotYValuesForSharedConditionPlot(...
    VYValues_Observed, yScaling, iCondition);
  VPlotYValues_Simulated = GetPlotYValuesForSharedConditionPlot(...
    VYValues_Simulated, yScaling, iCondition);
  plot(VPlotX, VPlotYValues_Observed, 'o', ...
    'Color', VPlotRGB, 'MarkerSize', 5)
  plot(VPlotX, VPlotYValues_Simulated, '-', 'Color', VPlotRGB)
  set(gca, 'YTick', [])
  set(gca, 'YLim', [-.2 4.2])
  
end % if bPlot



function VScaledResponseERPForPlot = ...
  GetScaledResponseERPForPlot(SDataSet, VbRows, SSettings, VPlotTimeStamp)

% get average of average response-locked ERP in peak interval (just before
% response)
[peakIntervalMeanERP, VMeanResponseERP] = ...
  GetAveragePeakResponseERPForDataSubset(SDataSet, VbRows, SSettings);
% scale the ERP to have average 1 in peak interval
VScaledResponseERP = VMeanResponseERP / peakIntervalMeanERP;
% resample to the specified plot time stamps
VScaledResponseERPForPlot = interp1(SSettings.SResponseERP.VTimeStamp, ...
  VScaledResponseERP, VPlotTimeStamp);







