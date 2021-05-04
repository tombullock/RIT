%{
Plot_ERPs_Target_Locked
Author: Tom Bullock
Date: 03.15.21
%}

clear
close all

% source dir
sourceDirEEG = '/bigboss/PROJECTS/RIT/Data_Compiled_Tom';
destDirPlots = '/bigboss/PROJECTS/RIT/Plots_Tom';

% loop through error type
for iErrorType=1:3
    
    % create topographic plots
    h=figure('units','normalized','outerposition',[0 0 1 1]);
    plotPos=0;
    
    for iCond=1:4
        
        % loop through stress condiitons
        clear chanlocs chanIndices chansForPlot erp_all_trials erp_nogo_all erp_nogo_image erp_nogo_rep erp_std erp_nogo_correct erp_nogo_error theseData
        
        % load data
        load([sourceDirEEG '/' sprintf('ERP_master_resp_locked_cond%02d.mat',iCond)])
        
        % select times for plotting
        theseTimes = find(times==100):find(times==300);
        
        % set colormap limits for topo plots
        theseMapLimits = [-8,8]; % microvolts
        
        % select data for plotting
        %theseData = ERP.erp_nogo;
        if iErrorType==1
            theseData = ERP.erp_nogo_all;
            thisDataType = 'nogo_all';
        elseif iErrorType==2
            theseData = ERP.erp_nogo_human;
            thisDataType = 'nogo_human';
        elseif iErrorType==3
            theseData = ERP.erp_nogo_repeat;
            thisDataType = 'nogo_repeat';
        end

%         if iErrorType==1
%             theseData = ERP.erp_go;
%             thisDataType = 'go';
%         elseif iErrorType==2
%             theseData = ERP.erp_nogo;
%             thisDataType = 'nogo';
%         end
        
        
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
    saveas(h,[destDirPlots '/' 'ERP_Plot_Topos_Resp_Locked_TB_' thisDataType '.jpg'],'jpeg')
    
end
