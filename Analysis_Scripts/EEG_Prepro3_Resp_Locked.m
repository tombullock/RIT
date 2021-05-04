%{
EEG_Prepro3_Resp_Locked
Author: Tom Bullock, UCSB Attention Lab (using Neil Dundon's filter
function)
Date: 05.02.21

Grabs imported, preprocessed continuous data, the applies epoching and
artifact rejection...

%}

clear 
close all

% set dirs
sourceDir = '/bigboss/PROJECTS/RIT/EEG_Prepro2';
destDir = '/bigboss/PROJECTS/RIT/EEG_Prepro3_Resp_Locked';

% load vector of subject numbers
[subjects,subsMissingBehData] = subjectInfo_RI;

% % get rid of bad subjects (these are specific to response epoching)
% subjects(find(subjects==127))=[];
% subjects(find(subjects==123))=[];
% subjects(find(subjects==120))=[];
% subjects(find(subjects==111))=[];

% run through all files, epoch and apply artifact rej/corr
d =dir([sourceDir '/' '*.mat']);

for iFile=1:length(d)
    
    try
    
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
    
    
    
    
    % create large epoch
    EEG = pop_epoch(EEG,{11,12,13,110},[-.5, 1.8]);
    
    % now epoch around each response and remove baseline %WHY BREAKING?
    EEG = pop_epoch(EEG,{25},[-.5,.8]); % must be 1 sec less than original epoch (e.g. if 1.8, then .8)
    EEG = pop_rmbase(EEG,[-500 -300]); % remove baseline 
    
    % edit beh file length to match shorterned EEG file if needed
    sjNum = str2double(d(iFile).name(3:5));
    iCond = str2double(d(iFile).name(9:10));
    if sjNum==133 &&iCond==1
        BEH.trialMat(252:end,:) = [];
    elseif sjNum==120 && iCond==1
        BEH.trialMat(204:end,:) = [];
    elseif sjNum==111 && iCond==2
        BEH.trialMat(226:end,:) = [];
    elseif sjNum==104 && iCond==2
        BEH.trialMat(415:end,:) = [];
    end
    
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
    
    
    
%     % do artifact rejection
%     EEG = pop_epoch(EEG,{11,12,13,110},[-.2, 1]);
%     EEG = pop_rmbase(EEG,[-200,0]);
    
    % do artifact rejection (eyeblink,chan, extreme)
    rejThresholdValues=[-150,150]; % extreme values thresholds
    rejThresholdTimes = [-.5, .8]; % apply rejection to these times in epoch
    
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
    
    catch
        
        disp(['Unable to process ' d(iFile).name ])
        
    end
    
end