%{
EEG_Prepro3_Stim_Locked
Author: Tom Bullock, UCSB Attention Lab (using Neil Dundon's filter
function)
Date: 04.28.21

Grabs imported, preprocessed continuous data, the applies epoching and
artifact rejection...

%}

clear 
close all

% set dirs
sourceDir = '/bigboss/PROJECTS/RIT/EEG_Prepro2';
destDir = '/bigboss/PROJECTS/RIT/EEG_Prepro3_Stim_Locked';

% load vector of subject numbers
[subjects,subsMissingBehData] = subjectInfo_RI;

% run through all files, epoch and apply artifact rej/corr
d =dir([sourceDir '/' '*.mat']);

for iFile=1:length(d)
    
    % load data
    load([d(iFile).folder '/' d(iFile).name])
    
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
    
    % filter
    EEG = my_fxtrap(EEG,.1,30,.1,0,0,0); %hp,lp,transition,rectif,smooth, resamp

    % get bad channel indices
    badChannels = EEG.bad_channel_list
    cnt=0; refChansIdx=[];
    for b=1:length(badChannels)
        for c=1:length(EEG.chanlocs)
            if strcmp(EEG.chanlocs(c).labels,badChannels{b})
                cnt=cnt+1;
                badChansIdx(cnt) = c;
            end
        end
    end
    
    % interpolate bad channels using bad channel list from earlier
    EEG = pop_interp(EEG,badChansIdx, 'spherical');
    
    % remove EKG channel (BrainAMP only - may be redundant)
    EEG = pop_select(EEG,'nochannel',{'ECG'});
    
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
    
    % do artifact rejection
    EEG = pop_epoch(EEG,{11,12,13,110},[-.2, 1]);
    EEG = pop_rmbase(EEG,[-200,0]);
    
    % do artifact rejection (eyeblink,chan, extreme)
    rejThresholdValues=[-150,150]; % extreme values thresholds
    rejThresholdTimes = [-.2, 1]; % apply rejection to these times in epoch
    
    % show rejected trials? (useful if high trial rej)
    showRejTrials = 0;
    
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
    
    % remove artifact trials from beh file
    sjNum = str2double(d(iFile).name(3:5));
    if ~ismember(sjNum,subsMissingBehData)
        EEG.trialMatAR = EEG.trialMatOriginal;
        EEG.trialMatAR(threshRejIdx,:)=[];
    end
    
    %threshRejIdx = [1,2,3];
    
    EEG.threshRejIdx = threshRejIdx;
    
    pcRejTrials = (length(threshRejIdx) / length(EEG.epoch))*100;
    
    save([destDir '/' d(iFile).name(1:13) '_prepro3.mat'],'EEG','bad_channel_list','BEH','pcRejTrials')
    
    clear EEG BEH bad_channel_list badChannels badChansIdx chansForThresholdRej chansForThresholdRejIdx threshRejIdx
    
end










