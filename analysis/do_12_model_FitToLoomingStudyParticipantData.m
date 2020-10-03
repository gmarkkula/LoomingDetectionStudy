
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


% Generates ABC samples for the model specified with a string input 
% argument (e.g., do_12_model_FitToLoomingStudyParticipantData('AV')), 
% calculating summary statistic distance metrics, to our behavioural and 
% neural data.
%
% The running time to generate 500,000 ABC samples for one model is on the 
% order of magnitude of one day.
%
% For each model, an output file ABCSamples_LoomingDetectionStudy_Model*.mat 
% is generated (if this file is above a size threshold, the bulk of the data 
% is serialised and saved into separate .dat files instead by the 
% SaveABCSamples function).

function do_12_model_FitToLoomingStudyParticipantData(c_sModel)

close all force

% constants

% - general analysis constants
SetLoomingDetectionStudyAnalysisConstants

% - model fitting constants
c_SSettings = GetLoomingDetectionStudyModelFittingConstants;
c_SSettings.nABCSamples = 500000;
c_SSettings.CsModelsToOverWrite = {'*'};
c_SSettings.CsDistanceMetricsToOverWrite = {};
c_SSettings.CsDataSetsToOverWrite = {};
c_SSettings.bPerABCSampleDebug = false;
c_SSettings.bOptimiseForSpeed = true;

% - experiment constants
c_SExperiment = GetLoomingDetectionStudyExperimentConstants(c_SSettings);

% - obtained results
[c_SObservations, c_SExperiment.CsDataSets] = ...
  GetLoomingDetectionStudyObservationsAndParticipantIDs; 

% - distance metrics
c_CsDistanceMetrics = {...
  'RTPercentile__10', ...
  'RTPercentile__30', ...
  'RTPercentile__50', ...
  'RTPercentile__70', ...
  'RTPercentile__90', ...
  'ERPPeakFraction__1', ...
  'ERPPeakFraction__2'
  };


% get ABC sample and distance metric values for the specified metrics and
% settings
SOut = GetModelABCSampleDistanceMetricsForExperimentResults(...
  c_sModel, c_SExperiment, c_SObservations, c_CsDistanceMetrics, c_SSettings);


% do a quick visualisation
c_SPlotOptions.bMakeScatterPlots = true;
c_SPlotOptions.bMakeHeatMaps = false;
c_SPlotOptions.bMakePosteriorPredictiveCheckFromModeOfPosterior = false;
c_SPlotOptions.bMakePosteriorPredictiveCheckFromMixOfPosteriorSamples = true;
c_SPlotOptions.fVisualisePosteriorPredictiveCheck = ...
  @VisualisePosteriorPredictiveCheckForLoomingDetectionStudy;
c_CsDistanceMetricsInFit = c_CsDistanceMetrics;
maxAbsDistance = 0.5;
c_nMeshPointsPerDimensionForKernelSmoothing = 10; % high values here lead to long computations for models with many parameters
c_ViConditionsInFit = [1 2 3 4];
for iParticipant = 1:10
    c_SPlotOptions.iBaseFigureNumber = iParticipant * 100;
    GetModelFitFromABCSamples(SOut, c_SObservations, ...
      iParticipant, ...
      c_CsDistanceMetricsInFit, maxAbsDistance, ...
      c_ViConditionsInFit, ...
      c_nMeshPointsPerDimensionForKernelSmoothing, c_SPlotOptions); 
end

