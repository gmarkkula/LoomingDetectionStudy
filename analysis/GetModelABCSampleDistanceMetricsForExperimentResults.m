
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


function SOut = ...
  GetModelABCSampleDistanceMetricsForExperimentResults(...
  sModel, SExperiment, SObservations, CsDistanceMetrics, SSettings)

% Inputs
% ======
%
% sModel
%
% SExperiment.
%   sName
%   nConditions
%   CsDataSets
%   [user-specified additional fields]
%
% SObservations.
%   <user-specified fields>
%
% CsDistanceMetrics
%
% SSettings.
%   nABCSamples
%   CsModelsToOverWrite
%   CsDistanceMetrics
%   CsDistanceMetricsToOverWrite
%   CsDataSetsToOverWrite
%   [user-specified additional fields]
%
%
% Expecting the following functions to be present
% ===============================================
%
% DistanceMetricPre_<SExperiment.sName>_<CsDistanceMetrics{}>
%   Input: (<SObservations or SSimulatedDataSet>, iDataSet, iCondition, ...
%           SSettings, extraArgument)
%   Output: SPrecalcResults
% DistanceMetric_<SExperiment.sName>_<CsDistanceMetrics{}>
%   Input: (SSimulatedDataSet, SObservations, iDataSet, iCondition, ...
%           iDistanceMetric, ...
%           SPreCalcResultsForDataSetAndCondition_Observed, ...
%           SPreCalcResultsForDataSetAndCondition_Simulated, SSettings, ...
%           extraArgument)
%   Output: distanceMetricValue
% DrawModelParameterSetFromPrior_<SExperiment.sName>
%   Input: (sModel, SSettings)
%   Output: SParameterSet
% SimulateDataSetFromModel
%   Input: (SExperiment, sModel, SParameterSet, SSettings)
%   Output: SSimulatedDataSet
%
%
% Outputs
% =======
%
% SOut.
%   sModel, SExperiment, CsDistanceMetrics, SSettings - copied from input
%   SModelParameterSets(<ABC sample>)
%   MDistanceMetricValues(<ABC sample>, <distance metric>, <data set>, <conditions>)
%   SModelParameterBounds
%

fprintf('*** Model %s - starting %s ***\n', sModel, string(datetime))

% constants
c_nDataSets = length(SExperiment.CsDataSets);
c_nConditions = SExperiment.nConditions;
c_nDistanceMetrics = length(CsDistanceMetrics);
c_nABCSamples = SSettings.nABCSamples;
c_SFileConstants = GetFileConstants(SExperiment.sName, sModel);
c_idxABCSampleMatrixDimension = 1;

% optional settings
if ~isfield(SSettings, 'iPerABCSampleDebugPlotBaseFigure')
  SSettings.iPerABCSampleDebugPlotBaseFigure = 100;
end
if ~isfield(SSettings, 'CVConditionPlotRGBs')
  SSettings.CVConditionPlotRGBs = {[0.9 0 0] [.5 0 0] [1 0.7 0] [1 0.2 0]};
%   SSettings.CVConditionPlotRGBs = {[0.95 0.5 0.5] [.75 0.5 0.5] [1 0.85 0.5] [1 0.6 0.5]};
end

bOverwriteAllExistingModelABCSamples = ...
  ~isempty(SSettings.CsModelsToOverWrite) && ...
  strcmp(SSettings.CsModelsToOverWrite{1}, '*');

% prepare output structure
% -- create distance metric matrix with NaNs everywhere
MEmptyDistanceMetricValues = NaN * ones(...
  c_nABCSamples, c_nDistanceMetrics, c_nDataSets, c_nConditions);
% -- if not overwriting results for this model, look for and load any 
% -- existing results for this model and experiment
if ~bOverwriteAllExistingModelABCSamples && ...
    ~ismember(sModel, SSettings.CsModelsToOverWrite) && ...
    exist(c_SFileConstants.sResultsMATFile, 'file')
  
  % load existing results
  SOut = LoadABCSamples(c_SFileConstants.sResultsMATFile);
  SPrevOut = SOut;
  clear SOut
  
  % get constants from existing results
  c_nPrevABCSamples = ...
    size(SPrevOut.MDistanceMetricValues, c_idxABCSampleMatrixDimension);
  c_nPrevConditions = SPrevOut.SExperiment.nConditions;
  
  % check that the existing structure has the right number of experimental
  % conditions
  if c_nPrevConditions ~= c_nConditions
    error('Number of conditions in previously existing results MAT file does not match input arguments.')
  end
  
  % populate the output structure in the right places with information from
  % the previous structure
  fprintf('Model %s: Copying already existing results for %d ABC samples...\n', ...
    sModel, c_nPrevABCSamples)
  SOut.MDistanceMetricValues = MEmptyDistanceMetricValues;
  for iABCSample = 1:c_nPrevABCSamples
    
    % copy over model parameter set
    SOut.SModelParameterSets(iABCSample) = ...
      SPrevOut.SModelParameterSets(iABCSample);
    
    % copy over distance metric values
    for iDistanceMetric = 1:c_nDistanceMetrics
      
      % find position of distance metric in existing data structure
      sDistanceMetric = CsDistanceMetrics{iDistanceMetric};
      iPrevDistanceMetric = ...
        find(strcmp(sDistanceMetric, SPrevOut.CsDistanceMetrics));
      if isempty(iPrevDistanceMetric)
        % distance metric not found in prev results, continue to next
        % metric
        continue
      end
      assert(length(iPrevDistanceMetric) == 1)
      
      for iDataSet = 1:c_nDataSets
        
        % find position of data set in existing data structure
        sDataSet = SExperiment.CsDataSets{iDataSet};
        iPrevDataSet = ...
          find(strcmp(sDataSet, SPrevOut.SExperiment.CsDataSets));
        if isempty(iPrevDataSet)
          % data set not found in prev results, continue to next data set
          continue
        end
        assert(length(iPrevDataSet) == 1)
        
        % distance metric and data set found in prev results, copy over
        % results across all experiment conditions
        SOut.MDistanceMetricValues(...
          iABCSample, iDistanceMetric, iDataSet, :) = ...
          SPrevOut.MDistanceMetricValues(...
          iABCSample, iPrevDistanceMetric, iPrevDataSet, :);
        
      end % iPrevDataSet for loop
      
    end % iPrevDistanceMetric for loop
  end % iPrevABCSample for loop
  
  clear SPrevOut
  
else
  
  % no previous results found
  SOut.MDistanceMetricValues = MEmptyDistanceMetricValues;
  c_nPrevABCSamples = 0;
  
end
clear MEmptyDistanceMetricValues
% -- copy over input data
SOut.sModel = sModel;
SOut.SExperiment = SExperiment;
SOut.CsDistanceMetrics = CsDistanceMetrics;
SOut.SSettings = SSettings;
% -- get parameter bounds with a dummy call to the function for drawing 
% -- from the prior
[~, SOut.SModelParameterBounds] = ...
  feval(c_SFileConstants.sDrawModelParameterSetFunctionName, sModel, SSettings);


% prepare data structures for keeping track of distance metric functions
% and precalculations
MbDistanceMetricPrecalculationsDone_Observations = ...
  false * ones(c_nDistanceMetrics, c_nDataSets, c_nConditions);
VDistanceMetricExtraArgument = NaN * ones(c_nDistanceMetrics, 1);
for iDistanceMetric = 1:c_nDistanceMetrics
  
  % get distance metric function names
  % -- distance metric name (including any arguments)
  sDistanceMetricLongName = CsDistanceMetrics{iDistanceMetric};
  % -- look for extra arguments
  idxArgumentStartChar = strfind(sDistanceMetricLongName, '__');
  switch length(idxArgumentStartChar)
    case 0
      sDistanceMetricShortName = sDistanceMetricLongName;
    case 1
      sDistanceMetricShortName = ...
        sDistanceMetricLongName(1:idxArgumentStartChar-1);
      VDistanceMetricExtraArgument(iDistanceMetric) = ...
        str2double(sDistanceMetricLongName(idxArgumentStartChar+2:end));
    otherwise
      error('Unexpected distance metric long name format %s.', ...
        sDistanceMetricLongName)
  end
  % -- get function pointer to main metric function
  sDistanceMetricFunctionName = ...
    sprintf(c_SFileConstants.sDistanceMetricFunctionNameFormat, ...
    sDistanceMetricShortName);
  CfDistanceMetricFunctions{iDistanceMetric} = ...
    eval(['@' sDistanceMetricFunctionName]);
  % -- get function to precalculations function if needed for this metric
  sDistanceMetricPreCalcFunctionName = ...
    sprintf(c_SFileConstants.sDistanceMetricPrecalcFunctionNameFormat, ...
    sDistanceMetricShortName);
  VbDistanceMetricNeedsPrecalculations(iDistanceMetric) = ...
    exist(sDistanceMetricPreCalcFunctionName, 'file');
  if VbDistanceMetricNeedsPrecalculations(iDistanceMetric)
    CfDistanceMetricPreCalcFunctions{iDistanceMetric} = ...
    eval(['@' sDistanceMetricPreCalcFunctionName]);
  else
    CfDistanceMetricPreCalcFunctions{iDistanceMetric} = NaN;
  end
  
  % structure for keeping precalculation results for observed data
  for iDataSet = 1:c_nDataSets
    for iCondition = 1:c_nConditions
      SDistanceMetricPreCalc_Observations(...
        iDistanceMetric, iDataSet, iCondition).SPreCalcResults = [];
    end % iCondition for loop
  end % iDataSet for loop
  
end % iDistanceMetric for loop


% get ABC samples
sMessage = ...
  sprintf('Model %s: Generating (up to) %d ABC samples...', ...
  sModel, c_nABCSamples);
disp(sMessage);
hWaitBar = waitbar(0, sMessage, 'Name', sprintf('Model %s', sModel));
for iABCSample = 1:c_nABCSamples
  
  if mod(iABCSample, 100) == 1
    waitbar(iABCSample / c_nABCSamples, hWaitBar);
  end
  
  % initialise/clear data structures from previous iteration
  clear SSimulatedDataSet
  bSimulatedDataSetGeneratedForABCSample = false;
  for iDistanceMetric = 1:c_nDistanceMetrics
    for iCondition = 1:c_nConditions
      SDistanceMetricPreCalc_Simulation(...
        iDistanceMetric, iCondition).SPreCalcResults = [];
    end % iCondition for loop
  end % iDistanceMetric for loop
  MbDistanceMetricPrecalculationsDone_Simulation = ...
    false * ones(c_nDistanceMetrics, c_nConditions);
  
  % clear any previous per-sample debug plots
  if SSettings.bPerABCSampleDebug
    DoDistanceMetricDebugPlottingInit(CsDistanceMetrics, SSettings)
  end
  
  % draw ABC sample, i.e., a model parameter set from prior
  rng(iABCSample) % for repeatability
  SParameterSet = ...
    feval(c_SFileConstants.sDrawModelParameterSetFunctionName, sModel, SSettings);
  % if previous results copied over for this ABC sample, verify that the
  % same parameter set was drawn this time
  if iABCSample <= c_nPrevABCSamples
    if ~AllStructFieldsEqual(SParameterSet, SOut.SModelParameterSets(iABCSample))
      error('Random draw not yielding same ABC parameter set as in previous run - priors or machine might have changed?')
    end
  else
    % no previous results for this ABC sample, store the parameter set in
    % output structure
    SOut.SModelParameterSets(iABCSample) = SParameterSet;
  end
  % debug output?
  if SSettings.bPerABCSampleDebug
    fprintf('ABC sample %d...\n', iABCSample)
    SParameterSet
  end
  
  % get distance metric values quantifying the distance between experiment
  % results and the results simulated using the ABC sample model
  % parameters, across all distance metrics, data sets, and experiment
  % conditions
  for iDistanceMetric = 1:c_nDistanceMetrics
    for iDataSet = 1:c_nDataSets
      for iCondition = 1:c_nConditions
        
        % need to calculate this metric value?
        existingMetricValue = SOut.MDistanceMetricValues(...
          iABCSample, iDistanceMetric, iDataSet, iCondition);
        if isnan(existingMetricValue) || ...
            ismember(CsDistanceMetrics{iDistanceMetric}, ...
            SSettings.CsDistanceMetricsToOverWrite) || ...
            ismember(SExperiment.CsDataSets{iDataSet}, ...
            SSettings.CsDataSetsToOverWrite)
          
          % yes, calculate this metric value
          
          % simulated data set generated yet for this ABC sample?
          if ~bSimulatedDataSetGeneratedForABCSample
            % no, so generate simulated data set now
            rng(iABCSample) % for repeatability
            SSimulatedDataSet = SimulateDataSetFromModel(...
              SExperiment, sModel, SParameterSet, SSettings);
            % remember that simulated data set has been generated
            bSimulatedDataSetGeneratedForABCSample = true;
          end % if simulated data set not yet generated for this ABC sample
          
          % distance metric precalculations needed?
          % -- for observed data set?
          if VbDistanceMetricNeedsPrecalculations(iDistanceMetric) && ...
              ~MbDistanceMetricPrecalculationsDone_Observations(...
              iDistanceMetric, iDataSet, iCondition)
            % do distance metric precalculations for observed data
            SDistanceMetricPreCalc_Observations(...
              iDistanceMetric, iDataSet, iCondition).SPreCalcResults = ...
              feval(CfDistanceMetricPreCalcFunctions{iDistanceMetric}, ...
              SObservations, iDataSet, iCondition, SSettings, ...
              VDistanceMetricExtraArgument(iDistanceMetric));
            % remember that distance metric precalculations have been done
            MbDistanceMetricPrecalculationsDone_Observations(...
              iDistanceMetric, iDataSet, iCondition) = true;
          end % if distance metric precalculations needed for observed data
          % -- for simulated data set?
          if VbDistanceMetricNeedsPrecalculations(iDistanceMetric) && ...
              ~MbDistanceMetricPrecalculationsDone_Simulation(...
              iDistanceMetric, iCondition)
            % do distance metric precalculations for simulated data
            SDistanceMetricPreCalc_Simulation(...
              iDistanceMetric, iCondition).SPreCalcResults = ...
              feval(CfDistanceMetricPreCalcFunctions{iDistanceMetric}, ...
              SSimulatedDataSet, [], iCondition, SSettings, ...
              VDistanceMetricExtraArgument(iDistanceMetric));
            % remember that distance metric precalculations have been done
            MbDistanceMetricPrecalculationsDone_Simulation(...
              iDistanceMetric, iCondition) = true;
          end % if distance metric precalculations needed for simulated data
          
          % calculate distance metric value
          SOut.MDistanceMetricValues(...
            iABCSample, iDistanceMetric, iDataSet, iCondition) = ...
            feval(CfDistanceMetricFunctions{iDistanceMetric}, ...
            SSimulatedDataSet, SObservations, ...
            iDataSet, iCondition, iDistanceMetric, ...
            SDistanceMetricPreCalc_Observations(...
            iDistanceMetric, iDataSet, iCondition).SPreCalcResults, ...
            SDistanceMetricPreCalc_Simulation(...
            iDistanceMetric, iCondition).SPreCalcResults, SSettings, ...
            VDistanceMetricExtraArgument(iDistanceMetric));
          
        end % if metric value to be calculated
        
      end % iCondition for loop
    end % iDataSet for loop
  end % iDistanceMetric for loop
  
  % debugging per ABC sample?
  if SSettings.bPerABCSampleDebug
    fprintf('\tPress any key to proceed to next ABC sample...\n')
    pause
  end
  
end % iABCSample for loop


% save results
SaveABCSamples(SOut, c_SFileConstants.sResultsMATFile)


% close waitbar
close(hWaitBar)


fprintf('*** Model %s - finished %s ***\n', sModel, string(datetime))






