
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


function GetModelABCSampleDistanceMetricsForLambleEtAlExperiment(...
  c_sModel, c_SSettings)

% set constants

% -- model fitting constants
c_SSettings.modelSimulationTimeStep = 0.02; 
c_SSettings.maxOpticalExpansionRate = 0.03; % rad/s (not really discussed in the Lamble et al paper, so using same threshold as in our experiment)
c_SSettings.bSaveTrialActivation = false;

% -- Lamble et al study
% ---- basics
c_SExperiment.sName = 'LambleEtAlStudy';
c_SExperiment.nConditions = 2;
c_SExperiment.CsDataSets = {'allParticipants'};
c_SExperiment.bERPIncluded = false;
c_SExperiment.nParticipants = 12;
c_SExperiment.nTrialRepetitionsPerParticipant = 4;
c_SExperiment.nRepetitionsPerTrialTypeInDataSet = ...
  c_SExperiment.nParticipants * c_SExperiment.nTrialRepetitionsPerParticipant;
c_SExperiment.maxOpticalExpansionRate = c_SSettings.maxOpticalExpansionRate;
% ---- looming conditions
c_SExperiment.carWidth = 1.65; % m (Lada Samara)
c_SExperiment.VTrialInitialDistances = [20 40]; % m
c_SExperiment.VTrialDecelerations = [0.7 0.7]; % m/s^2
c_SExperiment.VPreLoomingWaitTimes = 2.5;
c_SExperiment.SLoomingTraces = GetLoomingTraces(c_SExperiment, c_SSettings);
% ---- obtained results
c_SObservations = GetLambleEtAlObservations;

% -- distance metrics
c_CsDistanceMetrics = {...
  'NormalisedMeanThetaDotAtResponse'
  'NormalisedThetaDotCI_GroupMean'
  'FractionEarlyResponses'};

% get ABC sample and distance metric values for the specified metrics and 
% settings

GetModelABCSampleDistanceMetricsForExperimentResults(...
  c_sModel, c_SExperiment, c_SObservations, c_CsDistanceMetrics, c_SSettings);



