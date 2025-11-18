%%% Funct to find the photometry indices when mouse is on or off the platform during
%%% a tone or a shock
% Desired output: plot the avg photometry response to a shock, vs avoided
% shock
function [shockNum, Phot_x, Phot_y] = ShockxPhot(fname)
% clearvars -except fname
TDT = getPhotoSig_v2(fname);
zTDT = zscore(TDT.photoSig);
behname = strcat(fname,'_beh.mat');
load(behname);
videoTime = (strcat(fname,'.1.videoTimeStamps'));
if exist(videoTime)
    videoTime = readCameraModuleTimeStamps(videoTime);
else
    videoTime = readCameraModuleTimeStamps(strcat(fname,'.2.videoTimeStamps'));
end

dlcname = strcat(fname,'.1.h264DLC_resnet50_AA_v3Oct22shuffle1_500000.csv'); %changed all readmatrix to readmatrix on 6/19/24
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

x1 = trVals.toneStart; x2 = trVals.syncSent; % number TTL sent by Statescript
y2 = zeros(length(trVals.syncSent));
x3 = TDT.syncTime; y3 = zeros(length(TDT.syncTime));
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
            
% ***************************YOUR DESIRED TIME BIN HERE********************************************************
shockStart = trVals.toneStart + 30000;
shockEnd = shockStart + 2000;
shockNum = length(shockStart);
videoTime_ms = videoTime*1000;
onTimes = videoTime_ms(ON>0); % actual video time (aligned to statescript, in ms)
offTimes = videoTime_ms(ON<1); % actual video time (aligned to statescript, in ms)
padTime = 2000; % amount of extra you want before and after the shock
disp(strcat('You have selected to view', " ",string(padTime), ' milliseconds on each end'))
photshockStart = [];

for i = 1:length(shockStart) % for every index in shockStart
    shockStart_phot = find(newPhotTime > shockStart(i)-padTime & newPhotTime < shockEnd(i)+padTime);
    photshockStart{i} = cell2mat({shockStart_phot});  %add it to the cell array
end

min_sigLen = min(cellfun('size',photshockStart,2)); % find the shortest cell array
photshockStart = cellfun(@(x) x(:,1:min_sigLen),photshockStart,'UniformOutput',0); % trim all the cells to match the shortest
Phot_x = NaN(length(x1),min_sigLen);
Phot_y = NaN(length(x1),min_sigLen);

%% 
figure % plots the photometry signal for each individual shock, regardless of location
for s = 1:length(x1) % x1 is the shock start
    s_idx = photshockStart{1,s}; % gets the photometry indices
    Phot_x(s,:)= newPhotTime(s_idx); % gets the photometry timestamps (aligned)
    Phot_x(s,:) = Phot_x(s,:) - Phot_x(s,1)-padTime; % aligns all to start at 0
    Phot_y(s,:) = zTDT(s_idx); % gets the photometry signal
    %subplot(length(x1),1,s)
    plot(Phot_x(s,:),Phot_y(s,:))
    hold on
    axis([0-padTime 2000+padTime -2 6])
end

ylabel('z-scored GCamp6f signal')
xlabel('Time (ms)')

figure % plots the mean signal for all shocks, regardless of location
pY = nanmean(Phot_y,1); %#ok<*NANMEAN> 
pX = Phot_x(1,:);
pErr = nanstd(Phot_y)/sqrt(shockNum); %#ok<*NANSTD> 
plot(pX,pY,'k-') % arbitrarily using the times from first row (they're all identical)
hold on
shadedErrorBar(pX,pY,pErr,'lineProps',{'-b','MarkerFaceColor','b','LineWidth', 0.5})
hold on
xline(0)
ylabel('z-scored GCamp6f signal')
xlabel('Time (ms)')
title(fname)
axis([0-padTime 2000+padTime -2 6])
end
