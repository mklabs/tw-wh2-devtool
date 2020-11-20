local debug = require("tw-debug")("devtool:mod")

local devtool = require("devtool/devtool")
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

local function createMenuBarButton()
    local name = "devtool_wh2_button"
    debug("Create menu bar button")
    local buttonGroup = find_uicomponent(core:get_ui_root(), "menu_bar", "buttongroup")
    buttonGroup:CreateComponent(name, "script/ui/devtool/templates/round_small_button")

    local button = find_uicomponent(buttonGroup, name)
    button:SetImagePath("ui/skins/default/icon_toggle_unit_details.png")
    button:SetTooltipText("Devtool wh2 Console", true)

    button:PropagatePriority(200)
    buttonGroup:Adopt(button:Address())

    local listenerName = "devtool_button_Listener"
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context) return button == UIComponent(context.component) end,    
        createOrOpenFrame,
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