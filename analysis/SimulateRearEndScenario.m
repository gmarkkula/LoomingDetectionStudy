
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


function [xF, vF, xL, vL, dL, deltaX, deltaV, iCrashSample] = SimulateRearEndScenario(...
  t, svSpeed, ...
  initialDistance, initialPOVSpeed, ...
  povInitialDeceleration, povMaxDeceleration, timeToMaxPOVDeceleration, ...
  varargin)

c_scenarioTimeStep = t(2) - t(1);
assert(all(round(diff(t)*1000) == round(c_scenarioTimeStep*1000))) % constant time step required (requiring only three decimals, to avoid some problem with rounding...)

% simulate scenario
dL = ones(size(t)) * povMaxDeceleration;
if timeToMaxPOVDeceleration > 0
  iMaxDecReachedSample = round(timeToMaxPOVDeceleration / c_scenarioTimeStep);
  dL(1:iMaxDecReachedSample) = ...
    linspace(povInitialDeceleration, povMaxDeceleration, iMaxDecReachedSample);
end
vF0 = svSpeed;
vL0 = initialPOVSpeed;
deltaX0 = initialDistance;
xF = vF0 * t;
vF = ones(size(xF)) * vF0;
vL = vL0 + cumtrapz(t, -dL);
%           max(vL0 - dL * t, 0);
xL = deltaX0 + cumtrapz(t, vL);
deltaX = xL - xF;
deltaV = vL - vF;
iCrashSample = find(deltaX <= 0, 1, 'first') - 1;


if ~isempty(varargin) && strcmp(varargin{1}, 'plot')
  figure(999)
  clf
  
  if isempty(iCrashSample)
    iEndSample = length(t);
  else
    iEndSample = iCrashSample;
  end
  
  subplot(3, 1, 1)
  plot(t(1:iEndSample), deltaX(1:iEndSample), 'k-')
  ylabel('Headway (m)')
  title(sprintf('SV %d km/h; POV %.0f km/h; gap %.1f m; d %.2f->%.2f m/s^2; T_d %.1f s', ...
    svSpeed * 3.6, ...
    initialPOVSpeed*3.6, ...
    initialDistance, ...
    povInitialDeceleration, ...
    povMaxDeceleration, ...
    timeToMaxPOVDeceleration))
  set(gca, 'XLim', [0 t(iEndSample)])
  
  subplot(3, 1, 2)
  hold on
  plot(t(1:iEndSample), vF(1:iEndSample)*3.6, 'k-')
  plot(t(1:iEndSample), vL(1:iEndSample)*3.6, 'k--')
  set(gca, 'XLim', [0 t(iEndSample)])
  legend('SV', 'POV')
  ylabel('Speed (km/s)')
  
  subplot(3, 1, 3)
  plot(t(1:iEndSample), dL(1:iEndSample))
  ylabel('POV dec. (m/s^2)')
  set(gca, 'XLim', [0 t(iEndSample)])
  
%   pause
end