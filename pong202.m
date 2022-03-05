%% variable names and definitions
% f_low: low end of alpha wave frequency spectrum (can be adjusted later)
% f_high: high end of alpha wave frequency spectrum (can be adjusted later)
%
% p1, p2: structure with parameters data_t, data_vals, alpha_energy,
% threshold; data_t is vector of time values corresponding to player 1 or
% player 2 (i.e. p1, p2) for the Intan data; data_vals is the vector of
% amplitude values for the Intan data; alpha_energy is the amount of energy
% between f_low-f_high (alpha wave band); threshold is the threshold value
% calculated in the calibration function
% 
% fs: sample frequency
%
% paddle_velocity_slow: speed of paddle when alpha waves are detected
% paddle_velocity_fast: speed of paddle when alpha waves are not detected
%
%% function names and definitions
% connect(): make connection to TCP port
%
% data_collect(): start Intan data collection, should update data1_t, 
% data2_t, data1_vals, data2_vals with Intan data
%
% data_process(): process data in data1_t, data2_t, data1_vals, data2_vals;
% should measure the energy of for both players between 7-13Hz; set value
% of p1_alpha_energy, p2_alpha_energy to the energy values
%
% game(): should start pong game, continually refresh; should use
% data_process values p1_alpha_energy and p2_alpha_energy (along with
% p1_threshold and p2_threshold) in order to update the paddle velocities
% for p1 and p2
%
% threshold: these are the threshold values for the 
% energy of the 7-13Hz frequency components; if the energy is above this
% threshold, alpha waves are detected, and if the energy is below this
% threshold, no alpha waves are detected; this value should be somewhere
% between the noise level (i.e. no alpha waves) and the alpha wave level
%
%% timers
% t_data: callback function collects data from Intan software
% t_dsp: callback function processes data from Intan software
% t_game: callback function updates game logic, display

function pong202()
    %% initialize variables
    % use alpha waves (7-13Hz) by default (can be modified later)
    f_low = 7; f_high = 13;

    % define p1, p2
    p1 = struct('data_t',[], ...
        'data_vals', [], ...
        'alpha_energy', 0, ...
        'threshold', 0);

    p2 = struct('data_t',[], ...
        'data_vals', [], ...
        'alpha_energy', 0, ...
        'threshold', 0);

    %% initialize GUI
    % TODO: add GUI initilization here; should add the following buttons
    %
    % connect: button to connect to TCP port (callback function connect),
    % start timers for data collection, data processing
    %
    % calibrate_p1: button to start p1 calibration; it would be good to
    % have separate calibrations for each player so that it is easier to
    % debug; calls calibrate_p1 as callback function
    %
    % calibrate_p2: button to start p2 calibration;  calls calibrate_p2 as 
    % callback function
    % 
    % start game: button to start game; calls game as callback function   
    
    %% setup timers
    % set timer parameters here for each of the 3 timers
    data_start_delay = 0;
    data_period = 1;
    data_reps = 1;

    dsp_start_delay = 0;
    dsp_period = 1;
    dsp_reps = 1;

    game_start_delay = 0;
    game_period = 1;
    game_reps = 1;

    % on connect button press, call connect
    % on calibrateP1 button press, call calibrateP1
    % on calibrateP2 button press, call calibrateP2
    % on startGame button press, call game
    t_data = timer('StartDelay', data_start_delay, ...
        'Period', data_period, ...
        'TasksToExecute', data_reps, ...
        'ExecutionMode', 'fixedRate', ...
        'TimerFcn', @data_callback, ...
        'BusyMode', 'queue');

    t_dsp = timer('StartDelay', dsp_start_delay, ...
        'Period', dsp_period, ...
        'TasksToExecute', dsp_reps, ...
        'ExecutionMode', 'fixedRate', ...
        'TimerFcn', @dsp_callback, ...
        'BusyMode', 'queue');

    t_game = timer('StartDelay', game_start_delay, ...
        'Period', game_period, ...
        'TasksToExecute', game_reps, ...
        'ExecutionMode', 'fixedRate', ...
        'TimerFcn', @t_game_callback, ...
        'BusyMode', 'queue');

    % can add test commands here to test if code is working; example:
    connect;
    p1.threshold = 2; % sample threshold values
    p2.threshold = 3; % sample threshold values
    game;
    disconnect;


    % function to initialize connection to TCP port, should start the data
    % and dsp timers
    function connect
        % connect to TCP port
        % start data collection and data processing timers
        start(t_data); start(t_dsp);
    end

    function disconnect
        % disconnect from TCP port (may not be necessary)
        deleteTimers;
    end

    % function to process data in p1 and p2, should update alpha_energy for
    % each to be energy between f_low, f_high
    function dataProcess
        % compute fft of data
        % determine total energy (i.e. sum(val.^2)) between f_low, f_high
        p1.alpha_energy = 0;
        p2.alpha_energy = 0;
    end

    % calibrate player 1 threshold
    function calibrateP1
        % instruct player to have eyes open for t0 seconds
        % instruct player to have eyes closed for t0 seconds
        % find average alpha_energy over each time period
        % calculate threshold
        p1.threshold = 0;
    end

    % calibrate player 2 threshold
    function calibrateP2
        % instruct player to have eyes open for t0 seconds
        % instruct player to have eyes closed for t0 seconds
        % find average alpha_energy over each time period
        % calculate threshold
        p2.threshold = 0;
    end

    % pong game logic (replace the timer in pong.m with t_game timer; can
    % use same logic, but use this timer instead for consistency)
    function game
        % uses most logic from pong.m
        % implement updatePlayer1, updatePlayer2 functions so that paddle
        % moves up and down at constant rate paddle_velocity
        start(t_game);

        function t_game_callback
            % call functions to update game logic, display
        end
    end

    % delete all timers (should call upon game end)
    function deleteTimers(~, ~)
        stop(t_data); delete(t_data);
        stop(t_dsp); delete(t_dsp);
        stop(t_game); delete(t_game);
    end
end