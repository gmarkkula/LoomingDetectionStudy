
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


function SaveABCSamples(SABCSamples, sFileName)

% prepend the analysis results path to file name
SetLoomingDetectionStudyAnalysisConstants
sFileName = [c_sAnalysisResultsPath sFileName];

% constants
c_nSampleLimitForSingleMATFile = 10000;

% save the space-intensive parts of the struct as separate .dat files, for
% drastically improved saving/loading speed 
nSamples = SABCSamples.SSettings.nABCSamples;
if nSamples > c_nSampleLimitForSingleMATFile
  
  % serialise and save space-intensive fields - making sure distance
  % metrics are saved with single precision
  SerialiseAndSaveSeparately(...
    single(SABCSamples.MDistanceMetricValues), sFileName, 'dmv');
  SerialiseAndSaveSeparately(...
    SABCSamples.SModelParameterSets, sFileName, 'mps')
  % remove fields
  SABCSamples = ...
    rmfield(SABCSamples, {'MDistanceMetricValues', 'SModelParameterSets'});
  
end % if nSamples > c_nSampleLimitForSingleMATFile

% save the struct itself
save(sFileName, 'SABCSamples')



function SerialiseAndSaveSeparately(vDataToSerialise, sBaseFileName, ...
  sFileNameAppendix)

% serialise the data
ViByteStream = getByteStreamFromArray(vDataToSerialise);

% get file name for the serialised data
sSerialisedFileName = ...
  SetFileSuffix(AppendToFileName(sBaseFileName, sFileNameAppendix), '.dat');

% write the serialised data
iFileID = fopen(sSerialisedFileName, 'w');
if iFileID == -1
  error('Could not open %s for writing', sSerialisedFileName)
end
fwrite(iFileID, ViByteStream);
fclose(iFileID);
