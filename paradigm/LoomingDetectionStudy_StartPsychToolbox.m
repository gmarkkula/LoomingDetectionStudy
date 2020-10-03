
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


function [SConstants, SStates] = ...
  LoomingDetectionStudy_StartPsychToolbox(SConstants, SStates)

% font size
Screen('Preference', 'DefaultFontSize', 32);

% open the Psychtoolbox screen
ViScreens = Screen('Screens');
if length(ViScreens) > 1
  iScreenNumber = ViScreens(2);
else
  iScreenNumber = ViScreens(1);
end
SConstants.pWindow = Screen('OpenWindow', iScreenNumber, 0);

% blending
Screen('BlendFunction', SConstants.pWindow, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% key names
KbName('UnifyKeyNames');

% optimise display
Priority(MaxPriority(SConstants.pWindow));
HideCursor; % Hide the mouse cursor
ShowHideWinTaskbarMex(0); % Hide the windows task bar

% get some info about the screen from Psychtoolbox
SConstants.iWhiteIndex = WhiteIndex(SConstants.pWindow);
[SConstants.nScreenWidthPixels, SConstants.nScreenHeightPixels] = ...
  Screen('WindowSize', SConstants.pWindow);
SConstants.screenHeight = ...
  SConstants.nScreenHeightPixels * SConstants.screenWidth / ...
  SConstants.nScreenWidthPixels;
SConstants.monitorFlipInterval = ...
  Screen('GetFlipInterval', SConstants.pWindow);

% do first flip
SStates.vblTimeStamp = Screen('Flip', SConstants.pWindow);




