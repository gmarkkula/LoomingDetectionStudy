
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
  DistanceMetric_LambleEtAlStudy_NormalisedThetaDotCI_MeanOfMeans(...
  SSimulatedDataSet, SObservations, ~, iCondition, ~ , ~, ~, SSettings, ~, varargin)

ViConditionRows = find(SSimulatedDataSet.ViCondition == iCondition);
nConditionSamples = length(ViConditionRows);
c_nSamplesPerParticipant = 4;
nParticipants = nConditionSamples / c_nSamplesPerParticipant;
% assert(nParticipants == 12);
 fVParticipantMeanThetaDot = zeros(nParticipants, 1);
for iParticipant = 1:nParticipants
  VidxParticipantRows = ViConditionRows(...
    ((iParticipant-1) * c_nSamplesPerParticipant) + (1:c_nSamplesPerParticipant));
  VParticipantThetaDots = ...
    SSimulatedDataSet.VThetaDotAtResponse(VidxParticipantRows);
  VParticipantMeanThetaDot(iParticipant) = ...
    mean(VParticipantThetaDots(~isinf(VParticipantThetaDots)));
end
thetaDotCI_Simulated = GetHalf95CIOfMean(VParticipantMeanThetaDot);

thetaDotCI_Observed = ...
  SObservations.VErrorBarsForThetaDotAtResponse(iCondition);

distanceMetricValue = (thetaDotCI_Simulated - thetaDotCI_Observed) / ...
  thetaDotCI_Observed;


% debug plotting?
[bPlot, bPlotInNewWindow] = GetDebugPlottingSettings(SSettings, varargin);
if bPlot
  
  meanThetaDot_Simulated = mean(SSimulatedDataSet.VThetaDotAtResponse(ViConditionRows));
  meanThetaDot_Observed = SObservations.VMeanThetaDotAtResponse(iCondition);
  
  if bPlotInNewWindow
    figure(100 + iCondition)
  end
  
  hold on
  midYPoint = mean(get(gca, 'YLim'));
  plot([-1 1] * thetaDotCI_Observed + meanThetaDot_Observed, 0.2 * midYPoint * [1 1], 'k-')
  
  hPlot = plot([-1 1] * thetaDotCI_Simulated + meanThetaDot_Simulated, 0.1 * midYPoint * [1 1], 'r-');
  text(hPlot.XData(2), hPlot.YData(2), num2str(distanceMetricValue), 'Color', 'r')
  
end


