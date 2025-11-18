% Photometry signal during shock for multiple mice and/or sessions,
% regardless of mouse location

addpath(genpath('G:\analyzed_data'))
addpath(genpath('G:\platform_AA\DATA'))

clearvars
getfNames_phot();

phot_mtx = []; 
x_mtx = [];
err_mtx = [];
rewNum_sum = 0;

%% input 1 for reward retrieval, 0 for correct center poke, 2 for unrewarded center, 3 for inactive, 4 for unrewarded reward port
 r = 0;
 %%

for f = 1: length(fnames)
    [rewNum, Phot_x, Phot_y] = RewardxPhot(fnames{f},r); % input 1 for reward retrieval, 0 for correct center poke

    phot_mtx{f} = Phot_y; % y values of phot signal
    x_mtx{f} = Phot_x; % x values of phot signal
    rewNum_sum = rewNum_sum + rewNum;
    disp(strcat(fnames{f}, ' file has this many rewards: ', num2str(rewNum)))
    
end
% Gather the photometry signal around shocks 
maxLen = max(cellfun('size',phot_mtx,2));
rewMtx = nan(1,maxLen);
for i = 1:length(phot_mtx)
    if isnan(phot_mtx{i})
    continue
    else
        a = cell2mat(phot_mtx(i)); aLen = length(a);
        missingLen = maxLen-aLen; a = [a nan(size(a,1),missingLen)];
        rewMtx = [rewMtx;a];
    end
    a = [];
end

mean_rew = nanmean(rewMtx);
ste_rew= nanstd(rewMtx)/sqrt(rewNum_sum);

%%
figure
% plot(Phot_x(1,:),mean_rew(1:length(Phot_x)),'c-') 
% hold on
shadedErrorBar(Phot_x(1,:),mean_rew(1:length(Phot_x)),ste_rew(1:length(Phot_x)),'lineProps',{'-k','MarkerFaceColor','k','LineWidth', 4})
hold on
ylabel('GCamp6f signal (z)')
xlabel('Time (s)')
% xticklabels([-10 -5 0 5 10])
axis([-2000 3000 -1 1])
text(-9900,-1.35,strcat('n = ', num2str(f),' mice',' (',num2str(rewNum_sum), ' rewards)'))
set(gca,'fontsize',14)
set(gca,'color','none')
set(gca,'TickDir','out');
set(gcf,'units','inches','position',[5,5,3,3])
box('off')

if r == 0
    xline(0,'b--','label','rewarded center poke','LabelOrientation','horizontal','LabelHorizontalAlignment','center','LabelVerticalAlignment','bottom','FontSize',18)
elseif r == 1
    xline(0,'b--','label','reward retrieval','LabelOrientation','horizontal','LabelHorizontalAlignment','center','LabelVerticalAlignment','bottom','FontSize',18)
    elseif r == 2
        xline(0,'b--','label','unrewarded center poke','LabelOrientation','horizontal','LabelHorizontalAlignment','center','LabelVerticalAlignment','bottom','FontSize',18)
         elseif r == 3
        xline(0,'b--','label','inactive port entry','LabelOrientation','horizontal','LabelHorizontalAlignment','center','LabelVerticalAlignment','bottom','FontSize',18)
        elseif r == 4
        xline(0,'b--','label','reward port entry','LabelOrientation','horizontal','LabelHorizontalAlignment','center','LabelVerticalAlignment','bottom','FontSize',18)
end