
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


function SPreCalcResults = ...
  DistanceMetricPre_LoomingDetectionStudy_ERPPeakFraction(...
  SSimulatedOrObservedData, iDataSet, iCondition, ...
  SSettings, iERPInterval, varargin)

if ~isempty(iDataSet)
  VbRowsAllConditions = SSimulatedOrObservedData.ViDataSet == iDataSet;
else
  VbRowsAllConditions = true * ones(size(SSimulatedOrObservedData.ViCondition));
end
VbRowsThisCondition = VbRowsAllConditions & ...
  SSimulatedOrObservedData.ViCondition == iCondition;

VMeanResponseERPAllConditions = ...
  mean(SSimulatedOrObservedData.SResponseERP.MERPs(VbRowsAllConditions, :), 1);
VMeanResponseERPThisCondition = ...
  mean(SSimulatedOrObservedData.SResponseERP.MERPs(VbRowsThisCondition, :), 1);
peakIntervalMeanERP = ...
  mean(VMeanResponseERPAllConditions(SSettings.SResponseERP.CVidxMetricIntervals{1}));
testIntervalMeanERP = ...
  mean(VMeanResponseERPThisCondition(SSettings.SResponseERP.CVidxMetricIntervals{iERPInterval+1}));
SPreCalcResults.erpPeakFractionValue = ...
  testIntervalMeanERP / peakIntervalMeanERP;

% if true
%   iDataSet
%   iCondition
%   iERPInterval
%   figure(999)
%   clf
%   plot(SSettings.SResponseERP.VTimeStamp, VMeanResponseERPAllConditions, 'b-', ...
%     'LineWidth', 2)
%   hold on
%   plot(SSettings.SResponseERP.VTimeStamp, VMeanResponseERPThisCondition, 'k-')
%   VidxPeakInterval = SSettings.SResponseERP.CVidxMetricIntervals{1};
%   plot(SSettings.SResponseERP.VTimeStamp(VidxPeakInterval), ...
%     peakIntervalMeanERP * ones(size(VidxPeakInterval)), 'b--')
%   VidxTestInterval = ...
%     SSettings.SResponseERP.CVidxMetricIntervals{iERPInterval+1};
%   plot(SSettings.SResponseERP.VTimeStamp(VidxTestInterval), ...
%     testIntervalMeanERP * ones(size(VidxTestInterval)), 'k--')
%   title(sprintf('ERP peak fraction: %.2f', ...
%     SPreCalcResults.erpPeakFractionValue))
%   pause
% end




