
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


% Generates ABC samples for each tested model, calculating summary
% statistic distance metrics to the looming detection results reported by
% Lamble et al (1999) from their test track study. The running time for ...
% each model is on the order of magnitude of one hour.
%
% For each model, an output file ABCSamples_LambleEtAlStudy_Model*.mat is 
% generated (if this file is above a size threshold, the bulk of the data 
% is serialised and saved into separate .dat files instead by the 
% SaveABCSamples function). 

%% init
clearvars
close all force

c_CsModels = {'T' 'A' 'AG' 'AL' 'AV' 'AGL' 'AVG' 'AVL' 'AVGL'};
% also possible to run for one model at a time, as follows:
% c_CsModels = {'T'}

c_nModels = length(c_CsModels);

c_SSettings.nABCSamples = 300000;
c_SSettings.CsModelsToOverWrite = {''};
c_SSettings.CsDistanceMetricsToOverWrite = {};
c_SSettings.CsDataSetsToOverWrite = {};
c_SSettings.bPerABCSampleDebug = false;
c_SSettings.bOptimiseForSpeed = true;


bOverwriteAllExistingModelABCSamples = ...
  ~isempty(c_SSettings.CsModelsToOverWrite) && ...
  strcmp(c_SSettings.CsModelsToOverWrite{1}, '*');
if bOverwriteAllExistingModelABCSamples
  disp('Overwriting existing model ABC samples for all models. Sure? Press any key to continue...')
  pause
end

%% get ABC samples
for iModel = 1:c_nModels
  sModel = c_CsModels{iModel};
  GetModelABCSampleDistanceMetricsForLambleEtAlExperiment(...
    sModel, c_SSettings);
end


%% do simple visualisation of fits
c_maxAbsDistance = 0.2;
c_iLambleEtAlDataSet = 1;
c_ViLambleEtAlConditionsInFit = [1 2];
c_CsDistanceMetricsInFit = {...
  'NormalisedMeanThetaDotAtResponse'
  'NormalisedThetaDotCI_GroupMean'};
c_SPlotOptions.bMakeScatterPlots = true;
for iModel = 1:c_nModels
  
  % load ABC sample results
  sModel = c_CsModels{iModel};
  fprintf('Loading ABC samples for model %s and making scatter plot of posterior...\n', sModel)
  SFileConstants = GetFileConstants('LambleEtAlStudy', sModel);
  SABCSamples = LoadABCSamples(SFileConstants.sResultsMATFile);
  
  % get model fit 
  c_SPlotOptions.iBaseFigureNumber = iModel * 100;
  GetModelFitFromABCSamples(SABCSamples, [], ...
    c_iLambleEtAlDataSet, ...
    c_CsDistanceMetricsInFit, c_maxAbsDistance, ...
    c_ViLambleEtAlConditionsInFit, ...
    [], c_SPlotOptions);
  drawnow
  
end


