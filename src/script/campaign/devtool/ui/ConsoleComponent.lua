local debug = require("tw-debug")("devtool:ui:ConsoleComponent")

local devtool = require("devtool/devtool")
local removeComponent = require("devtool/utils/ui/removeComponent")
local positionComponentRelativeTo = require("devtool/utils/ui/positionComponentRelativeTo")
local resizeComponent = require("devtool/utils/ui/resizeComponent")
local createButton = require("devtool/utils/ui/createButton")

local _ = require("devtool/utils/ui/_")

local mixins = require("devtool/ui/mixins")
local includeMixins = mixins.includeMixins
local ComponentMixin = mixins.ComponentMixin

local ConsoleComponent = {
    frameName = "devtool_text_tab_component",
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
    textPanes = {}
}

function ConsoleComponent:new(devtool)
    self.devtool = devtool
    self.isTroy = cm:get_campaign_name() == "main_troy"

    self:createFrame()
    self:createComponents()
    return self
end

function ConsoleComponent:createFrame()
    local content = self.devtool.component

    content:CreateComponent(self.frameName, "script/ui/devtool/campaign ui/script_dummy")
    self.component = find_uicomponent(content, self.frameName)
    self.component:PropagatePriority(content:Priority())
    content:Adopt(self.component:Address())
end

function ConsoleComponent:createComponents()
    -- add the text box
    self:addTextBox()

    -- creating up / down arrow
    self.upButton = self:createUpArrow()
    self.downButton = self:createDownArrow()

    -- create enter button
    self.enterButton = self:createEnterButton()

    -- create execute button
    self.executeButton = self:createExecuteButton()
    
    -- create clear logs button
    self.clearLogsButton = self:createClearLogsButton()

    -- create clear code button
    self.clearCodeButton = self:createClearCodeButton()

    -- create line numerical display
    self:createLineNumberDisplay()

    -- create input file hint
    self:createInputFileHint()

    -- creating list box for scrolling
    self:createListView()

    -- creating list box for code viewin
    self:createCodeListView()

    -- update up / down arrows state
    self:updateUpDownArrowState()
end

function ConsoleComponent:addTextBox()
    local name = self.frameName .. "_TextBox"
    local filepath = "script/ui/devtool/common ui/file_requester"
    local content = self.component

    content:CreateComponent(name .. "_UITEMP", filepath)
    local tempUI = UIComponent(content:Find(name .. "_UITEMP"))
    local textbox = find_uicomponent(tempUI, "input_name")
    self.textbox = textbox
    
    textbox:PropagatePriority(content:Priority())
    content:Adopt(textbox:Address())
    removeComponent(find_uicomponent(textbox, "input_name_label"))
    removeComponent(tempUI)

    -- resize
    local contentWidth, contentHeight = self.devtool.content:Bounds()
    resizeComponent(textbox, contentWidth - self.secondPanelWidth)
    positionComponentRelativeTo(textbox, self.devtool.content, 20, 20)
end

function ConsoleComponent:createUpArrow()
    local name = self.frameName .. "_TextBox"
    local content = self.component
    local textbox = self.textbox

    -- creating button
    content:CreateComponent(name .. "_UpButton", "script/ui/devtool/templates/round_medium_button")
    local upButton = UIComponent(content:Find(name .. "_UpButton"))

    content:Adopt(upButton:Address())
    upButton:PropagatePriority(content:Priority())
    upButton:SetImagePath("ui/skins/default/parchment_sort_arrow_up.png")
    resizeComponent(upButton, 17, 17)
    self:positionComponentRelativeToWithOffset(upButton, textbox, 5, -30)

    local listenerName = "ConsoleComponent_TextBox_UpButtonListener"
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context)
            return upButton == UIComponent(context.component)
        end,

        function(context)
            self.devtool:decrementLines()
            self:updateUpDownArrowState()
        end,
        true
    )
    return upButton
end

function ConsoleComponent:createDownArrow()
    local name = self.frameName .. "_TextBox"
    local content = self.component
    local textbox = self.textbox

    -- creating button
    content:CreateComponent(name .. "_DownButton", "script/ui/devtool/templates/round_medium_button")
    local downButton = UIComponent(content:Find(name .. "_DownButton"))

    content:Adopt(downButton:Address())
    downButton:PropagatePriority(content:Priority())
    downButton:SetImagePath("ui/skins/default/parchment_sort_arrow_down.png")
    resizeComponent(downButton, 17, 17)
    self:positionComponentRelativeToWithOffset(downButton, textbox, 5, -15)

    local listenerName = "ConsoleComponent_TextBox_DownButtonListener"
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context)
            return downButton == UIComponent(context.component)
        end,

        function(context)
            self.devtool:incrementLines()
            self:updateUpDownArrowState()
        end,
        true
    )
    return downButton
end

function ConsoleComponent:createLineNumberDisplay()
    local componentName = self.frameName .. "_LineNumberComponent"
    local content = self.component

    content:CreateComponent(componentName .. "_UITEMP", "script/ui/devtool/campaign ui/mission_details")
    local tempUI = UIComponent(content:Find(componentName .. "_UITEMP"))

    local component = find_uicomponent(tempUI, "mission_details_child", "description_background", "description_view", "dy_description")
    content:Adopt(component:Address())
    component:PropagatePriority(content:Priority())
    removeComponent(tempUI)

    local contentWidth, contentHeight = content:Bounds()
    resizeComponent(component, 250, 30)
    positionComponentRelativeTo(component, self.textbox, 0, 35)

    self.currentLineNumberComponent = component
    self:updateLineNumberDisplay()
end

function ConsoleComponent:createInputFileHint()
    local componentName = self.frameName .. "_inputfile_hint"
    local content = self.component

    content:CreateComponent(componentName .. "_UITEMP", "script/ui/devtool/campaign ui/mission_details")
    local tempUI = UIComponent(content:Find(componentName .. "_UITEMP"))

    local component = find_uicomponent(tempUI, "mission_details_child", "description_background", "description_view", "dy_description")
    content:Adopt(component:Address())
    component:PropagatePriority(content:Priority())
    removeComponent(tempUI)

    local contentWidth, contentHeight = content:Bounds()
    local text = "You can also use the console/input.lua file in the script folder "
    local textWidth, textHeight = component:TextDimensionsForText(text)

    resizeComponent(component, textWidth, textHeight)

    local textboxWidth, textboxHeight = self.textbox:Bounds() 
    positionComponentRelativeTo(component, self.textbox, textboxWidth - textWidth, 35)
    component:SetStateText("[[col:help_page_link]]" .. text .. "[[/col]]")
    component:SetTooltipText("Click to open the file in your text editor.\n\nThe content of the file will be executed on each save as if you were using the console textbox.", true)

    local savedValue = cm:get_saved_value("devtool_options_fileWatch")
    -- compare against false to account for nil value when saved value has not been saved yet
    if savedValue == false then
        component:SetVisible(false)
    end

    local listenerName = "devtool_open_inputfile_listener"
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context) return component == UIComponent(context.component) end,    
        function(context)
            debug("Open input file in text editor", devtool.INPUT_FILEPATH)
            os.execute("start " .. devtool.INPUT_FILEPATH)
        end,
        true
    )

    core:remove_listener("devtool_options_fileWatch_changed_hint_listener")
    core:add_listener(
		"devtool_options_fileWatch_changed_hint_listener",
		"devtool_options_fileWatch_changed",
		true,
        function(context)
            local shouldWatchFile = context.bool
            debug("devtool_options_fileWatch_changed_hint_listener", shouldWatchFile)
            component:SetVisible(shouldWatchFile)
        end,
		true
	)

    return component
end

function ConsoleComponent:createListView()
    local content = self.component

    content:CreateComponent(self.frameName .. "_ListBox_UITEMP", "script/ui/devtool/campaign ui/finance_screen")
    -- content:CreateComponent(self.frameName .. "_ListBox_UITEMP", "script/ui/devtool/templates/finance_screen")

    local tempUI = UIComponent(content:Find(self.frameName .. "_ListBox_UITEMP"))
    local listView = find_uicomponent(tempUI, "tab_trade", "trade", "exports", "trade_partners_list", "listview")
    removeComponent(find_uicomponent(listView, "headers"))
    self.listView = listView

    content:Adopt(listView:Address())
    listView:PropagatePriority(content:Priority())
    removeComponent(tempUI)

    local contentWidth, contentHeight = self.devtool.content:Bounds()
    local textboxWidth, textboxHeight = self.textbox:Bounds()
    local lineNumberWidth, lineNumberHeight = self.currentLineNumberComponent:Bounds()
    resizeComponent(listView, contentWidth - self.secondPanelWidth, contentHeight - (textboxHeight + lineNumberHeight + 40))
    positionComponentRelativeTo(listView, self.textbox, 0, textboxHeight + lineNumberHeight + 10)

    if self.isTroy then
        local slider = _(listView, "vslider")
        local w, h = slider:Bounds()
        resizeComponent(slider, w, h + 100)
    end
end

function ConsoleComponent:createCodeListView()
    local content = self.component
    local listViewWidth, listViewHeight = self.listView:Bounds()

    -- list view title
    local componentTitleName = self.frameName .. "ListBoxTextTitle_UITEMP"
    content:CreateComponent(componentTitleName, "script/ui/devtool/campaign ui/mission_details")
    -- content:CreateComponent(componentTitleName, "script/ui/devtool/templates/mission_details")
    local tempTitleTextUI = UIComponent(content:Find(componentTitleName))

    local title = find_uicomponent(tempTitleTextUI, "mission_details_child", "description_background", "description_view", "dy_description")
    content:Adopt(title:Address())
    title:PropagatePriority(content:Priority())
    removeComponent(tempTitleTextUI)
    title:SetStateText("Current Code:")

    resizeComponent(title, self.secondPanelWidth, 30)
    positionComponentRelativeTo(title, self.listView, listViewWidth, -self.currentLineNumberComponent:Height())

    -- list view
    content:CreateComponent(self.frameName .. "_ListBox_UITEMP", "script/ui/devtool/campaign ui/finance_screen")
    -- content:CreateComponent(self.frameName .. "_ListBox_UITEMP", "script/ui/devtool/templates/finance_screen")

    local tempUI = UIComponent(content:Find(self.frameName .. "_ListBox_UITEMP"))
    local codeListView = find_uicomponent(tempUI, "tab_trade", "trade", "exports", "trade_partners_list", "listview")
    removeComponent(find_uicomponent(codeListView, "headers"))
    self.codeListView = codeListView

    content:Adopt(codeListView:Address())
    codeListView:PropagatePriority(content:Priority())
    removeComponent(tempUI)

    resizeComponent(codeListView, self.secondPanelWidth, listViewHeight)
    positionComponentRelativeTo(codeListView, self.listView, listViewWidth, 0)

    -- text code pane
    local componentName = self.frameName .. "ListBoxText_UITEMP"
    local listBoxContent = find_uicomponent(codeListView, "list_clip", "list_box")
    listBoxContent:CreateComponent(componentName, "script/ui/devtool/campaign ui/mission_details")
    -- listBoxContent:CreateComponent(componentName, "script/ui/devtool/templates/mission_details")
    local tempTextUI = UIComponent(listBoxContent:Find(componentName))

    local component = find_uicomponent(tempTextUI, "mission_details_child", "description_background", "description_view", "dy_description")
    self.codeListViewText = component
    listBoxContent:Adopt(component:Address())
    component:PropagatePriority(listBoxContent:Priority())
    removeComponent(tempTextUI)

    if self.isTroy then
        local slider = _(codeListView, "vslider")
        local w, h = slider:Bounds()
        resizeComponent(slider, w, h + 100)

        local x, y = slider:Position()
        slider:MoveTo(x - 30, y)
    end
end

function ConsoleComponent:createEnterButton()
    local upButton = self.upButton
    local textbox = self.textbox

    local id = self.frameName .. "_enter_btn"
    local button = createButton(id, self.component, "Enter", "Save current line and go into next", 120, function(context)
        self.devtool:incrementLines()
        self:updateUpDownArrowState()
        self.enterButton:SetState("down_off")
    end)

    self:positionComponentRelativeToWithOffset(button, upButton, 10, -(textbox:Height() / 2 + 5))
    return button
end

function ConsoleComponent:createExecuteButton()
    local textbox = self.textbox
    local enterButton = self.enterButton

    local id = self.frameName .. "_exec_btn"
    local button = createButton(id, self.component, "Execute", "Execute Code", 120, function(context)
        self.devtool:executeCode()
        self.executeButton:SetState("down_off")
    end)

    local offset = self.isTroy and 10 or 0
    self:positionComponentRelativeToWithOffset(button, enterButton, offset, -enterButton:Height())
    return button
end

function ConsoleComponent:createClearLogsButton()
    local executeButton = self.executeButton

    local width = self.isTroy and 120 or 150
    local id = self.frameName .. "_clear_logs_btn"
    local button = createButton(id, self.component, "Clear Logs", "Clear all output lines below the textbox", width, function(context)
        self:clearLogsOutput()
        self.clearLogsButton:SetState("down_off")
    end)

    local offset = self.isTroy and 10 or 0
    self:positionComponentRelativeToWithOffset(button, executeButton, offset, -executeButton:Height())
    return button
end

function ConsoleComponent:createClearCodeButton()
    local clearLogsButton = self.clearLogsButton

    local width = self.isTroy and 120 or 150
    local id = self.frameName .. "_clear_code_btn"
    local button = createButton(id, self.component, "Clear Code", "Clear all previously entered code in the textbox", width, function(context)
        self.devtool:clearCodeLines()
        self.clearCodeButton:SetState("down_off")
    end)

    local offset = self.isTroy and 10 or 0
    self:positionComponentRelativeToWithOffset(button, clearLogsButton, offset, -clearLogsButton:Height())
    return button
end

function ConsoleComponent:addTextOutput(text)
    local componentName = self.frameName .. "_Text" .. #self.textPanes

    local content = find_uicomponent(self.listView, "list_clip", "list_box")
    content:CreateComponent(componentName .. "_UITEMP", "script/ui/devtool/campaign ui/mission_details")
    -- content:CreateComponent(componentName .. "_UITEMP", "script/ui/devtool/templates/mission_details")
    local tempUI = UIComponent(content:Find(componentName .. "_UITEMP"))

    local component = find_uicomponent(tempUI, "mission_details_child", "description_background", "description_view", "dy_description")
    content:Adopt(component:Address())
    component:PropagatePriority(content:Priority())
    removeComponent(tempUI)

    local contentWidth, contentHeight = content:Bounds()
    local textWidth, textHeight = component:TextDimensionsForText(text)
    resizeComponent(component, textWidth, textHeight)

    local lastComponent = self.textPanes[#self.textPanes]
    if not lastComponent then
        positionComponentRelativeTo(component, self.listView, 0, 0)
    else 
        local lastWidth, lastHeight = lastComponent:Bounds()
        positionComponentRelativeTo(component, lastComponent, 0, lastHeight)
    end    

    component:SetStateText(text)
    table.insert(self.textPanes, component)

    return component
end

function ConsoleComponent:updateUpDownArrowState()
    local currentLineNumber = self.devtool.currentLineNumber
    local lines = self.devtool.lines

    if currentLineNumber == 1 then
        self.upButton:SetState("inactive")
        if #lines == 0 then
            self.downButton:SetState("inactive")
        else
            self.downButton:SetState("active")
        end
    elseif currentLineNumber >= #lines then
        self.upButton:SetState("active")
        self.downButton:SetState("inactive")
    else
        self.upButton:SetState("active")
        self.downButton:SetState("active")
    end
end

function ConsoleComponent:updateLineNumberDisplay()
    local component = self.currentLineNumberComponent
    component:SetStateText("Current Line: " .. self.devtool.currentLineNumber)
end

function ConsoleComponent:updateTextBox()
    local content = self.component
    local text = self.devtool.lines[self.devtool.currentLineNumber] or ""

    removeComponent(find_uicomponent(content, "input_name"))
    self:addTextBox()

    self.textbox:SimulateLClick()
    for i in string.gmatch(text, ".") do
        self.textbox:SimulateKey(i)
    end
end

function ConsoleComponent:clearLogsOutput()
    self.textPanes = {}
    local toClear = find_uicomponent(self.listView, "list_clip", "list_box")
    toClear:DestroyChildren()
end

function ConsoleComponent:hideFrame()
    self.component:SetVisible(false)
end

function ConsoleComponent:showFrame()
    self.component:SetVisible(true)
    self:updateTextBox()
end

includeMixins(ConsoleComponent, ComponentMixin)

return ConsoleComponent