function [Phot_x, Phot_ymean] = align_photometryStatescript_options_v2(plotNum,fname)
%% written by Robyn St. Laurent, August 2021
% This script is to align photometry to platform-mediated active avoidance events
% Statescript data: Tone, Shock, pokes
% DeepLabCut: entries onto platform, approach pokes, etc
% use "switch" so that you can pick which event to look at.

    %%1. = baseline before tone + tone + shock + after shock
    %%2. = end of tone + shock+ after shock
    %%3. = shock only
    %%4. = rewarded center port poke    

switch plotNum
        
    case 1 %% Pull out the signal around the tone start
clearvars -except fname
TDT = getPhotoSig_v2(fname);
behname = strcat(fname,'_beh.mat');
load(behname);
clearvars -except TDT trVals trialParams tstamps inStates outStates fname
sessionID = strcat(trialParams.mouseID, '-', trialParams.dateVal, '-' ,' " ', trialParams.notes, '"');
zTDT = zscore(TDT.photoSig);
% TTL pulses are sent every 10 trials (***only in later sessions, started out with fewer TTLs)
% Behavioral and neural sync check
if length(TDT.syncTime) == length(trVals.syncSent)
    disp('Matching number of syncs sent and received: All good!')
else
    disp('sync numbers do not match!')
end

x1 = trVals.toneStart;
y1 = zeros(length(x1));
x2 = trVals.syncSent; % number TTL sent by Statescript
y2 = zeros(length(trVals.syncSent));
x3 = TDT.syncTime; % number TTL received by photometry
y3 = zeros(length(TDT.syncTime));

% Find the difference in timing between TTLs sent by statescript
% and TTLs received by the photometry system
% output is x3_shift where you have photometry aligned. 
 if length(x3) >= 2 % Find diff btwn TTLs sent by statescript and received by photometry system
            tdiff = (x2(2) - x2(1))/(x3(2)-x3(1)); %error here if only 1 TTL detected
        else
            tdiff =  1.0008e+03;
            disp('not enough TTLs to get clock differences')
        end 
x3 = x3*tdiff; shift_diff = x3(1)-x2(1);
x3_shift = x3 - shift_diff; % this adjusted TDT sync time to match trVals sync sent. 

plot(x1,y1 + 1,'r|','MarkerSize',20,'LineWidth',2)
hold on
plot(x2, y2 +0.1,'b|','MarkerSize',20)
hold on
plot(x3_shift, y3 +0.2,'k|','MarkerSize',20)
disp('check that your alignment looks correct!')

% Now need to shift all of the photometry signal to match Time across both
newPhotTime = TDT.t*tdiff; %multiply by time diff
newPhotTime = newPhotTime-shift_diff; % subtract offset
plot(newPhotTime,zTDT)
hold on
plot(x1,y1 + 1,'r|','MarkerSize',20,'LineWidth',2)


% ***************************YOUR DESIRED TIME BIN HERE********************************************************
toneEnd = x1 + 30000; % end of tone
padTime = 2000; % amount of extra you want before and after the tone & shock
disp(strcat('You have selected to view', " ",string(padTime), ' milliseconds on each end'))
photTone_time = [];
for i = 1:length(x1) % for every index in toneStart
    toneStart_phot = find(newPhotTime > x1(i)-padTime & newPhotTime < toneEnd(i)+padTime); %find the indices for the photometry signal during 2s prior to  tone + 2s shock + 2s after
    photTone_time{i} = cell2mat({toneStart_phot});
end
photTone_time = photTone_time(~cellfun('isempty',photTone_time)); %removes any empty cells
min_sigLen = min(cellfun('size',photTone_time,2)); % find the shortest cell array
photTone_time = cellfun(@(x) x(:,1:min_sigLen),photTone_time,'un',0); % trim all the cells to match the shortest

%% Use the indices to grab the photometry signal, plot it, then plot the average and SEM

Phot_x = NaN(length(x1),min_sigLen);
Phot_y = NaN(length(x1),min_sigLen);
tm = zeros(16,1);
tmX = [1:16];

figure
for tone = 1:length(x1)
    tone_idx = photTone_time{1,tone}; % gets the photometry indices for 30s tone
    Phot_x(tone,:)= newPhotTime(tone_idx); % gets the photometry timestamps (aligned) for 30s tone
    Phot_x(tone,:) = Phot_x(tone,:) - Phot_x(tone,1)-padTime; % aligns all to start at 0
    Phot_y(tone,:) = zTDT(tone_idx); % gets the photometry signal for 30s tone
    tm(tone) = nanmean(Phot_y(tone,:));
    plot(Phot_x(tone,:),Phot_y(tone,:))
    axis([0-padTime 30000+padTime -2 6])
    title(sessionID)
    legendInfo{tone} = num2str(tone);
    legend(legendInfo, 'Location', 'EastOutside');
    hold on
end

ylabel('z-scored photometry signal')
xlabel('Time (ms)')
xline(0,'b--','Displayname', 'tone start')
xline(30000,'r--','Displayname', 'shock start')
xline(32000,'r--','Displayname', 'shock end')
    
figure
Phot_ymean = nanmean(Phot_y,1);
phot_err = std(Phot_y)/sqrt(length(Phot_y));
errorbar(Phot_x(1,:),Phot_ymean,phot_err,'c')
hold on
plot(Phot_x(1,:),Phot_ymean)
hold on
xline(0,'b--')
xline(30000,'r--')
xline(32000,'r--')
title(sessionID)
ylabel('z-scored GCamp6f photometry signal')
xlabel('Time (ms)')
axis([0-padTime 30000+padTime -2 10])

%% Case 2
    case 2 %% Pull out the signal around the shock
clearvars -except fname
TDT = getPhotoSig_v2(fname);
behname = strcat(fname,'_beh.mat');
load(behname);
clearvars -except TDT trVals trialParams tstamps inStates outStates fname
sessionID = strcat(trialParams.mouseID, '-', trialParams.dateVal, '-' ,' " ', trialParams.notes, '"');
zTDT = zscore(TDT.isoSig);

% TTL pulses are sent every 10 trials (***only in later sessions, started out with fewer TTLs)
% Behavioral and neural sync check
if length(TDT.syncTime) == length(trVals.syncSent)
    disp('Matching number of syncs sent and received: All good!')
else
    disp('sync numbers do not match!')
end

x1 = trVals.toneStart; % statescript event
y1 = zeros(length(x1));
x2 = trVals.syncSent; % number TTL sent by Statescript
y2 = zeros(length(trVals.syncSent));
x3 = TDT.syncTime; % number TTL received by photometry
y3 = zeros(length(TDT.syncTime));

if length(x3) > 1
    tdiff = (x2(2) - x2(1))/(x3(2)-x3(1));
    x3 = x3*tdiff;
    shift_diff = x3(1)-x2(1);
    x3_shift = x3 - shift_diff; % this adjusted TDT sync time to match trVals sync sent. 
else
               tdiff =  1.0008e+03;
            disp('not enough TTLs to get clock differences')
end    

figure
plot(x1,y1 + 1,'r|','MarkerSize',20,'LineWidth',2)
hold on
plot(x2, y2 +0.1,'b|','MarkerSize',20)
hold on
plot(x3_shift, y3 +0.2,'k|','MarkerSize',20)
disp('check that your alignment looks correct!')
%text('red = event; blue = TTLsent; black = TTLrec')
close

% Now need to shift all of the photometry signal to match Time across both
newPhotTime = TDT.t*tdiff; %multiply by time diff
newPhotTime = newPhotTime-shift_diff; % subtract offset
figure
plot(newPhotTime,zTDT)
hold on
plot(x1,y1 + 1,'r|','MarkerSize',20,'LineWidth',2)
close         
         
% ***************************YOUR DESIRED TIME BIN HERE********************************************************
shockStart = trVals.toneStart + 30000;
shockEnd = shockStart + 2000;
padTime = 10000; % amount of extra you want before and after the tone & shock
disp(strcat('You have selected to view', " ",string(padTime), ' milliseconds on each end'))
photshockStart = [];
for i = 1:length(shockStart) % for every index in toneStart
    shockStart_phot = find(newPhotTime > shockStart(i)-padTime & newPhotTime < shockEnd(i)+padTime); %find the indices for the photometry signal during 2s prior to  tone + 2s shock + 2s after
    photshockStart{i} = cell2mat({shockStart_phot});
end
photshockStart = photshockStart(~cellfun('isempty',photshockStart)); %removes any empty cells
min_sigLen = min(cellfun('size',photshockStart,2)); % find the shortest cell array
photshockStart = cellfun(@(x) x(:,1:min_sigLen),photshockStart,'un',0); % trim all the cells to match the shortest

Phot_x = NaN(length(x1),min_sigLen);
Phot_y = NaN(length(x1),min_sigLen);

figure
for s = 1:length(x1) % x1 is the tone start
    s_idx = photshockStart{1,s}; % gets the photometry indices for 30s tone
    Phot_x(s,:)= newPhotTime(s_idx); % gets the photometry timestamps (aligned) for 30s tone
    Phot_x(s,:) = Phot_x(s,:) - Phot_x(s,1)-padTime; % aligns all to start at 0
    Phot_y(s,:) = zTDT(s_idx); % gets the photometry signal for 30s tone
    subplot(length(x1),1,s)
    plot(Phot_x(s,:),Phot_y(s,:))
    axis([0-padTime 2000+padTime -2 6])
    hold on
    xline(0,'r-','Displayname', 'shock start')
    hold on
    xline(2000,'g-','Displayname', 'shock end')
end
ylabel('z-scored Phot')
xlabel('Time (ms)')
legend(sessionID,'shock start','shock end','Location','SouthOutside')

figure
Phot_ymean = nanmean(Phot_y,1);
phot_err = nanstd(Phot_y)/sqrt(length(Phot_y));
errorbar(Phot_x(1,:),Phot_ymean,phot_err,'c')
hold on
plot(Phot_x(1,:),Phot_ymean) % arbitrarily using the times from first row (they're all identical)
hold on
xline(0,'r--')
xline(2000,'g--')
title(sessionID)
ylabel('z-scored GCamp6f photometry signal')
xlabel('Time (ms)')
axis([0-padTime 2000+padTime -2 10])

%% 
case 3 %% Pull out the signal for only the shock to find the peak
clearvars -except fname
TDT = getPhotoSig_v2(fname);
behname = strcat(fname,'_beh.mat');
load(behname);
clearvars -except TDT trVals trialParams tstamps inStates outStates fname
sessionID = strcat(trialParams.mouseID, '-', trialParams.dateVal, '-' ,' " ', trialParams.notes, '"');
zTDT = zscore(TDT.isoSig);

% TTL pulses are sent every 10 trials (***only in later sessions, started out with fewer TTLs)
% Behavioral and neural sync check
if length(TDT.syncTime) == length(trVals.syncSent)
    disp('Matching number of syncs sent and received: All good!')
else
    disp('sync numbers do not match!')
end

x1 = trVals.toneStart; % statescript event
y1 = zeros(length(x1));
x2 = trVals.syncSent; % number TTL sent by Statescript
y2 = zeros(length(trVals.syncSent));
x3 = TDT.syncTime; % number TTL received by photometry
y3 = zeros(length(TDT.syncTime));

if length(x3) > 1
    tdiff = (x2(2) - x2(1))/(x3(2)-x3(1));
    x3 = x3*tdiff;
    shift_diff = x3(1)-x2(1);
    x3_shift = x3 - shift_diff; % this adjusted TDT sync time to match trVals sync sent. 
else
               tdiff =  1.0008e+03;
            disp('not enough TTLs to get clock differences')
end    

% Now need to shift all of the photometry signal to match Time across both
newPhotTime = TDT.t*tdiff; %multiply by time diff
newPhotTime = newPhotTime-shift_diff; % subtract offset
figure
plot(newPhotTime,zTDT)
hold on
plot(x1,y1 + 1,'r|','MarkerSize',20,'LineWidth',2)
close         
         
% ***************************YOUR DESIRED TIME BIN HERE********************************************************
shockStart = trVals.toneStart + 30000;
shockEnd = shockStart + 2000;
padTime = 5000; % amount of extra you want before and after the tone & shock
disp(strcat('You have selected to view', " ",string(padTime), ' milliseconds on each end'))
photshockStart = [];
for i = 1:length(shockStart) % for every index in toneStart
    shockStart_phot = find(newPhotTime > shockStart(i)-padTime & newPhotTime < shockEnd(i)+padTime); %find the indices for the photometry signal during 2s prior to  tone + 2s shock + 2s after
    photshockStart{i} = cell2mat({shockStart_phot});
end
photshockStart = photshockStart(~cellfun('isempty',photshockStart)); %removes any empty cells
min_sigLen = min(cellfun('size',photshockStart,2)); % find the shortest cell array
photshockStart = cellfun(@(x) x(:,1:min_sigLen),photshockStart,'un',0); % trim all the cells to match the shortest

Phot_x = NaN(length(x1),min_sigLen);
Phot_y = NaN(length(x1),min_sigLen);

figure
for s = 1:length(x1) % x1 is the tone start
    s_idx = photshockStart{1,s}; % gets the photometry indices for 30s tone
    Phot_x(s,:)= newPhotTime(s_idx); % gets the photometry timestamps (aligned) for 30s tone
    Phot_x(s,:) = Phot_x(s,:) - Phot_x(s,1)-padTime; % aligns all to start at 0
    Phot_y(s,:) = zTDT(s_idx); % gets the photometry signal for 30s tone
    subplot(length(x1),1,s)
    plot(Phot_x(s,:),Phot_y(s,:))
    xline(0)
    xline(2000)
    set(gca, 'visible','off')
    axis([0-padTime 2000+padTime -2 10])
    
end
ylabel('z-score Gcamp')
xlabel('Time (ms)')

figure
Phot_ymean = nanmean(Phot_y,1);
phot_err = nanstd(Phot_y)/sqrt(length(Phot_y));
errorbar(Phot_x(1,:),Phot_ymean,phot_err,'c')
hold on
plot(Phot_x(1,:),Phot_ymean) % arbitrarily using the times from first row (they're all identical)

title(sessionID)
ylabel('z-scored GCamp6f photometry signal')
xlabel('Time (ms)')
axis([0-padTime 2000+padTime -2 10])
xline(0)
 
%% Align photometry to rewarded center pokes
case 4  
    clearvars -except fname
TDT = getPhotoSig_v2(fname);
behname = strcat(fname,'_beh.mat');
load(behname);
sessionID = strcat(trialParams.mouseID, '-', trialParams.dateVal, '-' ,' " ', trialParams.notes, '"');
zTDT = zscore(TDT.isoSig);

% TTL pulses are sent every 10 trials (***only in later sessions, started out with fewer TTLs)
% Behavioral and neural sync check
if length(TDT.syncTime) == length(trVals.syncSent)
    disp('Matching number of syncs sent and received: All good!')
else
    disp('sync numbers do not match!')
end

x1 = trVals.correctCenterTime; % statescript event
y1 = zeros(length(x1));
x2 = trVals.syncSent; % number TTL sent by Statescript
y2 = zeros(length(trVals.syncSent));
x3 = TDT.syncTime; % number TTL received by photometry
y3 = zeros(length(TDT.syncTime));

if length(x3) > 1
    tdiff = (x2(2) - x2(1))/(x3(2)-x3(1));
    x3 = x3*tdiff;
    shift_diff = x3(1)-x2(1);
    x3_shift = x3 - shift_diff; % this adjusted TDT sync time to match trVals sync sent. 
else
               tdiff =  1.0008e+03;
            disp('not enough TTLs to get clock differences')
end    

% Now need to shift all of the photometry signal to match Time across both
newPhotTime = TDT.t*tdiff; %multiply by time diff
newPhotTime = newPhotTime-shift_diff; % subtract offset     
         
% ***************************YOUR DESIRED TIME BIN HERE********************************************************
        e_start = x1 ; % correct center poke
        e_end = e_start + 1000; % 2 s after poke
        padTime = 5000; % amount of extra you want before and after
        disp(strcat('You have selected to view', " ",string(padTime), ' milliseconds on each end'))
        correctCenter_time = [];
        for i = 1:length(x1) % for every index in toneStart
            corCenterStart_phot = find(newPhotTime > e_start(i)-padTime & newPhotTime < e_end(i)+padTime); %find the indices for the photometry signal during 2s prior to + 2s after
            correctCenter_time{i} = cell2mat({corCenterStart_phot});
        end
       correctCenter_time = correctCenter_time(~cellfun('isempty',correctCenter_time)); %removes any empty cells
        min_sigLen = min(cellfun('size',correctCenter_time,2)); % find the shortest cell array
        correctCenter_time = cellfun(@(x) x(:,1:min_sigLen),correctCenter_time,'un',0); % trim all the cells to match the shortest

        % Use the indices to grab the photometry signal, plot it, then plot the average and SEM
        Phot_x = NaN(length(x1),min_sigLen);
        Phot_y = NaN(length(x1),min_sigLen);
        for poke = 1:length(correctCenter_time) %changed from x1
            poke_idx = correctCenter_time{1,poke}; % gets the photometry indices 
            Phot_x(poke,:)= newPhotTime(poke_idx); % gets the photometry timestamps (aligned) f
            Phot_x(poke,:) = Phot_x(poke,:) - Phot_x(poke,1)-padTime; % aligns all to start at 0
            Phot_y(poke,:) = zTDT(poke_idx); % gets the photometry signal for correct center poke
        end

        Phot_ymean = nanmean(Phot_y,1);
        phot_err = nanstd(Phot_y)/sqrt(length(Phot_y));
        figure
        errorbar(Phot_x(1,:),Phot_ymean,phot_err,'c')
        hold on
        plot(Phot_x(1,:),Phot_ymean)
        hold on
        title(sessionID)
        axis([0-padTime 0+padTime -2 2])
        xlabel('Time (ms)')
        ylabel('z-scored GCamp6f photometry signal')
end
 
end