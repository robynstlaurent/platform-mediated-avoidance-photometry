%%% Function for converting TDT files from Stanford photometry rig

function TDT = getPhotoSig_v2(fname)

pname = strcat(fname,'Phot.mat');
load(pname);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SKIP IF ALREADY DONE:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
photoFileName = strrep(pname,'Phot.mat','_photoSig.mat');
TDT.fileName = photoFileName;
if ~exist(photoFileName)
     disp(['GENERATING FILE: ',photoFileName])
else
    disp([photoFileName, ' ALREADY EXISTS'])
    load(photoFileName)
    return;
end


[spectTimes,photoSig,isoSig] = spect_filter_v2(data);
fs = double(1/nanmedian(diff(spectTimes)));
oSig = pbFit_5min(photoSig,fs);

TDT.uncorrectedSig = photoSig;
TDT.photoSig = oSig;
TDT.isoSig = isoSig;

TDT.syncTime = getcamTTL_v2(fname); %getStatescriptTTL(fname); %changed this from Didi's b/c my TTL into cam port
TDT.t = spectTimes;

save(photoFileName,'TDT');
end
