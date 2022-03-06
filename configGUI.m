function configGUI()
fig = uifigure('Name','Configure GUI');
fig.Position = [200 300 400 250];

global p1 p2
p1 = struct('configState',0);
p2 = struct('configState',0);

lbl_1 = uilabel(fig);
lbl_1.Text = 'Configure Player 1';
lbl_1.Position = [50 200 100 15];
lbl_1a = uilabel(fig);
lbl_1a.Text = 'Record with eyes open';
lbl_1a.Position = [40 130 130 15];

lbl_2 = uilabel(fig);
lbl_2.Text = 'Configure Player 2';
lbl_2.Position = [250 200 100 15];
lbl_2a = uilabel(fig);
lbl_2a.Text = 'Record with eyes open';
lbl_2a.Position = [240 130 130 15];

btn1 = uibutton(fig,'push','Position',[50, 100, 100, 22],'Text','Start Recording','ButtonPushedFcn', @(btn1,event) configPlayer1(btn1,lbl_1a));
btn2 = uibutton(fig,'push','Position',[250, 100, 100, 22],'Text','Start Recording','ButtonPushedFcn', @(btn2,event) configPlayer2(btn2,lbl_2a));


function configPlayer1(btn1,lbl)
    curState = p1.configState;
    p1.configState = curState + 1;
    if p1.configState == 1
        btn1.Text = "Recording";
        btn1.BackgroundColor ='g';
        pause(2);
        configPlayer1(btn1,lbl)
    elseif p1.configState == 2
        lbl.Text = 'Record with eyes Closed';
        lbl.Position = [30 130 135 15];
        btn1.Text = "Start Recording";
        btn1.BackgroundColor = [0.96 0.96 0.96];
    elseif p1.configState == 3
        btn1.Text = "Recording";
        btn1.BackgroundColor ='g';
        pause(2);
        configPlayer1(btn1,lbl)
    elseif p1.configState == 4
        lbl.Text = 'Done Configuring';
        lbl.Position = [55 130 100 15];
        btn1.Text = "Restart";
        btn1.BackgroundColor = [0.96 0.96 0.96];
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
        pause(2);
        configPlayer2(btn2,lbl)
    elseif p2.configState == 2
        lbl.Text = 'Record with eyes Closed';
        lbl.Position = [230 130 135 15];
        btn2.Text = "Start Recording";
        btn2.BackgroundColor = [0.96 0.96 0.96];
    elseif p2.configState == 3
        btn2.Text = "Recording";
        btn2.BackgroundColor ='g';
        pause(2);
        configPlayer2(btn2,lbl)
    elseif p2.configState == 4
        lbl.Text = 'Done Configuring';
        lbl.Position = [255 130 100 15];
        btn2.Text = "Restart";
        btn2.BackgroundColor = [0.96 0.96 0.96];
    else
        lbl.Text = 'Record with eyes open';
        lbl.Position = [240 130 130 15];
        btn2.Text = "Start Recording";
        p2.configState= 0;
    end
end

end
    