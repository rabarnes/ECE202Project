%% method of modifying a shared variable between multiple timer functions
% purpose: It will be necessary to have multiple processes occurring
% simultaneously, and these processes will need to work with the same
% variables. Specifically, it will be necessary to retrieve the data from
% the Intan device, while also processing the current data available and
% passing values to control the game from the processing block. The below
% code shows an example of how to have two timers running simultaneously
% that modify a shared variable and use a shared variable. This approach of
% using nested functions can be applied to more than 2 functions as well.
%
% timer function explanation: Let t be a timer with a set period of time
% t0 and callback function tfunc. The timer will run in the background, and
% every t0 seconds, tfunc will be called. tfunc may call other functions.
% If timer t and function tfunc are both called within a function f (i.e.
% tfunc is a nested function), then tfunc may call another nested function.
% The nested functions that are called by tfunc may manipulate any
% variables defined within function f. Any variables defined in f are
% accessible to any function also defined within f.
%
% method: Use nested functions to allow callback function to call
% additional functions that modify variables local to the overall function.
% Variables defined within a function are accessible to any nested
% functions (functions defined within the function). These variables cannot
% be modified in the callback function directly, but the callback function
% can call other functions that modify them. Any data values that need to
% be modified by the timer callback will need to be initialized within
% the top function prior to starting the timer. Care should be taken to
% avoid having two functions change a variable simultaneously. For example,
% if x is a variable being manipulated by two timer callback functions, and
% both operations take a significant time to complete, it may be the case
% that one function tries to manipulate x while the other is still working
% with the initial x. To avoid issues, variables should be copied to the
% function locally first, and then assigned back to the variable at the
% end if necessary. This will apply to the data retrieval and data
% processing functions. The data retrieval function should obtain the data
% values from the Intan device locally, and then assign that data vector to
% the data vector available to the other functions (e.g. the processing
% function) after completion. The data processing function should copy the
% data vector to a local variable prior to manipulating it so that the data
% is not changed in the middle of the operation. Game processing logic is
% likely very simple and might not care that particular values are being
% modified, so this copying to a local variable might not be necessary.

function nestedFunc()
    % any variables defined within the function may be modified by any
    % function that is also defined within this function; x may be modified
    % by functions task1 and task 2
    x = 1;

    % timer parameters
    period = 1;
    start_delay = period;
    num_reps = 10;
    total_time = period*num_reps;

    % t1 is a timer that calls function onTimer1 every period seconds
    t1 = timer('StartDelay', start_delay, ...
        'Period', period, ...
        'TasksToExecute', num_reps, ...
        'ExecutionMode', 'fixedRate', ...
        'TimerFcn', @onTimer1);
    % t2 is a timer that calls function onTimer2 every period/2 seconds
    % (i.e. onTimer2 gets called twice as frequently as onTimer1)
    t2 = timer('StartDelay', start_delay/2, ...
        'Period', period/2, ...
        'TasksToExecute', num_reps*2, ...
        'ExecutionMode', 'fixedRate', ...
        'TimerFcn', @onTimer2);
    % start both timers
    start(t1);
    start(t2);
    % wait finite amount of time before ending the timers
    pause(total_time+1);
    % end the timers and free up their space in memory
    stop(t1); delete(t1); % stop and remove
    stop(t2); delete(t2); % stop and remove

    % onTimer1 and onTimer2 are the callback functions for timers t1 and
    % t2; they are called at the rate set by the timer; variables defined
    % in the function scope cannot be modified here, but functions defined
    % within the function scope can be called
    function onTimer1(~,~)
        task1;
    end

    function onTimer2(~,~)
        task2;
    end

    % functions task1 and task2 are called by the timer callback functions;
    % both of them modify x, so there will be two functions modifying the
    % value of x simultaneously; variables defined within the function
    % scope may be modified (they look like global variables within the
    % function)
    function task1
        x = x+1;
        fprintf("task 1 x = "+x+"\n");    
    end
    function task2
        x = x-2;
        fprintf("task 2 x = "+x+"\n");
    end
end




function tfunc1(obj,event)
    x = get(obj, 'UserData');
    x = x+1;
    fprintf("function 1, new x: "+x+"\n");
    set(obj,'UserData',x);
end