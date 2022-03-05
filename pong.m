function pong()
%PONG The game pong
%   Play against a basic AI in an unlimited score game. To exit, close the
%   figure.
%
%   pong() launches the game

% create basic gui
fig = figure('Name', 'PONG', ...
    'Color', [.1 .1 .1], ...
    'WindowStyle', 'modal', ...
    'NumberTitle', 'off', ...
    'Resize', 'off');
ax = axes(fig, ...
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
scoreP1 = text(ax, 0.3, 0.5, '0', ...
    'Color', [.1 .1 .1], ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', 72);
scoreP2 = text(ax, 0.7, 0.5, '0', ...
    'Color', [.1 .1 .1], ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', 72);
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
bh = 0.02 * (fig.Position(3) / fig.Position(4));
bw = 0.02;
ball = rectangle(ax, ...
    'Position', [.5 .5 - .5*bh bw bh], ...
    'FaceColor', 'w', ...
    'LineStyle', 'none');

% initialise velocities
bvx = 0;
bvy = 0;
constVel = 0.02;

% set up the player one paddle movement
fig.WindowButtonMotionFcn = @updatePlayer1;

% start the frame refresh loop
t = timer('Period', 0.10, ...
    'TimerFcn', @onTimer, ...
    'ExecutionMode', 'fixedRate', ...
    'BusyMode', 'drop');
fig.DeleteFcn = @deleteTimer;
reset;

    function onTimer(~, ~)
        updateBallPosition;
        updatePlayer2;
    end % onTimer

    function updatePlayer1(src, ~)
        % keep player paddle in line with mouse
        paddleP1.Position(2) = min([src.CurrentPoint(2) / src.Position(4), 1 - ph]);
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
        
    end % updateBallPosition

    function incrementScore(player)
        scores(player) = scores(player) + 1;
        if player == 1
            scoreP1.String = num2str(scores(player));
        else
            scoreP2.String = num2str(scores(player));
        end % if else
    end % incrementScore

    function reset()
        stop(t);
        randAngle = deg2rad((240-120)*rand + 120 - 180*randi(0:1));
        bvx = constVel*cos(randAngle);
        bvy = constVel*sin(randAngle);
        ball.Position(1:2) = [0.5 - .5*bw 0.5 - .5*bh];
        drawnow;
        start(t);
    end % reset

    function deleteTimer(~, ~)
        stop(t);
        delete(t);
    end % deleteTimer

end % pong
