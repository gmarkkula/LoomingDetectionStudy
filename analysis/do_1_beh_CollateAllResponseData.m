
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


% loads the per-participant Responses_*.csv files with behavioural responses 
% and collates them all into one big table, saved in AllResponseData.mat

clearvars
close all

SetLoomingDetectionStudyAnalysisConstants

c_CsExcludedParticipantIDs = {'azec'};

% get list of participant log files
SResponseLogFiles = dir([c_sResponseLogFilePath 'Responses_*.csv']);

% loop through participant log files
TResponses = [];
iParticipantCounter = 0;
for iLogFile = 1:length(SResponseLogFiles)
  sLogFileName = SResponseLogFiles(iLogFile).name;
  sParticipantID = sLogFileName(11:14);
  fprintf('%s...\n', sParticipantID)
  
  % participant included?
  bParticipantIncluded = ...
    isempty(find(strcmp(sParticipantID, c_CsExcludedParticipantIDs), 1, 'first'));
  if ~bParticipantIncluded
    fprintf('\tExcluded.\n')
    continue
  end
  
  % load data
  TThisParticipantResponses = ...
    readtable([c_sResponseLogFilePath sLogFileName]);
  
  % add participant information
  iParticipantCounter = iParticipantCounter + 1;
  nParticipantResponses = size(TThisParticipantResponses, 1);
  TThisParticipantResponses.iParticipantCounter = iParticipantCounter * ones(nParticipantResponses, 1);
  CsParticipantID = cell(nParticipantResponses, 1);
  for iRow = 1:nParticipantResponses
    CsParticipantID{iRow} = sParticipantID;
  end
  TThisParticipantResponses.sParticipantID = CsParticipantID;
  
  % add participant data to big table
  if isempty(TResponses)
    TResponses = TThisParticipantResponses;
  else
    TResponses(end+1:end+nParticipantResponses, :) = TThisParticipantResponses;
  end
  
end % iLogFile

fprintf('Saving output file...\n')
save([c_sAnalysisResultsPath 'AllResponseData.mat'], 'TResponses')