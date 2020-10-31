require("console");

function remove_component(component)
    local root = core:get_ui_root();

    if not component then
        return;
    end

    local dummy = find_uicomponent(root, 'DummyComponent');
    if dummy == false then
        root:CreateComponent("DummyComponent", "UI/campaign ui/script_dummy");        
        remove_component(component);
    else 
        dummy:Adopt(component:Address());
        dummy:DestroyChildren();
        component = nil;
    end
end