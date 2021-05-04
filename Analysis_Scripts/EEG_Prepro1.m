%function EEG_Preprocessing1

%{
EEG_Preprocessing1
Author: Tom Bullock, UCSB Attention Lab
Date: 11.30.19

Pre-process all EEG data (describe steps)
See end of script for snipped for processing aux data (write into separate
script or below this one)?

Once we agree upon a processing pipeline for the rest of the data, move
this to another non-project-specific folder so that it's easily accessible
and can be ran on other data.

%}

clear 

%% set dirs and dependencies
rDir = '/bigboss/MASTER';
%scriptsDir = '/bigboss/BOSS/Projects/Response_Inhibition/Analysis_Scripts';
scriptsDir = '/bigboss/PROJECTS/RIT/Analysis_Scripts';
eeglabDir = '/bigboss/BOSS/Dependencies/eeglab14_1_1b';
cd(eeglabDir)
eeglab
close all
cd (scriptsDir)

%% set task data to process (must match folder name - could make this do multiple tasks if needed)
task = 'ri';


% loop through the three sessions (bl,tx,ct)
for iCond=1:3
    
    % loop through the four stressors (CPT, MF, TR, PF)
    for iStressor=1:4
        
        % session names
        if      iCond==1; sessionFolder = 'Baseline';
        elseif  iCond==2; sessionFolder = 'Treatment';
        elseif  iCond==3; sessionFolder = 'Control';
        end
        
        % stressor names
        if      iStressor==1; stressFolder = 'CPT';
        elseif  iStressor==2; stressFolder = 'MF';
        elseif  iStressor==3; stressFolder = 'TR';
        elseif  iStressor==4; stressFolder = 'PF';
        end
        
        % task names
        if      strcmp(task,'ce'); taskFolder = 'Cognitive_Encoding';
        elseif  strcmp(task,'g1'); taskFolder = 'Gambling';
        elseif  strcmp(task,'g3'); taskFolder = 'Gambling';
        elseif  strcmp(task,'g5'); taskFolder = 'Gambling';
        elseif  strcmp(task,'m1'); taskFolder = 'Recognition_Memory';
        elseif  strcmp(task,'m2'); taskFolder = 'Recognition_Memory';
        elseif  strcmp(task,'ri'); taskFolder = 'Response_Inhibition';
        elseif  strcmp(task,'rs'); taskFolder = 'Resting';
        elseif  strcmp(task,'vs'); taskFolder = 'Visual_Search';
        elseif  strcmp(task,'wm'); taskFolder = 'Working_Memory';
        elseif  strcmp(task,'cm'); taskFolder = 'Stressor';
        elseif  strcmp(task,'cn'); taskFolder = 'Stressor';
        elseif  strcmp(task,'cr'); taskFolder = 'Stressor';
        elseif  strcmp(task,'cv'); taskFolder = 'Stressor';
        elseif  strcmp(task,'cf'); taskFolder = 'Stressor';
        elseif  strcmp(task,'nn'); taskFolder = 'Navigation';
        elseif  strcmp(task,'nt'); taskFolder = 'Navigation';
        elseif  strcmp(task,'tr'); taskFolder = 'Stressor';
        elseif  strcmp(task,'mf'); taskFolder = 'Stressor';
        elseif  strcmp(task,'ws'); taskFolder = 'Stressor';
        elseif  strcmp(task,'pf'); taskFolder = 'Stressor';
        elseif  strcmp(task,'pc'); taskFolder = 'Stressor';
        end
        
        % create dir path (raw EEG data)
        rawPath = [rDir '/' sessionFolder '/' stressFolder '/' taskFolder '/' 'EEG' '/' 'Raw'];
        
        % create new directory to save preprocessed EEG data
        savePathEEG = [rDir '/' sessionFolder '/' stressFolder '/' taskFolder '/' 'EEG' '/' 'Prepro1'];
        
        % if directory doesn't already exist, create it
        if ~exist(savePathEEG)
            mkdir(savePathEEG)
        end
        
        % create new directory to save preprocessed AUX electrode data
        savePathAux = [rDir '/' sessionFolder '/' stressFolder '/' taskFolder '/' 'EEG' '/' 'Aux_Channels'];
        
        % if directory doesn't already exist, create it
        if ~exist(savePathAux)
            mkdir(savePathAux)
        end
        
        % get contents of raw EEG folder
        d=dir([rawPath '/' '*.mat']);
        
        % loop through files and pre-process
        for iFiles=1:length(d)
            
            % load raw data
            load([rawPath '/' d(iFiles).name])
            
            % edit channel locations
            EEG=pop_chanedit(EEG, 'lookup',[eeglabDir '/' '/plugins/dipfit2.3/standard_BESA/standard-10-5-cap385.elp']);
            
            % separate scalp and aux channels for active system and create
            % separate dataset for aux channels
            if length(EEG.chanlocs)>64
                EEG_aux = pop_select(EEG,'channel',65:length(EEG.chanlocs));
                EEG = pop_select(EEG,'nochannel',65:length(EEG.chanlocs));
            end
            
            % separate EKG from scalp channels for passive system and
            % create separate dataset for aux channels
            if strcmp(EEG.chanlocs(32).labels,'ECG')
                EEG_aux = pop_select(EEG,'channel',{'ECG'});
                EEG = pop_select(EEG,'nochannel',{'ECG'});
            end
            
            % downsample data from 1000 Hz to 250 Hz (speeds up processing)
            EEG = pop_resample(EEG,250);
            
%             % choose bandpass range and then filter (may want to use
%             % different filter settings for different datasets!)
%             thisFilter = [1,30]; % for ICA based artifact rej, use 1Hz LPF
%             EEG = pop_eegfiltnew(EEG, thisFilter(1), thisFilter(2));


            %{ 
            The whole point of this next part is to filter the data at 1Hz,
            and run it through clear_rawdata to determine the bad channels,
            but then just save the unfiltered data, as we might want to use
            a different filter later in the pipeline
            %}

            % create an EEG Original
            originalEEG = EEG;

            % filter EEG
            EEG = my_fxtrap(EEG,1,30,.1,0,0,0); %hp,lp,transition,rectif,smooth, resamp
            
            % apply cleanline to reduce 60 Hz noise (needs 1Hz hp filt,
            % probably unnecessary if doing 30 Hz lp filt)
            %EEG = pop_cleanline(EEG,'SignalType','Channels','ChanCompIndices',1:EEG.nbchan);
            
            % apply clean_rawdata to identify and remove bad channels
            % (turn off highpass, ASR and window removal criterion)
            % EEG = clean_rawdata(EEG, arg_flatline, arg_highpass, arg_channel, arg_noisy, arg_burst, arg_window, varargin)
            
            EEG = clean_rawdata(EEG,5,-1,.80,4,-1,-1,'WindowCriterionTolerances','off'); 
            
            % interpolate bad channels for consistency across datasets
            EEG.original_chanlocs = originalEEG.chanlocs;
            bad_channels = setdiff({EEG.original_chanlocs.labels},{EEG.chanlocs.labels});
            bad_channel_list = {};
            bad_channel_list = unique(cat(2,bad_channel_list,bad_channels));
            %EEG = pop_interp(EEG,EEG.original_chanlocs, 'spherical');
            originalEEG.bad_channel_list = bad_channel_list;
            
            % just save the original EEG but with the bad channels list
            clear EEG
            EEG = originalEEG;
            
            
            
            % up to step 8 of makoto's processing pipeline
            
            % save EEG and Aux channels
            save([savePathEEG '/' d(iFiles).name(1:end-4) '_pre1.mat'],'EEG','bad_channel_list')
            save([savePathAux '/' d(iFiles).name(1:end-4) '_aux.mat'],'EEG_aux')
            
            clear EEG EEG_aux bad_channels bad_channel_list originalEEG
            
        end
        
    end
    
end




%     % some channels and sessions had messed up channel names that
%     % need correcting (just aux channels for active system)
%     relabelAuxChannels=0;
%     if isequal(d(iFiles).name(3:5),'201');relabelAuxChannels=1;
%     elseif isequal(d(iFiles).name(3:5),'206');relabelAuxChannels=1;
%     elseif isequal(d(iFiles).name(3:5),'203') && isequal(d(iFiles).name(10),'1');relabelAuxChannels=1;
%     elseif isequal(d(iFiles).name(3:5),'207') && isequal(d(iFiles).name(10),'1');relabelAuxChannels=1;
%     elseif isequal(d(iFiles).name(3:5),'207') && isequal(d(iFiles).name(10),'2');relabelAuxChannels=1;
%     elseif isequal(d(iFiles).name(3:5),'210') && isequal(d(iFiles).name(10),'1');relabelAuxChannels=1;
%     end
%     if relabelAuxChannels==1
%         disp('RELABEL AUX CHANS')
%         if isequal(EEG.chanlocs(63).labels,'ACC_X_leg')
%             EEG.chanlocs(63).labels = 'HEOG';
%         end
%         if isequal(EEG.chanlocs(64).labels,'ACC_Y_leg')
%             EEG.chanlocs(64).labels = 'GSR';
%         end
%         if isequal(EEG.chanlocs(65).labels,'ACC_Z_leg')
%             EEG.chanlocs(65).labels = 'ACC_X_leg';
%         end
%     end
%     
%     % check n elects to ensure correction applied where necessary
%     disp([d(iFiles).name '  nchans = ' num2str(size(EEG.chanlocs,2))])
%     nChansStruct(iFiles).nChans = [d(iFiles).name '  nchans = ' num2str(size(EEG.chanlocs,2))];


%end