
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


function VbABCSampleRetained = FindSubThresholdABCSamples(SABCSamples, ...
  c_iDataSet, c_CsDistanceMetricsInFit, c_VMaxAbsDistances, c_ViConditionsInFit)

% find indices of distance metrics to include
c_nDistanceMetricsInFit = length(c_CsDistanceMetricsInFit);
ViDistanceMetricsInFit = NaN * ones(1, c_nDistanceMetricsInFit);
for iDistanceMetricInFit = 1:c_nDistanceMetricsInFit
  iDistanceMetric = ...
    find(strcmp(c_CsDistanceMetricsInFit{iDistanceMetricInFit}, ...
    SABCSamples.CsDistanceMetrics));
  assert(length(iDistanceMetric) == 1)
  ViDistanceMetricsInFit(iDistanceMetricInFit) = iDistanceMetric;
end

% find ABC samples below threshold for all included metrics
VbABCSampleRetained = true * ones(SABCSamples.SSettings.nABCSamples, 1);
for iDistanceMetricInFit = 1:c_nDistanceMetricsInFit 
  iDistanceMetric = ViDistanceMetricsInFit(iDistanceMetricInFit);
  if length(c_VMaxAbsDistances) == 1
    thisMetricMaxAbsDistance = c_VMaxAbsDistances(1);
  else
    thisMetricMaxAbsDistance = c_VMaxAbsDistances(iDistanceMetricInFit);
  end
  for iCondition = c_ViConditionsInFit
    VbABCSampleRetained = ...
      VbABCSampleRetained & ...
      abs(SABCSamples.MDistanceMetricValues(...
      :, iDistanceMetric, c_iDataSet, iCondition)) < ...
      thisMetricMaxAbsDistance;
  end % iCondition for loop
end % iDistanceMetric for loop