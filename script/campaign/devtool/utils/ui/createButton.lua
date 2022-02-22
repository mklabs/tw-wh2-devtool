local function createButton(id, parent, text, tooltipText, width, callback)
    width = width or 120
    tooltipText = tooltipText or ""

    parent:CreateComponent(id, "ui/templates/square_medium_text_button_toggle")

    local button = UIComponent(parent:Find(id))
    local buttonText = find_uicomponent(button, "dy_province")

    parent:Adopt(button:Address())
    button:PropagatePriority(parent:Priority())
    button:ResizeTextResizingComponentToInitialSize(width, button:Height())
    buttonText:SetStateText(text)
    buttonText:SetTooltipText(tooltipText, true)

    if type(callback) == "function" then   
        local listenerName = id .. "_Listener"
        core:add_listener(
            listenerName,
            "ComponentLClickUp",
            function(context) return button == UIComponent(context.component) end,    
            callback,
            true
        )
    end

    return button
end

return createButton