close all; clear; clc;

figure;
hold on;

x = 1;

t1 = timer;
t1.Period = 1;
t1.StartFcn = @initTimer;
t1.UserData = [];
t1.TimerFcn = @(src,event,x)t1fcn;
t1.TasksToExecute = 10;
t1.ExecutionMode = 'fixedRate';
start(t1);

t2 = timer;
t2.Period = 2;
t2.StartFcn = @initTimer;
t2.UserData = [];
t2.TimerFcn = @(src,event,x)t2fcn;
t2.TasksToExecute = 10;
t2.ExecutionMode = 'fixedRate';
start(t2);


delete(timerfindall);


% 
% t2 = timer;
% t2.Period = 2.5;
% t2.TimerFcn = @(src,thisEvent) modifyY(t1.UserData);
% t2.TasksToExecute = 5;
% t2.ExecutionMode = 'fixedRate';
% start(t2);
% 
% t3 = timer;
% t3.Period = 5;
% t3.TimerFcn = @(src,thisEvent) plotXY(t1.UserData,t2.UserData);
% t3.TasksToExecute = 2;
% t3.ExecutionMode = 'fixedRate';
% start(t3);



function initTimer(src,event)
   src.UserData = 0;
   disp('initialised')
end


function t1fcn(src,event,x)
    disp(x)
    x = x+1;
end
% 
% function t2fcn(src,event,handles)
%     print("t2 fcn x = "+handles.x);
% end
