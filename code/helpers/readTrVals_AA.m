function [tStamps, trVals, inStates, outStates, trialParams] = readTrVals_AA(fname,useMatFile)

% make sure you have statescript and mat files in your path
fpath = pwd;
addpath(genpath(fpath));
disp(['You are looking for statescript logs in: ', fpath]);
    
behFileName = strcat(fname,'_beh.mat');
fname = strcat(fname,'.stateScriptLog');
if useMatFile && exist(behFileName,'file')
    load(behFileName);
    disp([behFileName, 'ALREADY EXISTS: delete and make a new one if you changed readTrVals'])
else
    disp('MAT FILE DOES NOT YET EXIST. READING LOG FILE TO GENERATE')
    
    ttlNum = 0;
    trialNum = 0;
    allLineNum = 0;
    portLineNum = 0;
    eventLineNum = 0;
    tStamps = [];
    inStates = [];
    outStates = [];
    pokeNum = 0;
    toneNum = 0;

    
    trVals.trEnd = []; %for gathering timestamps of trial end times
    trVals.syncSent = [];%timestamps of TTL sent (tied to trial numbers)
    trVals.shockTrNum = 0; %for keeping tally of shocks received
    trVals.toneTrNum = 0; %for keeping tally of tones received
    trVals.toneStart = []; % gather timestamps of tone start
    trVals.toneEnd = []; % gather timestamps of tone end
    trVals.shockStart = []; % gather timestamps of shock start
    trVals.shockEnd = []; % gather timestamps of shock end
    trVals.inactivePortNum = 0; %keep track of total inactive port pokes
    trVals.activePortNum = 0; %keep track of total active port pokes, no reward
    trVals.ITIpokeNum = 0; %keep track of total center port pokes, no reward
    trVals.inactivePortTime = []; %timestamps of inactive port pokes
    trVals.activePortTime = []; %timestamps of active port pokes, no reward
    trVals.ITIpokeTime = []; %timestamps of center port pokes during ITI
    trVals.correctTrNum = 0;%keep track of total center port pokes, rewarded
    trVals.correctCenterTime = []; %timestamps of center port pokes, rewarded
    trVals.rewDelivery = 0; % number of rewards received in active port
    trVals.waterOut = 0; % timestamps of reward received in active port
    trVals.pokeNum = 0; %All pokes

    trialParams.mouseID = [];
    trialParams.minHoldTime = [];
    trialParams.maxHoldTime = [];
    trialParams.lowRP = [];
    trialParams.highRP = [];
    trialParams.weight = [];
    trialParams.taskID = [];
    trialParams.date = [];
    trialParams.time = [];
    trialParams.sessionID = [];
    trialParams.notes = [];
    
    %open log file for reading
    disp(fname);
    fid = fopen(fname);
   
    % scan the log file line-by-line
    % tline = fgetl(fid); %getting an error on this line
    tline = fgetl(fid); % that's lowercase L in fgetl
    while ischar(tline)%only read lines that start with a character
        findSpaces = find(tline == ' '); % Find spaces in current line
        % Only parse this line if it has spaces in it and that it begins with a
        % number (timestamp). Otherwise it is probably just '~~~' output from 
        % microcontroller
        if any(findSpaces) && any(str2double(tline(1:(findSpaces(1)-1))))
            % Output from microcontroller is timestamp followed by either:
            % (1) declaration of trial initiation or termination (text), or
            % (2) reporting port states (numeric)

            % Increment port state line counter
            allLineNum = allLineNum + 1;
            
            if isletter(tline(findSpaces(1)+1)) %if words are after space
                %pull out timestamp
                thisTime = str2double(tline(1:(findSpaces(1)-1)));
                eventLineNum = eventLineNum + 1;
                if strcmp(tline(findSpaces(1)+1),' ')
                    eventStrings{eventLineNum} = tline((findSpaces(1)+2):end);
                else
                    eventStrings{eventLineNum} = tline((findSpaces(1)+1):end);
                end
                eventTimes(eventLineNum) = str2double(tline(1:(findSpaces(1)-1)));
                
                if ~isempty(strfind(eventStrings{eventLineNum},'end Trial'))
                    trialNum = trialNum + 1;
                    trVals.trEnd(trialNum) = eventTimes(eventLineNum);
                end
                if ~isempty(strfind(eventStrings{eventLineNum},'tone on'))
                    trVals.toneTrNum = trVals.toneTrNum + 1;
                    toneNum = toneNum + 1;
                    trVals.toneStart(toneNum) = eventTimes(eventLineNum);
                end
                if ~isempty(strfind(eventStrings{eventLineNum},'tone off, shock on'))
                    trVals.shockTrNum = trVals.shockTrNum + 1;
                    trVals.shockStart(toneNum) = eventTimes(eventLineNum);
                    trVals.toneEnd(toneNum) = eventTimes(eventLineNum);
                end
                if ~isempty(strfind(eventStrings{eventLineNum},'shock off'))
                    trVals.shockEnd(toneNum) = eventTimes(eventLineNum);
                end
                
                if ~isempty(strfind(eventStrings{eventLineNum},'Center Poke not rewarded')) %ITI center poke 
                    pokeNum = pokeNum + 1;
                    trVals.pokeNum = pokeNum;
                    trVals.ITIpokeNum = trVals.ITIpokeNum + 1; %tally center port pokes, unrewarded
                    trVals.ITIpokeTime(pokeNum) = eventTimes(eventLineNum);
                end
                if ~isempty(strfind(eventStrings{eventLineNum},'Poke 3 not rewarded'))
                    pokeNum = pokeNum + 1;
                    trVals.pokeNum = pokeNum;
                    trVals.activePortNum = trVals.activePortNum + 1; %tally active ports, unrewarded
                    trVals.activePortTime(pokeNum) = eventTimes(eventLineNum);
                end
                if ~isempty(strfind(eventStrings{eventLineNum},'Poke 2 initiate')) %center poke after appropriate ITI
                    pokeNum = pokeNum + 1;
                    trVals.pokeNum = pokeNum;
                    trVals.correctTrNum = trVals.correctTrNum + 1; %tally center port pokes, rewarded
                    trVals.correctCenterTime(pokeNum) = eventTimes(eventLineNum);
                end
                if ~isempty(strfind(eventStrings{eventLineNum},'Poke 3 reward retreived')) 
                    pokeNum = pokeNum + 1;
                    trVals.pokeNum = pokeNum;
                    trVals.rewDelivery = trVals.rewDelivery + 1;
                    trVals.waterOut(pokeNum) = eventTimes(eventLineNum);
                end
                if ~isempty(strfind(eventStrings{eventLineNum},'Poke 1 not rewarded')) 
                    pokeNum = pokeNum + 1;
                    trVals.pokeNum = pokeNum;
                    trVals.inactivePortNum = trVals.inactivePortNum + 1; % tally inactive pokes
                    trVals.inactivePortTime(pokeNum) = eventTimes(eventLineNum); %timestamps
                end
                
                if ~isempty(strfind(eventStrings{eventLineNum},'TTL on')) 
                    ttlNum = ttlNum + 1;
                    trVals.syncSent(ttlNum) = eventTimes(eventLineNum);
                end
                
                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %                SESSION PARAMETERS                       %
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                if ~isempty(strfind(eventStrings{eventLineNum},'Mouse ID'))
                    trialParams.mouseID = eventStrings{eventLineNum}(...
                        (find(eventStrings{eventLineNum}==':')+1):end);
                end
                
                if ~isempty(strfind(eventStrings{eventLineNum},'weight'))
                    trialParams.weight = str2double(eventStrings{eventLineNum}(...
                        (find(eventStrings{eventLineNum}==':')+1):end));
                end
                if ~isempty(strfind(eventStrings{eventLineNum},'taskID'))
                    trialParams.taskID = eventStrings{eventLineNum}(...
                        (find(eventStrings{eventLineNum}==':')+1):end);
                end
                if ~isempty(strfind(eventStrings{eventLineNum},'date'))
                    trialParams.dateVal = eventStrings{eventLineNum}(...
                        (find(eventStrings{eventLineNum}==':')+1):end);
                end
                if ~isempty(strfind(eventStrings{eventLineNum},'time'))
                    trialParams.timeVal = eventStrings{eventLineNum}(...
                        (find(eventStrings{eventLineNum}==':')+1):end);
                end
                if ~isempty(strfind(eventStrings{eventLineNum},'sessionID'))
                    trialParams.sessionID = eventStrings{eventLineNum}(...
                        (find(eventStrings{eventLineNum}==':')+1):end);
                end

                if ~isempty(strfind(eventStrings{eventLineNum},'notes'))
                    trialParams.notes = eventStrings{eventLineNum}(...
                        (find(eventStrings{eventLineNum}==':')+1):end);
                end
                
            elseif ~isnan(str2double(tline(findSpaces(1)+1)))
                % Type 2 output has a number after the first space

                % Increment port state line counter
                portLineNum = portLineNum + 1;

                % Set time stamp for this line in the port state matrix
                tStamps(portLineNum) = str2double(tline(1:(findSpaces(1)-1)));

                % Convert in/out port state numbers to binary strings
                    inPortStateStr = ...
                        dec2bin(str2double(tline((findSpaces(1)+1):(findSpaces(2)-1))),8);%dec2bin converts to binary representation
                if size(findSpaces,2) > 2
                    outPortStateStr = ...
                        dec2bin(str2double(tline((findSpaces(2)+1):(findSpaces(3)-1))),8);
                else
                    try
                    outPortStateStr = ...
                        dec2bin(str2double(tline((findSpaces(2)+1):end)),8);
                    catch
                        disp('problem! missing output port state!');
                        outPortStateStr = dec2bin(0,8);
                    end
                end

                %Add another line to the in/out port state variables
                inStates(portLineNum,:)=zeros(1,8);
                outStates(portLineNum,:)=zeros(1,8);

                % Convert binary strings to doubles and write into in/out port
                % state matrix. Count down from port 8-to-1 because binary
                % string of port states is formatted as 8-7-6-5-4-3-2-1
                for portNum = 1:8
                    inStates(portLineNum, 9-portNum) = ...
                        str2double(inPortStateStr(portNum));
                    outStates(portLineNum,9-portNum) = ...
                        str2double(outPortStateStr(portNum));
                end
             end
        end
        % Read in the next line of the file
        tline = fgetl(fid);
    end
    fclose(fid);
%     
    save(behFileName,...
        'trialParams','trVals','tStamps','inStates','outStates');
end
