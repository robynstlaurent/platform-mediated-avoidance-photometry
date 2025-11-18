disp('Navigate to folder containing Phot.mat files')


% getfNames_phot();
% getfNames_AA();
getfNames_OF();
% getfNames_FC();

for f = 1:length(fnames)
    TDT=getPhotoSig_v2(fnames{f}); disp('This script works on Photometry collected at Stanford')
%     TDT=getPhotoSig(fnames{f}); disp('This script works on Photometry collected at Gladstone')
end