# RIT

Scripts for analyzing BOSS Response Inhibition Task (RIT) data

Authors: Tom Bullock, Natalie Juo, Anabel Salimian

Date created:04.28.21

Notes:

Uses scripts from my other Response_Inhibition repo (Tom).  Import these.

## DATA

Data can be downloaded here [eventually add link to box folder]

## BEHAVIOR


## EEG

`EEG_Prepro1.m` Imports the raw EEG data, resamples, performs channel rejection and separates scalp/aux channels.  Saves in MASTER structure. DOES NOT FILTER OR REF!

`EEG_Prepro2.m` Grabs data from BOSS MASTER structure, imports any missing event codes, imports trial data and checks for EEG/BEH trial consistency and corrects if possible.

`EEG_Prepro3_Stim_Locked.m` Reference, filter, interpolate bad channels, do eyeblink and artifact rejection

`EEG_Compute_ERPs_Stim_Locked.m` Compiles stim-locked EEG data from all subjects and conditions into "master" matrices (one file per condition)

