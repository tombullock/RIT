%{
EEG_Compute_ERPs_Stim_Locked
Author: Tom Bullock, UCSB Attention Lab
Date created: 10.27.20 (last updated 05.02.21)

Notes:

Trial data are in EEG.trialMat.  Important column headings are:
col3 = trial number
col4 = stimulus type (100 = go, 2 = go, 1 = no-go person, 3 = repeat)
col5 = response (0=no press, 16=press)
col6 = RT
col7 = image code

For previous ERP scripts (many useful notes on subject exceptions for RIT):
/Users/tombullock/Documents/Psychology/ATTLAB_Repos/EEG_Exp_Template/Scripts_Old/fromProjects/Analysis_Scripts/EEG_Compile_ERPs_TargetLocked.m


%}

clear
close all

% set EEGLAB Path (if not already set)
%eeglabDir = '/Users/natal/OneDrive/Documents/Lab/BOSS/EEG_Exp_Template/eeglab2019_1';
eeglabDir = '/bigboss/BOSS/Dependencies/eeglab14_1_1b';

if ~exist('eeglab.m')
    cd(eeglabDir);eeglab;clear;close all;cd ..
else
    %eeglabDir = '/Users/natal/OneDrive/Documents/Lab/BOSS/EEG_Exp_Template/eeglab2019_1'
    eeglabDir = '/bigboss/BOSS/Dependencies/eeglab14_1_1b';
end

% set directories
%rDir = '/Users/natal/OneDrive/Documents/Lab/BOSS/EEG_Exp_Template';
rDir = '/bigboss/PROJECTS/RIT';
sourceDirEEG = [rDir '/' 'EEG_Prepro3_Stim_Locked']; % final stage EEG preprocessed data
destDirectoryERPs = [rDir '/' 'Data_Compiled_Tom']; % compiled ERPs
plotDir = [rDir '/' 'Plots'];

% add dependencies to path
addpath(genpath([rDir '/' 'Dependencies']))

% stress condition loop
for iCond=1:4
    
    % subjects for processing
    if iCond==1; subjects = [105,108,110,111,114:128,130,132:136,138:140,147:151,154:158,160,161];
    elseif iCond==2; subjects = [201,204,209,212:218,220:223,225,227:234,236,237,239:245];
    elseif iCond==3; subjects = [302:306,308:310,313:318,321:327,329:333,337,339:347];
    elseif iCond==4; subjects = [402:403,406,409:412,414,416,418:420,422:426,428,430:431,433,436:437,439,441,445];
    end
    
    % subject loop
    for iSub=1:length(subjects)
        sjNum = subjects(iSub);
        
        % condition loop
        for iSess=1:3
            
            % load EEG data
            load([sourceDirEEG '/' sprintf('sj%02d_se%02d_ri_prepro3.mat',sjNum,iSess)]);
            
            %         % get index of "eye"components from ICLabel
            %         badIC_idx  = find(EEG.etc.ic_classification.ICLabel.classifications(:,3) >= 0.7); % > 70% chance of occular artifact
            %
            %         % reject bad "eye" components
            %         EEG = pop_subcomp(EEG, badIC_idx, 0,0);
            
            % remove bad trials [threshold rejection]
            EEG = pop_select(EEG,'notrial',EEG.threshRejIdx);
            
            % extract trialMat from structure for ease of coding
            trialMat = EEG.trialMatAR;
            
            % loop through trials
            goCnt=0; nogoCnt=0; %create counters
            for iTrial=1:length(EEG.epoch)
                
                % parse trials depending on whether they are "go" or "nogo"
                if trialMat(iTrial,4)==100 || trialMat(iTrial,4)==2 % if "go" trial
                    goCnt=goCnt+1;
                    erp_go(:,:,goCnt) = EEG.data(:,:,iTrial);
                else % if "nogo" trial
                    nogoCnt=nogoCnt+1;
                    erp_nogo(:,:,nogoCnt) = EEG.data(:,:,iTrial);
                end
                
            end
            
            % average across trials to create ERPs
            ERP.erp_go(iSub,iSess,:,:) = mean(erp_go,3);
            ERP.erp_nogo(iSub,iSess,:,:) = mean(erp_nogo,3);
            
            clear erp_go erp_nogo
            
        end
        
    end
    
    chanlocs = EEG.chanlocs;
    times = EEG.times;
    
    save([destDirectoryERPs '/' sprintf('ERP_master_stim_locked_cond%d.mat',iCond)],'ERP','chanlocs','times')
    
    clear BEH EEG ERP trialMat
    
    
end








% %% quick plot ERPs (compare go and no-go trials)
% 
% chanlocs = EEG.chanlocs;
% times = EEG.times;
% 
% % set scalp channels (electrodes) to plot
% theseChannelLabels = {'POz','P3','P4'}; % parietal channels
% channelIndex = EEG_ATTLAB_Channel_Index_Finder2(chanlocs,theseChannelLabels);
% 
% % get actual times (s) from EEG mat
% theseTimes = times;%EEG.times;
% 
% h=figure('Units','Normalized', 'OuterPosition',[0,0.04,2,0.96]);
% 
% for iSess=1:3
%     subplot(1,3,iSess);
%     % plot grand average ERPs (i.e. averaged over participants)
%     erp_go_avg = squeeze(mean(mean(ERP.erp_go(:,iSess,channelIndex,:),1),3));
%     erp_nogo_avg = squeeze(mean(mean(ERP.erp_nogo(:,iSess,channelIndex,:),1),3));
%     
%     erp_go_avg = smooth(erp_go_avg,10);
%     erp_nogo_avg = smooth(erp_nogo_avg,10);
%     
%     line([0,0],[-100,100],'Color',[255,0,0]./255); hold on
%     line([-200,1000],[0,0]);
%     
%     plot(theseTimes,erp_go_avg,...
%         'LineWidth',1.5,...
%         'Color','g'); hold on
%     plot(theseTimes,erp_nogo_avg,...
%         'LineWidth',1.5,...
%         'Color','r');
%     
%     set(gca,'box','off','fontsize',18,'xlim',[-200,1000],'ylim',[-10,10],'xtick',-200:200:1000);%
%     pbaspect([2,1,1]);
%     
%     if iSess==1
%         thistitle='Baseline';
%     elseif iSess==2
%         thistitle='Treatment';
%     elseif iSess==3
%         thistitle='Control';
%     end
%     
%     title(thistitle);
% end
% 
% saveas(h,[plotDir '/' 'ERP_Plot_3conditions.jpg'],'jpeg')