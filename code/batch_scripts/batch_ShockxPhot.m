% Photometry signal during shock for multiple mice and/or sessions,
% regardless of mouse location

addpath(genpath('G:\analyzed_data'))
addpath(genpath('G:\platform_AA\DATA'))

clearvars
getfNames_phot();

phot_mtx = []; 
x_mtx = [];
err_mtx = [];
shockNum_sum = 0;

for f = 1: length(fnames)
    [shockNum, Phot_x, Phot_y] = ShockxPhot(fnames{f});
    phot_mtx{f} = Phot_y; % y values of phot signal
    x_mtx{f} = Phot_x; % x values of phot signal
    shockNum_sum = shockNum_sum + shockNum;
    disp(strcat(fnames{f}, ' file has this many shocks: ', num2str(shockNum)))
end

% Gather the photometry signal around shocks 
maxLen = max(cellfun('size',phot_mtx,2));
shockMtx = nan(1,maxLen);
for i = 1:length(phot_mtx)
    if isnan(phot_mtx{i})
    continue
    else
        a = cell2mat(phot_mtx(i)); aLen = length(a);
        missingLen = maxLen-aLen; a = [a nan(size(a,1),missingLen)];
        shockMtx = [shockMtx;a];
    end
    a = [];
end

mean_shock = nanmean(shockMtx);
ste_shock = nanstd(shockMtx)/sqrt(shockNum_sum);

%%
figure
plot(Phot_x(1,:),mean_shock(1:length(Phot_x)),'g-') 
hold on
shadedErrorBar(Phot_x(1,:),mean_shock(1:length(Phot_x)),ste_shock(1:length(Phot_x)),'lineProps',{'-g','MarkerFaceColor','g','LineWidth', 4})
hold on
xline(0,'--')
xline(2000,'--')
ylabel('z-scored GCamp6f signal')
xlabel('Time (s)')
xticklabels([-2 -1 0 1 2 3 4])
axis([-2000 4000 -2 6])
set(gca,'fontsize',14)
title('insert title')
