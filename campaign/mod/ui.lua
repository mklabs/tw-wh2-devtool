require("DevToolFrame");
require("MiniDevToolFrame");

local devFrame = nil;
local miniDevFrame = nil;

function devtool_createOrOpenFrame()
    if not devFrame then
        devFrame = DevToolFrame:new();
    else
        if devFrame.component:Visible() then
            devFrame:hideFrame();
        else
            devFrame:showFrame();
        end
    end
end;

function devtool_createMenuBarButton()
    local buttonGroup = find_uicomponent(core:get_ui_root(), "menu_bar", "buttongroup");
    buttonGroup:CreateComponent("devtool_button", "ui/templates/round_small_button");

    local button = find_uicomponent(buttonGroup, "devtool_button");
    button:SetImage("ui/skins/default/icon_toggle_unit_details.png");
    button:SetTooltipText("Devtool Console", true);

    button:PropagatePriority(buttonGroup:Priority());
    buttonGroup:Adopt(button:Address());

    local listenerName = "devtool_button_Listener";
    core:add_listener(
        listenerName,
        "ComponentLClickUp",
        function(context) return button == UIComponent(context.component); end,    
        function(context)
            devtool_createOrOpenFrame();
        end,
        true
    );
end;

--[[
core:add_listener(
    "test_ui_createFrame_F12",
    "ShortcutTriggered",
    function(context)
        --default F12
        return context.string == "camera_bookmark_view3"; 
    end, 
    function(context)
        console.log("Triggered F12");

        if not miniDevFrame then
            miniDevFrame = MiniDevToolFrame:new();
        else
            if miniDevFrame.component:Visible() then
                miniDevFrame:hideFrame();
            else
                miniDevFrame:showFrame();
            end
        end
    end,
    true
);
]]--

core:add_ui_created_callback(
    function()
        devtool_createMenuBarButton();
    end
);

_G.UIComponent = UIComponent;
_G.find_uicomponent = find_uicomponent;
_G.print_all_uicomponent_children = print_all_uicomponent_children;
_G.is_uicomponent = is_uicomponent;
_G.out = out;
_G.core = core;
_G.output_uicomponent = output_uicomponent;