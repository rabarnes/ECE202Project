function configGUI()
figConfig = uifigure('Name','Configure GUI');
figConfig.Position = [200 300 400 250];

global p1 p2
p1 = struct('configState',0);
p2 = struct('configState',0);

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

% btn1 = uibutton(figConfig,'push','Position',[50, 100, 100, 22],'Text','Start Recording','ButtonPushedFcn', @(btn1,event) configPlayer1(btn1,lbl_1a));
% btn2 = uibutton(figConfig,'push','Position',[250, 100, 100, 22],'Text','Start Recording','ButtonPushedFcn', @(btn2,event) configPlayer2(btn2,lbl_2a));
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
    