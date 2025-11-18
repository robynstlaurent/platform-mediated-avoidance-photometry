%%% Funct to find the photometry indices when mouse is on or off the platform during
%%% a tone or a tone
% Desired output: plot the avg photometry response to a tone, vs avoided
% tone
function [av, sh, p_av, p_sh, avoid_x, avoid_ymean, gets_x, gets_ymean, part_x, part_ymean] = Align_photTone(fname)
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
     dlc = readmatrix(dlcname); %xlsread(dlcname); % 
else % readmatrix does work
  dlcname = strcat(fname,'.1.h264DLC_resnet_50_AA_v1Jun26shuffle1_700000.csv');
  if exist(dlcname)
      dlc = readmatrix(dlcname);
  else
    dlcname = (strcat(fname,'.1.h264DLC_resnet50_AA_v1Jun26shuffle1_250000.csv'));
    if exist(dlcname)
        dlc = readmatrix(dlcname);
    else
        dlcname = strcat(fname,'.1.h264DLC_resnet50_AA_v2Sep29shuffle1_1030000.csv');
        if exist(dlcname)
            dlc = readmatrix(dlcname);
                        else
            dlcname = strcat(fname,'.1.h264DLC_resnet50_stanfordAAMar1shuffle1_200000.csv');
            if exist(dlcname)
             dlc = readmatrix(dlcname);
             else
             dlcname = strcat(fname,'.1.h264croppedDLC_resnet50_stanfordAAMar1shuffle1_200000.csv');
            if exist(dlcname)
             dlc = readmatrix(dlcname);
            end
        end
    end
end
  end
end

bodycenterX = dlc(:,8); bodycenterY = dlc(:,9);
platformLcornerX = nanmedian(dlc(:,23)); platformLcornerY = nanmedian(dlc(:,24));
platformRcornerX = nanmedian(dlc(:,26)); platformRcornerY = nanmedian(dlc(:,27));
platformBRcornerX = nanmedian(dlc(:,29)); platformBRcornerY = nanmedian(dlc(:,30));
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
  if length(x3)  >= 2 && length(x2) >= 2 % Find diff btwn TTLs sent by statescript and received by photometry system
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
toneStart = trVals.toneStart;
toneEnd = toneStart + 30000;
% % % toneEnd = toneStart + 2000; disp('ANALYSIS of first 2s only');
videoTime_ms = videoTime*1000;
onTimes = videoTime_ms(ON>0); % actual video time (aligned to statescript, in ms)
offTimes = videoTime_ms(ON<1); % actual video time (aligned to statescript, in ms)

padTime = 000;
padTimeEnd = 000;
disp(strcat('You have selected to view', " ",string(padTime), ' milliseconds at the beginning'))
disp(strcat('You have selected to view', " ",string(padTimeEnd), ' milliseconds at the end'))
phottoneStart = [];

for i = 1:length(toneStart) % for every index in toneStart
    toneStart_phot = find(newPhotTime > toneStart(i)-padTime & newPhotTime < toneEnd(i)+padTimeEnd);
    phottoneStart{i} = cell2mat({toneStart_phot}); %add it to the cell array
    tone_ON{i} = find(onTimes >= toneStart(i) & onTimes <= toneEnd(i));
    tone_OFF{i} = find(offTimes >= toneStart(i) & offTimes <= toneEnd(i));
end

min_sigLen = min(cellfun('size',phottoneStart,2)); % find the shortest cell array
max_sigLen = max(cellfun('size', phottoneStart, 2)); % find the longest cell array
% Pad all the cells to match the longest
% fixes problem of trimming to shortest if it's shorter than desired bin
phottoneStart = cellfun(@(x) [x repmat(ceil(x(:,end)+1), 1, max_sigLen - size(x, 2))], phottoneStart, 'UniformOutput', false);
Phot_x = NaN(length(x1), max_sigLen);
Phot_y = NaN(length(x1), max_sigLen);

% figure % plots the photometry signal for each individual tone, regardless of location
for s = 1:length(x1) % x1 is the tone start
    s_idx = phottoneStart{1,s}; % gets the photometry indices
    Phot_x(s,:)= newPhotTime(s_idx); % gets the photometry timestamps (aligned)
    Phot_x(s,:) = Phot_x(s,:) - Phot_x(s,1)-padTime; % aligns all to start at 0
    Phot_y(s,:) = zTDT(s_idx); % gets the photometry signal
    %subplot(length(x1),1,s)
%     plot(Phot_x(s,:),Phot_y(s,:))
%     hold on
%     axis([0-padTime 30000+padTime -2 6])
%     title('Individual tones')
end

Phot_ymean = nanmean(Phot_y,1);
phot_err = nanstd(Phot_y)/sqrt(length(Phot_y));
% figure % plots the mean signal for all tones, regardless of location
% shadedErrorBar(Phot_x(1,:),Phot_ymean,phot_err,'lineProps',{'-b','MarkerFaceColor','b','LineWidth', 0.5})
% hold on
% plot(Phot_x(1,:),Phot_ymean,'k-') % arbitrarily using the times from first row (they're all identical)
% ylabel('z-scored GCamp6f signal')
% xlabel('Time (ms)')
% title('average across tones')
% axis([0-padTime 30000+padTime -2 2])

%% Gather photometry data during Shocks, separated by on vs. off platform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
avoided_tone = tone_ON(~cellfun('isempty',tone_ON)); %on platform during tone
partial_avoid = {};
% But need to eliminate partial avoided tones:
for a = 1:length(avoided_tone)
    if length(avoided_tone{a}) < 800
        partial_avoid{a} = avoided_tone{a};
        avoided_tone{a} = [];
    else
        continue
    end
end
avoided_tone = avoided_tone(~cellfun('isempty',avoided_tone)); % on platform during tone
partial_avoid = partial_avoid(~cellfun('isempty',partial_avoid)); 
got_tone = tone_OFF(~cellfun('isempty',tone_OFF)); % off platform during tone
partial_tone = {};
for aa = 1:length(got_tone)
    if length(got_tone{aa}) < 800
        partial_tone{aa} = got_tone{aa};
        got_tone{aa} = [];
    else
        continue
    end
end
partial_tone = partial_tone(~cellfun('isempty',partial_tone)); 
got_tone = got_tone(~cellfun('isempty',got_tone));
%% Use times to get photometry data
avoids = []; avoid_x = [0]; avoid_y = [0]; avoid_err = [];
gets = []; gets_x = [0]; gets_y = [0]; gets_err = [];
part = []; part_x = [0]; part_y = [0]; part_err = [];
    for s = 1:length(avoided_tone) % 
        avoided_phot = find(newPhotTime >= onTimes(avoided_tone{s}(1))-padTime ...
            & newPhotTime <= onTimes(avoided_tone{s}(end))+padTimeEnd);
        avoids{s} = cell2mat({avoided_phot}); %add it to the cell array
        avoidLen(s) = length(avoided_phot);
        s_idx = avoids{1,s}; % gets the photometry indices
        avoid_x(s,1:length(s_idx)) = newPhotTime(s_idx); % gets the photometry timestamps (aligned)
        avoid_x(s,:) =avoid_x(s,:) - avoid_x(s,1)-padTime; % aligns all to tone at 0
        avoid_y(s,1:length(s_idx)) = zTDT(s_idx); % gets the photometry signal
    end
    avoid_y(avoid_y == 0) = NaN;  avoid_x(isnan(avoid_y)) = NaN;

for ss = 1:length(got_tone) % 
    gets_phot = find(newPhotTime >= offTimes(got_tone{ss}(1))-padTime ...
            & newPhotTime <= offTimes(got_tone{ss}(end))+padTimeEnd);
    gets{ss} = cell2mat({gets_phot}); %add it to the cell array
    getsLen(ss) = length(gets_phot);
    s_idx = gets{1,ss}; % gets the photometry indices
    gets_x(ss,1:length(s_idx))= newPhotTime(s_idx); % gets the photometry timestamps (aligned)
    gets_x(ss,:) = gets_x(ss,:) - gets_x(ss,1)-padTime; % aligns all to tone at 0
    gets_y(ss,1:length(s_idx)) = zTDT(s_idx); % gets the photometry signal
end
gets_y(gets_y == 0) = NaN; gets_x(isnan(gets_y)) = NaN;

for sss = 1:length(partial_tone) % 
    part_phot = find(newPhotTime >= offTimes(partial_tone{sss}(1))-padTime ...
            & newPhotTime <= offTimes(partial_tone{sss}(end))+padTimeEnd);
    part{sss} = cell2mat({part_phot}); %add it to the cell array
    partLen(sss) = length(part_phot);
    s_idx = part{1,sss}; % gets the photometry indices
    part_x(sss,1:length(s_idx))= newPhotTime(s_idx); % gets the photometry timestamps (aligned)
    part_x(sss,:) = part_x(sss,:) - part_x(sss,1)-padTime; % aligns all to tone at 0
    part_y(sss,1:length(s_idx)) = zTDT(s_idx); % gets the photometry signal
end
part_y(part_y == 0) = NaN; part_x(isnan(part_y)) = NaN;

% means of the photometry matrixes for avoided, not avoided, partial
avoid_ymean = nanmean(avoid_y,1); gets_ymean = nanmean(gets_y,1);
part_ymean = nanmean(part_y,1);


if length(avoided_tone) == 0 && length(got_tone) == 0
%     figure
%     plot(part_x(1,:),part_ymean,'b-')
%     legend('partial tone')
else
        %continue doing rest of code to plot fully avoided or toneed
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

%  %% plot the photometry signal around the shock  
% if isnan(avoid_y(1,1)) == 1 %if the avoids_ymean matrix is empty, plot the gets
%     disp('no avoided tones')
%     figure
%     plot(gets_x(1,:),gets_ymean,'r','LineWidth', 2) % arbitrarily using the times from first row (they're all identical)
%     hold on
% %     err2 = shadedErrorBar(gets_x(1,:),gets_ymean,gets_err,'lineProps',{'-r','MarkerFaceColor','r','LineWidth', 1});
% %     err2.patchSaturation = 0.3;
%     legend({'Not Avoided'},'Location','NorthWest','FontSize',14)
% elseif isnan(gets_ymean(1,1)) == 1 % if the gets_ymean matrix is empty, plot the avoids
%     disp('all tones avoided')
%     figure
%     plot(avoid_x(1,:),avoid_ymean,'b','LineWidth', 2) % arbitrarily using the times from first row (they're all identical)
%     hold on
% %     err = shadedErrorBar(avoid_x(1,:),avoid_ymean,avoid_err,'lineProps',{'-b','MarkerFaceColor','b','LineWidth', 1});
% %     err.patchSaturation = 0.3;
%     legend({Avoided'},'Location','NorthWest','FontSize',14)
% else % or plot both
%     disp('plotting avoided and not avoided')
%     figure
%     hold on
%     plot(avoid_x(1,:),avoid_ymean,'b','LineWidth', 2) % arbitrarily using the times from first row (they're all identical)
%     hold on
% %     err = shadedErrorBar(avoid_x(1,:),avoid_ymean,avoid_err,'lineProps',{'-b','MarkerFaceColor','b','LineWidth', 1});
% %     err.patchSaturation = 0.3;
%     hold on
%     plot(gets_x(1,:),gets_ymean,'r','LineWidth', 2) % arbitrarily using the times from first row (they're all identical)
%     hold on
% %     err2 = shadedErrorBar(gets_x(1,:),gets_ymean,gets_err,'lineProps',{'-r','MarkerFaceColor','r','LineWidth', 1});
% %     err2.patchSaturation = 0.3;
%     legend({' ','Avoided tone', ' ','Not Avoided tone'},'Location','NorthWest','FontSize',14)
% end
% 
% %make the graph pretty
%     xline(30000,'r--', 'lineWidth',2,'label','SHOCK','FONTSIZE',14)
%     xline(32000,'r--','lineWidth',2)
%     ylabel('z-scored GCamp6f signal')
%     xlabel('Time (s)')
%     axis([-5000 5000 -2 5])
%     set(gca,'fontsize',14)
%     xticklabels([-5 0 5])

%%  Quantification of tones receved/avoided
av = length(avoided_tone); sh = length(got_tone); p_av = length(partial_avoid); p_sh = length(partial_tone);
end
