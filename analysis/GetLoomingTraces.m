
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


function SLoomingTraces = GetLoomingTraces(c_SExperiment, c_SSettings)

c_bDebugPlot = false;

c_nTrialTypes = length(c_SExperiment.VTrialInitialDistances);
assert(length(c_SExperiment.VTrialDecelerations) == c_nTrialTypes);
c_nPreLoomingWaitTimes = length(c_SExperiment.VPreLoomingWaitTimes);

c_loomingDurationUpperLimit = ...
  sqrt(2 * max(c_SExperiment.VTrialInitialDistances) / min(c_SExperiment.VTrialDecelerations)); % longest time for car to reach zero distance to participant

for iTrialType = 1:c_nTrialTypes
  trialInitialDistance = c_SExperiment.VTrialInitialDistances(iTrialType);
  trialDeceleration = c_SExperiment.VTrialDecelerations(iTrialType);
  VLoomingTimeStamp = 0:c_SSettings.modelSimulationTimeStep:c_loomingDurationUpperLimit;
  VLoomingDistance = trialInitialDistance - trialDeceleration * VLoomingTimeStamp.^2 / 2;
  VLoomingSpeed = -trialDeceleration * VLoomingTimeStamp;
  VLoomingThetaDot = - c_SExperiment.carWidth * VLoomingSpeed ./ (VLoomingDistance.^2 + c_SExperiment.carWidth^2/4);
  
  if c_bDebugPlot
    figure(100)
    subplotGM(c_nTrialTypes, 4, iTrialType, 1)
    plot(VLoomingTimeStamp, VLoomingDistance)
    subplotGM(c_nTrialTypes, 4, iTrialType, 2)
    plot(VLoomingTimeStamp, VLoomingSpeed)
    subplotGM(c_nTrialTypes, 4, iTrialType, 3)
    plot(VLoomingTimeStamp, DoTwoPointNumericalDifferentiation(VLoomingTimeStamp, VLoomingSpeed))
    subplotGM(c_nTrialTypes, 4, iTrialType, 4)
    plot(VLoomingTimeStamp, VLoomingThetaDot)
  end
  
  for iPreLoomingWaitTime = 1:c_nPreLoomingWaitTimes
    preLoomingWaitTime = c_SExperiment.VPreLoomingWaitTimes(iPreLoomingWaitTime);
    VTrialTimeStamp = -preLoomingWaitTime:c_SSettings.modelSimulationTimeStep:c_loomingDurationUpperLimit;
    idxLoomingOnset = find(VTrialTimeStamp == 0);
    assert(length(idxLoomingOnset) == 1);
    VTrialThetaDot = zeros(size(VTrialTimeStamp));
    VTrialThetaDot(idxLoomingOnset:end) = VLoomingThetaDot;
    if isinf(c_SExperiment.maxOpticalExpansionRate)
      idxTrialEnd = length(VTrialThetaDot);
    else
      idxTrialEnd = find(VTrialThetaDot >= ...
        c_SExperiment.maxOpticalExpansionRate, 1, 'first');
      assert(~isempty(idxTrialEnd))
    end
    SLoomingTraces(iTrialType).SPreLoomingWaitTime(iPreLoomingWaitTime).VTimeStamp = ...
      VTrialTimeStamp(1:idxTrialEnd);
    SLoomingTraces(iTrialType).SPreLoomingWaitTime(iPreLoomingWaitTime).VThetaDot = ...
      VTrialThetaDot(1:idxTrialEnd);
    
    if c_bDebugPlot
      figure(101)
      subplotGM(c_nTrialTypes, c_nPreLoomingWaitTimes, iTrialType, iPreLoomingWaitTime)
      STrial = SLoomingTraces(iTrialType).SPreLoomingWaitTime(iPreLoomingWaitTime);
      plot(STrial.VTimeStamp, STrial.VThetaDot)
      axis([-5 15 -0.005 0.06])
    end
    
  end % iPreLoomingWaitTime
end % iTrialType for loop