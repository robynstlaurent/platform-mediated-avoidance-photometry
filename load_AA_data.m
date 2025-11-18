%% general function for loading AA data
function [dlc,trVals,videoTime,TDT,zTDT] = load_AA_data(fname,photometry)

clearvars -except fname fnames vnames photometry

% photometry data
if photometry == 1
    TDT = getPhotoSig(fname);
    zTDT = zscore(TDT.photoSig);
elseif photometry == 0
    TDT = [];
    zTDT = [];
end

% statescript data
behname = strcat(fname,'_beh.mat');
load(behname);
videoTimename = strcat(fname,'.4.videoTimeStamps');
if exist(videoTimename)
videoTime = readCameraModuleTimeStamps(videoTimename); 
else
    videoTimename = strcat(fname,'.2.videoTimeStamps');
    if exist(videoTimename)
    videoTime = readCameraModuleTimeStamps(videoTimename); 
    else
    videoTimename = strcat(fname,'.1.videoTimeStamps');
    videoTime = readCameraModuleTimeStamps(videoTimename); 
    end
end

% DeepLabCut data
dlcname = strcat(fname,'.1.h264DLC_resnet50_AA_v3Oct22shuffle1_500000.csv');
if exist(dlcname)
     dlc = readmatrix(dlcname); 
else 
  dlcname = strcat(fname,'.1.h264DLC_resnet_50_AA_v1Jun26shuffle1_700000.csv');
  if exist(dlcname)
      dlc = readmatrix(dlcname);
      else 
  dlcname = strcat(fname,'.2.h264DLC_resnet_50_AA_v1Jun26shuffle1_700000.csv');
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
            dlcname = strcat(fname,'.2.h264DLC_resnet50_stanfordAAMar1shuffle1_200000.csv');
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
disp(strcat('Finished loading data for: ',fname))
end