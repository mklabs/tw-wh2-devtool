require("DevToolFrame");

local frame = nil;

core:add_listener(
    "test_ui_createFrame_F11",
    "ShortcutTriggered",
    function(context)
        console.log("Shortcut triggered: " .. context.string); 
        --default F11
        -- return context.string == "camera_bookmark_view2"; 

        -- default F5
        return context.string == "standard_ping";
    end, 
    function(context)
        if not frame then
            frame = DevToolFrame:new();
        else
            frame:showFrame();
        end
    end,
    true
);

core:add_ui_created_callback(
    function()
        console.log("UI created callback");
    end
);

_G.UIComponent = UIComponent;
_G.find_uicomponent = find_uicomponent;
_G.print_all_uicomponent_children = print_all_uicomponent_children;
_G.is_uicomponent = is_uicomponent;
_G.out = out;
_G.core = core;
_G.output_uicomponent = output_uicomponent;