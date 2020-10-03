
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
  DrawModelParameterSetFromPrior_LambleEtAlStudy(sModel, SSettings)

% always fixed parameters
SParameterSet.P_lapse = single(0);
SParameterSet.alpha_ND = single(1);

% always free parameters
% -- non-decision time
% switch sModel
%   case {'WG', 'WVG'}
%     SBounds.T_ND.VBounds = [0 0.5]; % 100 ms in W&W2006
%   otherwise
    SBounds.T_ND.VBounds = [0 1];
% end
SParameterSet.T_ND = ...
  single(GetRandomValueFromUniformDistribution(SBounds.T_ND.VBounds));
% -- noise
switch sModel
  case {'T', 'A'}
    SBounds.sigma.VBounds = [0.01 1];
  case {'AL', 'AV', 'AVL'}
    SBounds.sigma.VBounds = [0.01 2];
  case {'AG', 'AGL', 'AVG', 'AVGL'}
    SBounds.sigma.VBounds = [0.01 25]; % gives a CDF of 0.55 at 1 for a 0.1 s time step, i.e. there is a 45% chance that the noise is above the threshold after 0.1 s
  case {'WG', 'WVG', 'WGS'}
    SBounds.sigma.VBounds = [0.001 0.5]; % 0.02 nA in W&W2006
  otherwise
    error('Unexpected model identifier %s.', sModel)
end
SParameterSet.sigma = ...
  single(GetRandomValueFromUniformDistribution(SBounds.sigma.VBounds));


% parameters that are free or fixed depending on model
switch sModel
  
  
  % threshold model
  case 'T'
    % looming detection threshld
    SBounds.thetaDot_d.VBounds = [0.001 0.012];
    SParameterSet.thetaDot_d = ...
      single(GetRandomValueFromUniformDistribution(SBounds.thetaDot_d.VBounds));
    
    
    % accumulator models
  case {'A', 'AG', 'AL', 'AV', 'AGL', 'AVG', 'AVL', 'AVGL'}
    
    % accumulation gain
    switch sModel
      case 'A'
        SBounds.K.VBounds = [50 2000];
      case {'AG', 'AGL', 'AVG', 'AVGL'} 
        SBounds.K.VBounds = [50 100000];
      otherwise
        SBounds.K.VBounds = [50 5000];
    end
    SParameterSet.K = single(GetRandomValueFromUniformDistribution(SBounds.K.VBounds));
    
%     % perceptual preprocessing time constant
%     if ismember(sModel, {'pAG', 'pAL'})
%       SBounds.T_p.VBounds = [0 1];
%       SParameterSet.T_p = ...
%         single(GetRandomValueFromUniformDistribution(SBounds.T_p.VBounds));
%     end
    
    % accumulation gain variability
    if ismember(sModel, {'AV', 'AVG', 'AVL', 'AVGL'})
      if strcmp(sModel, 'AV') || strcmp(sModel, 'AVL')
        SBounds.sigma_K.VBounds = [0 1];
      else
        SBounds.sigma_K.VBounds = [0 3]; % loosely based on Matzke and Wagenmakers (2009) where average drift rate variance in Table 3 is 0.133, i.e. std dev 0.365, which is 1.64 times the average drift rate 0.223
      end
      SParameterSet.sigma_K = ...
        single(GetRandomValueFromUniformDistribution(SBounds.sigma_K.VBounds));
    else
      SParameterSet.sigma_K = single(0);
    end
    
    % looming sensation threshold
    if ismember(sModel, {'AG', 'AGL', 'AVG', 'AVGL'})
      SBounds.thetaDot_s.VBounds = [0 0.006];
      SParameterSet.thetaDot_s = ...
        single(GetRandomValueFromUniformDistribution(SBounds.thetaDot_s.VBounds));
    else
      SParameterSet.thetaDot_s = single(0);
    end
    
    % leakage time constant
    if ismember(sModel, {'AL', 'AGL', 'AVL', 'AVGL'})
      SBounds.T_L.VBounds = [0.1 20];
      SParameterSet.T_L = ...
        single(GetRandomValueFromUniformDistribution(SBounds.T_L.VBounds));
    else
      SParameterSet.T_L = single(Inf);
    end
    
    % Wong and Wang (2006) model
  case {'WG', 'WVG', 'WGS'} 
    
    SParameterSet = SetFixedParametersForWongAndWangModel(SParameterSet);
    
    % synaptic input current from stimulus
    SBounds.J_Aext_x_mu_0.VBounds = [0.001 0.1]; % 5.2e-4 nA/Hz * 30 Hz = 0.0156 nA in W&W2006
    SParameterSet.J_Aext_x_mu_0 = single(...
      GetRandomValueFromUniformDistribution(SBounds.J_Aext_x_mu_0.VBounds));
    
    % firing rate threshold for response
    SBounds.r_threshold.VBounds = [10 100]; % 25 Hz in W&W2006
    SParameterSet.r_threshold = single(...
      GetRandomValueFromUniformDistribution(SBounds.r_threshold.VBounds));
    
    % looming sensation threshold
    SBounds.thetaDot_s.VBounds = [0 0.006]; 
    SParameterSet.thetaDot_s = ...
      single(GetRandomValueFromUniformDistribution(SBounds.thetaDot_s.VBounds));
    
    % looming input scaling
    if strcmp(sModel, 'WGS')
      SBounds.f.VBounds = [0.05 1]; %
      SParameterSet.f = single(...
        GetRandomValueFromUniformDistribution(SBounds.f.VBounds));
    else    
      SParameterSet.f = 1;
    end
    
    if strcmp(sModel, 'WVG')
      SBounds.sigma_f.VBounds = [0 3];
      SParameterSet.sigma_f = single(...
        GetRandomValueFromUniformDistribution(SBounds.sigma_f.VBounds));
    end
    
  otherwise
    error('Unexpected model identifier %s.', sModel)
    
    
end
