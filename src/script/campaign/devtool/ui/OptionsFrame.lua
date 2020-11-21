local debug = require("tw-debug")("devtool:ui:OptionsFrame")

local createConfirmBox = require("devtool/utils/ui/createConfirmBox")
local removeComponent = require("devtool/utils/ui/removeComponent")
local resizeComponent = require("devtool/utils/ui/resizeComponent")
local positionComponentRelativeTo = require("devtool/utils/ui/positionComponentRelativeTo")

local OptionsFrame = {
    frameName = "devtool_options_window"
}

function OptionsFrame:new()
    self.isTroy = cm:get_campaign_name() == "main_troy"

    self.formFields = {}

    local noop = function() end
    self.acceptCallback = noop
    self.cancelCallback = noop

    self:createFrame()
    self:createForm()
    return self
end

function OptionsFrame:createFrame()
    debug("OptionsFrame:createFrame")

    self.component = createConfirmBox(self.frameName, function()
        local data = self:data()
        self.acceptCallback(data)
    end, function()
        local data = self:data()
        self.cancelCallback(data)
    end)

    if self.isTroy then
        local title = self:createLabel(self.frameName .. "_title", "[[col:white]]Options[[/col]]")
        -- center
        local x, y = self.component:Position()
        local w, h = self.component:Bounds()
        local titleW, titleH = title:Bounds() 
        title:MoveTo(x + (w / 2 - (titleW / 2)) - 5, y + 20)
    else
        local title = self:createLabel(self.frameName .. "_title", "Options")
        -- center
        local x, y = self.component:Position()
        local w, h = self.component:Bounds()
        local titleW, titleH = title:Bounds() 
        title:MoveTo(x + (w / 2 - (titleW / 2)), y + 30)
    end
end

function OptionsFrame:accept(callback)
    self.acceptCallback = callback
end

function OptionsFrame:cancel(callback)
    self.cancelCallback = callback
end

function OptionsFrame:createForm()
    -- self:createFormRow(
    --     "codeOutput",
    --     "Path to code output: ",
    --     "Path to the code output to which a file will be created relative to Total War WARHAMMER II folder. It will contain the code you input and execute in the devtool.\n\nLeave it blank to disable the option."
    -- )

    -- self:createFormRow(
    --     "logsOutput",
    --     "Path to logs output: ",
    --     "Path to the logs output to which a file will be created relative to Total War WARHAMMER II folder. It will contain the text content you see below the console textbox, with executed code, print outputs and return result.\n\nLeave it blank to disable the option."
    -- )
    local label
    if self.isTroy then
        label = self:createLabel(self.frameName .. "_file_watching_checkbox_label", "[[col:white]]Enable file watch:[[/col]] ")
        positionComponentRelativeTo(label, self.component, 16, 160)
    else
        label = self:createLabel(self.frameName .. "_file_watching_checkbox_label", "Enable file watch: ")
        positionComponentRelativeTo(label, self.component, 16, 80)
    end

    label:SetTooltipText("Enable or disable data/text/console_input.lua file watching.\n\nThis file is used to input LUA script in the console that gets executed when the file is saved.\n\nYou can disable it if you don't use this feature to gain some performance.", true)

    local checkbox = self:createCheckbox(self.frameName .. "_file_watching_checkbox", label)
    local savedValue = cm:get_saved_value("devtool_options_fileWatch")
    debug("OptionsFrame:createForm devtool_options_fileWatch saved value:", savedValue)
    if savedValue or savedValue == nil then
        checkbox:SetState("selected")
    else
        checkbox:SetState("active")
    end

    table.insert(self.formFields, {
        fieldName = "fileWatch",
        type = "checkbox",
        label = label,
        field = checkbox        
    })
end

function OptionsFrame:createFormRow(fieldName, labelText, tooltipText)
    local component = self.component
    local componentName = self.frameName .. "_" .. fieldName
    tooltipText = tooltipText or ""
    
    -- Label
    local label = self:createLabel(componentName, labelText, tooltipText)
    local lastField = self.formFields[#self.formFields]
    if lastField then
        positionComponentRelativeTo(label, lastField.field, -8, 40)
    else
        positionComponentRelativeTo(label, component, 16, 60)
    end

    -- Field
    local textbox = self:createTextbox(componentName .. "_TextBox", label, tooltipText)

    table.insert(self.formFields, {
        fieldName = fieldName,
        type = "text",
        label = label,
        field = textbox        
    })
end

function OptionsFrame:createLabel(id, labelText, tooltipText)
    local component = self.component

    component:CreateComponent(id .. "_UITEMP", "script/ui/devtool/campaign ui/mission_details")
    local tempUI = UIComponent(component:Find(id .. "_UITEMP"))
    local label = find_uicomponent(tempUI, "mission_details_child", "description_background", "description_view", "dy_description")

    component:Adopt(label:Address())
    label:PropagatePriority(component:Priority())
    removeComponent(tempUI)
    
    label:SetStateText(labelText)

    if tooltipText then
        label:SetTooltipText(tooltipText, true)
    end

    local textWidth, textHeight = label:TextDimensionsForText(labelText)
    resizeComponent(label, textWidth, textHeight)

    return label
end

function OptionsFrame:createTextbox(id, label, tooltipText)
    local component = self.component

    local fieldComponentName = id .. "_TextBox"
    component:CreateComponent(fieldComponentName .. "_UITEMP", "script/ui/devtool/common ui/file_requester")
    local tempFieldUI = UIComponent(component:Find(fieldComponentName .. "_UITEMP"))
    local textbox = find_uicomponent(tempFieldUI, "input_name")
    
    textbox:PropagatePriority(component:Priority())
    component:Adopt(textbox:Address())
    removeComponent(find_uicomponent(textbox, "input_name_label"))
    removeComponent(tempFieldUI)

    -- set value from saved value
    -- local savedValue = self.optionsData[fieldName] or ""
    -- textbox:SimulateLClick()
    -- for i in string.gmatch(savedValue, ".") do
    --     textbox:SimulateKey(i)
    -- end
    if tooltipText then
        textbox:SetTooltipText(tooltipText, true)
    end

    local textboxWidth, textboxHeight = textbox:Bounds()
    local labelWidth, labelHeight = label:Bounds()

    resizeComponent(textbox, 370, textboxHeight)
    positionComponentRelativeTo(textbox, label, 10, labelHeight)

    return textbox
end

function OptionsFrame:createCheckbox(id, label, tooltipText)
    local component = self.component

	local checkbox = core:get_or_create_component(id, "ui/templates/checkbox_toggle")
    checkbox:PropagatePriority(component:Priority())
    component:Adopt(checkbox:Address())

    local labelWidth, labelHeight = label:Bounds()
    if self.isTroy then
        positionComponentRelativeTo(checkbox, label, labelWidth, -(labelHeight / 2) + 3)
    else
        positionComponentRelativeTo(checkbox, label, labelWidth, -(labelHeight / 2))
    end

    return checkbox
end

function OptionsFrame:data()
    local data = {}

    for i=1, #self.formFields do
        local formField = self.formFields[i]
        if formField.type == "text" then
            data[formField.fieldName] = formField.field:GetStateText()
        elseif formField.type == "checkbox" then
            data[formField.fieldName] = formField.field:CurrentState() == "selected"
        end
    end

    return data
end

return OptionsFrame