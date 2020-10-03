
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


function [SPosteriorModeParameterSet, iPosteriorModeParameterSet] = ...
  GetPosteriorModeParameterSetFromRetainedSamples(...
  MFreeParametersInRetainedSamples, CsFreeParameterNames, nMaxSamplesToAnalyse)

nFreeParameters = length(CsFreeParameterNames);
assert(size(MFreeParametersInRetainedSamples, 2) == nFreeParameters)
nRetainedSamples = size(MFreeParametersInRetainedSamples, 1);

if nRetainedSamples == 0
  SPosteriorModeParameterSet.VFreeParameters = ...
    NaN * ones(nFreeParameters, 1);
  iPosteriorModeParameterSet = [];
  return
end

% set kernel "bandwidths" according to the Silverman (1986) rule of thumb
% in the MATLAB documentation
VFreeParameterStdDev = std(MFreeParametersInRetainedSamples);
VParameterBandwidths = ...
  VFreeParameterStdDev * ( 4 / ( (nFreeParameters + 2) * nRetainedSamples ) ) ^ ...
  (1/(nFreeParameters + 4));

% get kernel smoothed posterior
nAnalysedSamples = min(nRetainedSamples, nMaxSamplesToAnalyse); % limiting the number of analysed samples is faster but approximate
VNonNormalisedSmoothedPosteriorProbabilitiesAtAnalysedSamples = mvksdensity(...
  MFreeParametersInRetainedSamples(1:nAnalysedSamples, :), ...
  MFreeParametersInRetainedSamples(1:nAnalysedSamples, :), ...
  'bandwidth', VParameterBandwidths);

% get the retained sample with highest posterior probability
[~, iPosteriorModeParameterSet] = ...
  max(VNonNormalisedSmoothedPosteriorProbabilitiesAtAnalysedSamples);
SPosteriorModeParameterSet.VFreeParameters = ...
  MFreeParametersInRetainedSamples(iPosteriorModeParameterSet, :);
for iFreeParam = 1:nFreeParameters
  SPosteriorModeParameterSet.(CsFreeParameterNames{iFreeParam}) = ...
    SPosteriorModeParameterSet.VFreeParameters(iFreeParam);
end



if false
  
  figure(9999)
  clf
  for iRow = 1:nFreeParameters
    for iCol = 1:nFreeParameters
      
      subplotGM(nFreeParameters, nFreeParameters, iRow, iCol)
      if iRow == iCol
        histogram(MFreeParametersInRetainedSamples(:, iRow))
      else
        h = scatter(MFreeParametersInRetainedSamples(1:nAnalysedSamples, iCol), ...
          MFreeParametersInRetainedSamples(1:nAnalysedSamples, iRow), 2, ...
          VNonNormalisedSmoothedPosteriorProbabilitiesAtAnalysedSamples);
        h.MarkerFaceAlpha = 1;
        colormap(flipud(colormap('gray')))
        hold on
        plot(SPosteriorModeParameterSet.VFreeParameters(iCol), ...
          SPosteriorModeParameterSet.VFreeParameters(iRow), 'ro', 'LineWidth', 3)
      end
      
    end
  end
  
  
end