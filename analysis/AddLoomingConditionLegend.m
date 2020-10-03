
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



hConditionLegend = axes;
cla

c_VDistances = unique(c_VTrialInitialDistances);
c_VDecelerations = unique(c_VTrialDecelerations);

c_VSnippetAngleEndPoints = (360 - [45 10]) * pi / 180;
c_VSnippetAngles = linspace(c_VSnippetAngleEndPoints(1), c_VSnippetAngleEndPoints(2), 20);
c_VSnippetRadius = 1;
VSnippetX = c_VSnippetRadius * cos(c_VSnippetAngles);
VSnippetY = c_VSnippetRadius * sin(c_VSnippetAngles);
VSnippetX = VSnippetX - mean(VSnippetX);
VSnippetY = VSnippetY - mean(VSnippetY);

% lines
for iDistance = 1:2
  for iDeceleration = 1:2
    distance = c_VDistances(iDistance);
    deceleration = c_VDecelerations(iDeceleration);
    iCondition = find(c_VTrialInitialDistances == distance & ...
      c_VTrialDecelerations == deceleration);
    assert(length(iCondition) == 1)
    x = iDistance;
    y = iDeceleration;
    plot(x + VSnippetX, y + VSnippetY, '-', ...
      'Color', c_CMConditionRGB{iCondition}, 'LineWidth', c_stdLineWidth * 1.5)
    hold on
  end
end

% text
for iDistance = 1:2
  x = iDistance;
  y = 2.9;
  text(x, y, sprintf('%d m', c_VDistances(iDistance)), ...
    'FontSize', c_stdFontSize, 'FontName', c_sFontName, ...
    'HorizontalAlignment', 'center')
end
for iDeceleration = 1:2
  x = -0.3;
  y = iDeceleration;
  text(x, y, sprintf('%.2f m/s^2', c_VDecelerations(iDeceleration)), ...
    'FontSize', c_stdFontSize, 'FontName', c_sFontName, ...
    'HorizontalAlignment', 'center')
end

% finish off
axis([-1.6 2.8 0 3.7])
hConditionLegend.Box = 'on';
hConditionLegend.XTick = [];
hConditionLegend.YTick = [];

