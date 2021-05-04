%{
Plot_ERPs_Target_Locked
Author: Tom Bullock
Date: 03.15.21
%}

clear
%close all

% source dir
sourceDir = '/bigboss/PROJECTS/RIT/Data_Compiled_Tom';
destDirPlots = '/bigboss/PROJECTS/RIT/Plots_Tom';

% plot different trial types
for iTrialType=1:2
    
    % create topographic plots
    h=figure('units','normalized','outerposition',[0 0 1 1]);
    plotPos=0;
    
    % loop through stress condiitons
    for iCond=1:4
        
        clear chanlocs chanIndices chansForPlot erp_all_trials erp_nogo_all erp_nogo_image erp_nogo_rep erp_std erp_nogo_correct erp_nogo_error theseData
        
        % load data
        load([sourceDir '/' sprintf('ERP_master_resp_locked_cond%02d.mat',iCond)])
        
        % select data for plotting
        if iTrialType==1
            theseData = ERP.erp_nogo_all;
        else
            theseData = ERP.erp_nogo_all;
        end
        
        % select times for plotting
        theseTimes = find(times==300):find(times==700);
        
        % set colormap limits for topo plots
        theseMapLimits = [0,5]; % microvolts
        
        
        %     %% zero out Fp1, Fpz, Fp2 elects (no eye-blink corr on these)
        %     zeroEOGchans = {'Fpz','Fp1','Fp2'};
        %
        %     zeroEOGChansIdx = [];
        %     cnt=0;
        %     for iChan=1:length(chanlocs)
        %         if ismember(chanlocs(iChan).labels,zeroEOGchans)
        %             cnt=cnt+1;
        %             zeroEOGChansIdx(cnt) = iChan;
        %         end
        %     end
        %
        %     theseData(:,:,zeroEOGChansIdx,:) = 0;
        
        
        %% remove mastoids from plotting
        theseMastoids = {'FT9','FT10'};
        
        theseMastoidsIdx = [];
        cnt=0;
        for iChan=1:length(chanlocs)
            if ismember(chanlocs(iChan).labels,theseMastoids)
                cnt=cnt+1;
                theseMastoidsIdx(cnt) = iChan;
            end
        end
        
        theseData(:,:,theseMastoidsIdx,:) = [];
        chanlocs(theseMastoidsIdx) = [];
        
        
        %% generate plots
        for iSession=1:3
            plotPos=plotPos+1;
            subplot(2,6,plotPos)
            topoplot(squeeze(mean(mean(theseData(:,iSession,:,theseTimes),1),4)),chanlocs,'maplimits',theseMapLimits);
            cbar
            if      iCond==1; thisTitle = 'CPT';
            elseif  iCond==2; thisTitle = 'MF';
            elseif  iCond==3; thisTitle = 'TR';
            elseif  iCond==4; thisTitle = 'PF';
            end
            if      iSession==1; seTitle = 'B';
            elseif  iSession==2; seTitle = 'T';
            elseif  iSession==3; seTitle = 'C';
            end
            title([thisTitle '-' seTitle],'fontsize',30)
            
        end
        
    end
    
    % save plots
    saveas(h,[plotDir '/' 'ERP_Plot_Stim_Locked_Topos_' thisTitle '.jpg'],'jpeg')
    
end










%%%% IGNORE %%%%

% %% create ERP plots
% h=figure;
% for iCond=1:4
%     
%     clear chanlocs chanIndices chansForPlot erp_all_trials erp_nogo_all erp_nogo_image erp_nogo_rep erp_std erp_nogo_correct erp_nogo_error theseData
%     
%     %% load data
%     load([sourceDir '/' sprintf('ERPs_Target_Locked_Cond%02d.mat',iCond) ])
%     
%      %% select data for plotting
%     theseData = [];
%     if     whichDataToPlot==1; theseData = ERP.erp_go;
%     elseif whichDataToPlot==2; theseData = ERP.erp_go_correct;
%     elseif whichDataToPlot==3; theseData = ERP.erp_nogo_human;
%     elseif whichDataToPlot==4; theseData = ERP.erp_nogo_repeat;
%     elseif whichDataToPlot==5; theseData = ERP.erp_nogo_all;
%     elseif whichDataToPlot==6; theseData = ERP.erp_nogo_correct_all;
%     elseif whichDataToPlot==7; theseData = ERP.erp_nogo_error_all;
%     elseif whichDataToPlot==8; theseData = ERP.erp_nogo_correct_human;
%     elseif whichDataToPlot==9; theseData = ERP.erp_nogo_error_human;
%     elseif whichDataToPlot==10; theseData = ERP.erp_nogo_correct_repeat;
%     elseif whichDataToPlot==11; theseData = ERP.erp_nogo_error_repeat;
%     end
% 
%     % check for missing data (e.g. if sub made no "human" errors, no data)
%     skipSubIndex = [];
%     for i=1:size(theseData,1)
%         removeThisSubject=0;
%         for j=1:3
%             if sum(sum(theseData(i,j,:,:)))==0
%                 removeThisSubject=1;
%             end
%         end
%         skipSubIndex(i)=removeThisSubject;
%     end
%     
%     % remove sub with missing data
%     theseData(find(skipSubIndex==1),:,:,:)=[];
%     if find(skipSubIndex)~=0
%         disp(['Removing Subject(s): ' num2str(subjects(find(skipSubIndex==1)))])
%     else
%         disp('No Subjects Removed')
%     end
%     
%     %
%     
%     
%     
%     
%     %% which channels to plot?
%     %chansForPlot = [{'Pz'},{'CPz'},{'P1'},{'P2'},{'POz'}]; % typical p3b channels
%     %chansForPlot = [{'POz'},{'Oz'},{'O1'},{'O2'},{'PO3'},{'PO4'}]; % typical p3b channels
%     %chansForPlot = [{'CP1','CPz','CP2','P1','Pz','P2','PO3','POz','PO4'}]; % seem to be large differences here!
%     chansForPlot = {'Oz','O1','O2','PO3','POz','PO4','P1','Pz','P2','CPz','CP1','CP2'};
%     
%     cnt=0;
%     for i=1:length(chanlocs)
%         if sum(strcmp(chanlocs(i).labels,chansForPlot))>0
%             cnt=cnt+1;
%             chanIndices(cnt) = i;
%         end
%     end
%     
%     
%          thisYaxis = [-5,10];
%      thisXaxis = [1,250];
%     
%      %% generate plots for no-go trials only (P3)
%     subplot(2,2,iCond)
%     for iSession=1:3
%         if iSession==1; thisColor = [214,214,214]./255;
%         elseif iSession==2; thisColor = [226,28,44]./255;
%         elseif iSession==3; thisColor = [0,136,255]./255;
%         end
%             
%         plot(squeeze(mean(mean(theseData(:,iSession,chanIndices,1:250),1),3)),...
%             'color',thisColor,...
%             'linewidth',3); hold on
%         xlabel('ms - no go trials','fontsize',18)
%         %errorbar(-200:999,squeeze(mean(mean(erp_nogo_all(:,iSession,theseChans,:),1),3)),squeeze(std(erp_nogo_all(:,iSession,theseChans,:),0,1)/sqrt(size(erp_nogo_all,1)))',thisColor); hold on
%     end
%     
%         
% %     if whichDataToPlot==1||whichDataToPlot==2
% %         thisYaxis = [-5,5];
% %     else
% %         thisYaxis = [-5,10];
% %     end
%     
% 
%     
%     set(gca,...
%         'box','off',...
%         'fontsize',24,...
%         'linewidth',1.5,...
%         'XTick',linspace(1,250,6),...-
%         'XTickLabel',[-200:200:800],...
%         'ylim',thisYaxis,...
%         'xlim',thisXaxis);
%     
%     line(thisXaxis,[0,0],...
%         'linestyle','--',...
%         'linewidth',1.5',...
%         'color','k');
%     
%     line([51,51],thisYaxis,...
%         'linestyle','--',...
%         'linewidth',1.5',...
%         'color','k');
%     
%     
%     %ylim([-5 15])
%     %legend('Baseline','Treatment','Control')
%     
%     if      iCond==1; thisTitle = 'CPT';
%     elseif  iCond==2; thisTitle = 'MF';
%     elseif  iCond==3; thisTitle = 'TR';
%     elseif  iCond==4; thisTitle = 'PF';
%     end
%     title([thisTitle ' (n= ' num2str(size(theseData,1)) ')'],'fontsize',30)
%     
%     %% run t-tests at each timepoint to detect differences between conditions
%     h1v2=ttest(squeeze(mean(theseData(:,1,chanIndices,:),3)),squeeze(mean(theseData(:,2,chanIndices,:),3)));
%     h1v3=ttest(squeeze(mean(theseData(:,1,chanIndices,:),3)),squeeze(mean(theseData(:,3,chanIndices,:),3)));
%     h2v3=ttest(squeeze(mean(theseData(:,2,chanIndices,:),3)),squeeze(mean(theseData(:,3,chanIndices,:),3)));
%     
%     %% plot t-tests
%     for t=1:3
%         if      t==1; thisTest=h1v2; thisPlotPos=-2; thisColor = 'k';
%         elseif  t==2; thisTest=h1v3; thisPlotPos=-3; thisColor = 'b';
%         elseif  t==3; thisTest=h2v3; thisPlotPos=-4; thisColor = 'g';
%         end
%         for i=1:length(thisTest)-1        
%             if thisTest(i)==1
%                 line([i:i+1],[thisPlotPos,thisPlotPos],'linewidth',10,'Color',thisColor)
%                 %timesVec(i):timesVec(i)+1
%             end          
%         end    
%     end
%     
% end