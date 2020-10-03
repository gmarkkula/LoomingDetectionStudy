
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



c_bDoBasicInit = true;
if c_bDoBasicInit
  
  clearvars
  close all force
  
  % constants
  SetLoomingDetectionStudyAnalysisConstants
  SetPlottingConstants
  
  % load info on obtained parameters from ABC and MLE fits
  fprintf('Loading fitting results...\n')
  % - ABC posteriors
  load([c_sAnalysisResultsPath c_sABCPosteriorsMATFileName])
  % - ML fitting results
  load([c_sAnalysisResultsPath c_sMLFittingMATFileName], ...
    'c_CsModels', 'SResults', 'c_VContaminantFractions')
  assert(all(strcmp(c_CCsModelsFitted{c_iMLEFitting}, c_CsModels))) % verifying that the models come in the expected order in the results MAT file
  clear c_CsModels
  c_iContaminantFractionToPlot = ...
    find(c_VContaminantFractions == c_mleContaminantFractionToPlot);
  assert(length(c_iContaminantFractionToPlot) == 1)
  
end

%%

c_CsModelsToPlot = {'T', 'A', 'AV'};
c_nModelsToPlot = length(c_CsModelsToPlot);

c_ViABCFitTypesToPlot = c_iRTFitMinThresh;

c_bExcludeAlphaND = true;

c_nMeshPointsPerDimensionForKernelSmoothing = 20;

c_VMLESymbolColor = [1 1 1] * 0.5;


for iModel = 1:c_nModelsToPlot
  sModel = c_CsModelsToPlot{iModel};
  
  % get some basic info about how this model was fitted
  CsFreeParameterNames = SABCPosteriors.(sModel).CsFreeParameterNames;
  iAlphaNDParam = find(strcmp(CsFreeParameterNames, 'alpha_ND'));
  nFreeParameters = length(CsFreeParameterNames);
  MFreeParameterBounds = SABCPosteriors.(sModel).MFreeParameterBounds;
  SMLEParamDefinitions = SResults.(sModel).SParameterDefinitions;
  nMLEParameters = length(SMLEParamDefinitions);
  for iMLEParam = 1:nMLEParameters
    CsMLEParameterNames{iMLEParam} = ...
      SMLEParamDefinitions(iMLEParam).sParameterName;
  end
  
  ViPlotParams = 1:nFreeParameters;
  MPlotParameterBounds = MFreeParameterBounds;
  if c_bExcludeAlphaND
    ViPlotParams(iAlphaNDParam) = [];
    MPlotParameterBounds(iAlphaNDParam, :) = [];
  end
  nPlotParams = length(ViPlotParams);
  
  % get ML parameterisations per participant (handling that fewer
  % parameters may have been fitted with MLE than ABC, and that the order
  % of the parameter values in the respective saved structures are not
  % guaranteed to be the same)
  MMLEParticipantParameterisations = ...
    NaN * ones(c_nFinalIncludedParticipants, nPlotParams);
  for iParticipant = 1:c_nFinalIncludedParticipants
    iBestParameterisation = SResults.MiBestParameterisation(iParticipant, ...
      iModel, c_iContaminantFractionToPlot, c_iOvertResponse);
    for iPlotParam = 1:nPlotParams
      iParam = ViPlotParams(iPlotParam);
      iMLEParam = find(strcmp(CsMLEParameterNames, CsFreeParameterNames{iParam}));
      assert(length(iMLEParam) <= 1)
      if ~isempty(iMLEParam)
        thisJitterWidth = (MFreeParameterBounds(iParam, 2) - ...
          MFreeParameterBounds(iParam, 1)) / 40;
        MMLEParticipantParameterisations(iParticipant, iPlotParam) = ...
          SResults.(sModel).MParameterValues(iBestParameterisation, iMLEParam) ...
          + (2 * rand - 1) * thisJitterWidth ;
      end
    end % iParam for loop
  end % iParticipant for loop
  
  % loop through ABC fit types (fixed RT distance threshold across
  % participants; optimised RT distance threshold per participant; combined
  % RT+ERP fit)
  for iABCFitType = c_ViABCFitTypesToPlot
    
    % get all of the retained ABC parameterisation for this fit type
    MAllRetainedParameterisations = [];
    VRetainedParameterisationWeights = [];
    for iParticipant = 1:c_nFinalIncludedParticipants
      if length(SABCPosteriors.(sModel).SParticipant(iParticipant).SFitType) ...
          < iABCFitType
        % no such fit for this participant, so skip to next
        continue
      end
      SABCPosterior = ...
        SABCPosteriors.(sModel).SParticipant(iParticipant).SFitType(iABCFitType);
      MAllRetainedParameterisations(end+1:end+SABCPosterior.nRetainedSamples, :) = ...
        SABCPosterior.MFreeParametersInRetainedSamples;
      VRetainedParameterisationWeights(end+1:end+SABCPosterior.nRetainedSamples) = ...
        1/SABCPosterior.nRetainedSamples;
    end % iParticipant for loop
    if c_bExcludeAlphaND
      MAllRetainedParameterisations(:, iAlphaNDParam) = [];
    end
    
    fprintf('\t\tGetting kernel-smoothed posterior...\n')
    [MParameterMesh, VPosteriorValues, SMeshGrids] = ...
      GetKernelSmoothedPosterior(MAllRetainedParameterisations, ...
      MPlotParameterBounds', c_nMeshPointsPerDimensionForKernelSmoothing, ...
      VRetainedParameterisationWeights);
    
    figure(10 * iModel + iABCFitType)
    clf
    nHeight_px = 500;
    if nPlotParams == 3
      nHeight_px = 460;
    end
    set(gcf, 'Position', [945   840   c_nFullWidthFigure_px   nHeight_px])
    
    
    maxAmplitude = -Inf;
    for iXPlotParam = 1:nPlotParams
      for iYPlotParam = 1:nPlotParams
        
        if iXPlotParam > iYPlotParam
          continue
        end
        
        [iRow, iCol] = SetSubPlot(nPlotParams, iXPlotParam, iYPlotParam);
        hold on
        set(gca, 'FontName', c_sFontName);
        set(gca, 'FontSize', c_stdFontSize);
        
        
        if iXPlotParam == iYPlotParam
          % 1-parameter plot
          % - ABC posterior across all participants
          [VMarginalPosterior, VXGrid] = ...
            GetMarginalPosterior(SMeshGrids, iXPlotParam);
          VMarginalPosterior = VMarginalPosterior / ...
            trapz(squeeze(VXGrid), squeeze(VMarginalPosterior));
          plot(squeeze(VXGrid), squeeze(VMarginalPosterior), 'b-')
          set(gca, 'XLim', MPlotParameterBounds(iXPlotParam, :))
          yMax = 1.2 * max(VMarginalPosterior);
          set(gca, 'YLim', [0 yMax]);
          % - MLE per-participant fits
          VX = MMLEParticipantParameterisations(:, iXPlotParam);
          hold on
          VYRug = [0.1 0.2] * yMax;
          for i = 1:length(VX)
            plot(VX([i i]), VYRug, '-', 'Color', c_VMLESymbolColor, 'LineWidth', 1);
          end
          
        elseif iXPlotParam < iYPlotParam
          
          % 2-parameter plot
          
          % - ABC posterior across all participants
          [MXYMarginalPosterior, MXMeshGrid, MYMeshGrid] = ...
            GetMarginalPosterior(SMeshGrids, [iXPlotParam iYPlotParam]);
          [~, VhContour(iXPlotParam, iYPlotParam)] = ...
            contour(squeeze(MXMeshGrid), squeeze(MYMeshGrid), ...
            squeeze(MXYMarginalPosterior));%, 'LineStyle', 'none');
          set(gca, 'XLim', MPlotParameterBounds(iXPlotParam, :))
          set(gca, 'YLim', MPlotParameterBounds(iYPlotParam, :))
          maxAmplitude = ...
            max(maxAmplitude, max(VhContour(iXPlotParam, iYPlotParam).LevelList));
          
          % - MLE per-participant fits
          VX = MMLEParticipantParameterisations(:, iXPlotParam);
          VY = MMLEParticipantParameterisations(:, iYPlotParam);
          hold on
          plot(VX, VY, '+', 'Color', c_VMLESymbolColor);
          
          
        end % 1 or 2 parameter plot if/else
        
        if iCol == 1
          if iRow < nPlotParams
            ylabel(GetAxisLabelForParameter(CsFreeParameterNames{ViPlotParams(iYPlotParam)}), ...
              'FontSize', c_annotationFontSize)
          else
            ylabel('Density (-)', 'FontSize', c_annotationFontSize)
          end
        end
        if iRow == nPlotParams
          xlabel(GetAxisLabelForParameter(CsFreeParameterNames{ViPlotParams(iXPlotParam)}), ...
            'FontSize', c_annotationFontSize)
        end
        
      end % iYParam for loop
    end % iXParam for loop
    
    % loop through panels again and adjust to use same contour levels and
    % colour axis
    set(gcf, 'Color', 'w')
    set(gcf, 'InvertHardCopy', 'off')
    MColourMap = colormap;
    VBGColour = MColourMap(1, :);
    VContourLevelList = linspace(0, maxAmplitude, 8);
    for iXPlotParam = 1:nPlotParams
      for iYPlotParam = 1:nPlotParams
        if iXPlotParam < iYPlotParam
          SetSubPlot(nPlotParams, iXPlotParam, iYPlotParam);
          VhContour(iXPlotParam, iYPlotParam).LevelList = VContourLevelList;
          caxis([0 maxAmplitude])
          %         elseif iXPlotParam > iYPlotParam
          %           set(gca, 'Visible', 'off')
        end
      end % iXParam for loop
    end % iYParam for loop
    
    drawnow
    
  end % iABCFitType for loop
  
end % iModel for loop



function [iRow, iCol] = SetSubPlot(nPlotParams, iXPlotParam, iYPlotParam)
iCol = iXPlotParam;
if iXPlotParam == iYPlotParam
  iRow = nPlotParams;
else
  iRow = nPlotParams + 1 - iYPlotParam; % iYPlotParam - 1;
end
subplotGM(nPlotParams, nPlotParams, iRow, iCol)

end
