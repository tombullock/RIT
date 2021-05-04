%function EEG_Preprocessing2

%{
EEG_Preprocessing2_Resp_Locked
Author: Tom Bullock, UCSB Attention Lab
Date: 11.30.19

Pre-process all EEG data (describe steps)
See end of script for snipped for processing aux data (write into separate
script or below this one)?

Once we agree upon a processing pipeline for the rest of the data, move
this to another non-project-specific folder so that it's easily accessible
and can be ran on other data.

On rare occasions TP9 and TP10 may be interpolated.  Ok to use as ref
chans?  What's the alternative apart from always using avg ref?

%}

clear 

%% set dirs and dependencies
rDir = '/bigboss/MASTER';
scriptsDir = '/bigboss/BOSS/Projects/Response_Inhibition/Analysis_Scripts';
sourceDirAudit = '/data/DATA_ANALYSIS/BOSS_PREPROCESSING/AUDIT/Combined_EYE_EEG_PHYSIO_MARKERS'; % still a work in progress - move this eventually

eeglabDir = '/bigboss/BOSS/Dependencies/eeglab14_1_1b';
cd(eeglabDir)
eeglab
close all
cd (scriptsDir)

%% set prepro2 dir
%destDir = '/bigboss/BOSS/Projects/Response_Inhibition/EEG_Resp_Epoched';
destDir = '/bigboss/PROJECTS/RI/EEG_Prepro2_Resp';

%% set task data to process (must match folder name - could make this do multiple tasks if needed)
task = 'ri';

%% do artifact rejection (eyeblink,chan, extreme)
rejThresholdValues=[-150,150]; % extreme values thresholds
rejThresholdTimes = [-.5, .8]; % apply rejection to these times in epoch

%% load vector of subject numbers
[subjects,subsMissingBehData] = subjectInfo_RI;

%% get rid of bad subjects (response epoching specific)
subjects(find(subjects==127))=[];
subjects(find(subjects==123))=[];
subjects(find(subjects==120))=[];
subjects(find(subjects==111))=[];

%% show rejected trials? (useful if high trial rej)
showRejTrials = 0;

% create cnt
skippedCnt=0;

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
        
        % create dir path (EEG data at preprocessed1 stage)
        prepro1_path = [rDir '/' sessionFolder '/' stressFolder '/' taskFolder '/' 'EEG' '/' 'Prepro1'];
        
        % create new directory to save preprocessed EEG data
        %destDir = [rDir '/' sessionFolder '/' stressFolder '/' taskFolder '/' 'EEG' '/' 'Prepro2'];
        
%         % if directory doesn't already exist, create it
%         if ~exist(destDir)
%             mkdir(destDir)
%         end
        
        % get contents of raw EEG folder
        d=dir([prepro1_path '/' '*.mat']);
        
        % remove subs with missing data (not on subjects list)
        clear tmp
        cnt=0;
        for i=1:length(d)
            if ~ismember(str2double(d(i).name(3:5)),subjects)
                cnt=cnt+1;
                tmp(cnt)=i;
            end
        end
        d(tmp)=[];
        
        
        % loop through files and pre-process
        for iFiles=1:length(d)
            
            try
            
            % load raw data
            load([prepro1_path '/' d(iFiles).name])
            
            % re-reference data (mastoids have different indices on active/passitve systems)
            refChannels = {'TP9','TP10'};
            cnt=0; refChansIdx=[];
            for b=1:length(refChannels)
                for c=1:length(EEG.chanlocs)
                    if strcmp(EEG.chanlocs(c).labels,refChannels{b})
                        cnt=cnt+1;
                        refChansIdx(cnt) = c;
                    end
                end
            end           
            EEG = pop_reref( EEG, refChansIdx ,'keepref','off');

            % import trial info data and change name
            BEH=[];
            sjNumStr = d(iFiles).name(3:5);
            sjNum = str2double(sjNumStr);
            if ~ismember(sjNum,subsMissingBehData)
                trialInfoPath = [rDir '/' sessionFolder '/' stressFolder '/' taskFolder '/' 'BEH' '/' 'Raw'];
                BEH = load([trialInfoPath '/' d(iFiles).name(1:13) '.mat']);
                %BEH = BEH.trialMat;
            end
            
            
            
            %==============================================================
            

            % load AUDIT file (to reclaim missing EEG triggers if needed)
            replaceTriggers=0;
            if sjNum==209 && iCond==2
                load([sourceDirAudit '/' sprintf('sj%d_se%02d.mat',sjNum,iCond) ])
                replaceTriggers=1;
            elseif sjNum==210 && iCond==2
                load([sourceDirAudit '/' sprintf('sj%d_se%02d.mat',sjNum,iCond) ])
                replaceTriggers=1;
            elseif sjNum==219 && iCond==3
                load([sourceDirAudit '/' sprintf('sj%d_se%02d.mat',sjNum,iCond) ])
                replaceTriggers=1;
            elseif sjNum==115 && iCond==3
                load([sourceDirAudit '/' sprintf('sj%d_se%02d.mat',sjNum,iCond) ])
                replaceTriggers=1;
            elseif sjNum==114 && iCond==3
                load([sourceDirAudit '/' sprintf('sj%d_se%02d.mat',sjNum,iCond) ])
                replaceTriggers=1;
            elseif sjNum==329 && iCond==1
                load([sourceDirAudit '/' sprintf('sj%d_se%02d.mat',sjNum,iCond) ])
                replaceTriggers=1;
            elseif sjNum==322 && iCond==1
                load([sourceDirAudit '/' sprintf('sj%d_se%02d.mat',sjNum,iCond) ])
                replaceTriggers=1;
            end
            
            
            EEG.recoveredEvents = 0; % default here is zero
            if replaceTriggers==1
                
                for s=1:length(allMarkers)
                    if strcmp(allMarkers(s).eyeTask,'ri')
                        thisRow=s;
                    end
                end
                
                % get recovered times and trigger codes from AUDIT file
                allTimes = allMarkers(thisRow).eegReconstructedMarkerTimes;
                if sjNum==209
                    allTriggers = allMarkers(thisRow).eyeTriggers;
                else
                    allTriggers = allMarkers(thisRow).eyeTriggersInt;
                end
                
                % downsamples times accordingly (native = 1000Hz)
                allTimes = round(allTimes./(1000/EEG.srate));
                
                for i=1:length(allTimes)
                    EEG.eventR(i).type = allTriggers(i);
                    EEG.eventR(i).latency = allTimes(i);
                    EEG.eventR(i).value = 'Stimulus';
                    EEG.eventR(i).duration = 1;
                    EEG.eventR(i).urevent = 2;
                end
                
                EEG.event = EEG.eventR;
                EEG.recoveredEvents = 1;
                
            end
            
            
            % loop through and fix/replace any R/S/empty codes and convert all
            % from string to double
            if EEG.recoveredEvents==0
                for i=1:length(EEG.event)
                    if ismember(EEG.event(i).type(1),'R') % "R"
                        EEG.event(i).type = 55;
                    elseif ismember(EEG.event(i).type(1),'S') % "S"
                        EEG.event(i).type = str2double(EEG.event(i).type(2:end));
                    elseif ismember(EEG.event(i).type(1),'empty')
                        EEG.event(i).type = 55;
                    else
                        EEG.event(i).type = str2double(EEG.event(i).type);
                    end
                end
            end
            
            
            % epoch data around each trial (make epochs large enough to capture
            % activity relating to errors of commission))
           % EEG = pop_epoch(EEG,{11,12,13,110},[-.2, 1]);
            EEG = pop_epoch(EEG,{11,12,13,110},[-.5, 1.8]);

            %EEG = pop_rmbase(EEG,[-200 -100]);
            
            % edit behavioral file length to match shorterned EEG file if
            % needed
            if sjNum==133 &&iCond==1
                BEH.trialMat(252:end,:) = [];
            elseif sjNum==120 && iCond==1
                BEH.trialMat(204:end,:) = [];
            elseif sjNum==111 && iCond==2
                BEH.trialMat(226:end,:) = [];
            elseif sjNum==104 && iCond==2
                BEH.trialMat(415:end,:) = [];
            end
            
            % now epoch around each response and remove baseline %WHY BREAKING?
            EEG = pop_epoch(EEG,{25},[-.5,.8]); % THIS MUST BE 1 sec less than original epoch (e.g. if 1.8, then .8)
            EEG = pop_rmbase(EEG,[-500 -300]); %% ***********CHANGE??********
            
            % remove non-responses (i.e. no-go) from the beh trial mat
            if ~ismember(sjNum,subsMissingBehData)
                cnt=0;
                for a=1:length(BEH.trialMat)
                    if BEH.trialMat(a,6)~=-1
                        cnt=cnt+1;
                        EEG.trialMatResponseOnly(cnt,:) = BEH.trialMat(a,:);
                    end
                end
            end
            
            BEH.trialMat = EEG.trialMatResponseOnly;
            
            
            
            %%% NEED TO MAKE SURE THESE ARE CORRECLTY ALIGNED@!@!!!!!
            
            % need to remove the final trial from behavior mat because the
            % final trial is cut off too early in the EEG
            if size(EEG.trialMatResponseOnly,1)-1==length(EEG.epoch)
                EEG.trialMatResponseOnly(end,:) = [];
                disp('Trial Mat Larger than EEG epochs')
            end
            
            if ~ismember(sjNum,subsMissingBehData)
                if size(EEG.trialMatResponseOnly,1)==length(EEG.epoch)
                    disp('Beh and EEG consistent')
                else
                    disp('Beh and EEG INCONSISTENT!!! ABORT!!!')
                    return
                end
            end
            
            
            
            
            
            
            
            
            % add behavior to EEG structure (assuming size consistency)
            if ~ismember(sjNum,subsMissingBehData)
                if EEG.trials==length(BEH.trialMat)
                    EEG.trialMatOriginal = BEH.trialMat;
                else
                    disp('EEG and BEH TRIAL COUNTS NOT CONSISTENT!')
                    %return
                end
            end
            
        %% REACTIVE THIS ONCE TRIAL CHECK COMPLETE  
            % do eyeblink artifact correction based on EOG channels
            EOGchans = {'Fp1','Fpz','Fp2'};
            EOG_chan_index = [];
            cnt=0;
            for iChan=1:length(EEG.chanlocs)
                if ismember(EEG.chanlocs(iChan).labels,EOGchans)
                    cnt=cnt+1;
                    EOG_chan_index(cnt) = iChan;
                end
            end
            EEG = pop_crls_regression(EEG,EOG_chan_index,1,0.9999,0.01,[]);
            
            % do threshold based artifact rejection on critical electrodes 
            % [not too far from center to reduce number of rejected trials]
            chansForThresholdRej = {
                'Fz','F1','F2','F3','F4',...
                'FCz','FC1','FC2','FC3','FC4',...
                'Cz','C1','C2','C3','C4',...
                'CPz','CP1','CP2','CP3','CP4',...
                'Pz','P1','P2','P3','P4',...
                'POz','PO3','PO4',...
                'Oz','O1','O2'};
            
            chansForThresholdRejIdx = [];
            cnt=0;
            for iChan=1:length(EEG.chanlocs)
                if ismember(EEG.chanlocs(iChan).labels,chansForThresholdRej)
                    cnt=cnt+1;
                    chansForThresholdRejIdx(cnt) = iChan;
                end
            end
            
            if showRejTrials==0
                [EEG threshRejIdx]  = pop_eegthresh(EEG, 1, chansForThresholdRejIdx, rejThresholdValues(1) , rejThresholdValues(2), rejThresholdTimes(1),rejThresholdTimes(2), 1, 0);
            else
                [EEG threshRejIdx]  = pop_eegthresh(EEG, 1, chansForThresholdRejIdx, rejThresholdValues(1) , rejThresholdValues(2), rejThresholdTimes(1),rejThresholdTimes(2), 1, 0);
                plotRejThr=trial2eegplot(EEG.reject.rejthresh,EEG.reject.rejthreshE,EEG.pnts,EEG.reject.rejthreshcol);
                rejE=plotRejThr;
                %Draw the data.
                eegplot(EEG.data,...
                    'eloc_file',EEG.chanlocs, ...
                    'srate',EEG.srate,...
                    'events',EEG.event,...
                    'winrej',rejE);
                %break
            end
            
%             % remove artifacts from beh file
%             if ~ismember(sjNum,subsMissingBehData)
%                 EEG.trialMatAR = EEG.trialMatOriginal;
%                 EEG.trialMatAR(threshRejIdx,:)=[];
%             end

            %threshRejIdx = [1,2,3];
            
            EEG.threshRejIdx = threshRejIdx;
            
            nRejTrials = (length(threshRejIdx) / length(EEG.epoch))*100;
            
            % save EEG data
            save([destDir '/' d(iFiles).name(1:13) '_respEpoched.mat'],'EEG','bad_channel_list','nRejTrials','BEH')
            
            clear EEG BEH
            
            catch
               
                skippedCnt=skippedCnt+1;
               skipped_sjs(skippedCnt) = sjNum;
                
            end
            

        end
        
    end
    
end