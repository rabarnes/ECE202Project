%% variable names and definitions
% fLow: low end of alpha wave frequency spectrum (can be adjusted later)
% fHigh: high end of alpha wave frequency spectrum (can be adjusted later)
%
% p1, p2: structure with parameters t, data, energyAlpha,
% threshold; t is vector of time values corresponding to player 1 or
% player 2 (i.e. p1, p2) for the Intan data; data is the vector of
% amplitude values for the Intan data; energyAlpha is the amount of energy
% between fLow-fHigh (alpha wave band); threshold is the threshold value
% calculated in the calibration function
% 
% fs: sample frequency
%
% paddleVelocitySlow: speed of paddle when alpha waves are detected
% paddleVelocityFast: speed of paddle when alpha waves are not detected
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


function pong202timer()
    %% --------------------------------------------------------------------
    %% initialize variables
    % TCP connection variables
    tcommand = [];
    twaveformdata = [];
    typeString = [];
    fs = 0;
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
    currentPlotBand = 1;

    % use alpha waves (7-13Hz) by default (can be modified later)
    fLow = 7; fHigh = 13;

    % define p1, p2
    p1 = struct('t',[], ...
        'data', [], ...
        'energyAlpha', 0, ...
        'threshold', 0);

    p2 = struct('t',[], ...
        'data', [], ...
        'energyAlpha', 0, ...
        'threshold', 0);

    endGame = 0;

    %% --------------------------------------------------------------------
    %% initialize GUI
    % TODO: add GUI initilization here; should add the following buttons
    %    figMain=uifigure;
    figMain=uifigure;
    
    bConnect = uibutton(figMain,'push',...
                'Text', 'Connect', ...
               'Position',[50, 218, 100, 22],...
               'ButtonPushedFcn', @(btn,event) connect);
    bCalibration = uibutton(figMain,'push',...
                'Text', 'OpenCalibration GUI', ...
               'Position',[175, 218, 100, 22],...
               'ButtonPushedFcn', @(btn,event) calibration); 

    bPong = uibutton(figMain,'push',...
                'Text', 'Play Pong', ...
               'Position',[400, 218, 100, 22],...
               'ButtonPushedFcn', @(btn,event) game);
                  
    % connect: button to connect to TCP port (callback function connect),
    % start timers for data collection, data processing
    %
    % calibrateP1: button to start p1 calibration; it would be good to
    % have separate calibrations for each player so that it is easier to
    % debug; calls calibrateP1 as callback function
    %
    % calibrateP2: button to start p2 calibration;  calls calibrateP2 as 
    % callback function
    % 
    % start game: button to start game; calls game as callback function

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
    ph = 0.2;
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
    constVel = 0.007;


    dataPeriod = 0.08;
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
    


%     %% --------------------------------------------------------------------
%     % test commands
%     % can add test commands here to test if code is working; example:
     connect;
% %     p1.threshold = 2; % sample threshold values
% %     p2.threshold = 3; % sample threshold values
% %     game;
% %     disconnect;
     start(tData);
     start(tGame);
% 
     pause(5);
    stop(tData);
     stop(tGame);
     delete(tData);
     delete(tGame);
%     fprintf("waveformbytes10blocks: "+waveformBytes10Blocks+"\n");

    %% --------------------------------------------------------------------
    % connect function
    % function to initialize connection to TCP port, should start the data
    % and process timers
    function connect
        % if initialized == 0, need to connect to TCP port
        if initialized == 0
            % connect to TCP port
            % start data collection and data processing timers
            fprintf("Connecting to TCP command server...\n");
            tcommand = tcpclient('localhost', 5000);
            fprintf("Connecting to TCP waveform server...\n");
            twaveformdata = tcpclient('localhost', 5001);
            fprintf("Clearing current TCP outputs...\n");
            sendCommand('execute clearalldataoutputs');
    
            fprintf("Enabling channels...\n");
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
            for channel = 1:numAmpChannels
                channelName = ['a-' num2str(channel - 1, '%03d')];
                commandString = ['set' channelName '.tcpdataoutputenabled true;'];
                commandString = [commandString ' set ' channelName '.tcpdataoutputenabledlow true;'];
                commandString = [commandString ' set ' channelName '.tcpdataoutputenabledhigh true;'];
                sendCommand(commandString);
            end
    
            fprintf("Preparing MATLAB to start streaming...\n");
            pause(1);
    
            initialized = 1;
        end

        % mark system as running
        stopped = 0;

        numBanprocesserChannel = 3;
        numAmplifierBands = numBanprocesserChannel * numAmpChannels;
        
        waveformBytesPerFrame = 4 + 2 * numAmplifierBands;
        waveformBytesPerBlock = framesPerBlock * waveformBytesPerFrame + 4;
        blocksPerRead = 10;
        waveformBytes10Blocks = blocksPerRead * waveformBytesPerBlock;

        amplifierData = 32768 * ones(numAmpChannels, framesPerBlock * 10);
        amplifierTimestamps = zeros(1, framesPerBlock * 10);

        amplifierTimestampsIndex = 1;

        chunkCounter = 0;

        % start board running
        fprintf("Streaming data...\n");
        write(tcommand, uint8('set runmode run'));
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
% 
%         flush(twaveformdata);
%         fprintf("in queue (post flush): "+twaveformdata.BytesAvailable+"\n");
%         while twaveformdata.BytesAvailable < waveformBytes10Blocks
%         end
%         fprintf("in queue (post pause): "+twaveformdata.BytesAvailable+"\n");

        % read waveform data in 10-block chunks
        if twaveformdata.BytesAvailable >= waveformBytes10Blocks
            drawnow;

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
            rawIndex = 1;

            for block = 1:blocksPerRead
                % expect 4 bytes to be TCP magic number as uint32
                % if not what's expected, print there was an error
                [magicNumber, rawIndex] = uint32ReadFromArray(waveformArray, rawIndex);
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
                        rawIndex = rawIndex + 2;
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

        amplifierData = 0.195 * (amplifierData - 32768);

        p1.t = amplifierTimestamps;
        p1.data = amplifierData(1,:);
        p2.t = amplifierTimestamps;
        p2.data = amplifierData(2,:);
        fprintf("in queue (post collection): "+twaveformdata.BytesAvailable+"\n");
    end

    % function to process data in p1 and p2, should update energyAlpha for
    % each to be energy between fLow, fHigh
    function processData
        % compute fft of data
        % determine total energy (i.e. sum(val.^2)) between fLow, fHigh
        for i=1:size(amplifierData,1)
            avg(i)=calcEnergyAvg(amplifierData(i,:), fs, fLow, fHigh);
        end
        fprintf("Avg1: "+avg(1)+"\n")
        fprintf("Avg2: "+avg(2)+"\n")
        p1.energyAlpha=avg(1);
        p1.energyAlpha=avg(2);
    end

    function onDataTimer(~,~)
        collectData;
    end
%%
function [avg, bins] = calcEnergyAvg(sampleData, fs, lowBoundFreq, upBoundFreq)
    L = length(sampleData);
    Y = fft(sampleData);
    P2 = abs(Y/L);
    P1 = P2(1:round(L/2+1));
    P1(2:end-1) = 2*P1(2:end-1);
    bins = chooseBins(fs, L, lowBoundFreq, upBoundFreq);
    avg = sum(P1(bins)) / size(bins,1);
end


% chooseBins returns the bins in which the frequencies
% bounded by lowBoundFreq and upBoundFreq contains, with
% given sampling frequency Fs and Sample size L.
% inputs:   Fs - Sampling Frequency
%           L  - Sample Size
%           lowBoundFreq - lower bound of frequency
%           upBoundFreq  - upper bound of frequency
% output:   bins - array of int indicating the bin number 
%                  (matlab index)
%
function bins = chooseBins(fs, L, lowBoundFreq, upBoundFreq)
    bins = [];
    for binNum = 1:round(L/2)
        binFreq = fs/(2*L)*(2*(binNum-1));
        if(binFreq <= upBoundFreq && binFreq >= lowBoundFreq)
            bins = [bins, binNum];
        end
    end
    if(size(bins,1) == 0)
        fprintf("Not enough resolution for bins!")
    end
end

%% --------------------------------------------------------------------
    % calibration functions
    % calibrate player 1 threshold
    function calibrateP1
        % instruct player to have eyes open for t0 seconds
        % instruct player to have eyes closed for t0 seconds
        % find average energyAlpha over each time period
        % calculate threshold
        p1.threshold = 0;
    end

    % calibrate player 2 threshold
    function calibrateP2
        % instruct player to have eyes open for t0 seconds
        % instruct player to have eyes closed for t0 seconds
        % find average energyAlpha over each time period
        % calculate threshold
        p2.threshold = 0;
    end

    %% --------------------------------------------------------------------
    % update game on timer callback
    function onGameTimer(~,~)
        processData;
        updatePlayer1;
        updatePlayer2;
        updateBallPosition;
    end

    %% --------------------------------------------------------------------
    % functions to update player paddle positions
    function updatePlayer1
        % get offset to center and calculate relative rate to move
        offset = (paddleP1.Position(2) + .5* paddleP1.Position(4)) - (ball.Position(2) + .5*bh);
        rate = abs(offset/ph);
        
        % move paddle in required direction at required rate
        if offset < 0
            paddleP1.Position(2) = paddleP1.Position(2) + 0.02*rate;
        elseif offset > 0
            paddleP1.Position(2) = paddleP1.Position(2) - 0.02*rate;
        end % if else
    end % updatePlayer1

    function updatePlayer2
        
        % get offset to center and calculate relative rate to move
        offset = (paddleP2.Position(2) + .5* paddleP2.Position(4)) - (ball.Position(2) + .5*bh);
        rate = abs(offset/ph);
        
        % move paddle in required direction at required rate
        if offset < 0
            paddleP2.Position(2) = paddleP2.Position(2) + 0.02*rate;
        elseif offset > 0
            paddleP2.Position(2) = paddleP2.Position(2) - 0.02*rate;
        end % if else
        
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
            else
                incrementScore(2);
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
            else
                incrementScore(1);
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
        bvx = constVel*cos(randAngle);
        bvy = constVel*sin(randAngle);
        ball.Position(1:2) = [0.5 - .5*bw 0.5 - .5*bh];
        drawnow;
    end % reset

    %% --------------------------------------------------------------------
    % delete pong game
    function deletePong(~,~)
        endGame = 1;
        stop(tGame);
        delete(tGame);
    end

    %% --------------------------------------------------------------------
    % game function calls collectData, processData, updateGame in loop
    % pong game logic (replace the timer in pong.m with tGame timer; can
    % use same logic, but use this timer instead for consistency)
    function dataRefresh
        % uses most logic from pong.m
        % implement updatePlayer1, updatePlayer2 functions so that paddle
        % moves up and down at constant rate paddleVelocity
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