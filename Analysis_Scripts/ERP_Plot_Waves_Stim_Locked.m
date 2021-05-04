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
for iTrialType=1:2
    
    % set up full screen figure
    h=figure('units','normalized','outerposition',[0 0 1 1]);
    
    for iStress=1:4
        
        % load data
        load([sourceDir '/' sprintf('ERP_master_stim_locked_cond%d.mat',iStress)])
        
        % set scalp channels (electrodes) to plot
        %theseChannelLabels = {'POz','P3','P4'}; % parietal channels
        theseChannelLabels = {'Pz','P1','P2','POz','PO3','PO4','Oz','O1','O2'};
        
        channelIndex = EEG_ATTLAB_Channel_Index_Finder2(chanlocs,theseChannelLabels);
        
        % get actual times (s) from EEG mat
        theseTimes = times;
        
        % generate averaged ERPs
        erp_go_avg = squeeze(mean(mean(ERP.erp_go(:,:,channelIndex,:),1),3));
        erp_nogo_avg = squeeze(mean(mean(ERP.erp_nogo(:,:,channelIndex,:),1),3));
        
        % generate ERPs SEMs (for plotting shaded error bars)
        erp_go_sem = squeeze(std(mean(ERP.erp_go(:,:,channelIndex,:),3),1)./sqrt(size(ERP.erp_go,1)));
        erp_nogo_sem = squeeze(std(mean(ERP.erp_nogo(:,:,channelIndex,:),3),1)./sqrt(size(ERP.erp_nogo,1)));
        
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
                theseDataMean = erp_go_avg;
                theseDataSEM = erp_go_sem;
                thisTitle = 'go';
            else
                theseDataMean = erp_nogo_avg;
                theseDataSEM = erp_nogo_sem;
                thisTitle = 'go';
            end
            
            % regular line plot
           %plot(times,theseDataMean(iCond,:),'color',thisColor,'linewidth',3); hold on

            % shaded error bar plot
            shadedErrorBar(times,theseDataMean(iCond,:),theseDataSEM(iCond,:),{'color',thisColor,'linewidth',3},1); hold on
            
            set(gca,'ylim',[-5,10],'box','off','fontsize',18); hold on
            
            title('ERP Plots');
            
            
            
        end
        
        %legend('Base','Tx','Ct');
        line([0,0],[-100,100],'Color','k');
        line([-200,1000],[0,0],'Color','k'); hold on
        
    end
    
    %h=gcf;
    saveas(h,[plotDir '/' 'ERP_Plot_Stim_Locked_' thisTitle '.jpg'],'jpeg')
    
end