function [spectTimes,photoSig,isoSig] = spect_filter_v2(data)
% Spectral filtering of raw modulated photometry signal (zeroLag)
% adapted from spect_Script SFO: 8.8.17
% for photometry collected in Malenka Lab 

rx = data.streams.Fi1r.data(3,:); %1:100000); % take first 100k points. Faster if constrict range!
Fs = data.streams.Fi1r.fs; % Sampling rate

freqRange = 100:5:1200; % Frequencies to calculate spectrogram in Hz
winSize = 0.04; % Window size for spectrogram (sec)
spectSample = 0.005; % Step size for spectrogram (sec)
inclFreqWin = 3; % Number of frequency bins to average (on either side of peak freq)
filtCut = 300; % Cut off frequency for low pass filter of data. **************** changed from 300 on 9/13/23

% Convert spectrogram window size and overlap from time to samples
spectWindow = 2.^nextpow2(Fs .* winSize);
spectOverlap = ceil(spectWindow - (spectWindow .* (spectSample ./ winSize)));
disp(['Calculating spectrum using window size ', num2str(spectWindow ./ Fs), '. Using Stanford conversion settings'])

% Create low pass filter for final data
lpFilt = designfilt('lowpassiir','FilterOrder',8, 'PassbandFrequency',400,...
    'PassbandRipple',0.01, 'SampleRate',Fs); % changed passbandfrequency from 300 on 9/13/23

% Calculate spectrogram
[spectVals,spectFreqs,spectTimes]=spectrogram(rx,spectWindow,spectOverlap,freqRange,Fs);
spectAmpVals = double(abs(spectVals));


% Find the two carrier frequencies ******ARE THESE DIFFERENT ON MALENKARIG?
avgFreqAmps = mean(spectAmpVals,2);
[pks,locs]=findpeaks(double(avgFreqAmps),'minpeakheight',max(avgFreqAmps./20)); %change to 100 if not finding iso signal

if length(pks)>1 % Kluge for when isosbestic LED not on
    sig2 = mean(abs(spectVals((locs(1)-inclFreqWin):(locs(1)+inclFreqWin),:)),1); % ******************* prior version assumed iso signal was locs(2)
    filtSig2 = filtfilt(lpFilt,double(sig2)); % isosBestic
    isoSig = filtSig2';
else
    isoSig = [];
end
% Calculate signal at each frequency band
sig1 = mean(abs(spectVals((locs(2)-inclFreqWin):(locs(2)+inclFreqWin),:)),1); % ******************* prior version assumed gcamp signal was locs(1)

% Low pass filter the signals
filtSig1 = filtfilt(lpFilt,double(sig1)); % gCaMP
photoSig = filtSig1';

% % remove outliers:%%%%%%%%%%% commented out because screws up some files
% rmIdx = find(zscore(photoSig)<=-4);
% spectTimes(rmIdx) = [];
% photoSig(rmIdx) = [];
% isoSig(rmIdx) = [];

%Convert signal to dF/F
normSig = (filtSig1 ./ filtSig2) ./ (mean(filtSig1 ./ filtSig2));

% Read in TDT data
tdtTs = (1:length(data.streams.x472N.data))./data.streams.x472N.fs;
normSigTdt = (data.streams.x472N.data./data.streams.x405N.data) ./ nanmean(data.streams.x472N.data./data.streams.x405N.data);



% Create figure to plot
plotFig = figure('color','w');
imAx = subplot(3,3,1:3,'parent',plotFig);
sigAx = subplot(3,3,4:6,'parent',plotFig); hold(sigAx,'on');
normAx = subplot(3,3,7:9,'parent',plotFig); hold(normAx,'on');

% Plot spectrogram image
imagesc('XData',spectTimes,'YData',spectFreqs,'CData',spectAmpVals,'parent',imAx);

% Plot 405 and 470 signals (unfiltered)
plot(spectTimes,sig1,'color',[0.5 0.5 1],'linewidth',0.5,'parent',sigAx);
plot(spectTimes,sig2,'color',[0.5 1 0.5],'linewidth',0.5,'parent',sigAx);
% Plot filtered signals
plot(spectTimes,filtSig1,'color',[0 0 0.7],'linewidth',2,'parent',sigAx);
plot(spectTimes,filtSig2,'color',[0 0.7 0],'linewidth',2,'parent',sigAx);

% Plot TDT signals
plot(spectTimes,normSig,'color',[0 0 0.7],'linewidth',2,'parent',normAx); 
plot(tdtTs,normSigTdt,'color',[0 0.7 0],'linewidth',2,'parent',normAx);
legend(normAx,{'SFO Calc','TDT Calc'},'location','northwest');
% plot(spectTimes,lpFiltData,'color','r','linewidth',2,'parent',sigAx);
% plot(spectFreqs,avgFreqAmps,'parent',freqAx);
% % % 
