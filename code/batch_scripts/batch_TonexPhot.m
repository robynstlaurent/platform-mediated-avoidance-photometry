% Photometry signal during shock for multiple mice and/or sessions,
% regardless of mouse location

addpath(genpath('G:\analyzed_data'))
addpath(genpath('G:\platform_AA\DATA'))

clearvars
getfNames_phot();

phot_mtx = []; 
x_mtx = [];
err_mtx = [];
toneNum_sum = 0;

for f = 1: length(fnames)
    [toneNum, Phot_x, Phot_y] = TonexPhot(fnames{f});
    phot_mtx{f} = Phot_y; % y values of phot signal
    x_mtx{f} = Phot_x; % x values of phot signal
    toneNum_sum = toneNum_sum + toneNum;
    disp(strcat(fnames{f}, ' file has this many tones: ', num2str(toneNum)))
end

% Gather the photometry signal around shocks 
maxLen = max(cellfun('size',phot_mtx,2));
toneMtx = nan(1,maxLen);
for i = 1:length(phot_mtx)
    if isnan(phot_mtx{i})
    continue
    else
        a = cell2mat(phot_mtx(i)); aLen = length(a);
        missingLen = maxLen-aLen; a = [a nan(size(a,1),missingLen)];
        toneMtx = [toneMtx;a];
    end
    a = [];
end
toneMtx = toneMtx(2:end,:); %remove first row of nans
starttoneMtx = toneMtx(:,1:2000);
endtoneMtx = toneMtx(:,4:end);
mean_tone = nanmean(toneMtx);
ste_tone= nanstd(toneMtx)/sqrt(toneNum_sum);

%%
figure
plot(Phot_x(1,:),mean_tone(1:length(Phot_x)),'g-') 
hold on
shadedErrorBar(Phot_x(1,:),mean_tone(1:length(Phot_x)),ste_tone(1:length(Phot_x)),'lineProps',{'-k','MarkerFaceColor','k','LineWidth', 1})
hold on
xline(0,'r--','lineWidth',2,'label','TONE','LabelVerticalAlignment', 'top','LabelHorizontalAlignment', 'left','FONTSIZE',14)
hold on
xline(30000,'r--', 'lineWidth',2,'label','END TONE','FONTSIZE',14,'alpha',0.3,'LabelVerticalAlignment', 'top', 'LabelHorizontalAlignment', 'left','labelorientation','aligned')
xline(32000,'r--','lineWidth',2,'alpha',0.3)
ylabel('z-scored GCamp6f signal')
xlabel('Time (s)')
xticklabels([-5 0 5 10 15 20 25 30 35])
% axis([-5000 35000 -0.5 1])
axis([-5000 35000 -0.5 1])
set(gca,'fontsize',14)
title('insert title')
box off
set(gcf,'units','inches','position',[5,5,3,3])
