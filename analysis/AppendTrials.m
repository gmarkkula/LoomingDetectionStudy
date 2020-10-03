
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


function SDataSet = AppendTrials(SDataSet, SDataSetToAppend, ...
  c_SSettings, c_SExperiment)

bHasDataSetInfo = isfield(SDataSetToAppend, 'ViDataSet');
if bHasDataSetInfo
  iDataSet = SDataSetToAppend.ViDataSet(1);
  assert(all(SDataSetToAppend.ViDataSet == iDataSet)) % only supporting appending data from one single data set
else
  iDataSet = 1;
end
    
% nothing to append to?
if isempty(SDataSet)
  if bHasDataSetInfo
    assert(iDataSet == 1) % the assignment below works for non-responses etc only if the first data set being appended is really the first one
  end
  SDataSet = SDataSetToAppend;
  return
end

% append
nTrialsSoFar = length(SDataSet.VResponseTime);
nNewTrials = length(SDataSetToAppend.VResponseTime);
% -- trial activation
if c_SSettings.bSaveTrialActivation
  SDataSet.STrialERPs(end+1:...
    end+length(SDataSetToAppend.STrialERPs)) = ...
    SDataSetToAppend.STrialERPs;
end
% -- ERPs
if c_SExperiment.bERPIncluded
  SDataSet.SStimulusERP.MERPs(nTrialsSoFar+1:nTrialsSoFar+nNewTrials, :) = ...
    SDataSetToAppend.SStimulusERP.MERPs;
  SDataSet.SStimulusERP.VidxResponseSample(nTrialsSoFar+1:nTrialsSoFar+nNewTrials) = ...
    SDataSetToAppend.SStimulusERP.VidxResponseSample;
  SDataSet.SResponseERP.MERPs(nTrialsSoFar+1:nTrialsSoFar+nNewTrials, :) = ...
    SDataSetToAppend.SResponseERP.MERPs;
end
% -- error responses
if size(SDataSet.MnEarlyResponsesPerCondition, 1) < iDataSet
  SDataSet.MnEarlyResponsesPerCondition(iDataSet, :) = ...
    zeros(1, c_SExperiment.nConditions);
  SDataSet.MnNonResponsesPerCondition(iDataSet, :) = ...
    zeros(1, c_SExperiment.nConditions);
end
SDataSet.MnEarlyResponsesPerCondition(iDataSet, :) = ...
  SDataSet.MnEarlyResponsesPerCondition(iDataSet, :) + ...
  SDataSetToAppend.MnEarlyResponsesPerCondition;
SDataSet.MnNonResponsesPerCondition(iDataSet, :) = ...
  SDataSet.MnNonResponsesPerCondition(iDataSet, :) + ...
  SDataSetToAppend.MnNonResponsesPerCondition;
% -- all other vectors
CsFields = fieldnames(SDataSetToAppend);
for iField = 1:length(CsFields)
  sField = CsFields{iField};
  if ~ismember(sField, {'STrialERPs', 'SStimulusERP', 'SResponseERP', ...
      'MnEarlyResponsesPerCondition', 'MnNonResponsesPerCondition'})
    SDataSet.(sField)(end+1:end+nNewTrials, :) = ...
      SDataSetToAppend.(sField);
  end
end % iField for loop