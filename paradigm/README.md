This is a MATLAB implementation of a looming detection paradigm. See the `README.md` in the root of this repository for links to more information about the paradigm itself, and the results obtained from it. The behavioural and EEG data we collected using this paradigm is available from this OSF repository: https://doi.org/10.17605/OSF.IO/KU3H4. The subfolder `experimenter docs` in that repository contains the participant information sheet and experimenter script that were used in our study.

Running this paradigm implementation requires:
* PsychToolbox-3 (the paradigm code is verified to work with v3.0.14) for generating the visual stimuli. Download and installation instructions available here: http://psychtoolbox.org/
* If sending parallel port trigs to a separate EEG recording computer: The io64 MATLAB utility for port I/O (the inp.m, outp.m, and config_io.m files in this repository are part of this utility). Download and installation instructions available here: http://apps.usd.edu/coglab/psyc770/IO64.html 
* On our computers, to solve a problem with choppy playback of the "beep" sounds that are part of the paradigm, we needed to install the ASIO4All sound drivers (http://www.asio4all.org/).

To run the paradigm, use `do_RunOneParticipant.m`. This script will prompt you for a string to use as participant ID; this string will then be included in the names of the generated log files.

If you only want to use/see the visual stimuli without sending any parallel port trigs, set `SStudyConstants.bSendParallelPortTrigs = false;` in `do_RunOneParticipant.m`, and then accept the warning that is given when you run the script.

When the paradigm starts it will first show just a fixation target. Pressing the space bar initiates a few demonstration trials (used when introducing the participant to the paradigm). The participant's task is to press the space bar as soon as they can see the car "coming closer" (i.e., growing on the screen). For further details on our experimental procedure, as mentioned above see our paper and/or the additional documents in the OSF data repository.