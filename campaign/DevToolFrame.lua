require("console");
require("remove_component");
require("MiniDevToolFrame");
require("TextTabComponent");
require("ui/ComponentMixin");

DevToolFrame = {
    frameName = "DevToolFrame",
    componentFile = "ui/campaign ui/technology_panel",
    component = nil,
    content = nil,
    miniUI = nil,
    miniUIButton = nil,
    textTabComponent = nil,
    lines = {},
    listeners = {},
    currentLineNumber = 1
};

function DevToolFrame:new()
    self:createFrame();

    self.miniUI = MiniDevToolFrame:new(self);
    self.miniUI:hideFrame();

    self.textTabComponent = TextTabComponent:new(self);

    self:createComponents();
    self:registerCloseButton(find_uicomponent(self.component, "panel_frame", "button_ok_lock", "button_ok"));

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
end;

function DevToolFrame:createComponents()
    -- add the mini switch button
    self.miniUIButton = self:addMiniUIButton();
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

function DevToolFrame:decrementLines()
    -- only allow decrement up to 0 index.
    if self.currentLineNumber == 1 then
        return;
    end;

    self:updateLines();
    self.currentLineNumber = self.currentLineNumber - 1;
    self:updateLineNumberDisplay();
    self.textTabComponent:updateTextBox();
end;

function DevToolFrame:incrementLines()
    self:updateLines();
    self.currentLineNumber = self.currentLineNumber + 1;
    self:updateLineNumberDisplay();
    self.textTabComponent:updateTextBox();
end;

function DevToolFrame:updateLines()
    local textbox = self.textTabComponent.textbox;
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
    self.textTabComponent.codeListViewText:SetStateText("\n" .. text);
end;

function DevToolFrame:updateLineNumberDisplay()
    self.textTabComponent:updateLineNumberDisplay();
    self.miniUI:updateLineNumberDisplay();
end;

function DevToolFrame:updateUpDownArrowState()
    self.textTabComponent:updateUpDownArrowState();
    self.miniUI:updateUpDownArrowState();
end;

function DevToolFrame:executeCode(component)
    component = component or self.textTabComponent;
    self:updateLines();

    local text = table.concat(self.lines, "\n");

    local numberedLines = {};
    for i, v in ipairs(self.lines) do
        numberedLines[i] = i .. ":    " .. self.lines[i];
    end
    local outputText = table.concat(numberedLines, "\n");

    component:addTextOutput(">>\n" .. outputText);

    local outputFunction, error = loadstring(text);
    if not outputFunction then
        return component:addTextOutput("[[col:red]] Got a compile error: " .. error .. "[[/col]]");
    end

    local ok, res = pcall(outputFunction);
    if ok then
        component:addTextOutput("=> " .. tostring(res));
    else
        component:addTextOutput("[[col:red]] Got a runtime error: " .. res .. "[[/col]]");
    end
end;

function DevToolFrame:clearCodeLines()
    self.lines = {};
    self.currentLineNumber = 1;
    self:updateLineNumberDisplay();
    self.textTabComponent:updateTextBox();
    self:updateUpDownArrowState();

    self.textTabComponent.codeListViewText:SetStateText("");
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
    self.textTabComponent:updateTextBox();
end;

includeMixins(DevToolFrame, ComponentMixin);