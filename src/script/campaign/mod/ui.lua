require("ui/DevToolFrame");

local devtool = nil;
function devtool_createOrOpenFrame()
    if not devtool then
        devtool = DevToolFrame:new();
    else
        if devtool.component:Visible() then
            devtool:hideFrame();
        else
            devtool:showFrame();
        end
    end
end;

function devtool_createMenuBarButton()
    local buttonGroup = find_uicomponent(core:get_ui_root(), "menu_bar", "buttongroup");
    buttonGroup:CreateComponent("devtool_button", "ui/templates/round_small_button");

    local button = find_uicomponent(buttonGroup, "devtool_button");
    button:SetImagePath("ui/skins/default/icon_toggle_unit_details.png");
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