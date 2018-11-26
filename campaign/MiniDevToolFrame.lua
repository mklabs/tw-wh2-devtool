require("console");
require("remove_component");
require("ui/ComponentMixin");


MiniDevToolFrame = {
    frameName = "MiniDevToolFrame",
    component = nil,
    componentWidth = 800,
    componentHeight = 100,
    devtool = nil,
    textbox = nil,
    upButton = nil,
    downButton = nil,
    enterButton = nil,
    executeButton = nil,
    clearCodeButton = nil,
    closeButton = nil,
    miniUIButton = nil,
    listeners = {}
};

function MiniDevToolFrame:new(devtool)
    self.devtool = devtool;

    local root = core:get_ui_root();
    local existing = find_uicomponent(root, self.frameName);

    if not existing then
        self:createFrame();
    else
        self.component = existing;
    end;

    return self;
end;

function MiniDevToolFrame:createFrame()
    local root = core:get_ui_root();

    root:CreateComponent(self.frameName, "ui/campaign ui/script_dummy");
    self.component = find_uicomponent(root, self.frameName);

    self.component:PropagatePriority(root:Priority());
    root:Adopt(self.component:Address());

    self:resizeComponent(self.component, self.componentWidth, self.componentHeight);
    self:positionComponentRelativeTo(self.component, root, 20, 100);

    -- create textbox
    self:addTextBox();

    -- creating up / down arrow
    self.upButton = self:createUpArrow();
    self.downButton = self:createDownArrow();

    -- create enter button
    self.enterButton = self:createEnterButton();

    -- create execute button
    self.executeButton = self:createExecuteButton();
    
    -- create clear code button
    self.clearCodeButton = self:createClearCodeButton();

    -- add the close button
    self.closeButton = self:createCloseButton();

    -- add the mini switch button
    self.miniUIButton = self:addMiniUIButton();

    -- create line numerical display
    self:createLineNumberDisplay();

    -- update up / down arrows state
    self:updateUpDownArrowState();
end;

function MiniDevToolFrame:addTextBox()
    local name = self.frameName .. "_TextBox";
    local filepath = "ui/common ui/file_requester";
    local content = self.component;

    self.component:CreateComponent(name .. "_UITEMP", filepath);
    local tempUI = UIComponent(self.component:Find(name .. "_UITEMP"));
    local textbox = find_uicomponent(tempUI, "input_name");
    self.textbox = textbox;
    
    textbox:PropagatePriority(self.component:Priority());
    self.component:Adopt(textbox:Address());
    remove_component(find_uicomponent(textbox, "input_name_label"));
    remove_component(tempUI);

    -- resize
    local contentWidth, contentHeight = self.component:Bounds();
    self:resizeComponent(textbox, contentWidth - 50);
    self:positionComponentRelativeTo(textbox, self.component, 0, 0);
end;

function MiniDevToolFrame:createUpArrow()
    local name = self.frameName .. "_TextBox_UpButton";
    local content = self.component;
    local textbox = self.textbox;

    -- creating button
    content:CreateComponent(name, "ui/templates/round_medium_button");
    local upButton = UIComponent(content:Find(name));

    content:Adopt(upButton:Address());
    upButton:PropagatePriority(content:Priority());
    upButton:SetImage("ui/skins/default/parchment_sort_arrow_up.png");
    self:resizeComponent(upButton, 17, 17);
    self:positionComponentRelativeToWithOffset(upButton, textbox, 5, -30);

    local listenerName = self.frameName .. "_TextBox_UpButtonListener";
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context)
            return upButton == UIComponent(context.component);
        end,

        function(context)
            self.devtool:decrementLines();
            self.devtool:updateUpDownArrowState();
            self:updateTextBox();
        end,
        true
    );
    table.insert(self.listeners, listenerName);

    return upButton;
end;

function MiniDevToolFrame:createDownArrow()
    local name = self.frameName .. "_TextBox_DownButton";
    local content = self.component;
    local textbox = self.textbox;

    -- creating button
    content:CreateComponent(name, "ui/templates/round_medium_button");
    local downButton = UIComponent(content:Find(name));

    content:Adopt(downButton:Address());
    downButton:PropagatePriority(content:Priority());
    downButton:SetImage("ui/skins/default/parchment_sort_arrow_down.png");
    self:resizeComponent(downButton, 17, 17);
    self:positionComponentRelativeToWithOffset(downButton, textbox, 5, -15);

    local listenerName = "DevToolFrame_TextBox_DownButtonListener";
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context)
            return downButton == UIComponent(context.component);
        end,

        function(context)
            self.devtool:incrementLines();
            self.devtool:updateUpDownArrowState();
            self:updateTextBox();
        end,
        true
    );
    table.insert(self.listeners, listenerName);

    return downButton;
end;

function MiniDevToolFrame:createEnterButton()
    local textbox = self.textbox;

    -- creating button
    local button = self:createButton("Enter", "Save current line and go into next", 120, function(context)
        self.devtool:incrementLines();
        self.devtool:updateUpDownArrowState();
        self:updateTextBox();

        self.enterButton:SetState("down_off");
    end);

    self:positionComponentRelativeTo(button, textbox, 0, textbox:Height() + 2);

    return button;
end;

function MiniDevToolFrame:createExecuteButton()
    local textbox = self.textbox;
    local enterButton = self.enterButton;

    -- creating button
    local executeButton = self:createButton("Execute", "Execute Code", 120, function(context)
        self.devtool:executeCode();
        self.executeButton:SetState("down_off");
    end);

    self:positionComponentRelativeToWithOffset(executeButton, enterButton, 0, -enterButton:Height());

    return executeButton;
end;

function MiniDevToolFrame:createClearCodeButton()
    local executeButton = self.executeButton;

    -- creating button
    local button = self:createButton("Clear Code", "Clear all previously entered code in the textbox", 150, function(context)
        self.devtool:clearCodeLines();
        self.clearCodeButton:SetState("down_off");

        self:updateTextBox();
    end);

    self:positionComponentRelativeToWithOffset(button, executeButton, 0, -executeButton:Height());
    return button;
end;

function MiniDevToolFrame:createCloseButton()
    local buttonName = self.frameName .. "_CloseMiniUIButton";
    self.component:CreateComponent(buttonName, "ui/templates/round_small_button");

    local button = find_uicomponent(self.component, buttonName);
    button:SetImage("ui/skins/default/icon_cross_small.png");
    button:SetTooltipText("Close", true);

    button:PropagatePriority(self.component:Priority());
    self.component:Adopt(button:Address());
    self:positionComponentRelativeToWithOffset(button, self.clearCodeButton, 0, -self.clearCodeButton:Height());

    local listenerName = buttonName .. "_Listener";
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context) return button == UIComponent(context.component); end,    
        function(context)
            self:hideFrame();
        end,
        true
    );
    table.insert(self.listeners, listenerName);

    return button;
end;

function MiniDevToolFrame:addMiniUIButton()
    local buttonName = self.frameName .. "_MiniUIButton";
    self.component:CreateComponent(buttonName, "ui/templates/round_small_button");

    local button = find_uicomponent(self.component, buttonName);
    button:SetImage("script/campaign/resize_icon.png");
    button:SetTooltipText("Switch to maximized UI", true);

    button:PropagatePriority(self.component:Priority());
    self.component:Adopt(button:Address());
    self:positionComponentRelativeToWithOffset(button, self.closeButton, 0, -self.closeButton:Height());

    local listenerName = buttonName .. "_Listener";
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context) return button == UIComponent(context.component); end,    
        function(context)
            self:hideFrame();
            self.devtool:showFrame();
        end,
        true
    );
    table.insert(self.listeners, listenerName);

    return button;
end;

function MiniDevToolFrame:createLineNumberDisplay()
    local componentName = self.frameName .. "_LineNumberComponent";
    local content = self.component;
    
    content:CreateComponent(componentName .. "_UITEMP", "ui/campaign ui/mission_details");
    local tempUI = UIComponent(content:Find(componentName .. "_UITEMP"));

    local component = find_uicomponent(tempUI, "mission_details_child", "description_background", "description_view", "dy_description");
    content:Adopt(component:Address());
    component:PropagatePriority(content:Priority());
    remove_component(tempUI);

    local textDimensionsWidth, textDimensionsHeight = component:TextDimensionsForText("Current Line: 000");
    self:resizeComponent(component, textDimensionsWidth, 30);
    self:positionComponentRelativeToWithOffset(component, self.textbox, -textDimensionsWidth, 10);

    self.currentLineNumberComponent = component;
    self:updateLineNumberDisplay();
end;

function MiniDevToolFrame:updateLineNumberDisplay()
    local component = self.currentLineNumberComponent;
    component:SetStateText("Current Line: " .. self.devtool.currentLineNumber);
end;

function MiniDevToolFrame:updateTextBox()
    local text = self.devtool.lines[self.devtool.currentLineNumber] or "";

    remove_component(find_uicomponent(self.component, "input_name"));
    self:addTextBox();

    self.textbox:SimulateLClick();
    for i in string.gmatch(text, ".") do
        self.textbox:SimulateKey(i);
    end
end;

function MiniDevToolFrame:updateUpDownArrowState()
    local currentLineNumber = self.devtool.currentLineNumber;
    local lines = self.devtool.lines;

    if currentLineNumber == 1 then
        self.upButton:SetState("inactive");
        if #lines == 0 then
            self.downButton:SetState("inactive");
        else
            self.downButton:SetState("active");
        end
    elseif currentLineNumber >= #lines then
        self.upButton:SetState("active");
        self.downButton:SetState("inactive");
    else
        self.upButton:SetState("active");
        self.downButton:SetState("active");
    end
end;

function MiniDevToolFrame:removeFrame()
    remove_component(self.component);
    for i, listener in ipairs(self.listeners) do
        core:remove_listener(listener);
    end

    self.listeners = {};
end;

function MiniDevToolFrame:hideFrame()
    self.component:SetVisible(false);
end;

function MiniDevToolFrame:showFrame()
    self.component:SetVisible(true);
    self:updateTextBox();
    self:updateUpDownArrowState();
end;

includeMixins(MiniDevToolFrame, ComponentMixin);