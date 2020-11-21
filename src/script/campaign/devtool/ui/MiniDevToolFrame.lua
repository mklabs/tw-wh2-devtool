local debug = require("tw-debug")("devtool:ui:MiniDevToolFrame")

local positionComponentRelativeTo = require("devtool/utils/ui/positionComponentRelativeTo")
local resizeComponent = require("devtool/utils/ui/resizeComponent")
local removeComponent = require("devtool/utils/ui/removeComponent")
local createButton = require("devtool/utils/ui/createButton")

local mixins = require("devtool/ui/mixins")
local includeMixins = mixins.includeMixins
local ComponentMixin = mixins.ComponentMixin

local MiniDevToolFrame = {
    frameName = "devtool_mini_frame",
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
    miniUIButton = nil
}

function MiniDevToolFrame:new(devtool)
    self.devtool = devtool
    self.isTroy = cm:get_campaign_name() == "main_troy"

    local root = core:get_ui_root()
    local existing = find_uicomponent(root, self.frameName)

    if not existing then
        self:createFrame()
    else
        self.component = existing
    end

    return self
end

function MiniDevToolFrame:createFrame()
    local root = core:get_ui_root()

    root:CreateComponent(self.frameName, "script/ui/devtool/campaign ui/script_dummy")
    self.component = find_uicomponent(root, self.frameName)

    self.component:PropagatePriority(root:Priority() + 1000)
    root:Adopt(self.component:Address())

    resizeComponent(self.component, self.componentWidth, self.componentHeight)
    local x = self.isTroy and 50 or 20
    local y = self.isTroy and 120 or 100
    positionComponentRelativeTo(self.component, root, x, y)

    -- create textbox
    self:addTextBox()

    -- creating up / down arrow
    self.upButton = self:createUpArrow()
    self.downButton = self:createDownArrow()

    -- create enter button
    self.enterButton = self:createEnterButton()

    -- create execute button
    self.executeButton = self:createExecuteButton()
    
    -- create clear code button
    self.clearCodeButton = self:createClearCodeButton()
    
    -- add the close button
    self.closeButton = self:createCloseButton()

    -- add the mini switch button
    self.miniUIButton = self:addMiniUIButton()

    -- create line numerical display
    self:createLineNumberDisplay()

    -- update up / down arrows state
    self:updateUpDownArrowState()
end

function MiniDevToolFrame:addTextBox()
    local name = self.frameName .. "_TextBox"
    -- local filepath = "script/ui/devtool/templates/file_requester"
    local filepath = "script/ui/devtool/common ui/file_requester"
    local content = self.component

    self.component:CreateComponent(name .. "_UITEMP", filepath)

    local tempUI = UIComponent(self.component:Find(name .. "_UITEMP"))

    local textbox = find_uicomponent(tempUI, "input_name")
    self.textbox = textbox
    
    textbox:PropagatePriority(self.component:Priority())

    self.component:Adopt(textbox:Address())

    removeComponent(find_uicomponent(textbox, "input_name_label"))
    removeComponent(tempUI)

    -- resize
    local contentWidth, contentHeight = self.component:Bounds()
    resizeComponent(textbox, contentWidth - 50)
    positionComponentRelativeTo(textbox, self.component, 0, 0)
end

function MiniDevToolFrame:createUpArrow()
    local name = self.frameName .. "_TextBox_UpButton"
    local content = self.component
    local textbox = self.textbox

    -- creating button
    content:CreateComponent(name, "script/ui/devtool/templates/round_medium_button")
    local upButton = UIComponent(content:Find(name))

    content:Adopt(upButton:Address())
    upButton:PropagatePriority(content:Priority())
    upButton:SetImagePath("ui/skins/default/parchment_sort_arrow_up.png")
    resizeComponent(upButton, 17, 17)
    self:positionComponentRelativeToWithOffset(upButton, textbox, 5, -30)

    local listenerName = self.frameName .. "_TextBox_UpButtonListener"
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context)
            return upButton == UIComponent(context.component)
        end,

        function(context)
            self.devtool:decrementLines()
            self.devtool:updateUpDownArrowState()
            self:updateTextBox()
        end,
        true
    )
    return upButton
end

function MiniDevToolFrame:createDownArrow()
    local name = self.frameName .. "_TextBox_DownButton"
    local content = self.component
    local textbox = self.textbox

    -- creating button
    content:CreateComponent(name, "script/ui/devtool/templates/round_medium_button")
    local downButton = UIComponent(content:Find(name))

    content:Adopt(downButton:Address())
    downButton:PropagatePriority(content:Priority())
    downButton:SetImagePath("ui/skins/default/parchment_sort_arrow_down.png")
    resizeComponent(downButton, 17, 17)
    self:positionComponentRelativeToWithOffset(downButton, textbox, 5, -15)

    local listenerName = "DevToolFrame_TextBox_DownButtonListener"
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context)
            return downButton == UIComponent(context.component)
        end,

        function(context)
            self.devtool:incrementLines()
            self.devtool:updateUpDownArrowState()
            self:updateTextBox()
        end,
        true
    )
    return downButton
end

function MiniDevToolFrame:createEnterButton()
    local textbox = self.textbox

    local id = self.frameName .. "_enter_btn"
    local button = createButton(id, self.component, "Enter", "Save current line and go into next", 120, function(context)
        self.devtool:incrementLines()
        self.devtool:updateUpDownArrowState()
        self.enterButton:SetState("down_off")

        self:updateTextBox()
    end)

    positionComponentRelativeTo(button, textbox, 0, textbox:Height() + 2)
    return button
end

function MiniDevToolFrame:createExecuteButton()
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

function MiniDevToolFrame:createClearCodeButton()
    local executeButton = self.executeButton

    local width = self.isTroy and 120 or 150
    local id = self.frameName .. "_clear_code_btn"
    local button = createButton(id, self.component, "Clear Code", "Clear all previously entered code in the textbox", width, function(context)
        self.devtool:clearCodeLines()
        self.clearCodeButton:SetState("down_off")

        self:updateTextBox()
    end)

    local offset = self.isTroy and 10 or 0
    self:positionComponentRelativeToWithOffset(button, executeButton, offset, -executeButton:Height())

    return button
end

function MiniDevToolFrame:createCloseButton()
    local buttonName = self.frameName .. "_CloseMiniUIButton"
    self.component:CreateComponent(buttonName, "ui/templates/round_small_button")

    local button = find_uicomponent(self.component, buttonName)
    local img = self.isTroy and "ui/skins/default/icon_cross_square.png" or "ui/skins/default/icon_cross_small.png"
    button:SetImagePath(img)
    button:SetTooltipText("Close", true)

    button:PropagatePriority(self.component:Priority())
    self.component:Adopt(button:Address())
    self:positionComponentRelativeToWithOffset(button, self.clearCodeButton, 0, -self.clearCodeButton:Height())

    local listenerName = buttonName .. "_Listener"
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context) return button == UIComponent(context.component) end,    
        function(context)
            self:hideFrame()
        end,
        true
    )
    return button
end

function MiniDevToolFrame:addMiniUIButton()
    local buttonName = self.frameName .. "_MiniUIButton"
    self.component:CreateComponent(buttonName, "ui/templates/round_small_button")

    local button = find_uicomponent(self.component, buttonName)
    button:SetImagePath("script/campaign/resize_icon.png")
    button:SetTooltipText("Switch to maximized UI", true)

    button:PropagatePriority(self.component:Priority())
    self.component:Adopt(button:Address())
    self:positionComponentRelativeToWithOffset(button, self.closeButton, 0, -self.closeButton:Height())

    local listenerName = buttonName .. "_Listener"
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context) return button == UIComponent(context.component) end,    
        function(context)
            self:hideFrame()
            self.devtool:showFrame()
        end,
        true
    )
    return button
end

function MiniDevToolFrame:createLineNumberDisplay()
    local componentName = self.frameName .. "_LineNumberComponent"
    local content = self.component
    
    -- content:CreateComponent(componentName .. "_UITEMP", "script/ui/devtool/templates/mission_details")
    content:CreateComponent(componentName .. "_UITEMP", "script/ui/devtool/campaign ui/mission_details")
    local tempUI = UIComponent(content:Find(componentName .. "_UITEMP"))

    local component = find_uicomponent(tempUI, "mission_details_child", "description_background", "description_view", "dy_description")
    content:Adopt(component:Address())
    component:PropagatePriority(content:Priority())
    removeComponent(tempUI)

    local textDimensionsWidth, textDimensionsHeight = component:TextDimensionsForText("Current Line: 000")
    resizeComponent(component, textDimensionsWidth, 30)
    self:positionComponentRelativeToWithOffset(component, self.textbox, -textDimensionsWidth, 10)

    self.currentLineNumberComponent = component
    self:updateLineNumberDisplay()
end

function MiniDevToolFrame:updateLineNumberDisplay()
    local component = self.currentLineNumberComponent
    if self.isTroy then
        component:SetStateText("[[col:white]]Current Line: " .. self.devtool.currentLineNumber .. "[[/col]]")
    else
        component:SetStateText("Current Line: " .. self.devtool.currentLineNumber)
    end
end

function MiniDevToolFrame:updateTextBox()
    local text = self.devtool.lines[self.devtool.currentLineNumber] or ""

    removeComponent(find_uicomponent(self.component, "input_name"))
    self:addTextBox()

    self.textbox:SimulateLClick()
    for i in string.gmatch(text, ".") do
        self.textbox:SimulateKey(i)
    end
end

function MiniDevToolFrame:updateUpDownArrowState()
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

function MiniDevToolFrame:hideFrame()
    self.component:SetVisible(false)
end

function MiniDevToolFrame:showFrame()
    self.component:SetVisible(true)
    self:updateTextBox()
    self:updateUpDownArrowState()
end

includeMixins(MiniDevToolFrame, ComponentMixin)

return MiniDevToolFrame