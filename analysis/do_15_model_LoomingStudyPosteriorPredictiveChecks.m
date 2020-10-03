
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


% Starts from the ABC model fit analysis results of the do_13... script,
% and gets posteriors for a number of more specific types of ABC fits,
% either using the minimum behavioural/neural thresholds for which a 
% minimum amount of ABC samples are retained, and/or fixed 
% behavioural/neural thresholds. The script generates plots showing
% posterior predictive distributions for these various fits, and also saves
% the posteriors (in the form of lists of retained ABC samples) in 
% ABCPosteriors.mat.

clearvars
close all

% general constants
c_bMakePlots = false;
c_bSavePlots = true;
SetLoomingDetectionStudyAnalysisConstants
c_ViParticipantsToAnalyse = 1:22;
c_iNoHoldOut = 1;
c_iOneConditionHeldOut = 2;

% PPC constants
c_fixedRTThresholdLow = 0.4;
c_fixedRTThresholdHigh = 0.8;
c_nMinRetainedSamplesForPPC = 100;

% constants for the GetModelFitFromABCSamples function
c_nMeshPointsPerDimensionForKernelSmoothing = [];
c_SPlotOptions.bMakeScatterPlots = false;
c_SPlotOptions.bMakeHeatMaps = false;
c_SPlotOptions.bMakePosteriorPredictiveCheckFromModeOfPosterior = false;
c_SPlotOptions.bMakePosteriorPredictiveCheckFromMixOfPosteriorSamples = c_bMakePlots;
c_SPlotOptions.fVisualisePosteriorPredictiveCheck = ...
  @VisualisePosteriorPredictiveCheckForLoomingDetectionStudy;
c_bKernelSmoothingAllowed = false;
c_SPlotOptions.bHideFigures = true;

% load experiment data
[c_SObservations, c_CsParticipantIDs] = ...
  GetLoomingDetectionStudyObservationsAndParticipantIDs;

% load results from model fit analyses (e.g., retained ABC samples for different distance thresholds)
load([c_sAnalysisResultsPath c_sModelFitAnalysisResultsMATFileName])

% fit types
c_iRTFitMinThresh = 1;
c_iRTFitFixedThreshLow = 2;
c_iRTFitFixedThreshHigh = 3;
c_iRTFixLowERPFit = 4;
c_iRTFixHighERPFit = 5;
c_nABCFitTypes = 5;

for iModel = 1:c_nModels
  
  % load ABC sample results
  sModel = c_CsModels{iModel};
  fprintf('Model %s...\n', sModel)
  fprintf('\tLoading ABC samples for model...\n')
  SFileConstants = GetFileConstants(c_sExperimentName, sModel);
  SABCSamples = LoadABCSamples(SFileConstants.sResultsMATFile);
  
  for iParticipant = c_ViParticipantsToAnalyse
    fprintf('\tParticipant %d...\n', iParticipant)
    for iFitType = 1:c_nABCFitTypes % fixed RT threshold only  VS  min RT thresh  VS  fixed RT thresh and min ERP thresh
      
      switch iFitType
          
        case c_iRTFitMinThresh
          erpThreshold = Inf;
          idxERPThreshold = GetABCDistanceThresholdIndex(erpThreshold, c_VERPThresholds);
          VnRetainedSamplesAcrossRTThresholds = ...
            squeeze(SResults(c_iNoHoldOut).(sModel).MnRetainedSamples(...
            iParticipant, 1, :, idxERPThreshold));
          idxRTThreshold = find(VnRetainedSamplesAcrossRTThresholds >= ...
            c_nMinRetainedSamplesForPPC, 1, 'first');
          rtThreshold = c_VRTThresholds(idxRTThreshold);
        
        case {c_iRTFitFixedThreshLow, c_iRTFitFixedThreshHigh}
          if iFitType == c_iRTFitFixedThreshLow
            rtThreshold = c_fixedRTThresholdLow;
          else
            rtThreshold = c_fixedRTThresholdHigh;
          end
          erpThreshold = Inf;
          
        case {c_iRTFixLowERPFit, c_iRTFixHighERPFit}
          if iFitType == c_iRTFixLowERPFit
            rtThreshold = c_fixedRTThresholdLow;
          else
            rtThreshold = c_fixedRTThresholdHigh;
          end
          idxRTThreshold = GetABCDistanceThresholdIndex(rtThreshold, c_VRTThresholds);
          VnRetainedSamplesAcrossERPThresholds = ...
            squeeze(SResults(c_iNoHoldOut).(sModel).MnRetainedSamples(...
            iParticipant, 1, idxRTThreshold, :));
          idxERPThreshold = find(VnRetainedSamplesAcrossERPThresholds >= ...
            c_nMinRetainedSamplesForPPC, 1, 'first');
          erpThreshold = c_VERPThresholds(idxERPThreshold);
          
      end  
      
      % get the retained samples describing the posterior
      if isempty(rtThreshold) || isempty(erpThreshold) % couldn't achieve the min required retained samples 
        nRetainedSamples = 0;
        MFreeParametersInRetainedSamples = zeros(0, length(CsFreeParameterNames));
      else
        c_SPlotOptions.iBaseFigureNumber = iParticipant * 10000 + (iModel-1) * 1000 + iFitType * 100;
        [nRetainedSamples, CsFreeParameterNames, ~, ~, ~, ~, ...
          MFreeParametersInRetainedSamples, MFreeParameterBounds, SABCSamples] = ...
          GetModelFitFromABCSamples(SABCSamples, c_SObservations, iParticipant, ...
          c_CsDistanceMetricsInFit, [rtThreshold * ones(1, 5) erpThreshold * ones(1, 2)], ...
          c_ViAllConditions, c_nMeshPointsPerDimensionForKernelSmoothing, ...
          c_SPlotOptions, c_bKernelSmoothingAllowed);
      end    

      % store the information about this posterior
      SABCPosteriors.(sModel).CsFreeParameterNames = CsFreeParameterNames;
      SABCPosteriors.(sModel).MFreeParameterBounds = MFreeParameterBounds;
      SABCPosteriors.(sModel).SParticipant(iParticipant).SFitType(...
        iFitType).rtThreshold = rtThreshold;
      SABCPosteriors.(sModel).SParticipant(iParticipant).SFitType(...
        iFitType).erpThreshold = erpThreshold;
      SABCPosteriors.(sModel).SParticipant(iParticipant).SFitType(...
        iFitType).nRetainedSamples = nRetainedSamples;
      SABCPosteriors.(sModel).SParticipant(iParticipant).SFitType(...
        iFitType).MFreeParametersInRetainedSamples = ...
        MFreeParametersInRetainedSamples;
      
      if c_bMakePlots
        set(gcf, 'Name', sprintf('P%d (%s); model %s; d_RT = %.2f; d_ERP = %.2f; n_R = %d', ...
          iParticipant, c_CsParticipantIDs{iParticipant}, sModel, ...
          rtThreshold, erpThreshold, nRetainedSamples))
        
        if c_bSavePlots
          saveas(gcf, sprintf('%sParticipantPPC_P%d-%s_Model%s_Fit%d_dRT%.2f_dERP%.2f.png', ...
            c_sAnalysisPlotPath, iParticipant, c_CsParticipantIDs{iParticipant}, ...
            sModel, iFitType, rtThreshold, erpThreshold))
        else
          pause
        end
      end
      
    end % iFitType for loop
  end % iParticipant for loop
  
end % iModel for loop


%%

save([c_sAnalysisResultsPath c_sABCPosteriorsMATFileName], ...
  'SABCPosteriors', 'c_iRTFi*', 'c_nABCFitTypes')


