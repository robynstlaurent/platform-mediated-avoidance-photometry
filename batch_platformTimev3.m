%% Batch analysis of AA deeplabcut data
% written by Robyn St. Laurent, August 2021
 
%ASSUMPTION IS MADE THAT PLATFORM IS LOCATED IN BOTTOM LEFT OF
%VIDEO/BEHAVIOR BOX (DLCversion < 4) see below.
% % AND TONES ARE 30 SECONDS EACH

function [a, fnames,vnames, excelMtx, ON,OFF, totalONforSession, ONtone, ONshock, totTime, totFrames, shockTime, numTones,LengthofvideoTime] = batch_platformTimev3(DLCversion,n)
% enter the DLC network number (1-4) and number of files to load

% NOT flexible for filenames of varying stem length 'RS01012000x_01012000'
% If you have _2 extension on filename, just need to change lines 22-23 to
% add 2 extra in length (1:22 for fnames and 1:24 for vnames)

% %% Get the platform location from DeepLabCut
%load('AA_DLCversion.mat',fnames,DLCversion,videoNumber); 
    %% Import data
% fprintf(sprintf('%s%s%s','Please select ',num2str(n),' DeepLabCut generated .csv files \n'));  
% [filecsv,pathcsv] = uigetfile('*.csv','multiselect','on'); % show you only .csv files for user-friendliness
% for i = 1:n
%     filenamecsv = strcat(pathcsv,filecsv{i}); data_struct = importdata(filenamecsv); rawdata{i} = data_struct.data; % import data as matrix in a cell
%     fnames{i} = filecsv{i}(1:20); % this gives the filename from the imported csvs
%     vnames{i} = filecsv{i}(1:22); % this gives the video name because of .1 or .2 videos if restarted session
%     disp(filenamecsv);
% end
getfNames_phot()
for f = 1: length(fnames)
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
end
bodycenterX = dlc(:,8); bodycenterY = dlc(:,9);
platformLcornerX = nanmedian(dlc(:,23)); platformLcornerY = nanmedian(dlc(:,24));
platformRcornerX = nanmedian(dlc(:,26)); platformRcornerY = nanmedian(dlc(:,27));
platformBRcornerX = nanmedian(dlc(:,29)); platformBRcornerY = nanmedian(dlc(:,30));

%% For each file, find the time on platform
ONtone = []; OFFtone = []; ON = []; OFF = []; tones = []; numTones = []; fps = [];%initialize

for f = 1:n
        behname = strcat(fnames{f},'_beh.mat');
        load(behname);
        videoTime = readCameraModuleTimeStamps(strcat(vnames{f},'.videoTimeStamps')); %flexible if SS video number isn't 1
        frame_rate = length(videoTime)/(videoTime(end)-videoTime(1)); 
        fps(f) = frame_rate;
        %firstpoke = tStamps(1); firstpoke = firstpoke/1000; [val,vidx] = min(abs(videoTime - firstpoke)); % find first poke video index
        load(strcat(fnames{f},'_beh.mat'));
        % extract DLC data 
        bodycenterX =  rawdata{1,f}(:,8); bodycenterY = rawdata{1,f}(:,9);
        totFrames(f) = length(bodycenterX);
        platformLcornerX = nanmedian(rawdata{1,f}(:,23)); platformRcornerX = nanmedian(rawdata{1,f}(:,26)); platformBRcornerX = nanmedian(rawdata{1,f}(:,29));  
        platformLcornerY = nanmedian(rawdata{1,f}(:,24)); platformRcornerY = nanmedian(rawdata{1,f}(:,27)); platformBRcornerY = nanmedian(rawdata{1,f}(:,30));
        rewardportX = nanmedian(rawdata{1,f}(:,14)); rewardportY = nanmedian(rawdata{1,f}(:,15));
        % trim videotime to match DLC
        LengthofvideoTime(f) = length(videoTime); 

        
        if DLCversion < 4 | DLCversion > 4% default camera orientation, platform in bottom left corner (top right of pxel tracking)
         ON{f} = find((bodycenterX <= platformRcornerX & bodycenterY >= platformRcornerY)); %
        else %AAv4 is in the top left corner
        ON{f} = find((bodycenterX <= platformLcornerX & bodycenterY <= platformRcornerY)); %% use this one if platform is in top left corner of video (bottom left of pixel tracking)
        end
%         disp(DLCversion)
        
            OFF{f} = setdiff([1:length(bodycenterX)]',ON{f});   
            totalONforSession{f} = length(ON{f});

%         plot(bodycenterX(ON{f}),bodycenterY(ON{f}),'r.')
%         plot(bodycenterX(OFF{f}),bodycenterY(OFF{f}),'b.')
               
%         tones{f} = trVals.toneStart / 1000; %milliseconds, convert to seconds to match video stamps
%         toneEnd{f} = tones{f} +30; %30s after start of tone

%         tones{f} = (trVals.toneStart / 1000) + 20; % final 10s of tone only 
%         toneEnd{f} = tones{f} +10; %30s after start of tone
%         disp('WARNING WARNING WARNING: ANALYZING final 10s of tone)')

        tones{f} = (trVals.toneStart / 1000); %  
        toneEnd{f} = tones{f}+30;  % 30s after start of tone ************UPDATE HERE FOR PORTION OF TONE****************
        disp('(analyzing all 30s of tone)')

        platformDur = [];
        for t = 1:length(tones{f}) % for every index in toneStart
            platformDur(t) = length(find(videoTime(ON{f}) >= tones{f}(t) & videoTime(ON{f}) <= toneEnd{f}(t))); %#frames  
        end
        
        shocks{f} = trVals.toneStart/1000 + 30; %milliseconds, convert to seconds to match video stamps
        shockEnd{f} = shocks{f} +2; %30s after start of tone
        platShockTime = [];
        for s = 1:length(shocks{f})
           platShockTime(s) = length(find(videoTime(ON{f}) >= shocks{f}(s) & videoTime(ON{f}) <= shockEnd{f}(s))); %#frames
        end
        
        
        ONtone{f} = platformDur;  totTime{f} = sum(ONtone{f}); %total time on platform during tones
        ONshock{f} = platShockTime;  shockTime{f} = sum(ONshock{f});%total time on platform during shocks
        numTones{f} = length(ONtone{f});
        showTime = strcat(behname,' total time on platform is: ', num2str(totTime{f}),' frames for:  ',num2str(numTones{f}), ' tones.');
        disp(showTime)
        
end
%% For ease of transferring to Prism or excel
platmtx = NaN([21 16]); platmtx2= NaN(21,1); platmtx3 = NaN([21 16]); platmtx4= NaN(21,1);
for s = 1:n 
platmtx(s,1:numTones{s}) = ONtone{s}; % on platform during each tone
platmtx2(s) = totTime{s};
platmtx3(s,1:numTones{s}) = ONshock{s}; % on platform during each shock
platmtx4(s) = shockTime{s};
end

for s = 1:n
a(s) = size(ON{s},1);
end


excelMtx = [totalONforSession{:}; shockTime{:}; totTime{:}; totFrames; numTones{:}; fps];

