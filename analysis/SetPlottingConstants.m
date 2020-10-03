
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



c_nFinalIncludedParticipants = 22;

c_ViConditionUrgencyOrder = [2 1 4 3]; % the experiment conditions in decreasing urgency order, i.e. condition 2 most urgent looming etc
% c_CMConditionRGB = {[0.9 0 0] [.5 0 0] [1 0.7 0] [1 0.2 0]};
c_CMConditionRGB = {...
  [208 81 74] / 255
  [188 16 56] / 255
  [248 211 111] / 255
  [228 146 93] / 255};
c_CMConditionRGB = {...
  [231 58 49] / 255
  [196 8 52] / 255
  [252 213 105] / 255
  [241 145 80] / 255};
c_stdLineWidth = 2;
c_sFontName = 'Open Sans';
c_stdFontSize = 10;
c_annotationFontSize = 11;
c_largeAnnotationFontSize = 13;
c_panelLabelFontSize = 14;
c_nFullWidthFigure_px = 1100;

c_iABCFitting = 1;
c_iMLEFitting = 2;
c_nFittingMethods = 2;
c_CsFittingMethods = {'ABC' 'MLE'};

c_CCsModelsFitted{c_iABCFitting} = {'T' 'A' 'AV' 'AG' 'AL' 'AVG' 'AVL' 'AGL' 'AVGL'};
c_CCsModelsFitted{c_iMLEFitting} = {'T' 'A' 'AV' 'AG' 'AL'};


c_CCsModelComparisons = {{'T' 'A'} {'A' 'AV'}};
c_nModelComparisons = length(c_CCsModelComparisons);
c_VnParamIncreaseInModelComparisons = [0 1];
c_VExtraColor1RGB = [89 205 144] / 255;
c_VExtraColor2RGB = [63 167 214] / 255;
c_CMModelComparisonRGB = {...
  c_VExtraColor1RGB
  c_VExtraColor2RGB};

c_mleContaminantFractionToPlot = 0.01;

c_VObservedRTCDFQuantiles = .05:.1:.95;
c_VModelRTCDFQuantiles = .025:.025:.975;
c_sRTCDFEmpiricalSymbol = 'o';
c_rtCDFMarkerSize = 6;
c_rtCDFEmpiricalLineWidth = c_stdLineWidth * .75;
c_VRTCDFLegendIllustrationRGB = [1 1 1] * .7;
c_VRTCDFXLim = [0.5 3.8];
c_VRTCDFYLim = [-.1 1.1];

c_MScalpMapColors = [...
    0.1320    0.3520    0.4520
    0.1461    0.3838    0.4689
    0.1608    0.4160    0.4858
    0.1762    0.4486    0.5028
    0.1923    0.4813    0.5197
    0.2091    0.5143    0.5366
    0.2265    0.5472    0.5536
    0.2446    0.5705    0.5610
    0.2634    0.5875    0.5621
    0.2828    0.6044    0.5636
    0.3029    0.6213    0.5654
    0.3237    0.6383    0.5676
    0.3451    0.6552    0.5704
    0.3672    0.6721    0.5739
    0.3900    0.6891    0.5781
    0.4134    0.7060    0.5832
    0.4375    0.7230    0.5892
    0.4623    0.7399    0.5962
    0.4877    0.7568    0.6044
    0.5138    0.7738    0.6139
    0.5406    0.7907    0.6246
    0.5681    0.8076    0.6368
    0.5962    0.8246    0.6506
    0.6249    0.8415    0.6660
    0.6544    0.8585    0.6831
    0.6845    0.8754    0.7020
    0.7153    0.8923    0.7229
    0.7477    0.9093    0.7467
    0.7869    0.9262    0.7788
    0.8252    0.9431    0.8116
    0.8626    0.9601    0.8451
    0.8989    0.9770    0.8792
    0.9340    0.9940    0.9140
    0.9131    0.9868    0.8794
    0.8960    0.9796    0.8453
    0.8826    0.9725    0.8115
    0.8728    0.9653    0.7782
    0.8665    0.9582    0.7453
    0.8636    0.9510    0.7127
    0.8641    0.9438    0.6806
    0.8679    0.9367    0.6489
    0.8749    0.9295    0.6176
    0.8850    0.9223    0.5867
    0.8981    0.9152    0.5562
    0.9080    0.9018    0.5262
    0.9009    0.8684    0.4965
    0.8937    0.8323    0.4672
    0.8865    0.7934    0.4384
    0.8794    0.7518    0.4099
    0.8722    0.7076    0.3819
    0.8651    0.6610    0.3542
    0.8579    0.6119    0.3270
    0.8507    0.5605    0.3002
    0.8436    0.5068    0.2738
    0.8364    0.4509    0.2478
    0.8293    0.3928    0.2222
    0.8221    0.3328    0.1970
    0.8149    0.2708    0.1722
    0.8078    0.2069    0.1478
    0.8006    0.1412    0.1238
    0.7934    0.1002    0.1267
    0.7863    0.0771    0.1494
    0.7791    0.0543    0.1745
    0.7720    0.0320    0.2020];