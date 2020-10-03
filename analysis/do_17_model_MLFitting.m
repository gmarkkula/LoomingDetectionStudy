
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


% Performs maximum likelihood estimation fitting of selected models to our
% behavioural response times, as well as to the CPP onset times estimatedby
% the do_16... script. The running time for the three-parameter models (T
% and A) are on the order of magnitude of hours, for the four-parameter
% models (AV, AG, AL) the running time is on the order of one or two days.
% The results are saved in MLFittingResults. To avoid running all models in
% one single go, see the notes about incremental running below. The script
% does the MLE fitting for a few different assumed frequencies of
% "contaminant responses".

clearvars
close all force
% constants
SetLoomingDetectionStudyAnalysisConstants
c_CsModels = {'T', 'A', 'AV', 'AG', 'AL'}; 
% The script is set up to support incremental running - to avoid the risk
% of losing all progress in case of a computer crash or similar. To use
% this feature, replace the line above with just
% c_CsModels = {'T'};
% then when that run is done, rerun the script with
% c_CsModels = {'T', 'A'};
% and so on... This will save results after each model fit, and reload the
% existing results before continuing with the next model.

% load any existing results?
c_bBuildOnPreviousRun = true;
if c_bBuildOnPreviousRun && ...
    exist([c_sAnalysisResultsPath c_sMLFittingMATFileName], 'file')
  
  % load existing results and settings (except list of models)
  CsModelsThisRun = c_CsModels;
  fprintf('Loading results from previous run...\n')
  load([c_sAnalysisResultsPath c_sMLFittingMATFileName])
  c_CsModels = CsModelsThisRun;
  c_bBuildOnPreviousRun = true;
  
else
  
  c_bBuildOnPreviousRun = false;
  
  % settings
  c_nGridValuesPerParameter = 20;
  c_nSimulatedTrialsPerCondition = 1000; % 50 in real experiment
  c_rtBinSize = 0.25;
  c_VContaminantFractions = [0.01 0.05 0.1];
  c_nContaminantFractions = length(c_VContaminantFractions);
  
  % model fitting constants (from ABC fitting)
  c_SSettings = GetLoomingDetectionStudyModelFittingConstants;
  
  % experiment constants
  c_SExperiment = GetLoomingDetectionStudyExperimentConstants(c_SSettings);
  
  % extras for the maximum likelihood fitting
  c_SSimulatedExperiment = c_SExperiment;
  c_SSimulatedExperiment.bERPIncluded = false;
  c_SSimulatedExperiment.nRepetitionsPerTrialTypeInDataSet = ...
    c_nSimulatedTrialsPerCondition / length(c_SExperiment.VPreLoomingWaitTimes);
  
  % get empirical results
  [c_SObservations, c_SExperiment.CsDataSets] = ...
    GetLoomingDetectionStudyObservationsAndParticipantIDs;
  c_nParticipantsToAnalyse = length(c_SExperiment.CsDataSets);
  load([c_sAnalysisResultsPath c_sCPPOnsetMATFileName], 'SCPPOnsetResults')
  
  % use same non-response and early response info as for overt responses,
  % scaled by the averaging used to estimate the CPP onsets
  SCPPOnsetResults.MnEarlyResponsesPerCondition = ...
    c_SObservations.MnEarlyResponsesPerCondition / c_nTrialsPerAverageForCPPOnset;
  SCPPOnsetResults.MnNonResponsesPerCondition = ...
    c_SObservations.MnNonResponsesPerCondition / c_nTrialsPerAverageForCPPOnset;
  
  % get RT bins to use for the respective looming conditions, and
  % pre-count observations for each participant in each bin
  for iCondition = 1:c_SExperiment.nConditions
    maxTimeStamp = c_SExperiment.SLoomingTraces(...
      iCondition).SPreLoomingWaitTime(1).VTimeStamp(end);
    c_SConditionRTBins(iCondition).VRTBins = ...
      [-Inf 0:c_rtBinSize:maxTimeStamp Inf];
    c_SConditionRTBins(iCondition).VRTBinCentres = ...
      -c_rtBinSize/2:c_rtBinSize:maxTimeStamp+c_rtBinSize/2;
    for iParticipant = 1:c_nParticipantsToAnalyse
      for iResponseType = 1:c_nResponseTypes
        switch iResponseType
          case c_iOvertResponse
            SData = c_SObservations;
          case c_iCPPOnset
            SData = SCPPOnsetResults;
          otherwise
            error('Unexpected response type ID.')
        end
        c_SParticipantResponsesPerConditionRTBin(...
          iParticipant, iCondition, iResponseType).VnResponses = ...
          GetRTBinCountsForDataSetAndCondition(...
          SData, c_SConditionRTBins, iParticipant, iCondition, ...
          c_CsResponseTypeFieldNames{iResponseType});
      end % iResponseType for loop
    end % iParticipant for loop
  end % iCondition for loop
  
end % if c_bBuildOnPreviousRun

% load uniform priors derived from Lamble et al study - used as regular
% grid bounds here
load([c_sAnalysisResultsPath c_sLambleEtAlDerivedPriorsFileName])

% loop through models and to ML fitting
c_nModels = length(c_CsModels);
for iModel = 1:c_nModels
  sModel = c_CsModels{iModel};
  
  % model already fitted in previous run?
  if c_bBuildOnPreviousRun && isfield(SResults, sModel)
    fprintf('Model %s already fitted.\n', sModel)
    continue
  end
  
  % get model parameterisation with all the basics for this model
  SBaseParameterSet = ...
    DrawModelParameterSetFromPrior_LoomingDetectionStudy(sModel, c_SSettings);
  SBaseParameterSet.alpha_ND = 1;
  
  % get model parameterisation grid to search for the free parameters
  % -- set struct with parameter definitions
  CsParameterNames = fieldnames(SUniformPriorBounds.(sModel));
  nParameters = length(CsParameterNames);
  for iParameter = 1:nParameters
    sParameter = CsParameterNames{iParameter};
    SModelParameterDefinitions(iParameter).sParameterName = sParameter;
    VParameterBounds = SUniformPriorBounds.(sModel).(sParameter).VBounds;
    SModelParameterDefinitions(iParameter).VParameterValues = ...
      linspace(VParameterBounds(1), VParameterBounds(2), ...
      c_nGridValuesPerParameter);
  end % iParameter for loop
  % -- get full grid
  [SResults.(sModel).SModelParameterisations, ...
    SResults.(sModel).MParameterValues] = ...
    GetGridForModelParameterGridSearch(SModelParameterDefinitions);
  SResults.(sModel).SParameterDefinitions = SModelParameterDefinitions;
  nParameterisations = length(SResults.(sModel).SModelParameterisations);
  
  % time info
  fprintf('*** Model %s - starting %s ***', sModel, string(datetime))
  
  % prep for waitbar
  hWaitBar = [];
  nParameterisationsBetweenWaitBarUpdate = 100;
  
  % traverse entire grid and get log likelihoods
  SResults.(sModel).MLogLikelihoods = NaN * ones(c_nParticipantsToAnalyse, ...
    nParameterisations, c_nContaminantFractions, c_nResponseTypes);
  for iParameterisation = 1:nParameterisations
    
    % display/update waitbar
    if mod(iParameterisation-1, nParameterisationsBetweenWaitBarUpdate) == 0
      if mod(iParameterisation-1, nParameterisationsBetweenWaitBarUpdate * 100) == 0
        fprintf('\n')
      end
      fprintf('.')
      if isempty(hWaitBar) || ~isvalid(hWaitBar)
        hWaitBar = waitbar(iParameterisation / nParameterisations, ...
          sprintf('Getting likelihoods for %d parameterisations...', ...
          nParameterisations), 'Name', sprintf('Model %s', sModel));
        drawnow
      else
        waitbar(iParameterisation / nParameterisations, hWaitBar);
      end
    end
    
    % simulate model with this parameterisation
    SParameterSet = SetStructFieldsFromOtherStruct(...
      SBaseParameterSet, SResults.(sModel).SModelParameterisations(...
      iParameterisation));
    SSimulatedDataSet = ...
      SimulateDataSetFromModel(c_SSimulatedExperiment, sModel, ...
      SParameterSet, c_SSettings);
    
    % loop through participants and get log likelihoods for parameterisation
    for iParticipant = 1:c_nParticipantsToAnalyse
      SResults.(sModel).MLogLikelihoods(iParticipant, iParameterisation, :, :) = ...
        GetParticipantLogLikelihoods(c_nSimulatedTrialsPerCondition, ...
        c_VContaminantFractions, c_nResponseTypes, c_SExperiment, ...
        c_SConditionRTBins, c_SParticipantResponsesPerConditionRTBin, ...
        SSimulatedDataSet, iParticipant);
    end % iParticipant for loop
    
  end % iParameterisation for loop
  
  % close waitbar
  close(hWaitBar)
  
  % time info
  fprintf('\n*** Model %s - finished %s ***\n', sModel, string(datetime))
  
end % iModel for loop

% get best fits
for iModel = 1:c_nModels
  sModel = c_CsModels{iModel};
  for iParticipant = 1:c_nParticipantsToAnalyse
    for iContaminantFraction = 1:c_nContaminantFractions
      for iResponseType = 1:c_nResponseTypes
        [SResults.MMaxLogLikelihood(iParticipant, iModel, iContaminantFraction, iResponseType), ...
          SResults.MiBestParameterisation(iParticipant, iModel, iContaminantFraction, iResponseType)] = ...
          max(SResults.(sModel).MLogLikelihoods(iParticipant, :, iContaminantFraction, iResponseType));
      end
    end
  end
end

% save results
fprintf('Saving results...\n')
save([c_sAnalysisResultsPath c_sMLFittingMATFileName], 'c_*', 'SResults')




