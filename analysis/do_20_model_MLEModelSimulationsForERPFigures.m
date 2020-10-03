
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


% like do_19..., but for smaller simulation sizes, and storing also model
% evidence traces, saving the results in MLESimulationsForERPFigures.mat

clearvars
close all force

% general constants
SetLoomingDetectionStudyAnalysisConstants
SetPlottingConstants


% model fitting constants
c_SSettings = GetLoomingDetectionStudyModelFittingConstants;
c_SExperiment = GetLoomingDetectionStudyExperimentConstants(c_SSettings);

% constants defining the simulations here
SSimulatedExperiment = c_SExperiment; % will be further adjusted for different purposes below
SSimulatedExperiment.bERPIncluded = true;
c_nExperimentUpscaling = 1; % how many times bigger the simulated experiment should be than the real experiment


% load model fitting results
fprintf('Loading MLE fitting results for all models...\n')
load([c_sAnalysisResultsPath c_sMLFittingMATFileName], 'SResults', ...
  'c_CsModels', 'c_VContaminantFractions')
iContaminantFractionToPlot = ...
  find(c_VContaminantFractions == c_mleContaminantFractionToPlot);
assert(length(iContaminantFractionToPlot) == 1)
c_CsModelsInMLEStruct = c_CsModels;
clear c_CsModels
ViResponseTypes = [c_iOvertResponse c_iCPPOnset];


%%

% loop through models
c_CsFittedModels = c_CCsModelsFitted{c_iMLEFitting};
for iModel = 1:length(c_CsFittedModels)
  
  sModel = c_CsFittedModels{iModel};
  fprintf('Simulating model %s...\n', sModel)
  
  % participant-independent prep per fitting method
  iModelInMLEStruct = find(strcmp(sModel, c_CsModelsInMLEStruct));
  assert(length(iModelInMLEStruct) == 1)
  SBaseParameterSet = ...
    DrawModelParameterSetFromPrior_LoomingDetectionStudy(sModel, c_SSettings);
  SBaseParameterSet.alpha_ND = 0.3;
  
  % start from an empty dataset
  bHasData = false;
  
  % loop through participants
  for iParticipant = 1:c_nFinalIncludedParticipants
    fprintf('\tParticipant %d...\n', iParticipant)
    
    % get the max likelihood parameterisation identified for this
    % participant and response type
    SModelParameters = SResults.(sModel).SModelParameterisations(...
      SResults.MiBestParameterisation(iParticipant, iModelInMLEStruct, ...
      iContaminantFractionToPlot, c_iOvertResponse));
    SModelParameters = SetStructFieldsFromOtherStruct(...
      SBaseParameterSet, SModelParameters);
    
    % define the simulated experiment to run with MLE fit (an
    % upscaled version of the experiment run for one human
    % participant, using the single best MLE parameterisation
    % identified for the participant)
    SSimulatedExperiment.nRepetitionsPerTrialTypeInDataSet = ...
      c_SExperiment.nRepetitionsPerTrialTypeInDataSet * ...
      c_nExperimentUpscaling;
 
    % get simulated data
    % generate simulated data for this parameterisation
    SThisSimulatedDataSet = SimulateDataSetFromModel(...
      SSimulatedExperiment, sModel, SModelParameters, c_SSettings);
    SThisSimulatedDataSet.ViDataSet = ...
      iParticipant * ones(size(SThisSimulatedDataSet.VResponseTime));
    % append to the bigger dataset
    if bHasData
      DataSetToAppendTo = SSimulatedDataSet;
    else
      DataSetToAppendTo = [];
    end
    SSimulatedDataSet = AppendTrials(...
      DataSetToAppendTo, SThisSimulatedDataSet, ...
      c_SSettings, SSimulatedExperiment);
    bHasData = true;
    
    SSimResultsWithERP.(sModel).SSimulatedData = ...
      SSimulatedDataSet;
    
    
  end % iParticipant for loop
  
end % iModel for loop



%% save results

fprintf('Saving results...\n')
save([c_sAnalysisResultsPath c_sSimulationsForERPFigsMATFileName], 'SSimResultsWithERP')
