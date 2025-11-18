%%% Funct to find the photometry indices when mouse received reward
% input event at 1 if you want the reward retrieval or 0 if you want rew
% delivery (correct center port)
function [rewNum, Phot_x, Phot_y] = RewardxPhot(fname,event)
% clearvars -except fname
TDT = getPhotoSig_v2(fname);
zTDT = zscore(TDT.photoSig); % 
behname = strcat(fname,'_beh.mat');
load(behname);
videoTime = (strcat(fname,'.1.videoTimeStamps'));

if exist(videoTime)
    videoTime = readCameraModuleTimeStamps(videoTime);
else
    videoTime = readCameraModuleTimeStamps(strcat(fname,'.2.videoTimeStamps'));
end

dlcname = strcat(fname,'.1.h264DLC_resnet50_AA_v3Oct22shuffle1_500000.csv');
if exist(dlcname)
     dlc = readmatrix(dlcname);
else
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

x1 = trVals.trEnd; x2 = trVals.syncSent; % number TTL sent by Statescript
y2 = zeros(length(trVals.syncSent));
x3 = TDT.syncTime; y3 = zeros(length(TDT.syncTime)); disp(strcat('x3 is this long: ', num2str(length(x3))));
  if length(x3) >= 2 && length(x2)>= 2 % Find diff btwn TTLs sent by statescript and received by photometry system
            tdiff = (x2(2) - x2(1))/(x3(2)-x3(1)); %error here if only 1 TTL detected
        else
            tdiff =  1.0008e+03;
            disp('not enough TTLs to get clock differences')
  end 

x3 = x3*tdiff; shift_diff = x3(1)-x2(1);
x3_shift = x3 - shift_diff; % this adjusted TDT sync time to match trVals sync sent. 
% Now need to shift all of the photometry signal to match Time across both
newPhotTime = TDT.t*tdiff; newPhotTime = newPhotTime-shift_diff; % subtract offset     
            
% ***************************YOUR DESIRED EVENT and TIME BIN HERE********************************************************
if event == 1
    rewStart = trVals.trEnd;
    rewEnd = rewStart + 1000; % 1 second after event
elseif event == 0 
    rewStart = trVals.correctCenterTime;
    rewStart = rewStart(rewStart~=0);
    rewEnd = rewStart + 1000; % 1 second after event
    elseif event == 2
        rewStart = trVals.ITIpokeTime;
        rewStart = rewStart(rewStart~=0);
        rewEnd = rewStart + 1000; % 1 second after event
            elseif event == 3
                rewStart = trVals.inactivePortTime;
                rewStart = rewStart(rewStart~=0);
                rewEnd = rewStart + 1000; % 1 second after event
                elseif event == 4
                rewStart = trVals.activePortTime;
                rewStart = rewStart(rewStart~=0);
                rewEnd = rewStart + 1000; % 1 second after event
end

rewNum = length(rewStart);
if rewNum < 1
        disp('< 1 pokes')
        Phot_x = []; Phot_y = [];
else
videoTime_ms = videoTime*1000;
onTimes = videoTime_ms(ON>0); % actual video time (aligned to statescript, in ms)
offTimes = videoTime_ms(ON<1); % actual video time (aligned to statescript, in ms)
padTime = 2000; % amount of extra you want before and after the reward
disp(strcat('You have selected to view', " ",string(padTime), ' milliseconds on each end'))
photrewStart = [];

for i = 1:length(rewStart) 
    rewStart_phot = find(newPhotTime > rewStart(i)-padTime & newPhotTime < rewEnd(i)+padTime);
    photrewStart{i} = cell2mat({rewStart_phot});  %add it to the cell array
end

min_sigLen = min(cellfun('size',photrewStart,2)); % find the shortest cell array
photrewStart = cellfun(@(x) x(:,1:min_sigLen),photrewStart,'UniformOutput',0); % trim all the cells to match the shortest
Phot_x = NaN(length(x1),min_sigLen);
Phot_y = NaN(length(x1),min_sigLen);

%% 
% % figure % plots the photometry signal for each individual reward
for s = 1:length(photrewStart) % x1 is the reward delivery (trial end)
    s_idx = photrewStart{1,s}; % gets the photometry indices
    Phot_x(s,:)= newPhotTime(s_idx); % gets the photometry timestamps (aligned)
    Phot_x(s,:) = Phot_x(s,:) - Phot_x(s,1)-padTime; % aligns all to start at 0
    Phot_y(s,:) = zTDT(s_idx); % gets the photometry signal
%     %subplot(length(x1),1,s)
%     %plot(Phot_x(s,:),Phot_y(s,:))
% %     hold on
% %     axis([0-padTime 1000+padTime -5 5])
% %     set(gca,'fontsize',14)
% %     xticklabels([-10 -5 0 5 10])
end

% figure % plots the mean signal for all reward deliveries
% pY = nanmean(Phot_y,1); %#ok<*NANMEAN> 
% pX = Phot_x(1,:);
% plot(pX,pY,'k-') % arbitrarily using the times from first row (they're all identical)
% hold on
% if s > 1
%     pErr = nanstd(Phot_y)/sqrt(rewNum); %#ok<*NANSTD> 
%     shadedErrorBar(pX,pY,pErr,'lineProps',{'-b','MarkerFaceColor','b','LineWidth', 0.5})
% end
% ylabel('z-scored GCamp6f signal')
% xlabel('Time (s)')
% xline(0,'b--')
% title(fname)
% set(gca,'fontsize',14)
% axis([0-padTime 1000+padTime -2 2])
end
end
