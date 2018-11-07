local console = {};
function console.log(msg)
    out("[test_ui] " .. msg);
end

function remove_component(component)
    local root = core:get_ui_root();

    local dummy = find_uicomponent(root, 'DummyComponent');
    if dummy == false then
        console.log("Unable to find ui component with name DummyComponent, creating it");
        root:CreateComponent("DummyComponent", "UI/campaign ui/script_dummy");        
        remove_component(component);
    else 
        console.log("Found ui component with name DummyComponent");
        console.log("Adopting address");
        dummy:Adopt(component:Address());
        console.log("Destroy children of dummy");
        dummy:DestroyChildren();
    end
end

core:add_listener(
    "test_ui_createFrame_F11",
    "ShortcutTriggered",
    function(context) return context.string == "camera_bookmark_view2"; end, --default F11
    function(context)
        console.log("F11 clicked");

        local root = core:get_ui_root();
        local frameName = "DevToolFrame";
        local componentFile = "ui/campaign ui/technology_panel";

        console.log("Attempting to create component: " .. componentFile);

        root:CreateComponent(frameName, componentFile);
        local component = UIComponent(root:Find(frameName));
        
        console.log("Created component with name " .. frameName);
        
        console.log("Trying to set up frame title");
        local title = find_uicomponent(component, "header_frame", "tx_technology");
        title:SetStateText(frameName);

        console.log("Trying to remove label_research_rate");
        local research_rate = find_uicomponent(component, "label_research_rate");
        remove_component(research_rate);
        console.log("Removed label_research_rate");


        local parchment = UIComponent(component:Find("parchment"));
        if not parchment then
            console.log("Unable to find parchment");
        end
        

        console.log("Setting up close button listener");
        core:add_listener(
            "DevToolFrame_CloseButtonListener",
            "ComponentLClickUp",
            function(context)
                console.log("ComponentLClickup");
                console.log("context.string: " .. context.string);
                return context.string == "button_ok";
            end,

            function(context)
                console.log("Button OK Clicked, removing component");
                remove_component(component);
                core:remove_listener("DevToolFrame_CloseButtonListener");
                console.log("Removed component and listener");
            end,
            true
        );

        console.log("End of component creation");
    end,
    true
);

core:add_listener(
    "test_ui_createFrame_F12",
    "ShortcutTriggered",
    function(context) return context.string == "camera_bookmark_view3"; end, --default F12
    function(context)
        console.log("F12 clicked!!");
        console.log("Attempting to delete the frame");

        local root = core:get_ui_root();
        local component = find_uicomponent(root, 'DevToolFrame');

        if component == false then
            console.log("Unable to find ui component with name DevToolFrame");
            return false;
        end
        console.log("Found ui component with name DevToolFrame");
        console.log("Calling remove_component");
        remove_component(component);
        console.log("End of component deletion");
    end,
    true
);

core:add_ui_created_callback(
    function()
        console.log("UI created callback");
    end
);