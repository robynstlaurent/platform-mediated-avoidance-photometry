%%% Funct to find the photometry indices when mouse is on or off the platform during
%%% a tone or a shock
% Desired output: plot the avg photometry response to a shock, vs avoided
% shock
function [av, sh, p_av, p_sh, avoid_x, avoid_y, gets_x, gets_y, part_x, part_y] = Align_photShock(fname)
clearvars -except fname
load(strcat(fname,'_photoSig.mat'))
% TDT = getPhotoSig(fname);
zTDT = zscore(TDT.photoSig);
behname = strcat(fname,'_beh.mat');
load(behname);
if exist(strcat(fname,'.1.videoTimeStamps'))
    videoTime = readCameraModuleTimeStamps(strcat(fname,'.1.videoTimeStamps'));
else
    videoTime = readCameraModuleTimeStamps(strcat(fname,'.2.videoTimeStamps'));
end

dlcname = strcat(fname,'.1.h264DLC_resnet50_AA_v3Oct22shuffle1_500000.csv');
if exist(dlcname)
     dlc = xlsread(dlcname); % apparently xlsread doesn't work on Mac
else % readmatrix does work
  dlcname = strcat(fname,'.1.h264DLC_resnet_50_AA_v1Jun26shuffle1_700000.csv');
  if exist(dlcname)
      dlc = xlsread(dlcname);
  else
    dlcname = (strcat(fname,'.1.h264DLC_resnet50_AA_v1Jun26shuffle1_250000.csv'));
    if exist(dlcname)
        dlc = xlsread(dlcname);
    else
        dlcname = strcat(fname,'.1.h264DLC_resnet50_AA_v2Sep29shuffle1_1030000.csv');
        if exist(dlcname)
            dlc = xlsread(dlcname);
                        else
            dlcname = strcat(fname,'.1.h264DLC_resnet50_stanfordAAMar1shuffle1_200000.csv');
            if exist(dlcname)
             dlc = xlsread(dlcname);
        end
    end
end
  end
end
bodycenterX = dlc(4:end,8); bodycenterY = dlc(4:end,9);
platformLcornerX = nanmedian(dlc(4:end,23)); platformLcornerY = nanmedian(dlc(4:end,24));
platformRcornerX = nanmedian(dlc(4:end,26)); platformRcornerY = nanmedian(dlc(4:end,27));
platformBRcornerX = nanmedian(dlc(4:end,29)); platformBRcornerY = nanmedian(dlc(4:end,30));
ON = []; 
 ONx =  bodycenterX < platformRcornerX;
 ONy =  bodycenterY > platformRcornerY;
 ON =  ONx ==1 & ONy ==1; % 1 logical means on platform, 0 means off

% Behavioral and neural sync check
if length(TDT.syncTime) == length(trVals.syncSent)
    disp('Matching number of syncs sent and received: All good!')
else
    disp('sync numbers do not match!')
end

x1 = trVals.toneStart; x2 = trVals.syncSent; % number TTL sent by Statescript
y2 = zeros(length(trVals.syncSent));
x3 = TDT.syncTime; y3 = zeros(length(TDT.syncTime));
  if length(x3) >= 2 % Find diff btwn TTLs sent by statescript and received by photometry system
            tdiff = (x2(2) - x2(1))/(x3(2)-x3(1)); %error here if only 1 TTL detected
        else
            tdiff =  1.0008e+03;
            disp('not enough TTLs to get clock differences')
        end 
        x3 = x3*tdiff; shift_diff = x3(1)-x2(1);
        x3_shift = x3 - shift_diff; % this adjusted TDT sync time to match trVals sync sent. 
        % Now need to shift all of the photometry signal to match Time across both
        newPhotTime = TDT.t*tdiff; newPhotTime = newPhotTime-shift_diff; % subtract offset     
        %%     
% ***************************YOUR DESIRED TIME BIN HERE********************************************************
shockStart = trVals.toneStart + 30000;
shockEnd = shockStart + 2000;
videoTime_ms = videoTime*1000;
onTimes = videoTime_ms(ON>0); % actual video time (aligned to statescript, in ms)
offTimes = videoTime_ms(ON<1); % actual video time (aligned to statescript, in ms)
padTime = 1000; % amount of extra you want before and after the shock
disp(strcat('You have selected to view', " ",string(padTime), ' milliseconds on each end'))
photshockStart = [];
for i = 1:length(shockStart) % for every index in shockStart
    shockStart_phot = find(newPhotTime > shockStart(i)-padTime & newPhotTime < shockEnd(i)+padTime);
    photshockStart{i} = cell2mat({shockStart_phot}); %add it to the cell array
    shock_ON{i} = find(onTimes >= shockStart(i) & onTimes <= shockEnd(i));
    shock_OFF{i} = find(offTimes >= shockStart(i) & offTimes <= shockEnd(i));
end

min_sigLen = min(cellfun('size',photshockStart,2)); % find the shortest cell array
photshockStart = cellfun(@(x) x(:,1:min_sigLen),photshockStart,'UniformOutput',0); % trim all the cells to match the shortest
Phot_x = NaN(length(x1),min_sigLen);
Phot_y = NaN(length(x1),min_sigLen);
%% optional figures

figure % plots the photometry signal for each individual shock, regardless of location
for s = 1:length(x1) % x1 is the shock start
    s_idx = photshockStart{1,s}; % gets the photometry indices
    Phot_x(s,:)= newPhotTime(s_idx); % gets the photometry timestamps (aligned)
    Phot_x(s,:) = Phot_x(s,:) - Phot_x(s,1)-padTime; % aligns all to start at 0
    Phot_y(s,:) = zTDT(s_idx); % gets the photometry signal
    plot(Phot_x(s,:),Phot_y(s,:))
    hold on
    axis([0-padTime 2000+padTime -2 6])
end

ylabel('z-scored GCamp6f signal')
xlabel('Time (ms)')

% figure % plots the mean signal for all shocks, regardless of location
% Phot_ymean = nanmean(Phot_y,1);
% phot_err = nanstd(Phot_y)/sqrt(length(Phot_y));
% %shadedErrorBar(Phot_x(1,:),Phot_ymean,phot_err,'lineProps',{'-b','MarkerFaceColor','b','LineWidth', 0.5})
% hold on
% plot(Phot_x(1,:),Phot_ymean,'k-') % arbitrarily using the times from first row (they're all identical)
% ylabel('z-scored GCamp6f signal')
% xlabel('Time (ms)')
% axis([0-padTime 2000+padTime -2 6])
% %axis off ;

%% Gather photometry data during Shocks, separated by on vs. off platform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
avoided_shock = shock_ON(~cellfun('isempty',shock_ON)); %on platform during shock
partial_avoid = {};
% But need to eliminate partial avoided shocks:
for a = 1:length(avoided_shock)
    if length(avoided_shock{a}) < 50
        partial_avoid{a} = avoided_shock{a};
        avoided_shock{a} = [];
    else
        continue
    end
end
avoided_shock = avoided_shock(~cellfun('isempty',avoided_shock)); %on platform during shock
partial_avoid = partial_avoid(~cellfun('isempty',partial_avoid)); 
got_shock = shock_OFF(~cellfun('isempty',shock_OFF)); % off platform during shock
partial_shock = {};
for aa = 1:length(got_shock)
    if length(got_shock{aa}) < 50
        partial_shock{aa} = got_shock{aa};
        got_shock{aa} = [];
    else
        continue
    end
end
partial_shock = partial_shock(~cellfun('isempty',partial_shock)); 
got_shock = got_shock(~cellfun('isempty',got_shock));
%% Use times to get photometry data
avoids = []; avoid_x = [0]; avoid_y = [0];
gets = []; gets_x = [0]; gets_y = [0];
part = []; part_x = [0]; part_y = [0];
    for s = 1:length(avoided_shock) % 
        avoided_phot = find(newPhotTime >= onTimes(avoided_shock{s}(1))-padTime ...
            & newPhotTime <= onTimes(avoided_shock{s}(end))+padTime);
        avoids{s} = cell2mat({avoided_phot}); %add it to the cell array
        avoidLen(s) = length(avoided_phot);
        s_idx = avoids{1,s}; % gets the photometry indices
        avoid_x(s,1:length(s_idx)) = newPhotTime(s_idx); % gets the photometry timestamps (aligned)
        avoid_x(s,:) =avoid_x(s,:) - avoid_x(s,1)-padTime; % aligns all to shock at 0
        avoid_y(s,1:length(s_idx)) = zTDT(s_idx); % gets the photometry signal
    end
    avoid_y(avoid_y == 0) = NaN;  avoid_x(isnan(avoid_y)) = NaN;

for ss = 1:length(got_shock) % 
    gets_phot = find(newPhotTime >= offTimes(got_shock{ss}(1))-padTime ...
            & newPhotTime <= offTimes(got_shock{ss}(end))+padTime);
    gets{ss} = cell2mat({gets_phot}); %add it to the cell array
    getsLen(ss) = length(gets_phot);
    s_idx = gets{1,ss}; % gets the photometry indices
    gets_x(ss,1:length(s_idx))= newPhotTime(s_idx); % gets the photometry timestamps (aligned)
    gets_x(ss,:) = gets_x(ss,:) - gets_x(ss,1)-padTime; % aligns all to shock at 0
    gets_y(ss,1:length(s_idx)) = zTDT(s_idx); % gets the photometry signal
end
gets_y(gets_y == 0) = NaN; gets_x(isnan(gets_y)) = NaN;

for sss = 1:length(partial_shock) % 
    part_phot = find(newPhotTime >= offTimes(partial_shock{sss}(1))-padTime ...
            & newPhotTime <= offTimes(partial_shock{sss}(end))+padTime);
    part{sss} = cell2mat({part_phot}); %add it to the cell array
    partLen(sss) = length(part_phot);
    s_idx = part{1,sss}; % gets the photometry indices
    part_x(sss,1:length(s_idx))= newPhotTime(s_idx); % gets the photometry timestamps (aligned)
    part_x(sss,:) = part_x(sss,:) - part_x(sss,1)-padTime; % aligns all to shock at 0
    part_y(sss,1:length(s_idx)) = zTDT(s_idx); % gets the photometry signal
end
part_y(part_y == 0) = NaN; part_x(isnan(part_y)) = NaN;

if length(avoided_shock) == 0 && length(got_shock) == 0
    plot(part_x,part_y,'y.')
    legend('partial shock')
    disp('Note: only partial shocks detected')
else
        %continue doing rest of code to plot fully avoided or shocked
    if length(avoids) <= 1 % in case only one instance, make false error bars
       avoid_ymean = nanmean(avoid_y,1); avoid_err = zeros(1,length(avoid_y));
    else
        avoid_ymean = nanmean(avoid_y,1); avoid_err = nanstd(avoid_y)/sqrt(length(avoid_y));
    end

    if length(gets) <= 1 % in case only one instance, make false erro bars
       gets_ymean = nanmean(gets_y,1); gets_err = zeros(1,length(gets_y));
    else
        gets_ymean = nanmean(gets_y,1); gets_err = nanstd(gets_y)/sqrt(length(gets_y));
    end
end
%     figure
%     %errorbar(avoid_x(1,:),avoid_ymean,avoid_err,'k','CapSize',0)
%     shadedErrorBar(avoid_x(1,:),avoid_ymean,avoid_err,'lineProps',{'-b','MarkerFaceColor','g','LineWidth', 0.5})
%     hold on
%     plot(avoid_x(1,:),avoid_ymean,'k') % arbitrarily using the times from first row (they're all identical)
%     hold on
%     %errorbar(gets_x(1,:),gets_ymean,gets_err,'r','CapSize',0)
%     shadedErrorBar(gets_x(1,:),gets_ymean,gets_err,'lineProps',{'-b','MarkerFaceColor','r','LineWidth', 0.5})
%     hold on
%     plot(gets_x(1,:),gets_ymean,'r') % arbitrarily using the times from first row (they're all identical)
%     hold on
%     xline(0)
%     xline(2000,'--')
%     ylabel('z-scored GCamp6f signal')
%     xlabel('Time (ms)')
%     legend({' ','Avoided shock', ' ','Received shock','Shock start','Shock end'},'Location','NorthWest','FontSize',14)
%     axis([-2000 4000 -2 6])
%     set(gca,'fontsize',18)


%%  Quantification of shocks receved/avoided
av = []; sh = []; p_av = []; p_sh = [];
av = length(avoided_shock); sh = length(got_shock); p_av = length(partial_avoid); p_sh = length(partial_shock);
end
