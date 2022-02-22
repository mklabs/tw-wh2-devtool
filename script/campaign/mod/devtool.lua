local debug = require("tw-debug")("devtool:mod")

local devtool = require("devtool/devtool")
local insertComponentAt = require("devtool/utils/ui/insertComponentAt")
local removeComponent = require("devtool/utils/ui/removeComponent")
local _ = require("devtool/utils/ui/_")

local DevToolFrame = require("devtool/ui/DevToolFrame")

local frame = nil
local function createOrOpenFrame()
    if not frame then
        frame = DevToolFrame:new()
    else
        if frame.component:Visible() then
            frame:hideFrame()
        else
            frame:showFrame()
        end
    end
end

local function createTroyMenuBarButton()
    debug("Create Troy menu button")

    local name = "devtool_button"
    local parent = find_uicomponent(core:get_ui_root(), "menu_bar", "buttongroup")
    local holder = UIComponent(_("menu_bar > buttongroup > holder_help_overlay"):CopyComponent(name .. "_holder"))
    local button = UIComponent(_(holder, "button_help_overlay"):CopyComponent(name))
    button:SetImagePath("ui/skins/default/icon_toggle_unit_details.png")
    button:SetTooltipText("Devtool Console", true)
    removeComponent(_(holder, "button_help_overlay"))

    parent:Divorce(holder:Address())
    insertComponentAt(holder, parent, 7)

    return button
end

local function createWarhammerMenuBarButton()
    debug("Create Warhammer menu button")

    local name = "devtool_button"
    local buttonGroup = find_uicomponent(core:get_ui_root(), "menu_bar", "buttongroup")
    buttonGroup:CreateComponent(name, "script/ui/devtool/templates/round_small_button")

    local button = find_uicomponent(buttonGroup, name)
    button:SetImagePath("ui/skins/default/icon_toggle_unit_details.png")
    button:SetTooltipText("Devtool Console", true)

    button:PropagatePriority(200)
    buttonGroup:Adopt(button:Address())

    return button
end

local function createMenuBarButton()
    local isTroy = cm:get_campaign_name() == "main_troy"

    local button = isTroy and createTroyMenuBarButton() or createWarhammerMenuBarButton()

    local listeners = {
        ComponentLClickUp = "devtool_button_click_listener",
        devtoolClose = "devtool_close_listener",
        devtoolOpen = "devtool_open_listener"
    }

    core:remove_listener(listeners.ComponentLClickUp)
    core:add_listener(
        listeners.ComponentLClickUp,
        "ComponentLClickUp",
        function(context) return button == UIComponent(context.component) end,    
        createOrOpenFrame,
        true
    )

    local listenerName = "devtool_button_close_listener"
    core:add_listener(
        listeners.devtoolClose,
        "devtool_close",
        true,    
        function()
            debug("devtool close")
            button:SetState("active")
        end,
        true
    )

    local listenerName = "devtool_button_open_listener"
    core:add_listener(
        listeners.devtoolOpen,
        "devtool_open",
        true,    
        function()
            debug("devtool open")
            button:SetState("selected")
        end,
        true
    )

    debug("Created devtool menu button")
end

core:add_ui_created_callback(createMenuBarButton)
cm:add_first_tick_callback(devtool.init)


_G.UIComponent = UIComponent
_G.find_uicomponent = find_uicomponent
_G.print_all_uicomponent_children = print_all_uicomponent_children
_G.is_uicomponent = is_uicomponent
_G.out = out
_G.core = core
_G.output_uicomponent = output_uicomponent
_G.uicomponent_to_str = uicomponent_to_str