require("console");
require("remove_component");

DevToolFrame = {
    frameName = "DevToolFrame",
    componentFile = "ui/campaign ui/technology_panel",
    component = false,
    content = false,
    textbox = false,
    listView = false,
    listeners = {},
    textPanes = {}
};

function DevToolFrame:new()
    console.log("DevToolFrame:new()");
    
    local root = core:get_ui_root();
    local existing = find_uicomponent(root, self.frameName);

    if not existing then
        self:createFrame();
        self:registerCloseButton(find_uicomponent(self.component, "panel_frame", "button_ok_lock", "button_ok"));
    else
        console.log(self.frameName .. " already existing, doing nothing");
    end;

    return self;
end;

function DevToolFrame:createFrame()
    local root = core:get_ui_root();
    root:CreateComponent(self.frameName, self.componentFile);

    local component = UIComponent(root:Find(self.frameName));
    self.component = component;
   
    local title = find_uicomponent(self.component, "header_frame", "tx_technology");
    title:SetStateText(self.frameName);

    local research_rate = find_uicomponent(self.component, "label_research_rate");
    if research_rate then
        remove_component(research_rate);
    end

    local button_info = find_uicomponent(self.component, "panel_frame", "button_info_holder", "button_info");
    if button_info then
        remove_component(button_info);
    end
    
    local parchment = UIComponent(self.component:Find("parchment"));
    self.content = parchment;
    
    self:addTextBox();

    -- creating list box for scrolling
    console.log("Creating list box");
    self.component:CreateComponent(self.frameName .. "_ListBox_UITEMP", "ui/campaign ui/finance_screen");
    local tempUI = UIComponent(self.component:Find(self.frameName .. "_ListBox_UITEMP"));
    local listView = find_uicomponent(tempUI, "tab_trade", "trade", "exports", "trade_partners_list", "listview");
    remove_component(find_uicomponent(listView, "headers"));
    self.listView = listView;

    self.component:Adopt(listView:Address());
    listView:PropagatePriority(self.component:Priority());
    remove_component(tempUI);
    console.log("End of creating list box");

    local contentWidth, contentHeight = self.content:Bounds();
    local textboxWidth, textboxHeight = self.textbox:Bounds();
    console.log("contentWidth: " .. contentWidth);
    console.log("contentHeight: " .. contentHeight);
    self:resizeComponent(listView, contentWidth, contentHeight - (textboxHeight + 20));
    self:positionComponentRelativeTo(listView, self.textbox, 0, 35);
end;

function DevToolFrame:removeFrame()
    console.log("Removing component: " .. self.component:Id());
    remove_component(self.component);
    for i, listener in ipairs(self.listeners) do
        console.log("Removing listener: " .. listener);
        core:remove_listener(listener);
    end
end;

function DevToolFrame:addTextBox()
    local name = self.frameName .. "_TextBox";
    local filepath = "ui/common ui/text_box";
    local content = self.component;

    console.log("Creating component in parent component " .. name .. " from filepath: " .. filepath);
    content:CreateComponent(name, filepath);

    local textbox = UIComponent(content:Find(name));
    self.textbox = textbox;
    content:Adopt(textbox:Address());
    textbox:PropagatePriority(content:Priority());

    -- resize
    local contentWidth, contentHeight = self.content:Bounds();
    self:resizeComponent(textbox, contentWidth - 200);
    self:positionComponentRelativeTo(textbox, self.content, 20, 20);

    -- creating button
    content:CreateComponent(name .. "_Button", "ui/templates/round_medium_button");
    local textboxButton = UIComponent(content:Find(name .. "_Button"));
    content:Adopt(textboxButton:Address());
    textboxButton:PropagatePriority(content:Priority());
    textboxButton:SetImage("ui/skins/default/icon_check.png");
    self:positionComponentRelativeToWithOffset(textboxButton, textbox, 10, -35);

    local listenerName = "DevToolFrame_TextBoxButtonListener";
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context)
            return textboxButton == UIComponent(context.component);
        end,

        function(context)
            console.log("TextBoxButton clicked");
            local text = textbox:GetStateText();
            console.log("TextBox text: " .. text);

            console.log("Compiling outputFunction from text");
            self:addText(text);

            local outputFunction, error = loadstring(text);
            console.log("Compiled outputFunction from text");
            if not outputFunction then
                console.log("Got an error: " .. error);
                return self:addText("[[col:red]] Got a compile error: " .. error .. "[[/col]]");
            end

            console.log("Calling outputFunction");
            local ok, res = pcall(outputFunction);
            if ok then
                self:addText(">> " .. res);
            else
                console.log("Got a runtime error: " .. res);
                self:addText("[[col:red]] Got a runtime error: " .. res .. "[[/col]]");
            end
        end,
        true
    );
    table.insert(self.listeners, listenerName);

    -- creating clear button
    console.log("Creating clear button");
    content:CreateComponent(name .. "_ClearButton", "ui/templates/square_medium_text_button_toggle");
    local clearButton = find_uicomponent(content, name .. "_ClearButton");
    local clearButtonText = find_uicomponent(clearButton, "dy_province");
    content:Adopt(clearButton:Address());
    clearButton:PropagatePriority(content:Priority());
    clearButtonText:SetStateText("Clear");
    clearButton:ResizeTextResizingComponentToInitialSize(120, clearButton:Height());
    self:positionComponentRelativeToWithOffset(clearButton, textboxButton, 10, -50);
    

    local listenerNameClearButton = "DevToolFrame_ClearButtonListener";
    core:add_listener(
        listenerNameClearButton,
        "ComponentLClickUp",
        function(context)
            return clearButton == UIComponent(context.component);
        end,

        function(context)
            console.log("ClearButton clicked");
            local toClear = find_uicomponent(self.listView, "list_clip", "list_box");
            toClear:DestroyChildren();
        end,
        true
    );
    table.insert(self.listeners, listenerNameClearButton);

    console.log("End of creating component " .. name);
    return component;
end;

function DevToolFrame:registerCloseButton(component)
    console.log("Setting up close button listener for: " .. component:Id());

    core:add_listener(
        "DevToolFrame_CloseButtonListener",
        "ComponentLClickUp",
        function(context)
            return component == UIComponent(context.component);
        end,

        function(context)
            self:removeFrame();
            core:remove_listener("DevToolFrame_CloseButtonListener");
        end,
        true
    );
end;

function DevToolFrame:addText(text)
    local componentName = self.frameName .. "_Text" .. #self.textPanes;
    console.log("Adding text: (" .. text .. ") into " .. componentName);

    local content = find_uicomponent(self.listView, "list_clip", "list_box");
    content:CreateComponent(componentName .. "_UITEMP", "ui/campaign ui/mission_details");
    local tempUI = UIComponent(content:Find(componentName .. "_UITEMP"));

    local component = find_uicomponent(tempUI, "mission_details_child", "description_background", "description_view", "dy_description");
    content:Adopt(component:Address());
    component:PropagatePriority(content:Priority());
    remove_component(tempUI);

    local contentWidth, contentHeight = content:Bounds();
    self:resizeComponent(component, contentWidth, 30);

    local lastComponent = self.textPanes[#self.textPanes];
    if not lastComponent then
        self:positionComponentRelativeTo(component, self.textbox, 0, 30);
    else 
        self:positionComponentRelativeTo(component, lastComponent, 0, 30);
    end    

    component:SetStateText(text);
    table.insert(self.textPanes, component);

    console.log("End of addText for: " .. text);
    return component;
end;

function DevToolFrame:positionComponentRelativeTo(component, relativeComponent, xDiff, yDiff)
    console.log("Positioning relative to " .. component:Id());

    xDiff = xDiff or 0;
    yDiff = yDiff or 0;

    local xPosition, yPosition = relativeComponent:Position();
    console.log("xPosition: " .. xPosition .. " yPosition: " .. yPosition);
    
    component:MoveTo(xPosition + xDiff, yPosition + yDiff);
end;

function DevToolFrame:positionComponentRelativeToWithOffset(component, relativeComponent, xDiff, yDiff)
    console.log("Positioning relative to with offset " .. component:Id());
    local xPosition, yPosition = relativeComponent:Position();
    local width, height = relativeComponent:Bounds();
    console.log("xPosition: " .. xPosition .. " yPosition: " .. yPosition);
    console.log("width: " .. width .. " height: " .. height);

    xDiff = xDiff or 0;
    yDiff = yDiff or 0;
    
    component:MoveTo(xPosition + width + xDiff, yPosition + height + yDiff);
end;

function DevToolFrame:resizeComponent(component, width, height)
    local componentWidth, componentHeight = component:Bounds();
    height = height or componentHeight;
    width = width or componentWidth;

    component:SetCanResizeHeight(true);
    component:SetCanResizeWidth(true);
    component:Resize(width, height);
    component:SetCanResizeHeight(false);
    component:SetCanResizeWidth(false);
end;