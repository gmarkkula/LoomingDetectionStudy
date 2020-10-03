
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


function [MUnpackedMeshGrid, VPosteriorValues, SMeshGrids] = ...
  GetKernelSmoothedPosterior(MParameterSets, MParameterBounds, ...
  nMeshPointsPerDimension, VParameterSetWeights)


nSamples = size(MParameterSets, 1);
nParameters = size(MParameterSets, 2);

if nargin < 4
  VParameterSetWeights = ones(nSamples, 1);
end

c_meshGridExpansionFactor = 0;

% prep for each parameter
MParameterMeshPoints = ...
  NaN * ones(nMeshPointsPerDimension, nParameters);
VParameterStdDev = NaN * ones(nParameters, 1);
sNDGridInputsCode = '';
sNDGridOutputsCode = '';
sReshapeDimensionsCode = '';
for iParam = 1:nParameters
  % mesh points for parameter
  VThisParamValues = MParameterSets(:, iParam);
  thisParamMin = min(VThisParamValues);
  thisParamMax = max(VThisParamValues);
  thisParamRange = thisParamMax - thisParamMin;
  thisParamMeshMin = ...
    thisParamMin - c_meshGridExpansionFactor * thisParamRange;
  thisParamMeshMax = ...
    thisParamMax + c_meshGridExpansionFactor * thisParamRange;
  MParameterMeshPoints(:, iParam) = ...
    linspace(thisParamMeshMin, thisParamMeshMax, nMeshPointsPerDimension); 
  % get input and output for ndgrid call as strings
  sNDGridInputsCode = ...
    [sNDGridInputsCode sprintf('MParameterMeshPoints(:, %d), ', iParam)];
  sNDGridOutputsCode = ...
    [sNDGridOutputsCode sprintf('SMeshGrids.SParameter(%d).MGrid, ', iParam)];
  sReshapeDimensionsCode = [sReshapeDimensionsCode 'nMeshPointsPerDimension, '];
  % std dev of parameter values
  VParameterStdDev(iParam) = std(VThisParamValues, VParameterSetWeights);
  VParameterStdDevTransformed(iParam) = ...
    std( log( (VThisParamValues - MParameterBounds(1, iParam)) ./ ...
    (MParameterBounds(2, iParam) - VThisParamValues) ) );
end
sNDGridOutputsCode = sNDGridOutputsCode(1:end-2);
sNDGridInputsCode = sNDGridInputsCode(1:end-2);
sReshapeDimensionsCode = sReshapeDimensionsCode(1:end-2);

% generate mesh grids
sNDGridCommand = [ '[' sNDGridOutputsCode '] = ndgrid(' sNDGridInputsCode ');' ];
eval(sNDGridCommand)

% reshape mesh grids for call to kernel smoothing function
nMeshPoints = nMeshPointsPerDimension ^ nParameters;
MUnpackedMeshGrid = NaN * ones(nMeshPoints, nParameters);
for iParam = 1:nParameters
  MUnpackedMeshGrid(:, iParam) = ...
    reshape(SMeshGrids.SParameter(iParam).MGrid, nMeshPoints, 1);
end

% set kernel "bandwidths" according to the Silverman (1986) rule of thumb 
% in the MATLAB documentation
VParameterBandwidths = ...
  VParameterStdDev * ( 4 / ( (nParameters + 2) * nSamples ) ) ^ ...
  (1/(nParameters + 4));

% get kernel smoothed posterior
VPosteriorValues = mvksdensity(MParameterSets, MUnpackedMeshGrid, ...
  'Bandwidth', VParameterBandwidths, 'Weights', VParameterSetWeights);%, 'Support', MParameterBounds);

if nargout == 3
  % repack posterior back into mesh grid format
  sRepackCommand = ...
    ['reshape(VPosteriorValues, ' sReshapeDimensionsCode ')'];
  SMeshGrids.MPosterior = eval(sRepackCommand);
end



