
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
  LoomingDetectionStudy_InitAfterStartingPTB(SConstants, SStates)


% prepare car image texture
% (..., optimizeForDrawAngle = 0, specialFlags = 1 [create as OpenGL
% texture of type GL_TEXTURE_2D, to allow mipmap scaling])
SConstants.iCarImageTexture = ...
  Screen('MakeTexture', SConstants.pWindow, 1 * SConstants.MCarImageRGBA, 0, 1);


% % get dot car arrays for all initial car distances
% for iInitialCarDistance = 1:SConstants.nInitialCarDistances
%   initialCarWidthOnScreen = ...
%     SConstants.screenViewingDistance * SConstants.carWidth / ...
%     SConstants.VInitialCarDistances(iInitialCarDistance);
%   initialCarFractionOfScreenWidth = ...
%     initialCarWidthOnScreen / SConstants.screenWidth;
%   initialCarWidthPixels = ...
%     initialCarFractionOfScreenWidth * SConstants.nScreenWidthPixels;
%   nCarWidthDots = round(initialCarWidthPixels / ...
%     (SConstants.dotSpacingInDotWidths * SConstants.iDotSize));
%   [VDotCarX, VDotCarY, MDotCarColor] = GetImageAsDotArray(...
%     SConstants.MCarImageRGBA(:, :, 1:3), SConstants.MCarImageRGBA(:, :, 4), ...
%     nCarWidthDots);
%   MWhiteDotCarColor = ones(size(MDotCarColor));
%   MDotCarColor = (1 * MDotCarColor + 0 * MWhiteDotCarColor);
%   SConstants.SDotCars(iInitialCarDistance).VDotX = VDotCarX';
%   SConstants.SDotCars(iInitialCarDistance).VDotY = VDotCarY';
%   SConstants.SDotCars(iInitialCarDistance).MDotColor = round(255 * MDotCarColor');
%   SConstants.SDotCars(iInitialCarDistance).nWidthInDots = max(VDotCarX);
%   SConstants.SDotCars(iInitialCarDistance).nHeightInDots = max(VDotCarY);
% end % iInitialCarDistance for loop


% audio init
% -- initialize sound driver
InitializePsychSound(1);
% -- open Psych-Audio port, with the follow arguements
% (1) [] = default sound device
% (2) 1 = sound playback only (not recording)
% (3) 1 = default level of latency; 3 = take over audio device completely,
%         with aggressive settings
% (4) Requested frequency in samples per second
% (5) 2 = stereo putput
c_audioFrequency = 44100;%6000;
SConstants.iPTBAudioHandle = PsychPortAudio('Open', [], 1, 3, c_audioFrequency, 2);
% -- set the volume 
PsychPortAudio('Volume', SConstants.iPTBAudioHandle, 0.5);
% -- make the needed beeps
% (1) frequency (Hz)
% (2) duration (s)
% (3) audio channel frequency (Hz)
% -- a nice little sine
SConstants.VStimulusOnsetBeep = 0.2 * MakeBeep(880, 0.2, c_audioFrequency);
% -- three blips of a saturated sine
VIncorrectBeep = 4 * MakeBeep(330, 0.1, c_audioFrequency);
VIncorrectBeep(VIncorrectBeep > 1) = 1;
VIncorrectBeep(VIncorrectBeep < -1) = -1;
VIncorrectBeep = [VIncorrectBeep zeros(1, length(VIncorrectBeep))];
SConstants.VIncorrectResponseBeep = repmat(VIncorrectBeep, 1, 3);


% flag for exiting the program
SStates.bQuitStudy = false;



