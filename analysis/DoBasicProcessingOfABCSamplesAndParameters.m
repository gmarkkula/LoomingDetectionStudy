
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


function [SABCSamples, nParameters, CsParameterNames, ...
  nFreeParameters, CsFreeParameterNames, MFreeParameterBounds] = ...
  DoBasicProcessingOfABCSamplesAndParameters(SABCSamples)
% includes creating a matrix MFreeParameters in the SABCSamples struct,
% holding the values of the free parameters for all ABC samples

SParameterSet = SABCSamples.SModelParameterSets(1); % just to get parameter names
CsParameterNames = fieldnames(SParameterSet);
nParameters = length(CsParameterNames);

if isfield(SABCSamples, 'MFreeParameterSets')
  bFreeParameterMatrixCreatedNow = false;
else
  bFreeParameterMatrixCreatedNow = true;
  SABCSamples.MFreeParameterSets = ...
    NaN * ones(SABCSamples.SSettings.nABCSamples, nParameters);
  for iParam = 1:nParameters
    for iABCSample = 1:SABCSamples.SSettings.nABCSamples
      SABCSamples.MFreeParameterSets(iABCSample, iParam) = ...
        SABCSamples.SModelParameterSets(iABCSample).(CsParameterNames{iParam});
    end % iABCSample for loop
  end % iParam for loop
end

% identify free parameters, and remove fixed parameters from parameter set
% matrix, if it was just created
CsNamesOfFreeParameters = fieldnames(SABCSamples.SModelParameterBounds); % might not have the free parameters in the same order as the
nFreeParameters = 0;
for iParam = nParameters:-1:1
  %   if all(SABCSamples.MFreeParameterSets(:, iParam) == SABCSamples.MFreeParameterSets(1, iParam))
  if ~ismember(CsParameterNames{iParam}, CsNamesOfFreeParameters)
    if bFreeParameterMatrixCreatedNow
      SABCSamples.MFreeParameterSets(:, iParam) = [];
    end
  else
    nFreeParameters = nFreeParameters + 1;
    CsFreeParameterNames{nFreeParameters} = CsParameterNames{iParam};
  end
end
CsFreeParameterNames = flip(CsFreeParameterNames);

% get bounds of free parameters
if ~isfield(SABCSamples, 'SModelParameterBounds')
  warning('Using dummy draw from prior to get parameter bounds.')
  c_SFileConstants = ...
    GetFileConstants(SABCSamples.SExperiment.sName, SABCSamples.sModel);
  [~, SABCSamples.SModelParameterBounds] = ...
    feval(c_SFileConstants.sDrawModelParameterSetFunctionName, ...
    SABCSamples.sModel, SABCSamples.SSettings);
end
MFreeParameterBounds = NaN * ones(nFreeParameters, 2);
for iFreeParameter = 1:nFreeParameters
  MFreeParameterBounds(iFreeParameter, :) = ...
    SABCSamples.SModelParameterBounds.(...
    CsFreeParameterNames{iFreeParameter}).VBounds;
end