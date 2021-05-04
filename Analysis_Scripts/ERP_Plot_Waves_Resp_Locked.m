%{
ERP_Plot_Stim_Locked
Author: Tom Bullock
Date: 02.05.21

Compare Bl, Tx and Ct ERPs within each stress condition

%}

clear
close all

% set EEGLAB Path (if not already set)
eeglabDir = '/bigboss/BOSS/Dependencies/eeglab14_1_1b';

if ~exist('eeglab.m')
    cd(eeglabDir);eeglab;clear;close all;cd ..
else
    %eeglabDir = '/Users/natal/OneDrive/Documents/Lab/BOSS/EEG_Exp_Template/eeglab2019_1'
    eeglabDir = '/bigboss/BOSS/Dependencies/eeglab14_1_1b';
end

% set directories
rDir = '/bigboss/PROJECTS/RIT'; % note new project folder (RIT)
sourceDir = [rDir '/' 'Data_Compiled_Tom']; % final stage EEG preprocessed data
destDirectoryERPs = [rDir '/' 'Data_Compiled_Tom']; % compiled ERPs
plotDir = [rDir '/' 'Plots_Tom'];

% add dependencies to paths
addpath(genpath([rDir '/' 'Dependencies']))

% plot different trial types
for iTrialType=1:3
    
    % set up full screen figure
    h=figure('units','normalized','outerposition',[0 0 1 1]);
    
    for iStress=1:4
        
        % load data
        load([sourceDir '/' sprintf('ERP_master_resp_locked_cond%02d.mat',iStress)])
        
        % set scalp channels (electrodes) to plot
        %theseChannelLabels = {'POz','P3','P4'}; % parietal channels
        theseChannelLabels = {'Pz','P1','P2','CPz','CP1','CP2','FCz','FC1','FC2'};%'POz','PO3','PO4'
        
        channelIndex = EEG_ATTLAB_Channel_Index_Finder2(chanlocs,theseChannelLabels);
        
        % get actual times (s) from EEG mat
        theseTimes = times;
        
        % generate averaged ERPs
        erp_nogo_all_avg = squeeze(mean(mean(ERP.erp_nogo_all(:,:,channelIndex,:),1),3));
        erp_nogo_human_avg = squeeze(mean(mean(ERP.erp_nogo_human(:,:,channelIndex,:),1),3));
        erp_nogo_repeat_avg = squeeze(mean(mean(ERP.erp_nogo_repeat(:,:,channelIndex,:),1),3));
        
        % generate ERPs SEMs (for plotting shaded error bars)
        erp_nogo_all_sem = squeeze(std(mean(ERP.erp_nogo_all(:,:,channelIndex,:),3),1)./sqrt(size(ERP.erp_nogo_all,1)));
        erp_nogo_human_sem = squeeze(std(mean(ERP.erp_nogo_human(:,:,channelIndex,:),3),1)./sqrt(size(ERP.erp_nogo_human,1)));
        erp_nogo_repeat_sem = squeeze(std(mean(ERP.erp_nogo_repeat(:,:,channelIndex,:),3),1)./sqrt(size(ERP.erp_nogo_repeat,1)));
        
        
        for iCond=1:3
            subplot(2,2,iStress)
            
            if iCond==1
                thisColor = 'b';
            elseif iCond==2
                thisColor = 'r';
            elseif iCond==3
                thisColor = 'g';
            end
            
            if iTrialType==1
                theseDataMean = erp_nogo_all_avg;
                theseDataSEM = erp_nogo_all_sem;
                thisTitle = 'nogo_all';
            elseif iTrialType==2
                theseDataMean = erp_nogo_human_avg;
                theseDataSEM = erp_nogo_human_sem;
                thisTitle = 'nogo_human';
            elseif iTrialType==3
                theseDataMean = erp_nogo_repeat_avg;
                theseDataSEM = erp_nogo_repeat_sem;
                thisTitle = 'nogo_repeat';
            end
            
            h.Name = thisTitle;
            
            % regular line plot
            %plot(times,theseDataMean(iCond,:),'color',thisColor,'linewidth',3); hold on
            
            % shaded error bar plot
            shadedErrorBar(times,theseDataMean(iCond,:),theseDataSEM(iCond,:),{'color',thisColor,'linewidth',3},1); hold on
            
            set(gca,'xlim',[-500,800],'ylim',[-6,12],'box','off','fontsize',18); hold on
            
            title('ERP Plots');
            
        end
        
        
        line([0,0],[-100,100],'Color','k');
        line([-500,800],[0,0],'Color','k'); hold on
        
        %legend('Base','Tx','Ct');
        
    end
    
    %h=gcf;
    saveas(h,[plotDir '/' 'ERP_Plot_Resp_Locked_' thisTitle '.jpg'],'jpeg')
    
end