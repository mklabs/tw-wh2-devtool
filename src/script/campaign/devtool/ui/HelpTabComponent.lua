local debug = require("tw-debug")("devtool:ui:HelpTabComponent")

local removeComponent = require("devtool/utils/ui/removeComponent")
local resizeComponent = require("devtool/utils/ui/resizeComponent")
local positionComponentRelativeTo = require("devtool/utils/ui/positionComponentRelativeTo")
local helpMessage = require("devtool/utils/messages/help")
local _ = require("devtool/utils/ui/_")

local HelpTabComponent = {
    frameName = "devtool_help_tab_component",
    devtool = nil,
    component = nil,
    content = nil
}

function HelpTabComponent:new(devtool)
    self.devtool = devtool
    self.isTroy = cm:get_campaign_name() == "main_troy"

    self:createFrame()
    self:addTextOutput(helpMessage())
    return self
end

function HelpTabComponent:createFrame()
    debug("HelpTabComponent:createFrame")
    local component = self.devtool.component
    local content = self.devtool.content

    component:CreateComponent(self.frameName, "script/ui/devtool/campaign ui/script_dummy")
    self.component = find_uicomponent(component, self.frameName)
    self.component:PropagatePriority(component:Priority())
    component:Adopt(self.component:Address())

    resizeComponent(self.component, content:Width(), content:Height())
    positionComponentRelativeTo(self.component, content, 0, 0)

    self.component:CreateComponent(self.frameName .. "_clanPanel_UITEMP", "script/ui/devtool/campaign ui/clan")
    local clan = find_uicomponent(self.component, self.frameName .. "_clanPanel_UITEMP")

    local traitPanel = find_uicomponent(clan, "main", "tab_children_parent", "Summary", "portrait_frame", "parchment_L", "trait_panel")
    traitPanel:PropagatePriority(self.component:Priority())
    self.component:Adopt(traitPanel:Address())
    removeComponent(clan)

    local heading = find_uicomponent(traitPanel, "parchment_divider_title", "heading_traits")
    heading:SetStateText("Help")

    local width = content:Width() - 50
    local height = content:Height() - 80

    resizeComponent(traitPanel, width, height)
    positionComponentRelativeTo(traitPanel, content, 25, 50)

    local traitList = find_uicomponent(traitPanel, "trait_list")
    resizeComponent(traitList, width - 70, height - 100)

    removeComponent(find_uicomponent(traitList, "list_clip"))
    removeComponent(find_uicomponent(traitList, "vslider"))

    if self.isTroy then
        local title = UIComponent(_("devtool_help_tab_component > trait_panel > parchment_divider_title > heading_traits"):CopyComponent("help_title"))
        local traitPanel = _("devtool_help_tab_component > trait_panel")
        traitPanel:Adopt(title:Address())
        removeComponent(_("devtool_help_tab_component > trait_panel > parchment_divider_title"))

        local x, y = title:Position()
        title:MoveTo(x, y - 35)
    end

    self.content = traitList
end

function HelpTabComponent:addTextOutput(text)
    local componentName = self.frameName .. "_Text"

    local content = self.content
    content:CreateComponent(componentName .. "_UITEMP", "script/ui/devtool/campaign ui/mission_details")
    local tempUI = UIComponent(content:Find(componentName .. "_UITEMP"))

    local component = find_uicomponent(tempUI, "mission_details_child", "description_background", "description_view", "dy_description")
    content:Adopt(component:Address())
    component:PropagatePriority(content:Priority())
    removeComponent(tempUI)

    local textWidth, textHeight = component:TextDimensionsForText(text)

    resizeComponent(component, self.component:Width(), self.component:Width())
    positionComponentRelativeTo(component, self.content, 0, 0)

    component:SetStateText(text)
    return component
end

function HelpTabComponent:hideFrame()
    self.component:SetVisible(false)
end

function HelpTabComponent:showFrame()
    self.component:SetVisible(true)
end

return HelpTabComponent