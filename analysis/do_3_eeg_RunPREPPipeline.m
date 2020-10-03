
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


% loads the downsampled per-participant EEG data, runs the PREP pipeline 
% for robust rereferencing, then saves new per-participant .MAT files

clearvars
close all

% constants
SetLoomingDetectionStudyAnalysisConstants

% start EEGLAB
StartEEGLAB

% get list of participant log files
SEEGFiles = dir([c_sEEGAnalysisDataPath sprintf(c_sResampledFileNameFormat, '*')]);

% inclusion (for rerunning if something went wrong; leave empty to run all)
c_CsOnlyProcessTheseParticipants = {'yzez', 'zeky'};

% loop through log files
for iEEGFile = 1:length(SEEGFiles)
  sEEGFileName = SEEGFiles(iEEGFile).name;
  sParticipantID = sEEGFileName(c_VidxParticipantIDInResampledFileName);
  fprintf('******** Participant %s ********\n', sParticipantID)
  
  % include?
  bInclude = isempty(c_CsOnlyProcessTheseParticipants) || ...
    ~isempty(find(strcmp(sParticipantID, c_CsOnlyProcessTheseParticipants), 1, 'first'));
  if ~bInclude
    fprintf('Excluded.\n')
    continue
  end
  
  % load data (structure SEEGResampled)
  fprintf('Loading MAT file...\n')
  load([c_sEEGAnalysisDataPath sEEGFileName])
  
  % run PREP pipeline
  fprintf('Running PREP pipeline...\n')
  SPREPParams.name = sParticipantID;
  SPREPParams.referenceChannels = 1:64;
  SPREPParams.evaluationChannels = 1:64;
  SPREPParams.rereferencedChannels = 1:70;
  SPREPParams.lineFrequencies = 50:50:250;
%   SEEGDummy = pop_select(SEEGResampled, 'time', [0 100]);
  SEEGRereferenced = prepPipeline(SEEGResampled, SPREPParams);
  
  % PREP reporting
  fprintf('Generating PREP reports...\n')
  % -- remove summary file if it exists
  sPREPSummaryFile = [c_sPREPReportPath sprintf(c_sPREPSummaryFileNameFormat, sParticipantID)];
  if exist(sPREPSummaryFile, 'file')
    delete(sPREPSummaryFile)
  end
  % -- generate reports
  publishPrepReport(SEEGRereferenced, sPREPSummaryFile, ...
    [c_sPREPReportPath sprintf(c_sPREPReportFileNameFormat, sParticipantID)], 1);
  
  % save .mat file
  fprintf('Saving MAT file...\n')
  save([c_sEEGAnalysisDataPath sprintf(c_sRereferencedFileNameFormat, sParticipantID)], 'SEEGRereferenced')
    
end % iLogFile