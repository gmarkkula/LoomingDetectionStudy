
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


function MakeERPOverviewFigure(VEpochTimeStamp, nSampleRate, ...
  SChannelLocations, nDataChannels, ...
  MICAWeights, MInvertedICAWeights, ...
  MEpochEEGChannelData, MEpochICAComponentData, ...
  ViEpochTrialIDs, VResponseLatencies, VidxResponseSamples, ...
  CViEEGChannelAveragesToPlot, ViICAComponentsToPlot, ...
  bPlotResponseLockedScalpMaps, varargin)


nEpochs = size(MEpochEEGChannelData, 3);

% plotting constants
c_nEEGChannelsToPlot = length(CViEEGChannelAveragesToPlot);
c_nICAComponentsToPlot = length(ViICAComponentsToPlot);
c_nSignalsToPlot = c_nEEGChannelsToPlot + c_nICAComponentsToPlot;
c_nSubplotCols = c_nSignalsToPlot;
if bPlotResponseLockedScalpMaps
  c_nSubplotCols = c_nSubplotCols + 1;
end
c_bOnlyEEGERP = c_nEEGChannelsToPlot > 0 && c_nICAComponentsToPlot == 0;
c_bOnlyICAERP = c_nEEGChannelsToPlot == 0 && c_nICAComponentsToPlot > 0;

c_ViPlotTrialIDs = [2 1 4 3];
c_nPlotTrialIDs = length(c_ViPlotTrialIDs);
c_CMPlotTrialRGB = {[.5 0 0] [0.9 0 0] [1 0.2 0] [1 0.7 0]};
c_VScalpMapLatencies_ms = [-500 -250 0 250];

if c_bOnlyEEGERP
  c_nSubplotRows = 4;
  c_iSortedEpochPlotRow = 2;
  c_VERPPlotLimits = [-5 15]; % uV
  c_sERPUnit = '\muV';
  c_vTopoPlotMapLimitValue = c_VERPPlotLimits;
  set(gcf, 'Position', [60         260        1573         718])
else
  c_nSubplotRows = 5;  
  c_iSortedEpochPlotRow = 3;
  c_VERPPlotLimits = []; % mixed unit
  c_sERPUnit = '-';
  c_vTopoPlotMapLimitValue = 'absmax';
  set(gcf, 'Position', [60         260        1573         868])
end

if length(varargin) == 1
  c_VERPPlotLimits = varargin{1};
  c_vTopoPlotMapLimitValue = c_VERPPlotLimits;
end

% constants for response-locking
c_nPreResponsePlotSamples = round(1 * nSampleRate); %find(VEpochTimeStamp >= minLatency_ms, 1, 'first');
c_nPostResponsePlotSamples = round(0.4 * nSampleRate);
c_VidxDataRangeAroundResponse = [-c_nPreResponsePlotSamples+1:c_nPostResponsePlotSamples];
c_nResponseLockedPlotSamples = length(c_VidxDataRangeAroundResponse);
c_VResponseLockedTimes_ms = c_VidxDataRangeAroundResponse * (1000/nSampleRate);


% per electrode plots
for iPlotCol = 1:c_nSignalsToPlot
  
  if iPlotCol <= c_nEEGChannelsToPlot
    bPlottingEEGChannel = true;
    MEpochSignalData = MEpochEEGChannelData;
    VidxSignalsToPlot = CViEEGChannelAveragesToPlot{iPlotCol};
  else
    bPlottingEEGChannel = false;
    MEpochSignalData = MEpochICAComponentData;
    VidxSignalsToPlot = ViICAComponentsToPlot(iPlotCol - c_nEEGChannelsToPlot);
  end
    
  % electrode location / component scalp maps
  if bPlottingEEGChannel
    subplotGM(c_nSubplotRows, c_nSubplotCols, c_iSortedEpochPlotRow-1, iPlotCol)
    topoplot([], SChannelLocations, ...
      'plotchans', VidxSignalsToPlot, ...
      'style', 'blank', 'electrodes', 'labels');
    axis([-1 1 -1 1] * .6)
  else
    subplotGM(c_nSubplotRows, c_nSubplotCols, 1, iPlotCol)
    topoplot(MInvertedICAWeights(:, VidxSignalsToPlot), SChannelLocations, ...
      'maplimits', c_vTopoPlotMapLimitValue, 'electrodes', 'off');
    title(sprintf('ICA #%d', VidxSignalsToPlot))
    subplotGM(c_nSubplotRows, c_nSubplotCols, 2, iPlotCol)
    topoplot(MICAWeights(VidxSignalsToPlot, :), SChannelLocations, ...
      'maplimits', c_vTopoPlotMapLimitValue, 'electrodes', 'off');
    title(sprintf('ICA #%d unm.', VidxSignalsToPlot))
  end
  
  % all epochs, sorted by response latency
  %   pop_erpimage(SEEGEpoched, 1, [30], [[]], 'POz', 5, 1, {'1'}, [], 'latency' ,'yerplabel','\muV','erp','on','cbar','on','topo', { [30] SChannelLocations SEEGEpoched.chaninfo } );
  subplotGM(c_nSubplotRows, c_nSubplotCols, c_iSortedEpochPlotRow, iPlotCol)
  MData = mean(MEpochSignalData(VidxSignalsToPlot, :, :), 1);
  if isempty(c_VERPPlotLimits)
    vCAxis = 1;
    sCBarSetting = 'off';
  else
    vCAxis = c_VERPPlotLimits;
    sCBarSetting = 'on';
  end
  erpimage(MData, VResponseLatencies' * 1000, ...
    VEpochTimeStamp * 1000, [], 10, 1, 'cbar', sCBarSetting, 'cbar_title', c_sERPUnit, ...
    'caxis', vCAxis);
%   if ~bPlotResponseLockedScalpMaps
%     % plot colorbar
%   end
  
  % time-locked averages per trial type
  for idxPlotTrialID = 1:c_nPlotTrialIDs
    iPlotTrialID = c_ViPlotTrialIDs(idxPlotTrialID);
    ViPlotEpochs = find(ViEpochTrialIDs == iPlotTrialID);
    nPlotEpochs = length(ViPlotEpochs);
    MPlotEpochData = squeeze(mean(MEpochSignalData(VidxSignalsToPlot, :, ViPlotEpochs), 1))';
    % stimulus-locked plot
    subplotGM(c_nSubplotRows, c_nSubplotCols, c_iSortedEpochPlotRow+1, iPlotCol)
    hold on
    hLine = plot(VEpochTimeStamp * 1000, mean(MPlotEpochData), '-', 'LineWidth', 1, 'Color', c_CMPlotTrialRGB{idxPlotTrialID});
    hLine.Color(4) = 0.5;
    set(gca, 'XLim', [-500 3000])
    if ~isempty(c_VERPPlotLimits)
      set(gca, 'YLim', c_VERPPlotLimits)
    end
    plot([0 0], get(gca, 'YLim'), 'k-', 'LineWidth', 1)
    xlabel('Time (ms)')
    if iPlotCol == 1
      ylabel(sprintf('ERP (%s)', c_sERPUnit))
    end
    % response-locked plot
    MResponseLockedEpochData = NaN * ones(nPlotEpochs, c_nResponseLockedPlotSamples);
    for idxPlotEpoch = 1:nPlotEpochs
      iPlotEpoch = ViPlotEpochs(idxPlotEpoch);
      idxEpochResponseSample = VidxResponseSamples(iPlotEpoch);
      MResponseLockedEpochData(idxPlotEpoch, :) = ...
        MPlotEpochData(idxPlotEpoch, idxEpochResponseSample + c_VidxDataRangeAroundResponse);
    end % idxPlotEpoch for loop
    subplotGM(c_nSubplotRows, c_nSubplotCols, c_iSortedEpochPlotRow+2, iPlotCol)
    hold on
    hLine = plot(c_VResponseLockedTimes_ms, mean(MResponseLockedEpochData), '-', 'LineWidth', 1, 'Color', c_CMPlotTrialRGB{idxPlotTrialID});
    hLine.Color(4) = 0.5;
    set(gca, 'XLim', [-1200 500])
    if ~isempty(c_VERPPlotLimits)
      set(gca, 'YLim', c_VERPPlotLimits)
    end
    plot([0 0], get(gca, 'YLim'), 'k-', 'LineWidth', 1)
    xlabel('Time rel. to resp. (ms)')
    if iPlotCol == 1
      ylabel(sprintf('ERP (%s)', c_sERPUnit))
    end
  end % idxPlotTrialID for loop
  
end % iPlotCol for loop

if bPlotResponseLockedScalpMaps
  % response-locked scalp maps
  for iLatency = 1:length(c_VScalpMapLatencies_ms)
    MEpochChannelDataAtLatency = NaN * ones(nEpochs, nDataChannels);
    for iEpoch = 1:nEpochs
      idxThisEpochLatencySample = ...
        find(VEpochTimeStamp*1000 >= VResponseLatencies(iEpoch)*1000 + c_VScalpMapLatencies_ms(iLatency), 1, 'first');
      MEpochChannelDataAtLatency(iEpoch, :) = ...
        MEpochEEGChannelData(1:nDataChannels, idxThisEpochLatencySample, iEpoch);
    end
    subplotGM(c_nSubplotRows, c_nSubplotCols, iLatency, c_nSubplotCols)
    topoplot(mean(MEpochChannelDataAtLatency), SChannelLocations, ...
      'maplimits', c_vTopoPlotMapLimitValue);
    VXLim = get(gca, 'XLim');
    VYLim = get(gca, 'YLim');
    text(mean(VXLim), VYLim(2), sprintf('%d ms\nresponse locked', ...
      c_VScalpMapLatencies_ms(iLatency)), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom')
  end % iLatency for loop
  hColorBar = colorbar('EastOutside');
  hColorBar.Position = [0.9275    0.7326    0.0117    0.1713];
  hColorBar.Label.String = c_sERPUnit;
end