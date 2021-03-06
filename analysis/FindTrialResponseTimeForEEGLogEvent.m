
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


function responseTime = FindTrialResponseTimeForEEGLogEvent(...
  SEvents, iLoomingOnsetEvent, VTimeStamps_ms, bVerbose)

responseTime = NaN;
loomingOnsetTimeStamp = ...
  GetTimeStampForEEGLogEvent(SEvents(iLoomingOnsetEvent), VTimeStamps_ms);
for iEventDelta = [-1 1]
  iPossibleResponseEvent = iLoomingOnsetEvent + iEventDelta;
  iPossibleResponseEventType = SEvents(iPossibleResponseEvent).type;
  if bVerbose
    fprintf('{%d: %d} ', iEventDelta, iPossibleResponseEventType)
  end
  if iPossibleResponseEventType == 1 % the trig ID for a response
    responseTimeStamp = ...
      GetTimeStampForEEGLogEvent(SEvents(iPossibleResponseEvent), VTimeStamps_ms);
    responseTime = responseTimeStamp - loomingOnsetTimeStamp;
    break
  end
end


