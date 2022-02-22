local debug = require("tw-debug")("devtool:ui:DevToolFrame")

local inspect = require("devtool/vendors/inspect")

local devtool = require("devtool/devtool")
local MiniDevToolFrame = require("devtool/ui/MiniDevToolFrame")
local ConsoleComponent = require("devtool/ui/ConsoleComponent")
local HelpTabComponent = require("devtool/ui/HelpTabComponent")
local OptionsFrame = require("devtool/ui/OptionsFrame")

local removeComponent = require("devtool/utils/ui/removeComponent")
local createConfirmBox = require("devtool/utils/ui/createConfirmBox")
local positionComponentRelativeTo = require("devtool/utils/ui/positionComponentRelativeTo")
local welcomeMessage = require("devtool/utils/messages/welcome")
local setupTroyPanels = require("devtool/utils/ui/troy/setupTroyPanels")
local _ = require("devtool/utils/ui/_")

local mixins = require("devtool/ui/mixins")
local includeMixins = mixins.includeMixins
local ComponentMixin = mixins.ComponentMixin

local DevToolFrame = {
    frameName = "devtool_frame",
    troyTemplate = "ui/campaign ui/objectives_screen",
    warhammerTemplate = "script/ui/devtool/campaign ui/technology_panel",
    component = nil,
    content = nil,
    miniUI = nil,
    miniUIButton = nil,
    consoleComponent = nil,
    helpTabComponent = nil,
    textTabButton = nil,
    helpTabButton = nil,
    optionsButton = nil,
    welcomeMessageDisplayed = true,
    lines = {},
    listeners = {},
    currentLineNumber = 1,
    isTroy = false,
    inspectOptions = { depth = 2, indent = "\t", newline = "\n-" }
}

function DevToolFrame:new()
    debug("Create DevToolFrame")
    self.isTroy = cm:get_campaign_name() == "main_troy"

    self:createFrame()
    self:createComponents()
    self:registerCloseButton()

    self.consoleComponent = ConsoleComponent:new(self)
    self.miniUI = MiniDevToolFrame:new(self)
    self.helpTabComponent = HelpTabComponent:new(self)

    self.helpTabComponent:hideFrame()
    self.miniUI:hideFrame()

    self:welcomeMessage()
    self:registerListeners()
    
    self.textTabButton:SetState("selected")

    core:trigger_event("devtool_open")
    return self
end

function DevToolFrame:registerListeners()
    local listeners = {
        devtoolLogline = "devtool_logline_listener",
        devtoolInputFileChanged = "devtool_inputfile_changed_listener",
        devtoolOutputFileChanged = "devtool_outputfile_changed_listener",
        devtoolErrorFileChanged_compile = "devtool_errorfile_changed_compile_listener",
        devtoolErrorFileChanged_runtime = "devtool_errorfile_changed_runtime_listener"
    }

    debug("Register listeners", listeners)
    core:remove_listener(listeners.devtoolLogline)
    core:add_listener(
        listeners.devtoolLogline,
        "devtoolLogline",
        true,
        function(context)
            debug("devtoolLogline event", context.string)
            self.consoleComponent:addTextOutput(context.string)
        end,
        true
    )

    core:remove_listener(listeners.devtoolInputFileChanged)
    core:add_listener(
        listeners.devtoolInputFileChanged,
        "devtoolInputFileChanged",
        true,
        function(context)
            debug("Input file changed", context.string)

            if self.welcomeMessageDisplayed then
                self.consoleComponent:clearLogsOutput()
                self.welcomeMessageDisplayed = false
            end

            self:insertCodeInput(context.string)
            self.consoleComponent.codeListViewText:SetStateText("\n" .. context.string)
        end,
        true
    )

    core:remove_listener(listeners.devtoolOutputFileChanged)
    core:add_listener(
        listeners.devtoolOutputFileChanged,
        "devtoolOutputFileChanged",
        true,
        function(context)
            debug("Output file changed")

            if self.welcomeMessageDisplayed then
                self.consoleComponent:clearLogsOutput()
                self.welcomeMessageDisplayed = false
            end

            local content = devtool.readOutput()
            self:insertCodeResult(content)
        end,
        true
    )

    core:remove_listener(listeners.devtoolErrorFileChanged_compile)
    core:add_listener(
        listeners.devtoolErrorFileChanged_compile,
        "devtoolErrorFileChanged_compile",
        true,
        function(context)
            debug("Error file changed (compile error)", context.string)

            if self.welcomeMessageDisplayed then
                self.consoleComponent:clearLogsOutput()
                self.welcomeMessageDisplayed = false
            end

            self:insertCodeCompileError(context.string)
        end,
        true
    )

    core:remove_listener(listeners.devtoolErrorFileChanged_runtime)
    core:add_listener(
        listeners.devtoolErrorFileChanged_runtime,
        "devtoolErrorFileChanged_runtime",
        true,
        function(context)
            debug("Error file changed (runtime error)", context.string)

            if self.welcomeMessageDisplayed then
                self.consoleComponent:clearLogsOutput()
                self.welcomeMessageDisplayed = false
            end

            self:insertCodeRuntimeError(context.string)
        end,
        true
    )
end

function DevToolFrame:createFrame()
    local root = core:get_ui_root()
    local template = self.isTroy and self.troyTemplate or self.warhammerTemplate
    root:CreateComponent(self.frameName, template)

    local component = UIComponent(root:Find(self.frameName))
    component:PropagatePriority(10)
    self.component = component

    local titlePath = { "header_frame", "tx_technology" }
    if self.isTroy then
        titlePath = { "panel", "panel_title", "panel_title_bar", "panel_header", "title"}
    end

    local title = find_uicomponent(component, unpack(titlePath))
    title:SetStateText("DevTool Console")

    if self.isTroy then
        local parent = find_uicomponent(component, "panel", "TabGroup", "tab_victory_conditions", "tab_child", "tree_holder")
        find_uicomponent(parent, "victory_type_tree", "slot_parent", "troy_main_victory_type_personal"):SetVisible(false)
        find_uicomponent(parent, "victory_type_tree", "slot_parent", "troy_main_victory_type_total"):SetVisible(false)
        setupTroyPanels(component)

        self.content = _(component, "panel > TabGroup > tab_victory_conditions > inner_frame_old")

        local x, y = self.component:Position()
        self.component:MoveTo(x, y + 20)
    else
        removeComponent(find_uicomponent(self.component, "label_research_rate"))
        removeComponent(find_uicomponent(self.component, "panel_frame", "button_info_holder", "button_info"))
        removeComponent(find_uicomponent(self.component, "info_holder"))
        self.content = UIComponent(self.component:Find("parchment"))
    end
end

function DevToolFrame:createComponents()
    -- add the mini switch button
    self.miniUIButton = self:addMiniUIButton()

    -- add the options button
    self.optionsButton = self:addOptionsButton()

    -- add the tab buttons
    self.textTabButton = self:addConsoleTabButton()
    self.helpTabButton = self:addHelpTabButton()
end

function DevToolFrame:welcomeMessage()
    local text = welcomeMessage()
    self.consoleComponent:addTextOutput(text)
end

function DevToolFrame:addMiniUIButton()

    if self.isTroy then
        local component = self.component
        local originalInfoBtn = _(component, "panel > panel_title > button_info")
        originalInfoBtn:SetVisible(false)
    
        local btn = UIComponent(originalInfoBtn:CopyComponent("DevToolFrame_miniUI_btn"))
        btn:SetVisible(true)
        btn:SetImagePath("script/campaign/resize_icon.png")
        btn:SetTooltipText("Switch to minimized UI", true)
    
        local listener = "DevToolFrame_miniUI_btn_listener"
        core:remove_listener(listenerIlistenernfoBtn)
        core:add_listener(
            listener,
            "ComponentLClickUp",
            function(context) return btn == UIComponent(context.component) end,    
            function(context)
               self.miniUI:showFrame()
               self:hideFrame()
            end,
            true
        )
        return btn
    else
        local buttonName = self.frameName .. "_MiniUIButton"
        self.component:CreateComponent(buttonName, "script/ui/devtool/templates/round_small_button")
    
        local btn = find_uicomponent(self.component, buttonName)
        btn:SetImagePath("script/campaign/resize_icon.png")
        btn:SetTooltipText("Switch to minimized UI", true)
    
        btn:PropagatePriority(self.component:Priority())
        self.component:Adopt(btn:Address())
    
        local componentWidth, componentHeight = self.component:Bounds()
        positionComponentRelativeTo(btn, self.component, componentWidth - 80, 30)
    
        local listenerName = "devtool_button_Listener"
        core:add_listener(
            listenerName,
            "ComponentLClickUp",
            function(context) return btn == UIComponent(context.component) end,    
            function(context)
                self.miniUI:showFrame()
                self:hideFrame()
            end,
            true
        )
    
        return btn
    end
end

function DevToolFrame:addOptionsButton()
    local button
    local buttonName = self.frameName .. "_options_button"
    if self.isTroy then
        local originalInfoBtn = _(self.component, "panel > panel_title > button_info")
        originalInfoBtn:SetVisible(false)

        button = UIComponent(originalInfoBtn:CopyComponent(buttonName))
        button:SetVisible(true)
        button:SetImagePath("ui/skins/default/icon_options.png")
    else
        local buttonName = self.frameName .. "_options_button"
        self.component:CreateComponent(buttonName, "script/ui/devtool/templates/round_small_button")
        button = find_uicomponent(self.component, buttonName)
        button:SetImagePath("ui/skins/warhammer2/icon_options.png")
    end

    button:SetTooltipText("Options", true)
    button:PropagatePriority(self.component:Priority())
    self.component:Adopt(button:Address())

    if self.isTroy then
        positionComponentRelativeTo(button, _(self.component, "DevToolFrame_miniUI_btn"), -30, 0)
    else
        local componentWidth, componentHeight = self.component:Bounds()
        positionComponentRelativeTo(button, self.component, componentWidth - 125, 30)
    end


    local listenerName = "devtool_options_button_Listener"
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context) return button == UIComponent(context.component) end,    
        function(context)
            local options = OptionsFrame:new()

            options:accept(function(data)
                cm:set_saved_value("devtool_options_fileWatch", data.fileWatch)
                core:trigger_event("devtool_options_fileWatch_changed", data.fileWatch)

                cm:save(function()
                    debug("Saved")
                end)
            end)
        end,
        true
    )

    return button
end

function DevToolFrame:addConsoleTabButton()
    if self.isTroy then
        local component = self.component
        local originalTabBtn = _(component, "tree_holder > victory_type_tree > slot_parent > troy_main_victory_type_personal")
        originalTabBtn:SetVisible(false)
    
        local btn = UIComponent(originalTabBtn:CopyComponent("DevToolFrame_tabConsoleBtn_btn"))
        btn:SetVisible(true)
        _(btn, "tx_details"):SetStateText("Console")
        btn:SetTooltipText("Switch to Console", true)
    
        local listener = "DevToolFrame_tabConsoleBtn_btn_listener"
        core:remove_listener(listener)
        core:add_listener(
            listener,
            "ComponentLClickUp",
            function(context) return btn == UIComponent(context.component) end,    
            function(context)
                self.consoleComponent:showFrame()
                self.helpTabComponent:hideFrame()
                self.helpTabButton:SetState("down_off")
                self.textTabButton:SetState("selected")
            end,
            true
        )

        return btn
    else
        -- creating button
        local button = self:createButton("Console", "Switch to Console", 120, function(context)
            self.consoleComponent:showFrame()
            self.helpTabComponent:hideFrame()
            self.helpTabButton:SetState("down_off")
            self.textTabButton:SetState("selected")
        end)

        local componentWidth, componentHeight = self.component:Bounds()
        positionComponentRelativeTo(button, self.component, 40, 33)

        return button
    end
end

function DevToolFrame:addHelpTabButton()
    if self.isTroy then
        local component = self.component
        local originalTabBtn = _(component, "tree_holder > victory_type_tree > slot_parent > troy_main_victory_type_personal")
        local btn = UIComponent(originalTabBtn:CopyComponent("DevToolFrame_tabOptionsBtn_btn"))
        btn:SetVisible(true)
        _(btn, "tx_details"):SetStateText("Help")
        btn:SetTooltipText("Switch to Help", true)
    
        local listener = "DevToolFrame_tabOptionsBtn_btn_listener"
        core:remove_listener(listener)
        core:add_listener(
            listener,
            "ComponentLClickUp",
            function(context) return btn == UIComponent(context.component) end,    
            function(context)
               self.helpTabComponent:showFrame()
               self.consoleComponent:hideFrame()
               self.textTabButton:SetState("down_off")
               self.helpTabButton:SetState("selected")
            end,
            true
        )
        return btn
    else

        -- creating button
        local btn = self:createButton("Help", "Help", 120, function(context)
            self.helpTabComponent:showFrame()
            self.consoleComponent:hideFrame()
            self.textTabButton:SetState("down_off")
            self.helpTabButton:SetState("selected")
        end)
        self:positionComponentRelativeToWithOffset(btn, self.textTabButton, 0, -self.textTabButton:Height())
        return btn
    end
end

function DevToolFrame:decrementLines()
    -- only allow decrement up to 0 index.
    if self.currentLineNumber == 1 then
        return
    end

    self:updateLines()
    self.currentLineNumber = self.currentLineNumber - 1
    self:updateLineNumberDisplay()
    self.consoleComponent:updateTextBox()
end

function DevToolFrame:incrementLines()
    self:updateLines()
    self.currentLineNumber = self.currentLineNumber + 1
    self:updateLineNumberDisplay()
    self.consoleComponent:updateTextBox()
end

function DevToolFrame:updateLines()
    local textbox = self.consoleComponent.textbox
    if self.miniUI.component:Visible() then
        textbox = self.miniUI.textbox
    end

    local text = textbox:GetStateText()
    self.lines[self.currentLineNumber] = text

    self:updateTextCode()
end

function DevToolFrame:updateTextCode()
    local lines = {}
    for i, v in ipairs(self.lines) do
        lines[i] = i .. ":    " .. self.lines[i]
    end

    local text = table.concat(lines, "\n")
    self.consoleComponent.codeListViewText:SetStateText("\n" .. text)
end

function DevToolFrame:updateLineNumberDisplay()
    self.consoleComponent:updateLineNumberDisplay()
    self.miniUI:updateLineNumberDisplay()
end

function DevToolFrame:updateUpDownArrowState()
    self.consoleComponent:updateUpDownArrowState()
    self.miniUI:updateUpDownArrowState()
end

function DevToolFrame:executeCode(component)
    component = component or self.consoleComponent
    self:updateLines()

    if self.welcomeMessageDisplayed then
        self.consoleComponent:clearLogsOutput()
        self.welcomeMessageDisplayed = false
    end

    local text = table.concat(self.lines, "\n")
    local logs = {}

    local numberedLines = {}
    for i, v in ipairs(self.lines) do
        numberedLines[i] = i .. ":    " .. self.lines[i]
    end
    local outputText = table.concat(numberedLines, "\n")

    table.insert(logs, ">>\n" .. outputText)
    self:insertCodeInput(outputText)

    local status, res  = devtool.exec(text)
    if status == devtool.EXEC_COMPILE_ERROR then
        -- self:insertCodeCompileError(res)
        table.insert(logs, " Got a compile error: " .. res)
    elseif status == devtool.EXEC_RUNTIME_ERROR then
        -- self:insertCodeRuntimeError(res)
        table.insert(logs, " Got a runtime error: " .. res)
    else
        -- self:insertCodeResult(res)
        table.insert(logs, "=> " .. inspect(res, self.inspectOptions))
    end
end

function DevToolFrame:insertCodeInput(text)
    self.consoleComponent:addTextOutput("> " .. text)
end

function DevToolFrame:insertCodeResult(res)
    self.consoleComponent:addTextOutput("[[col:dark_g]]<[[/col]] " .. res)
end

function DevToolFrame:insertCodeCompileError(text)
    self.consoleComponent:addTextOutput("[[col:dark_r]] Got a compile error: " .. text .. "[[/col]]")
end

function DevToolFrame:insertCodeRuntimeError(text)
    self.consoleComponent:addTextOutput("[[col:dark_r]] Got a runtime error: " .. text .. "[[/col]]")
end

function DevToolFrame:clearCodeLines()
    self.lines = {}
    self.currentLineNumber = 1
    self:updateLineNumberDisplay()
    self.consoleComponent:updateTextBox()
    self:updateUpDownArrowState()

    self.consoleComponent.codeListViewText:SetStateText("")
end

function DevToolFrame:registerCloseButton()
    local btn = find_uicomponent(self.component, "panel_frame", "button_ok_lock", "button_ok")
    if self.isTroy then
        local originalBtn = _(self.component, "panel > bottom_buttons > bottom_buttons > button_slot1 > button_victory")
        originalBtn:SetVisible(false)
    
        btn = UIComponent(originalBtn:CopyComponent("DevToolFrame_close_btn"))
        btn:SetVisible(true)
    end

    local listenerName = "DevToolFrame_CloseButtonListener"
    core:remove_listener(listenerName)
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context)
            return btn == UIComponent(context.component)
        end,

        function(context)
            self:hideFrame()
            self.miniUI:hideFrame()
        end,
        true
    )
end

function DevToolFrame:hideFrame()
    core:trigger_event("devtool_close")
    self.component:SetVisible(false)
end

function DevToolFrame:showFrame()
    core:trigger_event("devtool_open")

    self.miniUI:hideFrame()
    self.component:SetVisible(true)
    self.consoleComponent:updateTextBox()
end

includeMixins(DevToolFrame, ComponentMixin)

return DevToolFrame