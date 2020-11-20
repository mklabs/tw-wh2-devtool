local function removeComponent(component)
    local root = core:get_ui_root()

    if not component then
        return
    end

    local dummy = find_uicomponent(root, 'DummyComponent')
    if dummy == false then
        root:CreateComponent("DummyComponent", "script/ui/devtool/campaign ui/script_dummy")        
        removeComponent(component)
    else 
        dummy:Adopt(component:Address())
        dummy:DestroyChildren()
        component = nil
    end
end

return removeComponent