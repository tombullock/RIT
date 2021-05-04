function [subjects,subsMissingBehData,subjectsCPT,subjectsMF,subjectsTR,subjectsPF ] = subjectInfo_RI

%% subjects
subjectsCPT = [105,108,110,111,114:128,130,132:136,138:140,147,148,149:151,154:158,160,161]; % 40 currently have triggers
%subjectsCPT = [111];
% 101 different number of chans? [scrap]
% 102 se03 missing [unrecoverable]
% 103 se02 too few epochs [EEG died after 48 trials, unrecoverable]
% 104 se02 too few epochs [fixed] but se03 MISSING [unrecoverable]
% 107 se02 too few epochs [EEG died after 50 trials, unrecoverable]
% 109 se02 no epochs found [unrecoverable]

% 111 se02 missing epochs [half EEG file missing, but beh OK] FIXED
% 114 se03 no epochs found [triggers recovered, FIXED]
% 115 se03 no epochs found [triggers recovered, FIXED]
% 120 se01 missing epochs [half EEG file missing, but neh OK] FIXED
% 133 se01 missing epochs [half EEG file missing, but beh OK] FIXED
% 143 se02 no EEG markers, no beh [unrecoverable, unless use PC labjack tr]
% 144 se01 no triggers during entire session [unrecoverable]
% 159 se02 no triggers during entire session [unrecoverable]


subjectsMF = [201,204,209,212:218,220:223,225,227:234,236,237,239:245]; % 37/40 currently have triggers
%subjectsMF =[];
% 203 se03 NOISY ALL CHANNELS - NOT USABLE
% 206 se03 DATA NOT RECORDED PROPERLY - NOT USABLE
% 207 se03 only 326 epochs, no beh saved [FIXED,need to rep behavior file]
% 208 se02 super, super noisy data (NOT USABLE)
% 209 se02 no EEG markers - FIXED!
% 210 se02 no EEG markers [unrecoverable?]
% 211 se01 very high blink rate [files OK] [NOT USABLE]
% 219 se03 no EEG markers [unrecoverable]
% 226 baseline missing events [unrecoverable, probably]


subjectsTR = [302:306,308:310,313:318,321:327,329:333,337,339:347]; % 36/40 currently have triggers
%subjectsTR =[];
% [none of these subjects have any triggers in part 3 of the session, so no
% info in audit file...may need to try concat the three parts of the audit file and using eegPtime from part 1]
% 307 se02 no EEG markers 
% 312 se03 no EEG markers 
% 319 se02 no EEG markers
% 322 se01 no EEG markers [FIXED!]
% 328 se02 no EEG markers
% 329 se01 no EEG markers [FIXED!]

subjectsPF = [402:403,405:406,409:412, 414:420,422,423:428,430,431,433:439,441,443:445]; % OLD 24/24 have triggers
%subjectsPF = [424,430,431,433:445]; 
%subjectsPF = [442:445];
% 440 tx is bad - try to fix with audit stuff (alex re-export 440 se02)

% 413 SE01 NOISY UNUSABLE
%subjectsPF = [401];

%% compile all subject vectors
subjects = [subjectsCPT,subjectsMF,subjectsTR,subjectsPF];
%subjects = [subjectsPF];
%subjects = 322;

%% create list of subjects with INTACT EEG BUT MISSING BEH FILES (could try to reconstruct beh from EEG?)
subsMissingBehData = [207,401,407,442]; 

return


%             % get BAD electrodes (just use automated kurtosis based rej for
%             % now)...perhaps try and figure out PREP pipeline for future...
% %             badElectrodeIndex = [];
% %             [~,badElectrodeIndex] = pop_rejchan(EEG,'measure','kurt','threshold',5,'norm','on');
%             
%             % add MANUAL exceptions (manually, some subs still bad coz one electrode)
%             badElectManual = [];
%             if sjNum==119 && iCond==3
%                 badElectManual= {'CPz','F4'};
%             elseif sjNum==155 && iCond==3
%                 badElectManual= {'F1'};
%             elseif sjNum==203 && iCond==3
%                 badElectManual= {'Cz'};
%             elseif sjNum==206 && iCond==2
%                 badElectManual= {'CP4','FC3','F1','F5'};
%             elseif sjNum==212 && iCond==2
%                 badElectManual= {'Oz','O1','POz'};
%             elseif sjNum==214 && iCond==3
%                 badElectManual= {'P2'};
%             elseif sjNum==217 && iCond==2
%                 badElectManual= {'PO4'};
%             elseif sjNum==222 && iCond==2
%                 badElectManual= {'POz'};
%             elseif sjNum==225 && iCond==1
%                 badElectManual= {'Fz','FC1','F3','CP1','C4'};
%             elseif sjNum==225 && iCond==3
%                 badElectManual= {'Oz','O2','PO4'};
%             elseif sjNum==241 && iCond==1
%                 badElectManual= {'C1'};
%             elseif sjNum==243 && iCond==3
%                 badElectManual= {'FC1','FT9','CP6','FC1','FC3','CP3','C1','PO3','PO4'};
%             elseif sjNum==245 && iCond==2
%                 badElectManual= {'CPz'};
%             elseif sjNum==306 && iCond==1
%                 badElectManual= {'CPz','POz'};
%             elseif sjNum==315 && iCond==1
%                 badElectManual= {'CPz'};
%             elseif sjNum==322 && iCond==3
%                 badElectManual= {'CP2'};
%             elseif sjNum==343 && iCond==3
%                 badElectManual= {'Oz'};
%             elseif sjNum==345 && iCond==1
%                 badElectManual= {'Oz'};
%             elseif sjNum==346 && iCond==1
%                 badElectManual= {'C2'};
%             elseif sjNum==410 && iCond==2
%                 badElectManual= {'CP2','CPz'};
%             elseif sjNum==416 && iCond==2
%                 badElectManual= {'Fz','F3','FC1','CP1','C4','C1','POz','P4','PO4','P2','Pz'};
%             elseif sjNum==427 && iCond==3
%                 badElectManual= {'FC1','Fz'};
%             else
%                 badElectManual = {'CPz'}; % ADDED THIS FOR CONSISTENCY WITH RESP LOCKED STUFF (BUT NOT RUN YET)***051419
%             end
%             
%             badElectManualIdx = [];
%             cnt=0;
%             for iChan=1:length(EEG.chanlocs)
%                 if ismember(EEG.chanlocs(iChan).labels,badElectManual)
%                     cnt=cnt+1;
%                     badElectManualIdx(cnt) = iChan;
%                 end
%             end
%             
%             badElectrodeIndex = [badElectrodeIndex,badElectManualIdx];
%             
%             
%             % interp bad electrodes [check which onees are being interp]
%             EEG = pop_interp(EEG,badElectrodeIndex,'spherical');