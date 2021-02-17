
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


% run a bootstrap analysis on the CPP onset results from the do_16... 
% script, to get confidence intervals for metrics quantifying the 
% difference between conditions in CPP onset relative to response, saving 
% the results in CPPRelOnsetDiffs.mat

clearvars
close all force

SetLoomingDetectionStudyAnalysisConstants

load([c_sAnalysisResultsPath c_sCPPOnsetMATFileName])

VbIncluded = ismember(SCPPOnsetResults.ViDataSet, ...
  SCPPOnsetResults.ViIncludedParticipants) & ...
  SCPPOnsetResults.VbHasCPPOnsetTime;
ViParticipantID = SCPPOnsetResults.ViDataSet(VbIncluded);
ViConditionID = SCPPOnsetResults.ViCondition(VbIncluded);
VCPPRelOnsetTime = SCPPOnsetResults.VCPPRelOnsetTime(VbIncluded);

% precalculate some basics
global ViParticipantIDs nParticipants ViConditionIDs nConditions
ViParticipantIDs = unique(ViParticipantID);
nParticipants = length(ViParticipantIDs);
ViConditionIDs = unique(ViConditionID)';
nConditions = length(ViConditionIDs);
assert(all(ViConditionIDs == 1:nConditions))

VCondAvs = GetConditionAverages(ViParticipantID, ViConditionID, VCPPRelOnsetTime)
VAbsCondDiffs = GetAbsConditionDifferences(VCondAvs)
maxAbsCondDiff = max(VAbsCondDiffs)
meanAbsCondDiff = mean(VAbsCondDiffs)
minCPPRelOnset = min(VCondAvs)
maxCPPRelOnset = max(VCondAvs)

% precalculate some more stuff
nMaxParticipantDataPoints = 0;
for iParticipant = 1:nParticipants
  iParticipantID = ViParticipantIDs(iParticipant);
  for iConditionID = ViConditionIDs
    CVCPPRelOnsetTime{iParticipant, iConditionID} = VCPPRelOnsetTime(...
      ViParticipantID == iParticipantID & ViConditionID == iConditionID);
  end
  nMaxParticipantDataPoints = max(nMaxParticipantDataPoints, ...
    length(find(ViParticipantID == iParticipantID)));
end
nMaxBootstrapSampleSize = nMaxParticipantDataPoints * nParticipants;


c_nBootstrapSamples = 100000;
[VMaxAbsCondDiff, VMeanAbsCondDiff, VMinCPPRelOnset, VMaxCPPRelOnset] = ...
  deal(NaN * ones(c_nBootstrapSamples, 1));
for iBootstrap = 1:c_nBootstrapSamples
  
  % prepare bootstrap sample data vectors
  [ViParticipantID_B, ViConditionID_B, VCPPRelOnsetTime_B] = ...
    deal(NaN * ones(nMaxBootstrapSampleSize, 1));
  
  % generate the bootstrap sample
  nDataPoints = 0;
  for iParticipant = 1:nParticipants
    % draw a participant
    iParticipant_B = randi(nParticipants);
    for iConditionID = ViConditionIDs
      VOriginalCPPRelOnsetTimes = ...
        CVCPPRelOnsetTime{iParticipant_B, iConditionID};
      nNewDataPoints = length(VOriginalCPPRelOnsetTimes);
      VDrawnCPPRelOnsetTimes = ...
        VOriginalCPPRelOnsetTimes(randi(nNewDataPoints, nNewDataPoints, 1));
      ViNewDataRange = nDataPoints + 1:nDataPoints + nNewDataPoints;
      % note not _B below, because this would reuse the same ID multiple 
      % times - instead just reusing the same order of participant IDs as 
      % in the original data set for simplicity
      ViParticipantID_B(ViNewDataRange) = ViParticipantIDs(iParticipant); 
      ViConditionID_B(ViNewDataRange) = iConditionID;
      VCPPRelOnsetTime_B(ViNewDataRange) = VDrawnCPPRelOnsetTimes;
      nDataPoints = nDataPoints + nNewDataPoints;
    end % iConditionID for loop
  end % iParticipant for loop
  
  % remove unused parts of data vectors
  ViParticipantID_B(nDataPoints + 1:end) = [];
  ViConditionID_B(nDataPoints + 1:end) = [];
  VCPPRelOnsetTime_B(nDataPoints + 1:end) = [];
  
  % analyse the generated bootstrap sample
  VCondAvs_B = GetConditionAverages(...
    ViParticipantID_B, ViConditionID_B, VCPPRelOnsetTime_B);
  VAbsCondDiffs_B = GetAbsConditionDifferences(VCondAvs_B);
  maxAbsCondDiff_B = max(VAbsCondDiffs_B);
  meanAbsCondDiff_B = mean(VAbsCondDiffs_B);
  
  % store the results
  VMaxAbsCondDiff(iBootstrap) = maxAbsCondDiff_B;
  VMeanAbsCondDiff(iBootstrap) = meanAbsCondDiff_B;
  VMinCPPRelOnset(iBootstrap) = min(VCondAvs_B);
  VMaxCPPRelOnset(iBootstrap) = max(VCondAvs_B);
  
end % iBootstrap

% confidence interval for the maximum absolute difference between 
% conditions in average CPP onset time relative to the overt response
figure(1)
histogram(VMaxAbsCondDiff)
VMaxAbsCondDiff95CIEdges = prctile(VMaxAbsCondDiff, [2.5 97.5])
VYLim = get(gca, 'YLim');
hold on
plot([1 1] * maxAbsCondDiff, VYLim, 'r-')
plot([1 1] * VMaxAbsCondDiff95CIEdges(1), VYLim, 'k-')
plot([1 1] * VMaxAbsCondDiff95CIEdges(2), VYLim, 'k-')

% confidence interval for the maximum absolute difference between 
% conditions in average CPP onset time relative to the overt response
figure(2)
histogram(VMeanAbsCondDiff)
VMeanAbsCondDiff95CIEdges = prctile(VMeanAbsCondDiff, [2.5 97.5])
VYLim = get(gca, 'YLim');
hold on
plot([1 1] * meanAbsCondDiff, VYLim, 'r-')
plot([1 1] * VMeanAbsCondDiff95CIEdges(1), VYLim, 'k-')
plot([1 1] * VMeanAbsCondDiff95CIEdges(2), VYLim, 'k-')

% confidence intervals for the minimum and maximum, across conditions, 
% average CPP onset times relative to the overt response
figure(3)
subplot(2, 1, 1)
histogram(VMinCPPRelOnset)
VMinCPPRelOnset95CIEdges = prctile(VMinCPPRelOnset, [2.5 97.5])
VYLim = get(gca, 'YLim');
hold on
plot([1 1] * minCPPRelOnset, VYLim, 'r-')
plot([1 1] * VMinCPPRelOnset95CIEdges(1), VYLim, 'k-')
plot([1 1] * VMinCPPRelOnset95CIEdges(2), VYLim, 'k-')
subplot(2, 1, 2)
histogram(VMaxCPPRelOnset)
VMaxCPPRelOnset95CIEdges = prctile(VMaxCPPRelOnset, [2.5 97.5])
VYLim = get(gca, 'YLim');
hold on
plot([1 1] * maxCPPRelOnset, VYLim, 'r-')
plot([1 1] * VMaxCPPRelOnset95CIEdges(1), VYLim, 'k-')
plot([1 1] * VMaxCPPRelOnset95CIEdges(2), VYLim, 'k-')


% save results
SCPPRelOnsetResults.VCondAvCPPRelOnsets = VCondAvs;
SCPPRelOnsetResults.VAbsCondDiffs = VAbsCondDiffs;
SCPPRelOnsetResults.maxAbsCondDiff = maxAbsCondDiff;
SCPPRelOnsetResults.meanAbsCondDiff = meanAbsCondDiff;
SCPPRelOnsetResults.minCPPRelOnset = minCPPRelOnset;
SCPPRelOnsetResults.maxCPPRelOnset = maxCPPRelOnset;
SCPPRelOnsetResults.VMaxAbsCondDiff95CIEdges = VMaxAbsCondDiff95CIEdges;
SCPPRelOnsetResults.VMeanAbsCondDiff95CIEdges = VMeanAbsCondDiff95CIEdges;
SCPPRelOnsetResults.VMinCPPRelOnset95CIEdges = VMinCPPRelOnset95CIEdges;
SCPPRelOnsetResults.VMaxCPPRelOnset95CIEdges = VMaxCPPRelOnset95CIEdges;
save([c_sAnalysisResultsPath c_sCPPRelOnsetDiffsMATFileName], ...
  'SCPPRelOnsetResults')



function VCondAvs = GetConditionAverages(ViParticipantID, ViConditionID, VMetric)

global ViParticipantIDs nParticipants ViConditionIDs nConditions

VParticipantAvs = NaN * ones(nParticipants, nConditions);
for iParticipant = 1:nParticipants
  iParticipantID = ViParticipantIDs(iParticipant);
  for iCondition = 1:nConditions
    iConditionID = ViConditionIDs(iCondition);
    VbRows = ...
      ViParticipantID == iParticipantID & ViConditionID == iConditionID;
    VParticipantAvs(iParticipant, iCondition) = mean(VMetric(VbRows));
  end
end
VParticipantAvs;
VCondAvs = mean(VParticipantAvs);

end % function


function VAbsCondDiffs = GetAbsConditionDifferences(VCondAvs)

global nConditions
i = 0;
VAbsCondDiffs = NaN * ones(nchoosek(nConditions, 2), 1);
for iCondition1 = 1:nConditions-1
  for iCondition2 = iCondition1+1:nConditions
    i = i + 1;
    VAbsCondDiffs(i) = abs(VCondAvs(iCondition2) - VCondAvs(iCondition1));
  end
end

end % function
