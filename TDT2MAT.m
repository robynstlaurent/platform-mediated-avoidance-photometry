%% automatically grab raw TDT files and convert them to .mat format
disp('NOTE: must navigate to folder containing raw data')

% i = 1;
% getfNames_phot();
getfNames_AA();
% getfNames_OF();
% getfNames_FC();

for i = 1:length(fnames)

%[BLOCK_PATH] = uigetdir(); % if you want to select from a file window
[BLOCK_PATH] = fnames{i}; % if you want to specify a list
data = TDTbin2mat(BLOCK_PATH);
% fname = strcat(BLOCK_PATH(end-19:end),'Phot'); %change to 21 if _x file
fname = strcat(BLOCK_PATH,'Phot'); %change to 21 if _x file
save(fname,'data')
% i = i +1;
end