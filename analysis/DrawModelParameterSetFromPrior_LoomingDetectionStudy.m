
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


function [SParameterSet, SBounds] = ...
  DrawModelParameterSetFromPrior_LoomingDetectionStudy(sModel, SSettings)

% get bounds for the uniform parameter prior bounds for this model as
% derived from the fitting to the Lamble et al results
if ~strcmp(sModel, 'T0')
  SBounds = SSettings.SUniformModelPriorBounds.(sModel);
else
  SBounds = SSettings.SUniformModelPriorBounds.T;
  SBounds.thetaDot_d.VBounds(1) = 0;
end

% set bounds for parameters not included in the fitting to the Lamble et al
% results
SBounds.alpha_ND.VBounds = [0 1];

% always fixed parameters
SParameterSet.P_lapse = single(0);
SParameterSet.T_p = single(0); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% always free parameters
% -- non-decision time
SParameterSet.T_ND = ...
  single(GetRandomValueFromUniformDistribution(SBounds.T_ND.VBounds));
% -- non-decision pre/post decision fraction
SParameterSet.alpha_ND = ...
  single(GetRandomValueFromUniformDistribution(SBounds.alpha_ND.VBounds));
% -- noise
SParameterSet.sigma = ...
  single(GetRandomValueFromUniformDistribution(SBounds.sigma.VBounds));


% parameters that are free or fixed depending on model
switch sModel
  
  case {'T', 'T0'}
    % looming detection threshld
    SParameterSet.thetaDot_d = ...
      single(GetRandomValueFromUniformDistribution(SBounds.thetaDot_d.VBounds));
    
  case {'A', 'AG', 'AL', 'AV', 'AGL', 'AVG', 'AVL', 'AVGL'}
    
    % accumulation gain
    SParameterSet.K = ...
      single(GetRandomValueFromUniformDistribution(SBounds.K.VBounds));
    
    % accumulation gain variability
    if ismember(sModel, {'AV', 'AVG', 'AVL', 'AVGL'})
      SParameterSet.sigma_K = ...
        single(GetRandomValueFromUniformDistribution(SBounds.sigma_K.VBounds));
    else
      SParameterSet.sigma_K = single(0);
    end
    
    % looming sensation threshold
    if ismember(sModel, {'AG', 'AGL', 'AVG', 'AVGL'})
      SParameterSet.thetaDot_s = ...
        single(GetRandomValueFromUniformDistribution(SBounds.thetaDot_s.VBounds));
    else
      SParameterSet.thetaDot_s = single(0);
    end
    
    % leakage time constant
    if ismember(sModel, {'AL', 'AGL', 'AVL', 'AVGL'})
      SParameterSet.T_L = ...
        single(GetRandomValueFromUniformDistribution(SBounds.T_L.VBounds));
    else
      SParameterSet.T_L = single(Inf);
    end
    
  case {'WG', 'WVG', 'WGS'}
    
    SParameterSet = SetFixedParametersForWongAndWangModel(SParameterSet);
    SParameterSet.J_Aext_x_mu_0 = single(...
      GetRandomValueFromUniformDistribution(SBounds.J_Aext_x_mu_0.VBounds));
    SParameterSet.r_threshold = single(...
      GetRandomValueFromUniformDistribution(SBounds.r_threshold.VBounds));
    SParameterSet.thetaDot_s = ...
      single(GetRandomValueFromUniformDistribution(SBounds.thetaDot_s.VBounds));
    if strcmp(sModel, 'WGS')
      SParameterSet.f = single(...
        GetRandomValueFromUniformDistribution(SBounds.f.VBounds));
    else
      SParameterSet.f = single(1);
    end
    if strcmp(sModel, 'WVG')
      SParameterSet.sigma_f = single(...
      GetRandomValueFromUniformDistribution(SBounds.sigma_f.VBounds));
    end
    
  otherwise
    error('Unexpected model identifier %s.', sModel)
    
end
