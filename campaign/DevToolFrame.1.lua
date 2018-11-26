require("console");
require("remove_component");
require("MiniDevToolFrame");
require("ui/ComponentMixin");

DevToolFrame = {
    frameName = "DevToolFrame",
    componentFile = "ui/campaign ui/technology_panel",
    component = nil,
    content = nil,
    textbox = nil,
    listView = nil,
    codeListView = nil,
    codeListViewText = nil,
    enterButton = nil,
    executeButton = nil,
    clearLogsButton = nil,
    clearCodeButton = nil,
    miniUI = nil,
    miniUIButton = nil,
    upButton = nil,
    downButton = nil,
    lines = {},
    listeners = {},
    currentLineNumber = 1,
    currentLineNumberComponent = nil,
    textPanes = {},
    secondPanelWidth = 600
};

function DevToolFrame:new()  
    local root = core:get_ui_root();
    local existing = find_uicomponent(root, self.frameName);

    self.miniUI = MiniDevToolFrame:new(self);
    self.miniUI:hideFrame();

    if not existing then
        self:createFrame();
        self:registerCloseButton(find_uicomponent(self.component, "panel_frame", "button_ok_lock", "button_ok"));
    end;

    return self;
end;

function DevToolFrame:createFrame()
    local root = core:get_ui_root();
    root:CreateComponent(self.frameName, self.componentFile);

    local component = UIComponent(root:Find(self.frameName));
    self.component = component;
   
    local title = find_uicomponent(self.component, "header_frame", "tx_technology");
    title:SetStateText("DevTool Console");

    remove_component(find_uicomponent(self.component, "label_research_rate"));
    remove_component(find_uicomponent(self.component, "panel_frame", "button_info_holder", "button_info"));
    remove_component(find_uicomponent(self.component, "info_holder", "dy_treasury"));
    remove_component(find_uicomponent(self.component, "info_holder", "infamy_holder"));
        
    local parchment = UIComponent(self.component:Find("parchment"));
    self.content = parchment;
    
    -- add the text box
    self:addTextBox();

    -- add the mini switch button
    self.miniUIButton = self:addMiniUIButton();

    -- creating up / down arrow
    self.upButton = self:createUpArrow();
    self.downButton = self:createDownArrow();

    -- create enter button
    self.enterButton = self:createEnterButton();

    -- create execute button
    self.executeButton = self:createExecuteButton();
    
    -- create clear logs button
    self.clearLogsButton = self:createClearLogsButton();

    -- create clear code button
    self.clearCodeButton = self:createClearCodeButton();

    -- create line numerical display
    self:createLineNumberDisplay();

    -- creating list box for scrolling
    self:createListView();

    -- creating list box for code viewin
    self:createCodeListView();

    -- update up / down arrows state
    self:updateUpDownArrowState();
end;

function DevToolFrame:addMiniUIButton()
    local buttonName = self.frameName .. "_MiniUIButton";
    self.component:CreateComponent(buttonName, "ui/templates/round_small_button");

    local button = find_uicomponent(self.component, buttonName);
    button:SetImage("script/campaign/resize_icon.png");
    button:SetTooltipText("Switch to minimized UI", true);

    button:PropagatePriority(self.component:Priority());
    self.component:Adopt(button:Address());

    local componentWidth, componentHeight = self.component:Bounds();
    self:positionComponentRelativeTo(button, self.component, componentWidth - 80, 30);

    local listenerName = "devtool_button_Listener";
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context) return button == UIComponent(context.component); end,    
        function(context)
            self.miniUI:showFrame();
            self:hideFrame();
        end,
        true
    );
    table.insert(self.listeners, listenerName);

    return button;
end;

function DevToolFrame:addTextBox()
    local name = self.frameName .. "_TextBox";
    local filepath = "ui/common ui/file_requester";
    local content = self.component;

    content:CreateComponent(name .. "_UITEMP", filepath);
    local tempUI = UIComponent(content:Find(name .. "_UITEMP"));
    local textbox = find_uicomponent(tempUI, "input_name");
    self.textbox = textbox;
    
    textbox:PropagatePriority(content:Priority());
    content:Adopt(textbox:Address());
    remove_component(find_uicomponent(textbox, "input_name_label"));
    remove_component(tempUI);

    -- resize
    local contentWidth, contentHeight = self.content:Bounds();
    self:resizeComponent(textbox, contentWidth - self.secondPanelWidth);
    self:positionComponentRelativeTo(textbox, self.content, 20, 20);
end;

function DevToolFrame:createUpArrow()
    local name = self.frameName .. "_TextBox";
    local content = self.component;
    local textbox = self.textbox;

    -- creating button
    content:CreateComponent(name .. "_UpButton", "ui/templates/round_medium_button");
    local upButton = UIComponent(content:Find(name .. "_UpButton"));

    content:Adopt(upButton:Address());
    upButton:PropagatePriority(content:Priority());
    upButton:SetImage("ui/skins/default/parchment_sort_arrow_up.png");
    self:resizeComponent(upButton, 17, 17);
    self:positionComponentRelativeToWithOffset(upButton, textbox, 5, -30);

    local listenerName = "DevToolFrame_TextBox_UpButtonListener";
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context)
            return upButton == UIComponent(context.component);
        end,

        function(context)
            self:decrementLines();
            self:updateUpDownArrowState();
        end,
        true
    );
    table.insert(self.listeners, listenerName);

    return upButton;
end;

function DevToolFrame:decrementLines()
    -- only allow decrement up to 0 index.
    if self.currentLineNumber == 1 then
        return;
    end;

    self:updateLines();
    self.currentLineNumber = self.currentLineNumber - 1;
    self:updateLineNumberDisplay();
    self:updateTextBox();
end;

function DevToolFrame:createDownArrow()
    local name = self.frameName .. "_TextBox";
    local content = self.component;
    local textbox = self.textbox;

    -- creating button
    content:CreateComponent(name .. "_DownButton", "ui/templates/round_medium_button");
    local downButton = UIComponent(content:Find(name .. "_DownButton"));

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
            self:incrementLines();
            self:updateUpDownArrowState();
        end,
        true
    );
    table.insert(self.listeners, listenerName);

    return downButton;
end;

function DevToolFrame:incrementLines()
    self:updateLines();
    self.currentLineNumber = self.currentLineNumber + 1;
    self:updateLineNumberDisplay();
    self:updateTextBox();
end;

function DevToolFrame:createLineNumberDisplay()
    local componentName = self.frameName .. "_LineNumberComponent";
    local content = self.component;
    
    content:CreateComponent(componentName .. "_UITEMP", "ui/campaign ui/mission_details");
    local tempUI = UIComponent(content:Find(componentName .. "_UITEMP"));

    local component = find_uicomponent(tempUI, "mission_details_child", "description_background", "description_view", "dy_description");
    content:Adopt(component:Address());
    component:PropagatePriority(content:Priority());
    remove_component(tempUI);

    local contentWidth, contentHeight = content:Bounds();
    self:resizeComponent(component, contentWidth - self.secondPanelWidth, 30);
    self:positionComponentRelativeTo(component, self.textbox, 0, 35);

    self.currentLineNumberComponent = component;
    self:updateLineNumberDisplay();
end;

function DevToolFrame:createListView()
    self.component:CreateComponent(self.frameName .. "_ListBox_UITEMP", "ui/campaign ui/finance_screen");
    local tempUI = UIComponent(self.component:Find(self.frameName .. "_ListBox_UITEMP"));
    local listView = find_uicomponent(tempUI, "tab_trade", "trade", "exports", "trade_partners_list", "listview");
    remove_component(find_uicomponent(listView, "headers"));
    self.listView = listView;

    self.component:Adopt(listView:Address());
    listView:PropagatePriority(self.component:Priority());
    remove_component(tempUI);

    local contentWidth, contentHeight = self.content:Bounds();
    local textboxWidth, textboxHeight = self.textbox:Bounds();
    local lineNumberWidth, lineNumberHeight = self.currentLineNumberComponent:Bounds();
    self:resizeComponent(listView, contentWidth - self.secondPanelWidth, contentHeight - (textboxHeight + lineNumberHeight + 40));
    self:positionComponentRelativeTo(listView, self.textbox, 0, textboxHeight + lineNumberHeight + 10);
end;

function DevToolFrame:createCodeListView()
    local listViewWidth, listViewHeight = self.listView:Bounds();

    -- list view title
    local componentTitleName = self.frameName .. "ListBoxTextTitle_UITEMP";
    self.component:CreateComponent(componentTitleName, "ui/campaign ui/mission_details");
    local tempTitleTextUI = UIComponent(self.component:Find(componentTitleName));

    local title = find_uicomponent(tempTitleTextUI, "mission_details_child", "description_background", "description_view", "dy_description");
    self.component:Adopt(title:Address());
    title:PropagatePriority(self.component:Priority());
    remove_component(tempTitleTextUI);
    title:SetStateText("Current Code:");

    self:resizeComponent(title, self.secondPanelWidth, 30);
    self:positionComponentRelativeTo(title, self.listView, listViewWidth, -self.currentLineNumberComponent:Height());

    -- list view
    self.component:CreateComponent(self.frameName .. "_ListBox_UITEMP", "ui/campaign ui/finance_screen");
    local tempUI = UIComponent(self.component:Find(self.frameName .. "_ListBox_UITEMP"));
    local codeListView = find_uicomponent(tempUI, "tab_trade", "trade", "exports", "trade_partners_list", "listview");
    remove_component(find_uicomponent(codeListView, "headers"));
    self.codeListView = codeListView;

    self.component:Adopt(codeListView:Address());
    codeListView:PropagatePriority(self.component:Priority());
    remove_component(tempUI);

    self:resizeComponent(codeListView, self.secondPanelWidth, listViewHeight);
    self:positionComponentRelativeTo(codeListView, self.listView, listViewWidth, 0);

    -- text code pane
    local componentName = self.frameName .. "ListBoxText_UITEMP";
    local listBoxContent = find_uicomponent(codeListView, "list_clip", "list_box");
    listBoxContent:CreateComponent(componentName, "ui/campaign ui/mission_details");
    local tempTextUI = UIComponent(listBoxContent:Find(componentName));

    local component = find_uicomponent(tempTextUI, "mission_details_child", "description_background", "description_view", "dy_description");
    self.codeListViewText = component;
    listBoxContent:Adopt(component:Address());
    component:PropagatePriority(listBoxContent:Priority());
    remove_component(tempTextUI);
end;

function DevToolFrame:updateLines()
    local textbox = self.textbox;
    if self.miniUI.component:Visible() then
        textbox = self.miniUI.textbox;
    end;

    local text = textbox:GetStateText();
    self.lines[self.currentLineNumber] = text;

    self:updateTextCode();
end;

function DevToolFrame:updateTextCode()
    local lines = {};
    for i, v in ipairs(self.lines) do
        lines[i] = i .. ":    " .. self.lines[i];
    end

    local text = table.concat(lines, "\n");
    self.codeListViewText:SetStateText("\n" .. text);
end;

function DevToolFrame:updateLineNumberDisplay()
    local component = self.currentLineNumberComponent;
    component:SetStateText("Current Line: " .. self.currentLineNumber);

    self.miniUI:updateLineNumberDisplay();
end;

function DevToolFrame:updateTextBox()
    local text = self.lines[self.currentLineNumber] or "";

    remove_component(find_uicomponent(self.component, "input_name"));
    self:addTextBox();

    self.textbox:SimulateLClick();
    for i in string.gmatch(text, ".") do
        self.textbox:SimulateKey(i);
    end
end;

function DevToolFrame:updateUpDownArrowState()
    if self.currentLineNumber == 1 then
        self.upButton:SetState("inactive");
        if #self.lines == 0 then
            self.downButton:SetState("inactive");
        else
            self.downButton:SetState("active");
        end
    elseif self.currentLineNumber >= #self.lines then
        self.upButton:SetState("active");
        self.downButton:SetState("inactive");
    else
        self.upButton:SetState("active");
        self.downButton:SetState("active");
    end

    self.miniUI:updateUpDownArrowState();
end;

function DevToolFrame:createEnterButton()
    local upButton = self.upButton;
    local textbox = self.textbox;

    -- creating button
    local button = self:createButton("Enter", "Save current line and go into next", 120, function(context)
        self:incrementLines();
        self:updateUpDownArrowState();
        self.enterButton:SetState("down_off");
    end);

    self:positionComponentRelativeToWithOffset(button, upButton, 10, -(textbox:Height() / 2 + 5));

    return button;
end;

function DevToolFrame:createExecuteButton()
    local textbox = self.textbox;
    local enterButton = self.enterButton;

    -- creating button
    local executeButton = self:createButton("Execute", "Execute Code", 120, function(context)
        self:executeCode();
        self.executeButton:SetState("down_off");
    end);

    self:positionComponentRelativeToWithOffset(executeButton, enterButton, 0, -enterButton:Height());

    return executeButton;
end;

function DevToolFrame:executeCode()
    self:updateLines();

    local text = table.concat(self.lines, "\n");

    local numberedLines = {};
    for i, v in ipairs(self.lines) do
        numberedLines[i] = i .. ":    " .. self.lines[i];
    end
    local outputText = table.concat(numberedLines, "\n");

    self:addTextOutput(">>\n" .. outputText);

    local outputFunction, error = loadstring(text);
    if not outputFunction then
        return self:addTextOutput("[[col:red]] Got a compile error: " .. error .. "[[/col]]");
    end

    local ok, res = pcall(outputFunction);
    if ok then
        self:addTextOutput("=> " .. tostring(res));
    else
        self:addTextOutput("[[col:red]] Got a runtime error: " .. res .. "[[/col]]");
    end
end;

function DevToolFrame:createClearLogsButton()
    local executeButton = self.executeButton;

    -- creating button
    local clearButton = self:createButton("Clear Logs", "Clear all output lines below the textbox", 150, function(context)
        self:clearLogsOutput();
        self.clearLogsButton:SetState("down_off");
    end);

    self:positionComponentRelativeToWithOffset(clearButton, executeButton, 0, -executeButton:Height());
    return clearButton;
end;

function DevToolFrame:clearLogsOutput()
    local toClear = find_uicomponent(self.listView, "list_clip", "list_box");
    toClear:DestroyChildren();
end;

function DevToolFrame:createClearCodeButton()
    local clearLogsButton = self.clearLogsButton;

    -- creating button
    local button = self:createButton("Clear Code", "Clear all previously entered code in the textbox", 150, function(context)
        self:clearCodeLines();
        self.clearCodeButton:SetState("down_off");
    end);

    self:positionComponentRelativeToWithOffset(button, clearLogsButton, 0, -clearLogsButton:Height());
    return button;
end;

function DevToolFrame:clearCodeLines()
    self.lines = {};
    self.currentLineNumber = 1;
    self:updateLineNumberDisplay();
    self:updateTextBox();
    self:updateUpDownArrowState();

    self.codeListViewText:SetStateText("");
end;

function DevToolFrame:addTextOutput(text)
    local componentName = self.frameName .. "_Text" .. #self.textPanes;
    
    local content = find_uicomponent(self.listView, "list_clip", "list_box");
    content:CreateComponent(componentName .. "_UITEMP", "ui/campaign ui/mission_details");
    local tempUI = UIComponent(content:Find(componentName .. "_UITEMP"));

    local component = find_uicomponent(tempUI, "mission_details_child", "description_background", "description_view", "dy_description");
    content:Adopt(component:Address());
    component:PropagatePriority(content:Priority());
    remove_component(tempUI);

    local contentWidth, contentHeight = content:Bounds();
    local textWidth, textHeight = component:TextDimensionsForText(text);
    self:resizeComponent(component, textWidth, textHeight);

    local lastComponent = self.textPanes[#self.textPanes];
    if not lastComponent then
        self:positionComponentRelativeTo(component, self.listView, 0, 0);
    else 
        local lastWidth, lastHeight = lastComponent:Bounds();
        self:positionComponentRelativeTo(component, lastComponent, 0, lastHeight);
    end    

    component:SetStateText(text);
    table.insert(self.textPanes, component);

    return component;
end;

function DevToolFrame:registerCloseButton(component)
    local listenerName = "DevToolFrame_CloseButtonListener";
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context)
            return component == UIComponent(context.component);
        end,

        function(context)
            self:hideFrame();
            self.miniUI:hideFrame();
        end,
        true
    );
    table.insert(self.listeners, listenerName);
end;

function DevToolFrame:removeFrame()
    remove_component(self.component);
    for i, listener in ipairs(self.listeners) do
        core:remove_listener(listener);
    end

    self.listeners = {};
end;

function DevToolFrame:hideFrame()
    self.component:SetVisible(false);
end;

function DevToolFrame:showFrame()
    self.miniUI:hideFrame();
    self.component:SetVisible(true);
    self:updateTextBox();
end;

includeMixins(DevToolFrame, ComponentMixin);