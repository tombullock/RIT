%{
EEG_Compute_ERPs_Resp_Locked
Author: Tom Bullock, UCSB Attention Lab
Date: 05.03.21

%}

% % add eeglab to path
% cd /data/DATA_ANALYSIS/eeglab14_1_1b
% eeglab
% clear 
% close all
% cd ..

% set dirs
sourceDir = '/bigboss/PROJECTS/RIT/EEG_Prepro3_Resp_Locked';
destDir = '/bigboss/PROJECTS/RIT/Data_Compiled_Tom';

%% loop through conditions and generate separate mats for each
for iCond=1:4
    

    clear subjects erp_this_go_correct erp_this_nogo_error_human erp_this_nogo_error_repeat erp_this_nogo_error_all
        
    
    if iCond==1
        subjects = [105,108,110,114:119,121:122, 124:126,128,130,132,133,135,136,138:140,147,148,149:151,154:158,161]; % reemove 160 coz no human errrors + 127?
    elseif iCond==2
        subjects = [201,204,209,212:218,220:223,225,228:234,236,237,239:245]; % remove 208,211 
    elseif iCond==3
        subjects = [302:306,308:310,313:318,321:327,329:333,337,339:347]; % 33/40 currently have triggers
    elseif iCond==4
        subjects = [402:403,405:406,409:412,414:420,422,423,425,426,427,428,]; % 18/18 have triggers [401,407,413 something up with beh]
    end
    
    

    for iSub=1:length(subjects)
        sjNum = subjects(iSub)
        for iSession = 1:3
            if iSession==1
                thisRep=1;
            else
                thisRep=2;
            end
           % EEG = pop_loadset([sourceDir '/' sprintf('sj%d_se%02d_ri_respEpoched.set',sjNum,iSession)]);
            load([sourceDir '/' sprintf('sj%d_se%02d_ri_prepro3.mat',sjNum,iSession)]);
            
            %% split main file into different trial epochs [response locked only]
            cnt1=0; cnt2=0; cnt3=0; cnt4=0;
            this_go_correct = [];
            this_nogo_error_human = [];
            this_nogo_error_repeat = [];
            this_nogo_error_all = [];
            for iTrial=1:length(EEG.epoch)            
                if EEG.trialMatResponseOnly(iTrial,4)==100||EEG.trialMatResponseOnly(iTrial,4)==2 % all "go" trials where participant has made a correct response
                    cnt1=cnt1+1;
                    this_go_correct(:,:,cnt1)= EEG.data(:,:,iTrial);   
                elseif EEG.trialMatResponseOnly(iTrial,4)==1 % all "no-go-human" trials where participant has incorrectly responded
                    cnt2=cnt2+1;
                    this_nogo_error_human(:,:,cnt2)= EEG.data(:,:,iTrial);                 
                elseif EEG.trialMatResponseOnly(iTrial,4)==3 % all "no-go-repeat" trials where participant has incorrectly responded
                    cnt3=cnt3+1;
                    this_nogo_error_repeat(:,:,cnt3)= EEG.data(:,:,iTrial); % all "no-go-repeat" trials where participant has incorrectly responded    
                end
                    
                if EEG.trialMatResponseOnly(iTrial,4)==1||EEG.trialMatResponseOnly(iTrial,4)==3 
                    cnt4=cnt4+1;
                    this_nogo_error_all(:,:,cnt4)= EEG.data(:,:,iTrial); % combined "no-go-repeat and no-go-human" trials where participant incorrectly responded                 
                end         
            end
             
            %% average across trials for each type and compile into master file
            erp_this_go_correct(iSub,iSession,:,:) = mean(this_go_correct,3);
            erp_this_nogo_error_human(iSub,iSession,:,:) = mean(this_nogo_error_human,3);
            erp_this_nogo_error_repeat(iSub,iSession,:,:) = mean(this_nogo_error_repeat,3);
            erp_this_nogo_error_all(iSub,iSession,:,:) = mean(this_nogo_error_all,3);
            
            clear this_go_correct this_nogo_error_human this_nogo_error_repeat this_nogo_error_all
            
        end
    end
    
    chanlocs = EEG.chanlocs;
    times = EEG.times;
    ERP.erp_nogo_all = erp_this_nogo_error_all;
    ERP.erp_nogo_human = erp_this_nogo_error_human;
    ERP.erp_nogo_repeat = erp_this_nogo_error_repeat;
    
    save([destDir '/' sprintf('ERP_master_resp_locked_cond%02d.mat',iCond)],...
        'ERP',...
        'times',...
        'chanlocs')
    
    clear chanlocs times ERP
    
%     save([destDir '/' sprintf('ERP_Master_Resp_Locked_Cond%02d.mat',iCond)],...
%         'erp_this_go_correct',...
%         'erp_this_nogo_error_human',...
%         'erp_this_nogo_error_repeat',...
%         'erp_this_nogo_error_all',...
%         'chanlocs')
end

