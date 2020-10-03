
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


% For each ABC-fitted model, this script goes through various combinations 
% of the ABC distance thresholds for the behavioural and neural summary 
% statistics, for each combination calculating the number of retained
% samples. The script also does the same analysis with a k-fold
% cross-validation approach. The intention of these analyses was to see
% whether joint behavioural-neural fitting would outperform purely
% behavioural fitting in terms of performance on unseen validation data.
% Since the ERP data turned out not to align well with the model evidence
% signals, these analyses were not pursued further here.
%
% The results are stored in a struct SResults, saved in a file
% LoomingDetectionModelFitAnalysisResults.mat.

% init
clearvars
close all force

SetLoomingDetectionStudyAnalysisConstants

c_CsModels = {'T' 'A' 'AG' 'AL' 'AV' 'AGL' 'AVG' 'AVL' 'AVGL'};
c_nModels = length(c_CsModels);
c_bKeepExistingAnalysisResults = false; % this feature should only be used if the only modification is adding one or more additional models

% are there previous results to build on?
if c_bKeepExistingAnalysisResults 
  
  if exist([c_sAnalysisResultsPath c_sModelFitAnalysisResultsMATFileName], 'file')
    % load previous results as well as the constants used when generating
    % them
    c_CsModelsThisRun = c_CsModels;
    load([c_sAnalysisResultsPath c_sModelFitAnalysisResultsMATFileName])
    c_CsModels = c_CsModelsThisRun;
  else
    error('No previous results found, looked for: %s', ...
      [c_sAnalysisResultsPath c_sModelFitAnalysisResultsMATFileName])
  end
  
else
  
  % not building on previous run, so set constants

  c_ViAllConditions = 1:c_nStimulusTypes;
  
  c_VnConditionsToHoldOut = [0 1];
  c_nHoldOutApproaches = length(c_VnConditionsToHoldOut);
  
  c_VRTThresholds = [0.1:0.1:0.8 Inf];
  c_nRTThresholds = length(c_VRTThresholds);
  c_VERPThresholds = c_VRTThresholds; % same values work ok also for the neural metrics
  c_nERPThresholds = length(c_VERPThresholds);
  c_maxRTThresholdForGettingPosteriorMode = 0.5;
  
  c_CsDistanceMetricsInFit = {...
    'RTPercentile__10', ...
    'RTPercentile__30', ...
    'RTPercentile__50', ...
    'RTPercentile__70', ...
    'RTPercentile__90', ...
...%     'ERPPeakFraction__1', ... % in earlier tests we fitted with two neural distance metrics per condition
    'ERPPeakFraction__2'
    };
  c_nRTMetrics = 5;
  c_nERPMetrics = 1;
  c_ViRTDistanceMetrics = 1:c_nRTMetrics;
  c_ViERPDistanceMetrics = c_nRTMetrics + (1:c_nERPMetrics);
  
  c_nSamplingTypes = 2; % sampling over posterior vs sampling only posterior mode
  
  c_sExperimentName = 'LoomingDetectionStudy';
  c_SObservations = GetLoomingDetectionStudyObservationsAndParticipantIDs;
  c_ViParticipantsToAnalyse = 1:22;
  
  c_nMaxSamplesToAnalyseForPosteriorMode = 1000; % approximate mode calculation

end


% analyse

for iModel = 1:c_nModels
  
  % load ABC sample results
  sModel = c_CsModels{iModel};
  fprintf('Model %s...\n', sModel)
  if c_bKeepExistingAnalysisResults && isfield(SResults(1), sModel)
    fprintf('\tAlready analysed.\n')
    continue
  end
  fprintf('\tLoading ABC samples for model...\n')
  SFileConstants = GetFileConstants(c_sExperimentName, sModel);
  SABCSamples = LoadABCSamples(SFileConstants.sResultsMATFile);
  bResultsMatrixPreallocationDoneForModel = false;
  
%   % make sure the distance metrics used for generating the ABC samples
%   % were the same - and stored in the same order - as assumed here
%   assert(all(strcmp(SABCSamples.CsDistanceMetrics, c_CsDistanceMetricsInFit)))
  
  % add matrix of ABC sample parameter sets to ABC sample structure
  fprintf('\tGetting matrix of ABC sample parameter sets...\n')
  SABCSamples = DoBasicProcessingOfABCSamplesAndParameters(SABCSamples);
  
  for iHoldOutApproach = 1:c_nHoldOutApproaches
    
    % figure out what conditions to hold out, and how many cross-validation
    % folds this implies
    nConditionsToHoldOut = c_VnConditionsToHoldOut(iHoldOutApproach);
    MiConditionsToHoldOutPerFold = nchoosek(c_ViAllConditions, nConditionsToHoldOut);
    SResults(iHoldOutApproach).nFolds = size(MiConditionsToHoldOutPerFold, 1);
    
    fprintf('\tHoldout approach %d of %d, holding out %d condition(s)\n', ...
      iHoldOutApproach, c_nHoldOutApproaches, nConditionsToHoldOut)
    
    for iParticipant = c_ViParticipantsToAnalyse
      fprintf('\t\tGetting fits for model %s to participant %d...\n', ...
        sModel, iParticipant)
      
      for iFold = 1:SResults(iHoldOutApproach).nFolds
        ViConditionsInValidationSet = MiConditionsToHoldOutPerFold(iFold, :);
        ViConditionsInTrainingSet = ...
          setdiff(c_ViAllConditions, ViConditionsInValidationSet);
        fprintf('\t\t\tFold %d of %d, fitting to conditions [%s] across all combinations of ABC thresholds...\n\t\t\t', ...
          iFold, SResults(iHoldOutApproach).nFolds, num2str(ViConditionsInTrainingSet))
        
        for iRTThreshold = 1:c_nRTThresholds
          for iERPThreshold = 1:c_nERPThresholds
            
            % get model fit for this pair of ABC distance thresholds, for
            % the training dataset (i.e., minus any held-out conditions)
            thisRTThreshold = c_VRTThresholds(iRTThreshold);
            thisERPThreshold = c_VERPThresholds(iERPThreshold);
            VDistanceThresholdsAcrossMetrics = ...
              [thisRTThreshold * ones(1, c_nRTMetrics) ...
              thisERPThreshold * ones(1, c_nERPMetrics)];
            fprintf('.')
            [nFreeParameters, CsFreeParameterNames, MFreeParameterBounds, ...
              VbABCSampleRetained, nRetainedABCSamples, MFreeParametersInRetainedSamples, ...
              SPosteriorMeanParameterSet, SFreeParameterCredibleIntervals] = ...
              DoABCThresholdingBasicsForModel(SABCSamples, iParticipant, ...
              c_CsDistanceMetricsInFit, VDistanceThresholdsAcrossMetrics, ...
              ViConditionsInTrainingSet);
            ViRetainedABCSamples = find(VbABCSampleRetained);
            
            % store some basics about the model fit
            SResults(iHoldOutApproach).(sModel).nFreeParameters = nFreeParameters;
            SResults(iHoldOutApproach).(sModel).CsFreeParameterNames = CsFreeParameterNames;
            SResults(iHoldOutApproach).(sModel).MFreeParameterBounds = MFreeParameterBounds;
            
            % get posterior mode parameter set, if thresholds are small enough
            if thisRTThreshold <= c_maxRTThresholdForGettingPosteriorMode
              [SPosteriorModeParameterSet, iPosteriorModeParameterSetAmongRetained] = ...
                GetPosteriorModeParameterSetFromRetainedSamples(...
                MFreeParametersInRetainedSamples, CsFreeParameterNames, ...
                c_nMaxSamplesToAnalyseForPosteriorMode);
              iPosteriorModeParameterSet = ...
                ViRetainedABCSamples(iPosteriorModeParameterSetAmongRetained);
            else
              [SPosteriorModeParameterSet, iPosteriorModeParameterSet] = ...
                GetPosteriorModeParameterSetFromRetainedSamples(...
                zeros(0, nFreeParameters), CsFreeParameterNames);
            end
            
            % preallocate analysis results matrices, if not done for model yet
            if ~bResultsMatrixPreallocationDoneForModel
              % parameter value results
              SResults(iHoldOutApproach).(sModel).MnRetainedSamples = ...
                NaN * ones(max(c_ViParticipantsToAnalyse), ...
                SResults(iHoldOutApproach).nFolds, c_nRTThresholds, c_nERPThresholds);
              MNaNResultsPerParameterMatrix = NaN * ones(max(c_ViParticipantsToAnalyse), ...
                SResults(iHoldOutApproach).nFolds, c_nRTThresholds, c_nERPThresholds, nFreeParameters);
              [SResults(iHoldOutApproach).(sModel).STrainingSet.MFreeParameterCIMin, ...
                SResults(iHoldOutApproach).(sModel).STrainingSet.MFreeParameterCIMax, ...
                SResults(iHoldOutApproach).(sModel).STrainingSet.MFreeParameterPosteriorMean, ...
                SResults(iHoldOutApproach).(sModel).STrainingSet.MFreeParameterPosteriorMode] = ...
                deal(MNaNResultsPerParameterMatrix);
              % goodness of fit results
              MNaNResultsPerSamplingTypeMatrix = NaN * ones(max(c_ViParticipantsToAnalyse), ...
                SResults(iHoldOutApproach).nFolds, c_nRTThresholds, c_nERPThresholds, c_nSamplingTypes);
              [SResults(iHoldOutApproach).(sModel).STrainingSet.MAverageAbsRTError, ...
                SResults(iHoldOutApproach).(sModel).STrainingSet.MAverageAbsERPError] = ...
                deal(MNaNResultsPerSamplingTypeMatrix);
              % preallocate also for validation set goodness of fit results,
              % if any holdout is being done
              if nConditionsToHoldOut > 0
                [SResults(iHoldOutApproach).(sModel).SValidationSet.MAverageAbsRTError, ...
                  SResults(iHoldOutApproach).(sModel).SValidationSet.MAverageAbsERPError, ...
                  SResults(iHoldOutApproach).(sModel).SValidationSet.MAverageAbsRTErrorAlt, ...
                  SResults(iHoldOutApproach).(sModel).SValidationSet.MAverageAbsERPErrorAlt] = ...
                  deal(MNaNResultsPerSamplingTypeMatrix);
              end
              % remember that this has been done
              bResultsMatrixPreallocationDoneForModel = true;
            end
            
            % store info about retained parameter values
            SResults(iHoldOutApproach).(sModel).MnRetainedSamples(...
              iParticipant, iFold, iRTThreshold, iERPThreshold) = ...
              nRetainedABCSamples;
            SResults(iHoldOutApproach).(sModel).MFreeParameterCIMin(...
              iParticipant, iFold, iRTThreshold, iERPThreshold, :) = ...
              SFreeParameterCredibleIntervals.MAllIntervals(:, 1);
            SResults(iHoldOutApproach).(sModel).MFreeParameterCIMax(...
              iParticipant, iFold, iRTThreshold, iERPThreshold, :) = ...
              SFreeParameterCredibleIntervals.MAllIntervals(:, 2);
            SResults(iHoldOutApproach).(sModel).MFreeParameterPosteriorMean(...
              iParticipant, iFold, iRTThreshold, iERPThreshold, :) = ...
              SPosteriorMeanParameterSet.VFreeParameters;
            SResults(iHoldOutApproach).(sModel).MFreeParameterPosteriorMode(...
              iParticipant, iFold, iRTThreshold, iERPThreshold, :) = ...
              SPosteriorModeParameterSet.VFreeParameters;
            
            % store goodness of fit results both across entire posterior
            % and for mode parameter set
            for iSamplingType = 1:c_nSamplingTypes
              switch iSamplingType
                case 1
                  ViSampledParameterSets = ViRetainedABCSamples;
                case 2
                  ViSampledParameterSets = iPosteriorModeParameterSet;
              end
              % store goodness of fit results for the training data set
              SResults(iHoldOutApproach).(sModel).STrainingSet.MAverageAbsRTError(...
                iParticipant, iFold, iRTThreshold, iERPThreshold, iSamplingType) = ...
                GetGrandAverageOfAbsDistanceMetrics(SABCSamples, iParticipant, ...
                c_ViRTDistanceMetrics, ViSampledParameterSets, ViConditionsInTrainingSet);
              SResults(iHoldOutApproach).(sModel).STrainingSet.MAverageAbsERPError(...
                iParticipant, iFold, iRTThreshold, iERPThreshold, iSamplingType) = ...
                GetGrandAverageOfAbsDistanceMetrics(SABCSamples, iParticipant, ...
                c_ViERPDistanceMetrics, ViSampledParameterSets, ViConditionsInTrainingSet);
              % store goodness of fit results for the validation set, if any holdout is being done
              if nConditionsToHoldOut > 0
                SResults(iHoldOutApproach).(sModel).SValidationSet.MAverageAbsRTError(...
                  iParticipant, iFold, iRTThreshold, iERPThreshold, iSamplingType) = ...
                  GetGrandAverageOfAbsDistanceMetrics(SABCSamples, iParticipant, ...
                  c_ViRTDistanceMetrics, ViSampledParameterSets, ViConditionsInValidationSet);
                SResults(iHoldOutApproach).(sModel).SValidationSet.MAverageAbsERPError(...
                  iParticipant, iFold, iRTThreshold, iERPThreshold, iSamplingType) = ...
                  GetGrandAverageOfAbsDistanceMetrics(SABCSamples, iParticipant, ...
                  c_ViERPDistanceMetrics, ViSampledParameterSets, ViConditionsInValidationSet);
                SResults(iHoldOutApproach).(sModel).SValidationSet.MAverageAbsRTErrorAlt(...
                  iParticipant, iFold, iRTThreshold, iERPThreshold, iSamplingType) = ...
                  GetGrandAverageOfAbsDistanceMetrics(SABCSamples, iParticipant, ...
                  c_ViRTDistanceMetrics, ViSampledParameterSets, ViConditionsInValidationSet, 1);
                SResults(iHoldOutApproach).(sModel).SValidationSet.MAverageAbsERPErrorAlt(...
                  iParticipant, iFold, iRTThreshold, iERPThreshold, iSamplingType) = ...
                  GetGrandAverageOfAbsDistanceMetrics(SABCSamples, iParticipant, ...
                  c_ViERPDistanceMetrics, ViSampledParameterSets, ViConditionsInValidationSet, 1);
              end % if nConditionsToHoldOut > 0
            end % iSamplingType for loop
            
          end % iERPThreshold for loop
        end % iRTThreshold for loop
        fprintf('\n')
        
      end % iFold for loop
      
    end % iParticipant for loop
    
  end % iHoldOutApproach
  
end % iModel for loop

save([c_sAnalysisResultsPath c_sModelFitAnalysisResultsMATFileName], ...
  'SResults', 'c_*')



function grandAverage = GetGrandAverageOfAbsDistanceMetrics(...
  SABCSamples, iParticipant, ViDistanceMetrics, ViABCSamples, ViConditions, varargin)
% get absolute values of all included distance metric values in a vector
MAbsDistanceMetricValues = abs(squeeze(SABCSamples.MDistanceMetricValues(...
  ViABCSamples, ViDistanceMetrics, iParticipant, ViConditions)));
nValues = numel(MAbsDistanceMetricValues);
VAbsDistanceMetricValues = reshape(MAbsDistanceMetricValues, nValues, 1);
% handle Inf values (should only exist if this is a validation dataset)
if nargin < 6
  % remove Inf values
  VAbsDistanceMetricValues(isinf(VAbsDistanceMetricValues)) = [];
else
  % replace Inf values with a user-provided error value
  VAbsDistanceMetricValues(isinf(VAbsDistanceMetricValues)) = varargin{1};
end
% take the average
grandAverage = mean(VAbsDistanceMetricValues);
end

