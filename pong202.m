%% variable names
% tuning parameters
% fLow: low end of frequency spectrum of interest (e.g. alpha wave band)
% fHigh: high end of frequency spectrum of interest (e.g. alpha wave band)
% dataPeriod: time between data collection attempts
% ballVelocity: speed of the ball, should generally range 0.001-0.1
% paddleVelocityFast: paddle movement speed when alpha waves not detected
% paddleVelocitySlow: paddle movement speed when alpha waves detected
% thresholdSkew: allows for higher/lower sensitivity threshold value
% calibrationDuration: duration of recording time for each calibration step
% 
% p1,p2 struct
% t: vector of timestamps for current EEG data
% data: vector of timeseries amplitudes for current EEG data
% energyAlpha: average energy between fLow, fHigh in current EEG data
% threshold: comparison value to determine paddle speed
% calibrate: set to 1 to save all data in calibrationData for calibration
% calibrationData: stores past data values to be used for averaging
%
%% function names and definitions
% connect(): make connection to TCP port
%
% collectData(): start Intan data collection, should update p1.t, 
% p2.data, p1.data, p2.data with Intan data
%
% processData(): process data in p1.t, p2.data, p1.data, p2.data;
% should measure the energy of for both players between 7-13Hz; set value
% of p1.energyAlpha, p2.energyAlpha to the energy values
%
% game(): should start pong game, continually refresh; should use
% processData values p1.energyAlpha and p2.energyAlpha (along with
% p1.threshold and p2.threshold) in order to update the paddle velocities
% for p1 and p2
%
% threshold: these are the threshold values for the 
% energy of the 7-13Hz frequency components; if the energy is above this
% threshold, alpha waves are detected, and if the energy is below this
% threshold, no alpha waves are detected; this value should be somewhere
% between the noise level (i.e. no alpha waves) and the alpha wave level
%

function pong202()
    close all; clear; clc;
    delete(timerfindall);
    x=load("lp10k.mat","lp10k");

    %% --------------------------------------------------------------------
    % tuning parameters
    fLow = 7; fHigh = 13; % use alpha waves (7-13Hz) by default (can be modified later)
    ballVelocity = 0.003; % ball speed
    paddleVelocityFast = 0.01; % paddle rate when alpha waves not detected
    paddleVelocitySlow = 0.001; % paddle rate when alpha waves detected
    dataPeriod = 0.08; % time between data collection attempts
    thresholdSkew = 0.3; % can favor higher or lower threshold (smaller value makes it more sensitive)
    calibrationDuration = 15; % time (seconds) for each calibration step
    numRepsBeforeProcess = 7; % number of data retrievals before processing data
%     fftLength = 1280*2*numRepsBeforeProcess; % set length of fft

    % flags
    filterFlag = 0; % set 1 to low-pass filter data using lp10k filter
    plotFlag = 0; % set 1 to plot time series data live
    alphaEnergyPrintFlag = 1; % set 1 to print alpha energy values


    %% --------------------------------------------------------------------
    % initialize variables
    % TCP connection variables
    tcommand = [];
    twaveformdata = [];
    typeString = [];
    fs = 10e3;
    timestep = 0;
    numAmpChannels = 2;
    initialized = 0;
    stopped = 1;
    framesPerBlock = 128;
    waveformBytesPerFrame = 0;
    waveformBytesPerBlock = 0;
    blocksPerRead = 10;
    waveformBytes10Blocks = 0;
    amplifierData = [];
    amplifierTimestamps = [];
    amplifierTimestampsIndex = 1;
    chunkCounter = 0;
    currentPlotBand = 'Low';
    channels = [10, 11];
    repCount = 1;
    if plotFlag
        ampDataFigure = figure(10);
        ampDataFigure.Name = ['Amplifier Data - ', currentPlotBand];
    end

    minAxis = 0;
    maxAxis = 0;
    % define p1, p2
    p1 = struct('t',zeros(1,1280*numRepsBeforeProcess), ...
        'data', zeros(1,1280*numRepsBeforeProcess), ...
        'energyAlpha', 0, ...
        'threshold', 0, ...
        'direction', 1, ...
        'calibrate', 0, ...
        'lowerThreshold', 0, ...
        'upperThreshold', 0, ...
        'configState', 0, ...
        'calibrationData', []);

    p2 = struct('t',zeros(1,1280*numRepsBeforeProcess), ...
        'data', zeros(1,1280*numRepsBeforeProcess), ...
        'energyAlpha', 0, ...
        'threshold', 0, ...
        'direction', 1, ...
        'calibrate', 0, ...
        'lowerThreshold', 0, ...
        'upperThreshold', 0, ...
        'configState', 0, ...
        'calibrationData', []);

    %% --------------------------------------------------------------------
    %% initialize GUI
    figMain = uifigure('Name','EEG Pong Control Pannel');
    figMain.Position = [200 300 500 250];
    
    % button to connect to board
    bConnect = uibutton(figMain,'push',...
                'Text', 'Connect', ...
               'Position',[50, 200, 100, 22],...
               'ButtonPushedFcn', @(bConnect,event) connect);

    bCalibration = uibutton(figMain,'push',...
                'Text', 'OpenCalibration GUI', ...
               'Position',[175, 200, 150, 22],...
               'ButtonPushedFcn', @(bCalibration,event) configGUI); 

    bPong = uibutton(figMain,'push',...
                'Text', 'Play Pong', ...
               'Position',[350, 200, 100, 22],...
               'ButtonPushedFcn', @(bPong,event) startGame(figMain));


    bClose = uibutton(figMain,'push',...
                'Text', 'Exit', ...
               'Position',[350, 100, 100, 22],...
               'ButtonPushedFcn', @(bClose,event) closeMainGui(figMain));

    figMain.DeleteFcn = @deleteDataCollection;

    function configGUI()
        figConfig = uifigure('Name','Configure GUI');
        figConfig.Position = [200 300 400 250];
        
        ttl_p1 = uilabel(figConfig);
        ttl_p1.Text = 'Configure Player 1';
        ttl_p1.Position = [50 200 100 15];
        txt_p1 = uilabel(figConfig);
        txt_p1.Text = 'Record with eyes open';
        txt_p1.Position = [40 130 130 15];
        
        ttl_p2 = uilabel(figConfig);
        ttl_p2.Text = 'Configure Player 2';
        ttl_p2.Position = [250 200 100 15];
        txt_p2 = uilabel(figConfig);
        txt_p2.Text = 'Record with eyes open';
        txt_p2.Position = [240 130 130 15];
        
        cfgBtnP1 = uibutton(figConfig,'push','Position',[50, 100, 100, 22],'Text','Start Recording','ButtonPushedFcn', @(cfgBtnP1,event) configPlayer1(cfgBtnP1,txt_p1));
        cfgBtnP2 = uibutton(figConfig,'push','Position',[250, 100, 100, 22],'Text','Start Recording','ButtonPushedFcn', @(cfgBtnP2,event) configPlayer2(cfgBtnP2,txt_p2));
        closeConfigBtn = uibutton(figConfig,'push','Position',[150, 50, 100, 22],'Text','Done','ButtonPushedFcn', @(closeConfigBtn,event) closeConfig(figConfig));

        function closeConfig(fig)
            close(fig);
        end

        function configPlayer1(btn1,lbl)
            curState = p1.configState;
            p1.configState = curState + 1;
            if p1.configState == 1
                btn1.Text = "Recording";
                btn1.BackgroundColor ='g';
                p1.calibrate = 1; % start calibration
                pause(calibrationDuration);
                p1.calibrate = 0; % end calibration
                % display(p1.calibrationData);
                p1.lowerThreshold = mean(p1.calibrationData); % process calibration data
                fprintf("Player 1 lowerThreshold: %f \n", p1.lowerThreshold)
                p1.calibrationData = []; % clear calibration data after processing
                configPlayer1(btn1,lbl)
            elseif p1.configState == 2
                lbl.Text = 'Record with eyes Closed';
                lbl.Position = [30 130 135 15];
                btn1.Text = "Start Recording";
                btn1.BackgroundColor = [0.96 0.96 0.96];
            elseif p1.configState == 3
                btn1.Text = "Recording";
                btn1.BackgroundColor ='g';
                p1.calibrate = 1; % start calibration
                pause(calibrationDuration);
                p1.calibrate = 0; % end calibration
                p1.upperThreshold = mean(p1.calibrationData); % process calibration data
                fprintf("Player 1 upperThreshold: %f \n", p1.upperThreshold)
                p1.calibrationData = []; % clear calibration data after processing
                configPlayer1(btn1,lbl)
            elseif p1.configState == 4
                lbl.Text = 'Done Configuring';
                lbl.Position = [55 130 100 15];
                btn1.Text = "Restart";
                btn1.BackgroundColor = [0.96 0.96 0.96];
                try
                    p1.threshold = ((1-thresholdSkew)*p1.lowerThreshold)+(thresholdSkew*p1.upperThreshold);%thresholdSkew*(p1.lowerThreshold+p1.upperThreshold);
                catch
                    warning("Calaculation of Player 1 Threshold Failed.");
                end
                fprintf("Player 1 Threshold: %f \n", p1.threshold)
            else
                lbl.Text = 'Record with eyes open';
                lbl.Position = [40 130 130 15];
                btn1.Text = "Start Recording";
                p1.configState= 0;
            end
        end
        
        function configPlayer2(btn2,lbl)
            curState = p2.configState;
            p2.configState = curState + 1;
            if p2.configState == 1
                btn2.Text = "Recording";
                btn2.BackgroundColor ='g';
                p2.calibrate = 1; % start calibration
                pause(calibrationDuration);
                p2.calibrate = 0; % end calibration   
                p2.lowerThreshold = mean(p2.calibrationData); % process calibration data
                fprintf("Player 2 lowerThreshold: %f \n", p2.lowerThreshold)
                p2.calibrationData = []; % clear calibration data after processing
                configPlayer2(btn2,lbl)
            elseif p2.configState == 2
                lbl.Text = 'Record with eyes Closed';
                lbl.Position = [230 130 135 15];
                btn2.Text = "Start Recording";
                btn2.BackgroundColor = [0.96 0.96 0.96];
            elseif p2.configState == 3
                btn2.Text = "Recording";
                btn2.BackgroundColor ='g';
                p2.calibrate = 1; % start calibration
                pause(calibrationDuration);
                p2.calibrate = 0; % end calibration
                p2.upperThreshold = mean(p2.calibrationData); % process calibration data
                fprintf("Player 2 upperThreshold: %f \n", p2.upperThreshold)
                p2.calibrationData = []; % clear calibration data after processing
                configPlayer2(btn2,lbl)
            elseif p2.configState == 4
                lbl.Text = 'Done Configuring';
                lbl.Position = [255 130 100 15];
                btn2.Text = "Restart";
                btn2.BackgroundColor = [0.96 0.96 0.96];
                try
                    p2.threshold = ((1-thresholdSkew)*p2.lowerThreshold)+(thresholdSkew*p2.upperThreshold);
                catch
                    warning("Calaculation of Player 2 Threshold Failed.");
                end
                fprintf("Player 2 Threshold: %f \n", p2.threshold)
            else
                lbl.Text = 'Record with eyes open';
                lbl.Position = [240 130 130 15];
                btn2.Text = "Start Recording";
                p2.configState= 0;
            end
        end
    end

    function startGame(figMain)
        fprintf("\n--------------------------------------------------------------------\n")
        fprintf("STARTING GAME\n")
        figMain.Visible = 'off';

        start(tGame);
    end

    function closeMainGui(figMain)
        try
            %delete(timerfindall);
            close all;
            close(figMain);
        catch
            warning("Closing GUI resulted in error");
        end
    end

    %% --------------------------------------------------------------------
    % set up pong game figure
    figPong = figure('Name', 'PONG', ...
        'Color', [.1 .1 .1], ...
        'WindowStyle', 'modal', ...
        'NumberTitle', 'off', ...
        'Resize', 'off');
  
    ax = axes(figPong, ...
        'Box', 'off', ...
        'XColor', 'k', ...
        'YColor', 'k', ...
        'Color', 'k', ...
        'TickLength', [0 0], ...
        'XLim', [0 1], ...
        'YLim', [0 1], ...
        'Position', [0 0 1 1]);
    curPixPos = getpixelposition(ax);
    setpixelposition(ax, curPixPos + [30 30 -60 -60]);
    ax.Toolbar.Visible = 'off';

    % draw scores
    scores = [0 0];
    scoreP1 = text(ax, 0.3, 0.5, '0',...
        'Color', [.1 .1 .1],...
        'HorizontalAlignment', 'center',...
        'VerticalAlignment', 'middle',...
        'FontSize',72);
    scoreP2 = text(ax, 0.7, 0.5, '0',...
        'Color', [.1 .1 .1],...
        'HorizontalAlignment', 'center',...
        'VerticalAlignment', 'middle',...
        'FontSize',72);
    text(ax, 0.5, 0.5, '-', ...
        'Color', [.1 .1 .1], ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'FontSize', 72);
    % draw paddles
    ph = 0.3;
    pw = 0.02;
    paddleP1 = rectangle(ax, ...
        'Position', [0, .5 - .5 * ph, pw, ph], ...
        'FaceColor', 'w', ...
        'LineStyle', 'none');
    paddleP2 = rectangle(ax, ...
        'Position', [1 - pw, .5 - .5 * ph, pw, ph], ...
        'FaceColor', 'w', ...
        'LineStyle', 'none');

    % draw ball
    bh = 0.02 * (figPong.Position(3) / figPong.Position(4));
    bw = 0.02;
    ball = rectangle(ax, ...
        'Position', [.5 .5 - .5*bh bw bh], ...
        'FaceColor', 'w', ...
        'LineStyle', 'none');

    % initialise velocities
    bvx = 0;
    bvy = 0;
    
    tData = timer('Period', dataPeriod, ...
        'ExecutionMode', 'fixedRate', ...
        'TimerFcn', @onDataTimer, ...
        'BusyMode', 'drop');

    tGame = timer('Period', round(1/30, 3), ...
        'TimerFcn', @onGameTimer, ...
        'ExecutionMode', 'fixedRate', ...
        'BusyMode', 'queue');

    figPong.DeleteFcn = @deletePong;
    reset;
    


    %% --------------------------------------------------------------------
    % test commands
    % can add test commands here to test if code is working; example:
%     gameTest;
%     fullTest;


    % full test, including connecting to TCP, calibration for both players,
    % running game
    function fullTest
        connect;
        start(tData);
        calibrateP1;
        calibrateP2;
        display(p1.threshold);
        display(p2.threshold);
    
        fprintf("\n--------------------------------------------------------------------\n")
        fprintf("STARTING GAME\n")
        start(tGame);
        pause(10);
        stop(tData);
        delete(tData);
    %     fprintf("waveformbytes10blocks: "+waveformBytes10Blocks+"\n");
    end

    % use gameTest to check if game is functioning correctly
    function gameTest
        start(tGame);
        fprintf("both paddles fast\n");
        pause(5);
        fprintf("paddle 1 slow\n")
        p1.energyAlpha = 10;
        pause(5);
        fprintf("both paddles slow\n");
        p2.energyAlpha = 10;
        pause(10);
    end

    %% --------------------------------------------------------------------
    % connect function
    % function to initialize connection to TCP port, should start the data
    % and process timers
    function connect
        fprintf("\n--------------------------------------------------------------------\n")
        fprintf("CONNECTING TO TCP PORT\n\n")
        % if initialized == 0, need to connect to TCP port
        if initialized == 0
            % connect to TCP port
            % start data collection and data processing timers
            fprintf("connecting to TCP command server...\n");
            tcommand = tcpclient('localhost', 5000);
            fprintf("connecting to TCP waveform server...\n");
            twaveformdata = tcpclient('localhost', 5001);
            fprintf("clearing current TCP outputs...\n");
            sendCommand('execute clearalldataoutputs');
    
            fprintf("enabling channels...\n");
            sendCommand('get type');
            commandReturn = readCommand();
            if strcmp(commandReturn, 'Return: Type ControllerRecordUSB2')
                typeString = 'ControllerRecordUSB2';
            elseif strcmp(commandReturn, 'Return: Type ControllerRecordUSB3')
                typeString = 'ControllerRecordUSB3';
            elseif strcmp(commandReturn, 'Return: Type ControllerStimRecordUSB2')
                typeString = 'ControllerStimRecordUSB2';
            else
                error('Unrecognized Controller Type');
            end
            
            % calculate timestep based on sample rate
            fs = getSampleRate();
            timestep = 1/fs;
    
            % send TCP commands to set up TCP Data Output Enabled for all bands
            % of 1 channel
            for i = 1:length(channels)
                channelName = ['a-' num2str(channels(i) - 1, '%03d')];
                commandString = ['set' channelName '.tcpdataoutputenabled true;'];
%                 commandString = [commandString ' set ' channelName '.tcpdataoutputenabledwide true;'];
                commandString = [commandString ' set ' channelName '.tcpdataoutputenabledlow true;'];
                commandString = [commandString ' set ' channelName '.tcpdataoutputenabledhigh true;'];
                commandString = [commandString ' set ' channelName '.tcpdataoutputenabledspike false;'];
                sendCommand(commandString);
            end
    
            fprintf("preparing MATLAB to start streaming...\n");
            pause(1);
    
            initialized = 1;
        end

        % mark system as running
        stopped = 0;

        numBandsPerChannel = 2;
        numAmplifierBands = numBandsPerChannel * numAmpChannels;
        
        waveformBytesPerFrame = 4 + 2 * numAmplifierBands;
        waveformBytesPerBlock = framesPerBlock * waveformBytesPerFrame + 4;
        blocksPerRead = 10;
        waveformBytes10Blocks = blocksPerRead * waveformBytesPerBlock;

        amplifierData = 32768 * ones(numAmpChannels, framesPerBlock * 10);
        amplifierTimestamps = zeros(1, framesPerBlock * 10);

        amplifierTimestampsIndex = 1;

        chunkCounter = 0;
        
        % start board running
        fprintf("streaming data...\n");
        write(tcommand, uint8('set runmode run'));
        start(tData);
    end

    %% --------------------------------------------------------------------
    % function to collect data from Intan
    function collectData
        % if twaveformdata has been closed already, just exit
        if twaveformdata == 0
            return;
        end
        
        % reset amplifierData, amplifierTimestamps
        amplifierData = 32768 * ones(numAmpChannels, framesPerBlock * 10);
        amplifierTimestamps = zeros(1, framesPerBlock * 10);

        % read waveform data in 10-block chunks
        if twaveformdata.BytesAvailable >= waveformBytes10Blocks
            drawnow;
            % fprintf("Num of bytes avaible: %d \n", twaveformdata.BytesAvailable);

            % track which 10-block chunk has just come in; if there have
            % already been 10 blocks plotted, reset to 1
            chunkCounter = chunkCounter + 1;
            if chunkCounter > 10
                chunkCounter = 1;
            end

            % exit now if user has requested stop
            if stopped == 1
                return;
            end

            waveformArray = read(twaveformdata, waveformBytes10Blocks);
            % fprintf("Length of waveformArray: %d \n", length(waveformArray));
            rawIndex = 1;

            for block = 1:blocksPerRead
                % expect 4 bytes to be TCP magic number as uint32
                % if not what's expected, print there was an error
                [magicNumber, rawIndex] = uint32ReadFromArray(waveformArray, rawIndex);
                if magicNumber ~= 0x2ef07a08
                    fprintf(1, 'Error... block %d magic number incorrect.\n', block);
                end
          
                % each block should contain 128 frames of data - process each
                % of these one-by-one
                for frame = 1:framesPerBlock
                    % expect 4 bytes to be timestamp as int32
                    [amplifierTimestamps(1, amplifierTimestampsIndex), rawIndex] = int32ReadFromArray(waveformArray, rawIndex);
                    amplifierTimestamps(1, amplifierTimestampsIndex) = timestep * amplifierTimestamps(1, amplifierTimestampsIndex);
                    % parse all bands of amplifier channels
                    for channel = 1:numAmpChannels
                        if strcmp(currentPlotBand, 'Wide')
                            % 2 bytes of wide, then 2 bytes of low (ignored)
                            % then 2 bytes of high (ignored)
                            [amplifierData(channel, amplifierTimestampsIndex), rawIndex] = uint16ReadFromArray(waveformArray, rawIndex);
                            rawIndex = rawIndex + (2 * 2);
                        elseif strcmp(currentPlotBand, 'Low')
                            % 2 bytes of wide (ignored), then 2 bytes of low,
                            % then 2 bytes of high (ignored)
%                             rawIndex = rawIndex + 2;
                            [amplifierData(channel, amplifierTimestampsIndex), rawIndex] = uint16ReadFromArray(waveformArray, rawIndex);
                            rawIndex = rawIndex + 2;
                        else
                            % 2 bytes of wide (ignored), then 2 bytes of low
                            % (ignored), then 2 bytes of high
                            rawIndex = rawIndex + (2 * 2);
                            [amplifierData(channel, amplifierTimestampsIndex), rawIndex] = uint16ReadFromArray(waveformArray, rawIndex);
                        end
                    end
                    amplifierTimestampsIndex = amplifierTimestampsIndex + 1;
                end
            end
            % For every 10 chunks, recalculate the minimum and maximum time
            % values that will be plotted (and should be used both during spike
            % and waveform plotting)
            if chunkCounter == 1
                minAxis = amplifierTimestamps(1,1);
                maxAxis = minAxis + 100 * framesPerBlock * timestep;
            end
            amplifierData = 0.195 * (amplifierData - 32768);
    

            % plot the filter data if checked
            if filterFlag == 1
                filterData;
                fprintf("filteringData");
            end
            
            % update p1 and p2 data/timestamps
            p1.t(1+(repCount-1)*1280:1280*repCount) = amplifierTimestamps;
            p1.data(1+(repCount-1)*1280:1280*repCount) = amplifierData(1,:);
            p2.t(1+(repCount-1)*1280:1280*repCount) = amplifierTimestamps;
            p2.data(1+(repCount-1)*1280:1280*repCount) = amplifierData(2,:);
            
%             % only process data after certain amount of data has been
%             % collected
%             if repCount < numRepsBeforeProcess
%                 repCount = repCount+1;
%             else
%                 fprintf("min: "+min(p2.data)+"min 1: "+min(p1.data));
%                 processData;
%                 repCount = 1;
%             end
            p1.t = [p1.t(1281:end) amplifierTimestamps];
            p1.data = [p1.data(1281:end) amplifierData(1,:)];
%             fprintf("length: "+length(p1.data) + "min "+min(p1.data)+" max" +max(p1.data)+"\n");
            p2.t = [p2.t(1281:end) amplifierTimestamps];
            p2.data = [p2.data(1281:end) amplifierData(2,:)];
            processData;

            % plot the time series data if checked
            if plotFlag == 1
                plotTimeSeries;
            end

            % Reset timestamp index
            amplifierTimestampsIndex = 1;

%             processData; % process the data if new data is collected
        end
%         fprintf("in queue (post collection): "+twaveformdata.BytesAvailable+"\n");
    end

    %% --------------------------------------------------------------------
    % function to process data in p1 and p2, should update energyAlpha for
    % each to be energy between fLow, fHigh
    function processData
        % compute fft of data
        % determine total energy (i.e. sum(val.^2)) between fLow, fHigh
        p1.energyAlpha=calcEnergyBand(p1.data, fs, fLow, fHigh);
        p2.energyAlpha=calcEnergyBand(p2.data,fs, fLow, fHigh);
        if alphaEnergyPrintFlag
            fprintf("alpha energy: "+p1.energyAlpha+"             "+p2.energyAlpha+"\n");
        end
    end

    % calcEnergyBand calculates the average of magnitude within the frequency
    function energy = calcEnergyBand(x, fs, fLow, fHigh)
%         fx = fftshift(fft(x,fftLength));
%         df = fs/fftLength;
%         f = -fs/2:df:fs/2-df;
%         energy = sum(abs(fx((f>=fLow)&(f<=fHigh)).^2));
        energy = bandpower(x,fs,[fLow fHigh]); % https://raphaelvallat.com/bandpower.html uses this approach
    end

    % filter data
    function filterData()
        amplifierData(1,:) = filtfilt(x.lp10k,1,amplifierData(1,:));
        amplifierData(2,:) = filtfilt(x.lp10k,1,amplifierData(2,:));
    end

    % plot time series data
    function plotTimeSeries()
        figure(ampDataFigure);
        subplot(2,1,1);
        % For every 10 chunks, plot with hold 'off' to clear the
        % previous plot. In all other cases, plot with hold 'on' to add
        % each 10 data-block chunk to the previous chunks
        if chunkCounter ~= 1
            hold on
        end
        plot(amplifierTimestamps, p1.data, 'Color', 'blue');
        hold off;
        title('Player 1');
        axis([minAxis maxAxis -400 400]);
        subplot(2,1,2);
        if chunkCounter ~= 1
            hold on
        end
        plot(amplifierTimestamps, p2.data, 'Color', 'blue');
        hold off;
        title('Player 2');
        axis([minAxis maxAxis -400 400]);
        subplot(2,1,2);
    end


    % code to run on timer callback
    function onDataTimer(~,~)
        collectData;
        if p1.calibrate == 1
            p1.calibrationData = [p1.calibrationData p1.energyAlpha];
        end
        if p2.calibrate == 1
            p2.calibrationData = [p2.calibrationData p2.energyAlpha];
        end
    end

    %% --------------------------------------------------------------------
    % update game on timer callback
    function onGameTimer(~,~)
%         processData;
        updatePlayer1;
        updatePlayer2;
        updateBallPosition;
    end

    %% --------------------------------------------------------------------
    % functions to update player paddle positions
    function updatePlayer1
        if paddleP1.Position(2) <= paddleP1.Position(1)
            p1.direction = +1; % if at top, move down
        elseif paddleP1.Position(2) >= 1-paddleP1.Position(4)
            p1.direction = -1; % if at bottom, move up
        end
        if p1.energyAlpha > p1.threshold
            paddleP1.Position(2) = paddleP1.Position(2) + p1.direction*paddleVelocitySlow;
        else
            paddleP1.Position(2) = paddleP1.Position(2) + p1.direction*paddleVelocityFast;
        end
    end % updatePlayer1

    function updatePlayer2
        if paddleP2.Position(2) >= paddleP2.Position(1)-paddleP2.Position(4)
            p2.direction = -1; % if at top, move down
        elseif paddleP2.Position(2) <= paddleP2.Position(3)
            p2.direction = +1; % if at bottom, move up
        end
        if p2.energyAlpha > p2.threshold
            paddleP2.Position(2) = paddleP2.Position(2) + p2.direction*paddleVelocitySlow;
        else
            paddleP2.Position(2) = paddleP2.Position(2) + p2.direction*paddleVelocityFast;
        end
    end % updatePlayer2

    %% --------------------------------------------------------------------
    % update ball position
    function updateBallPosition
        
        % calc proposed new position
        newPos = ball.Position(1:2) + [bvx, bvy];
        
        % bounce off the top if we are there
        isSlow = abs(bvy) <= bh;
        if (newPos(2) + bh*isSlow) >= 1 - bh*isSlow
            bvy = -bvy;
        end % if
        
        % bounce off the bottom if we are there
        if newPos(2) <= 0
            bvy = -bvy;
            newPos(2) = 0;
        end % if
        
        % bounce off left paddle
        if newPos(1) < pw
            if newPos(2) + bh > paddleP1.Position(2) && ...
                    newPos(2) < paddleP1.Position(2) + paddleP1.Position(4)
                d = paddleP1.Position(2) + paddleP1.Position(4)/2 - newPos(2);
                bvy = bvy - 0.1*d;
                bvx = -bvx;
                beep;
            else
                incrementScore(2);
                beep;
                reset;
                return
            end % if else
        end % if

        % bounce off right paddle
        if (newPos(1) + bw) > (1 - pw)
            if newPos(2)+ bh  > paddleP2.Position(2) && ...
                    newPos(2) < paddleP2.Position(2) + paddleP2.Position(4)
                d = paddleP2.Position(2) + paddleP2.Position(4)/2 - newPos(2);
                bvy = bvy - 0.1*d;
                bvx = -bvx;
                beep;
            else
                incrementScore(1);
                beep;
                reset;
                return
            end % if else
        end % if
        
        % set new position
        ball.Position(1:2) = newPos;
    end

    %% --------------------------------------------------------------------
    % increment score
    function incrementScore(player)
        scores(player) = scores(player) + 1;
        if player == 1
            scoreP1.String = num2str(scores(player));
        else
            scoreP2.String = num2str(scores(player));
        end % if else
    end % incrementScore

    %% --------------------------------------------------------------------
    % reset game
    function reset()
        randAngle = deg2rad((240-120)*rand + 120 - 180*randi(0:1));
        bvx = ballVelocity*cos(randAngle);
        bvy = ballVelocity*sin(randAngle);
        ball.Position(1:2) = [0.5 - .5*bw 0.5 - .5*bh];
        drawnow;
    end % reset

    %% --------------------------------------------------------------------
    % delete pong game
    function deletePong(~,~)
        stop(tGame);
        delete(tGame);
        stop(tData);
        delete(tData);
        fprintf("\nGAME OVER\n\n")
        close all;
%         figure;
%         plot(1:length(debugData),debugData);
%         save("debugData","debugData");
    end

    % delete data collection
    function deleteDataCollection(~,~)
        stop(tData);
        delete(tData);
        fprintf("DATA COLLECTION TERMINATED\n\n");
    end

    %% --------------------------------------------------------------------
    % functions used for TCP connection, data retrieval
    % send command over TCP command socket
    function sendCommand(command)
        write(tcommand, uint8(command));
    end

    % read result of command over TCP command socket
    function command = readCommand()
        tic;
        while tcommand.BytesAvailable == 0
            elapsedTime = toc;
            if elapsedTime > 2
                error('Reading command timed out');
            end
            pause(0.01);
        end
        commandArray = read(tcommand);
        command = char(commandArray);
    end

    % query sample rate from board, get as double
    function sampleRate = getSampleRate()
        sendCommand('get sampleratehertz');
        commandString = readCommand();
        expectedReturnString = 'Return: SampleRateHertz ';
        if ~contains(commandString, expectedReturnString)
            error('Unable to get sample rate from server');
        else
            sampleRateString = commandString(length(expectedReturnString):end);
            sampleRate = str2double(sampleRateString);
        end
    end

    % read 4 bytes from array as uint32
    function [var, arrayIndex] = uint32ReadFromArray(array, arrayIndex)
        varBytes = array(arrayIndex : arrayIndex + 3);
        var = typecast(uint8(varBytes), 'uint32');
        arrayIndex = arrayIndex + 4;
    end

    % read 4 bytes from array as int32
    function [var, arrayIndex] = int32ReadFromArray(array, arrayIndex)
        varBytes = array(arrayIndex : arrayIndex + 3);
        var = typecast(uint8(varBytes), 'int32');
        arrayIndex = arrayIndex + 4;
    end

    % read 2 bytes from array as uint16
    function [var, arrayIndex] = uint16ReadFromArray(array, arrayIndex)
        varBytes = array(arrayIndex : arrayIndex + 1);
        var = typecast(uint8(varBytes), 'uint16');
        arrayIndex = arrayIndex + 2;
    end
    
    % read 1 byte from array as uint8
    function [var, arrayIndex] = uint8ReadFromArray(array, arrayIndex)
        var = array(arrayIndex);
        arrayIndex = arrayIndex + 1;
    end

    % read 5 bytes from array as 5 chars
    function [var, arrayIndex] = char5ReadFromArray(array, arrayIndex)
        varBytes = array(arrayIndex : arrayIndex + 4);
        var = native2unicode(varBytes);
        arrayIndex = arrayIndex + 5;
    end
end
