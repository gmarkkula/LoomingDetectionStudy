
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


function c_SSettings = GetLoomingDetectionStudyModelFittingConstants

SetLoomingDetectionStudyAnalysisConstants

% -- model simulation time step
c_SSettings.modelSimulationTimeStep = 0.02; 
% -- no need to save trial activation in addition to saving the ERP as
% configured below
c_SSettings.bSaveTrialActivation = false;
% -- priors
load([c_sAnalysisResultsPath c_sLambleEtAlDerivedPriorsFileName])
c_SSettings.SUniformModelPriorBounds = SUniformPriorBounds;
% -- ERP
% --- stimulus-locked
c_SSettings.SStimulusERP.VTimeInterval = c_VEpochExtractionInterval;
c_SSettings.SStimulusERP.VBaselineInterval = c_VEpochBaselineInterval;
c_SSettings.SStimulusERP.VTimeStamp = c_VEpochExtractionInterval(1):...
  c_SSettings.modelSimulationTimeStep:c_VEpochExtractionInterval(2);
% --- interval of stimulus-locked ERP to use as baseline
c_SSettings.SStimulusERP.VidxBaselineInterval = find(...
  c_SSettings.SStimulusERP.VTimeStamp > c_VEpochBaselineInterval(1) & ...
  c_SSettings.SStimulusERP.VTimeStamp <= c_VEpochBaselineInterval(2));
% --- response-locked
c_SSettings.SResponseERP.VTimeInterval = [-1 0]; % s
c_SSettings.SResponseERP.VTimeStamp = ...
  c_SSettings.SResponseERP.VTimeInterval(1):...
  c_SSettings.modelSimulationTimeStep:...
  c_SSettings.SResponseERP.VTimeInterval(2);
c_SSettings.SResponseERP.idxResponseSample = ...
  find(c_SSettings.SResponseERP.VTimeStamp >= 0, 1, 'first');
c_SSettings.SResponseERP.VidxSampleDeltaAroundResponse = ...
  (1:length(c_SSettings.SResponseERP.VTimeStamp)) - ...
  c_SSettings.SResponseERP.idxResponseSample;
% --- intervals of response-locked ERP to get for ERPPeakFraction metric
% --- calculation
c_SSettings.SResponseERP.CVMetricIntervals = ...
  {[-0.1 0], [-0.4 -0.1], [-0.7 -0.4]}; % s
for iInterval = 1:length(c_SSettings.SResponseERP.CVMetricIntervals)
  c_SSettings.SResponseERP.CVidxMetricIntervals{iInterval} = find(...
    c_SSettings.SResponseERP.VTimeStamp > ...
    c_SSettings.SResponseERP.CVMetricIntervals{iInterval}(1) & ...
    c_SSettings.SResponseERP.VTimeStamp <= ...
    c_SSettings.SResponseERP.CVMetricIntervals{iInterval}(2));
end
