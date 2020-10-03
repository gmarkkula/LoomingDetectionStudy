
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


function [idxResponse, VActivation, VAccumulatorInput] = SimulateOneTrial_AccumulatorModel(...
  VTimeStamp, VThetaDot, SParameters, SSettings)

% init
nSamples = length(VTimeStamp);
[nPreAccumulatorDelay, nPostAccumulatorDelay] = ...
  GetModelDelays(SParameters, SSettings);

% get input to accumulator
if SParameters.T_p == 0
  VAccumulatorInput = VThetaDot(:);
else
  VAccumulatorInput = zeros(nSamples, 1);
  for i = 2:nSamples
    accumulatorInputRateOfChange = ...
      -(VAccumulatorInput(i-1) - VThetaDot(i-1)) / SParameters.T_p;
    VAccumulatorInput(i) = VAccumulatorInput(i-1) + ...
      SSettings.modelSimulationTimeStep * accumulatorInputRateOfChange;
  end
end

% get accumulator input gain
if SParameters.sigma_K == 0
  inputGain = SParameters.K;
else
  inputGain = SParameters.K * (1 + SParameters.sigma_K * randn);
end

% get unbounded activation change (amplified, gated accumulator input and noise)
VNoise = randn(nSamples, 1) .* sqrt(SSettings.modelSimulationTimeStep) * ...
  SParameters.sigma;
VNoiseFreeActivationDerivative = ...
  inputGain * (VAccumulatorInput - SParameters.thetaDot_s);
VBoundFreeActivationChange = ...
  VNoiseFreeActivationDerivative * SSettings.modelSimulationTimeStep + VNoise;

% integrate with time delays, leakage and downward bounding at zero to get activation
% over time, and find threshold crossing
VActivation = zeros(size(VTimeStamp));
bExceededThreshold = false;
idxResponse = Inf;
for i = max(2, nPreAccumulatorDelay + 2) : nSamples
  VActivation(i) = max(0, VActivation(i-1) + ...
    VBoundFreeActivationChange(i-(nPreAccumulatorDelay+1)) - ...
    SSettings.modelSimulationTimeStep * VActivation(i-1) / SParameters.T_L);
  if bExceededThreshold
    % continue integrating activation until overt response
    if i >= idxResponse + 1
      break
    end
  elseif VActivation(i) >= 1
    % exceeded threshold for first time
    bExceededThreshold = true;
    idxResponse = i + nPostAccumulatorDelay;
    if idxResponse > nSamples
      idxResponse = Inf;
    end
  end
end % i for loop

% if true
%   figure(9999)
%   clf
%   plot(VTimeStamp, VActivation, 'b-')
%   hold on
%   plot(VTimeStamp(idxResponse) * [1 1], get(gca, 'YLim'), 'k--')
%   pause
% end

