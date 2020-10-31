require("console");
require("remove_component");
require("force_require");
require("devtool_log");
require("ui/MiniDevToolFrame");
require("ui/TextTabComponent");
require("ui/optionsTabComponent");
require("ui/ComponentMixin");

local inspect = require("vendors/inspect");
local json = require("vendors/json");

DevToolFrame = {
    frameName = "DevToolFrame",
    componentFile = "ui/campaign ui/technology_panel",
    component = nil,
    content = nil,
    miniUI = nil,
    miniUIButton = nil,
    textTabComponent = nil,
    optionsTabComponent = nil,
    textTabButton = nil,
    optionsTabButton = nil,
    welcomeMessageDisplayed = true,
    lines = {},
    listeners = {},
    currentLineNumber = 1,
    inspectOptions = { depth = 4, indent = "\t", newline = "\n-" }
};

function DevToolFrame:new()
    console.log("Creating devtool frame");
    self:createFrame();

    self.miniUI = MiniDevToolFrame:new(self);
    self.miniUI:hideFrame();

    self.textTabComponent = TextTabComponent:new(self);
    self.optionsTabComponent = OptionsTabComponent:new(self);
    self.optionsTabComponent:hideFrame();

    self:createComponents();
    self:registerCloseButton(find_uicomponent(self.component, "panel_frame", "button_ok_lock", "button_ok"));

    self:welcomeMessage();

    core:add_listener(
        "DevToolLogLine_Listener",
        "DevToolLogLine",
        true,
        function(context)
            self.textTabComponent:addTextOutput(context.string);
        end,
        true
    );

    cm:add_game_destroyed_callback(function()
        self:gameDestroyedCallback();
    end);

    return self;
end;

function DevToolFrame:gameDestroyedCallback()
    local formData = self.optionsTabComponent:getFormData();
    local file = io.open("devtool_options.json", "w");
    local jsonString = json.encode(formData);
    file:write(jsonString, "\n");
    file:close();
end;

function DevToolFrame:createFrame()
    local root = core:get_ui_root();
    root:CreateComponent(self.frameName, self.componentFile);

    local component = UIComponent(root:Find(self.frameName));
    component:PropagatePriority(1000)
    self.component = component;
   
    local title = find_uicomponent(self.component, "header_frame", "tx_technology");
    title:SetStateText("DevTool Console");

    remove_component(find_uicomponent(self.component, "label_research_rate"));
    remove_component(find_uicomponent(self.component, "panel_frame", "button_info_holder", "button_info"));
    remove_component(find_uicomponent(self.component, "info_holder"));
        
    local parchment = UIComponent(self.component:Find("parchment"));
    self.content = parchment;
end;

function DevToolFrame:createComponents()
    -- add the mini switch button
    self.miniUIButton = self:addMiniUIButton();

    -- add the tab buttons
    self.textTabButton = self:addTextTabButton();
    self.optionsTabButton = self:addOptionsTabButton();
end;

function DevToolFrame:welcomeMessage()
    local text = [[
        
        Welcome to the Modding Console Devtool.

        This welcome message will dismiss on first execute.

        Description
        -----------

        The purpose of this tool is to provide you with an UI that lets you execute LUA code while the game is running.
        It has two UI mode, a minimized and maximized one. Both lets you enter any number of lines (limited to 150 char per line)
        and hit the "Execute" button to loadstring (eval) the code within the game.

        It is inspired by browser developer tools console and aims to provide a basic REPL (read eval print loop) within the game.

        The code you enter has access to the global scope, so any function definition or variables defined globally within the game
        are accessible (core, cm, etc.). To see the log output, remember to add a return statement within the code you input
        in the textbox.

        Printing
        --------

        You can use "print()" or "devtool_log()" with any number of variables to inspect them in the console.

        Loading and Executing a File
        ----------------------------

        Little tip: You can use `force_require()` with a filepath relative to data/script (or inspect the package.path variable to know 
        where the LUA engine will lookup for files) to dynamically require and execute it. It might be handy for longer code, and lets 
        you edit it in your prefered text editor.

        Within required file, you can't use "print()" but you can make use of "devtool_log()" to inspect and log variables to the console.

        Compilation / runtime errors should be displayed in the console.

        Options
        -------

        The options tab you can access by clicking on the "Options" button at the top left of the console window, lets you customize two things:

        - Path to code output: A filepath that when set will make the console write a file to disk. It will contain the code you execute 
        in the console, and is updated each time you hit the "Execute" button.
        
        - Path to logs output: Similar to the above options, this filepath will make the console write another file to disk. This one
        will contain the logs output you can see printed below the textbox each time you hit the "Execute" button.

        These options were added to let you copy and paste content from them, and let you load them in your prefered text editor.

        Both of these options can be disabled if left blank.
    ]];

    self.textTabComponent:addTextOutput(text);
end;

function DevToolFrame:addMiniUIButton()
    local buttonName = self.frameName .. "_MiniUIButton";
    self.component:CreateComponent(buttonName, "ui/templates/round_small_button");

    local button = find_uicomponent(self.component, buttonName);
    button:SetImagePath("script/campaign/resize_icon.png");
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

function DevToolFrame:addTextTabButton()
    -- creating button
    local button = self:createButton("Console", "Switch to Console", 120, function(context)
        console.log("Clicked on the console button");
        self.textTabComponent:showFrame();
        self.optionsTabComponent:hideFrame();
        self.textTabButton:SetState("down_off");
    end);

    local componentWidth, componentHeight = self.component:Bounds();
    self:positionComponentRelativeTo(button, self.component, 40, 33);

    return button;
end;

function DevToolFrame:addOptionsTabButton()
    -- creating button
    local button = self:createButton("Options", "Switch to Options", 120, function(context)
        console.log("Clicked on the options tab button");
        self.optionsTabComponent:showFrame();
        self.textTabComponent:hideFrame();
        self.optionsTabButton:SetState("down_off");
    end);

    self:positionComponentRelativeToWithOffset(button, self.textTabButton, 0, -self.textTabButton:Height());
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

    if self.welcomeMessageDisplayed then
        self.textTabComponent:clearLogsOutput()
        self.welcomeMessageDisplayed = false;
    end;

    local text = table.concat(self.lines, "\n");
    local logs = {};

    local numberedLines = {};
    for i, v in ipairs(self.lines) do
        numberedLines[i] = i .. ":    " .. self.lines[i];
    end
    local outputText = table.concat(numberedLines, "\n");

    component:addTextOutput(">>\n" .. outputText);
    table.insert(logs, ">>\n" .. outputText);

    local outputFunction, error = loadstring(text);
    if not outputFunction then
        component:addTextOutput("[[col:red]] Got a compile error: " .. error .. "[[/col]]");
        table.insert(logs, " Got a compile error: " .. error);
        return self:writeCodeAndLogsToDisk(text, logs);
    end

    -- Set the environment of the Lua chunk to the same one as this file, plus the print function
	setfenv(outputFunction, self:getExecuteEnv());

    local ok, res = pcall(outputFunction);
    if ok then
        component:addTextOutput("=> " .. inspect(res, self.inspectOptions));
        table.insert(logs, "=> " .. inspect(res, self.inspectOptions));
    else
        component:addTextOutput("[[col:red]] Got a runtime error: " .. res .. "[[/col]]");
        table.insert(logs, " Got a runtime error: " .. res);
    end

    self:writeCodeAndLogsToDisk(text, logs);
end;

local old_print = print;
function DevToolFrame:getExecuteEnv()
    -- get the local environment
    local local_env = getfenv(1);

    local env = {};
    setmetatable(env, { __index = local_env });
    --[[
    env.print = function (...)
        local str = "";
        local args = {...};
        for i=1, #args do
            local value = args[i];
            local separator = "";
            if i ~= 1 then
                separator = "\t";
            end

            str = str .. separator .. inspect(value, self.inspectOptions);
        end

        core:trigger_event("DevToolLogLine", str);
        return old_print(str);
    end;
    ]]--

    env.print = devtool_log;
    env.devtool = self;

    return env;
end;

function DevToolFrame:writeCodeAndLogsToDisk(code, logs)
    console.log("writeCodeAndLogsToDisk()");

    local options = self.optionsTabComponent:getFormData();
    local codeOutputPath = options.codeOutput;
    local logsOutputPath = options.logsOutput;
    console.log("code output path: " .. codeOutputPath);
    console.log("logs output path: " .. codeOutputPath);

    if codeOutputPath and codeOutputPath ~= "" then
        console.log("Writing code to " .. codeOutputPath);

        local file = io.open(codeOutputPath, "w");
        file:write("\n", code, "\n");
        file:close();
    end;

    if logsOutputPath and logsOutputPath ~= "" then
        console.log("Writing logs to " .. logsOutputPath);

        local file = io.open(logsOutputPath, "a");

        for i=1, #logs do
            file:write(logs[i], "\n");
        end;
        
        file:close();
    end;
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