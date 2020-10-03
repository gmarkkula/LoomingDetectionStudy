
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


function VerticalRainCloudPlot(VData, VDataPlotLimits, VRGB, lineWidth)

c_xDistanceUnit = 0.1;
c_nXDistanceUnitsToPeakOfAssumedGaussianForScaling = 3;
c_fillAlpha = 0.8;
c_stdDevsInPlotLimitsForScaling = 4;
% c_plotRangeExpandFactor = 0.5;
% c_densityPlotPoints = 300;

scatter(-c_xDistanceUnit * ones(size(VData)), VData, 8, 'MarkerFaceColor', VRGB, ...
  'MarkerFaceAlpha', 1, 'MarkerEdgeColor', 'none')
% plot(-c_xDistanceUnit * ones(size(VData)), VData, '.', 'Color', VRGB)
hold on

% dataMin = min(VData);
% dataMax = max(VData);
% dataMid = (dataMin + dataMax) / 2;
% plotRange = c_plotRangeExpandFactor * (dataMax - dataMin);
% plotMin = dataMid - plotRange/2;
% plotMax = dataMid + plotRange/2;
% VPlotPoints = linspace(plotMin, plotMax, c_densityPlotPoints); 
[VDensity, VDensityPoints] = ksdensity(VData, 'support', VDataPlotLimits);

dataRange = VDataPlotLimits(2) - VDataPlotLimits(1);
stdDevOfAssumedNormalForScaling = ...
  dataRange / (2 * c_stdDevsInPlotLimitsForScaling);
peakValueOfAssumedNormalWithoutScaling = ...
  1 / (stdDevOfAssumedNormalForScaling * sqrt(2 * pi));
peakValueOfAssumedNormalWithScaling = c_xDistanceUnit * ...
  c_nXDistanceUnitsToPeakOfAssumedGaussianForScaling;

VScaledDensity = VDensity * peakValueOfAssumedNormalWithScaling ...
  / peakValueOfAssumedNormalWithoutScaling;

VEdgeRGB = 0.75 * VRGB;
fill(c_xDistanceUnit + VScaledDensity, VDensityPoints, VRGB, ...
  'FaceAlpha', c_fillAlpha, 'EdgeColor', VEdgeRGB, 'LineWidth', lineWidth)

plot(c_xDistanceUnit, mean(VData), 'd', 'MarkerEdgeColor', 'none', ...
  'MarkerSize', 6, 'MarkerFaceColor', VEdgeRGB)

set(gca, 'YLim', VDataPlotLimits)
set(gca, 'XLim', [-5 ...
  3 * c_nXDistanceUnitsToPeakOfAssumedGaussianForScaling+1] * c_xDistanceUnit)
