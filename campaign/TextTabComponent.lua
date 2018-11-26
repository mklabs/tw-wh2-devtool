require("console");
require("remove_component");
require("ui/ComponentMixin");


TextTabComponent = {
    frameName = "DevToolTextTabComponent",
    devtool = nil,
    component = nil,
    textbox = nil,
    listView = nil,
    codeListView = nil,
    codeListViewText = nil,
    enterButton = nil,
    executeButton = nil,
    clearLogsButton = nil,
    clearCodeButton = nil,
    upButton = nil,
    downButton = nil,
    currentLineNumberComponent = nil,
    secondPanelWidth = 600,
    textPanes = {},
    listeners = {}
};

function TextTabComponent:new(devtool)
    self.devtool = devtool;
    self:createFrame();
    self:createComponents();
    return self;
end;

function TextTabComponent:createFrame()
    local content = self.devtool.component;

    content:CreateComponent(self.frameName, "UI/campaign ui/script_dummy");
    self.component = find_uicomponent(content, self.frameName);
    self.component:PropagatePriority(content:Priority());
    content:Adopt(self.component:Address());
end;

function TextTabComponent:createComponents()
    -- add the text box
    self:addTextBox();

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

function TextTabComponent:addTextBox()
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
    local contentWidth, contentHeight = self.devtool.content:Bounds();
    self:resizeComponent(textbox, contentWidth - self.secondPanelWidth);
    self:positionComponentRelativeTo(textbox, self.devtool.content, 20, 20);
end;

function TextTabComponent:createUpArrow()
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

    local listenerName = "TextTabComponent_TextBox_UpButtonListener";
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context)
            return upButton == UIComponent(context.component);
        end,

        function(context)
            self.devtool:decrementLines();
            self:updateUpDownArrowState();
        end,
        true
    );
    table.insert(self.listeners, listenerName);

    return upButton;
end;

function TextTabComponent:createDownArrow()
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

    local listenerName = "TextTabComponent_TextBox_DownButtonListener";
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context)
            return downButton == UIComponent(context.component);
        end,

        function(context)
            self.devtool:incrementLines();
            self:updateUpDownArrowState();
        end,
        true
    );
    table.insert(self.listeners, listenerName);

    return downButton;
end;

function TextTabComponent:createLineNumberDisplay()
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

function TextTabComponent:createListView()
    local content = self.component;

    content:CreateComponent(self.frameName .. "_ListBox_UITEMP", "ui/campaign ui/finance_screen");
    local tempUI = UIComponent(content:Find(self.frameName .. "_ListBox_UITEMP"));
    local listView = find_uicomponent(tempUI, "tab_trade", "trade", "exports", "trade_partners_list", "listview");
    remove_component(find_uicomponent(listView, "headers"));
    self.listView = listView;

    content:Adopt(listView:Address());
    listView:PropagatePriority(content:Priority());
    remove_component(tempUI);

    local contentWidth, contentHeight = self.devtool.content:Bounds();
    local textboxWidth, textboxHeight = self.textbox:Bounds();
    local lineNumberWidth, lineNumberHeight = self.currentLineNumberComponent:Bounds();
    self:resizeComponent(listView, contentWidth - self.secondPanelWidth, contentHeight - (textboxHeight + lineNumberHeight + 40));
    self:positionComponentRelativeTo(listView, self.textbox, 0, textboxHeight + lineNumberHeight + 10);
end;

function TextTabComponent:createCodeListView()
    local content = self.component;
    local listViewWidth, listViewHeight = self.listView:Bounds();

    -- list view title
    local componentTitleName = self.frameName .. "ListBoxTextTitle_UITEMP";
    content:CreateComponent(componentTitleName, "ui/campaign ui/mission_details");
    local tempTitleTextUI = UIComponent(content:Find(componentTitleName));

    local title = find_uicomponent(tempTitleTextUI, "mission_details_child", "description_background", "description_view", "dy_description");
    content:Adopt(title:Address());
    title:PropagatePriority(content:Priority());
    remove_component(tempTitleTextUI);
    title:SetStateText("Current Code:");

    self:resizeComponent(title, self.secondPanelWidth, 30);
    self:positionComponentRelativeTo(title, self.listView, listViewWidth, -self.currentLineNumberComponent:Height());

    -- list view
    content:CreateComponent(self.frameName .. "_ListBox_UITEMP", "ui/campaign ui/finance_screen");
    local tempUI = UIComponent(content:Find(self.frameName .. "_ListBox_UITEMP"));
    local codeListView = find_uicomponent(tempUI, "tab_trade", "trade", "exports", "trade_partners_list", "listview");
    remove_component(find_uicomponent(codeListView, "headers"));
    self.codeListView = codeListView;

    content:Adopt(codeListView:Address());
    codeListView:PropagatePriority(content:Priority());
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

function TextTabComponent:createEnterButton()
    local upButton = self.upButton;
    local textbox = self.textbox;

    -- creating button
    local button = self:createButton("Enter", "Save current line and go into next", 120, function(context)
        self.devtool:incrementLines();
        self:updateUpDownArrowState();
        self.enterButton:SetState("down_off");
    end);

    self:positionComponentRelativeToWithOffset(button, upButton, 10, -(textbox:Height() / 2 + 5));

    return button;
end;

function TextTabComponent:createExecuteButton()
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

function TextTabComponent:createClearLogsButton()
    local executeButton = self.executeButton;

    -- creating button
    local clearButton = self:createButton("Clear Logs", "Clear all output lines below the textbox", 150, function(context)
        self:clearLogsOutput();
        self.clearLogsButton:SetState("down_off");
    end);

    self:positionComponentRelativeToWithOffset(clearButton, executeButton, 0, -executeButton:Height());
    return clearButton;
end;

function TextTabComponent:createClearCodeButton()
    local clearLogsButton = self.clearLogsButton;

    -- creating button
    local button = self:createButton("Clear Code", "Clear all previously entered code in the textbox", 150, function(context)
        self.devtool:clearCodeLines();
        self.clearCodeButton:SetState("down_off");
    end);

    self:positionComponentRelativeToWithOffset(button, clearLogsButton, 0, -clearLogsButton:Height());
    return button;
end;

function TextTabComponent:addTextOutput(text)
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

function TextTabComponent:updateUpDownArrowState()
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

function TextTabComponent:updateLineNumberDisplay()
    local component = self.currentLineNumberComponent;
    component:SetStateText("Current Line: " .. self.devtool.currentLineNumber);
end;

function TextTabComponent:updateTextBox()
    local content = self.component;
    local text = self.devtool.lines[self.devtool.currentLineNumber] or "";

    remove_component(find_uicomponent(content, "input_name"));
    self:addTextBox();

    self.textbox:SimulateLClick();
    for i in string.gmatch(text, ".") do
        self.textbox:SimulateKey(i);
    end
end;

function TextTabComponent:clearLogsOutput()
    local toClear = find_uicomponent(self.listView, "list_clip", "list_box");
    toClear:DestroyChildren();
end;

function TextTabComponent:removeFrame()
    remove_component(self.component);
    for i, listener in ipairs(self.listeners) do
        core:remove_listener(listener);
    end

    self.listeners = {};
end;

function TextTabComponent:hideFrame()
    self.component:SetVisible(false);
end;

function TextTabComponent:showFrame()
    self.component:SetVisible(true);
    self:updateTextBox();
end;

includeMixins(TextTabComponent, ComponentMixin);