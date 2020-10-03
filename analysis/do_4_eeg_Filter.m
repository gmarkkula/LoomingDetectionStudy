
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


% loads the rereferenced per-participant EEG data, applies band pass
% filtering, then saves new per-participant .MAT files

clearvars
close all

% constants
SetLoomingDetectionStudyAnalysisConstants

% start EEGLAB
StartEEGLAB

% get list of participant log files
SEEGFiles = dir([c_sEEGAnalysisDataPath sprintf(c_sRereferencedFileNameFormat, '*')]);

% inclusion (for rerunning if something went wrong; leave empty to run all)
c_CsOnlyProcessTheseParticipants = {'yzez', 'zeky'};

% loop through log files
for iEEGFile = 1:length(SEEGFiles)
  sEEGFileName = SEEGFiles(iEEGFile).name;
  sParticipantID = sEEGFileName(c_VidxParticipantIDInRereferencedFileName);
  fprintf('******** Participant %s ********\n', sParticipantID)
  
  % include?
  bInclude = isempty(c_CsOnlyProcessTheseParticipants) || ...
    ~isempty(find(strcmp(sParticipantID, c_CsOnlyProcessTheseParticipants), 1, 'first'));
  if ~bInclude
    fprintf('Excluded.\n')
    continue
  end
  
  % load data (structure SEEGRereferenced)
  fprintf('Loading MAT file...\n')
  load([c_sEEGAnalysisDataPath sEEGFileName])
  
  % remove verbose rereferencing information (no need to retain this in all
  % analysis steps)
  SEEGRereferenced.etc.noiseDetection.reference = 'removed to save space - see earlier step in analysis pipeline';
  
  % apply filters
  SEEGLPFiltered = pop_firws(SEEGRereferenced, 'fcutoff', 45, 'ftype', 'lowpass', 'wtype', 'kaiser', 'warg', 5.65326, 'forder', 372, 'minphase', 0);
  SEEGFiltered = pop_firws(SEEGLPFiltered, 'fcutoff', 0.1, 'ftype', 'highpass', 'wtype', 'kaiser', 'warg', 5.65326, 'forder', 1856, 'minphase', 0);
  
  % save .mat file
  fprintf('Saving MAT file...\n')
  save([c_sEEGAnalysisDataPath sprintf(c_sFilteredFileNameFormat, sParticipantID)], 'SEEGFiltered')
  
end % iLogFile