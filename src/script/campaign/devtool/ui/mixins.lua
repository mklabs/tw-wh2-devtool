local ComponentMixin = {
    positionComponentRelativeTo = function (self, component, relativeComponent, xDiff, yDiff)
        xDiff = xDiff or 0
        yDiff = yDiff or 0
    
        local xPosition, yPosition = relativeComponent:Position() 
        component:MoveTo(xPosition + xDiff, yPosition + yDiff)
    end,
    
    positionComponentRelativeToWithOffset = function (self, component, relativeComponent, xDiff, yDiff)
        local xPosition, yPosition = relativeComponent:Position()
        local width, height = relativeComponent:Bounds()
    
        xDiff = xDiff or 0
        yDiff = yDiff or 0
        
        component:MoveTo(xPosition + width + xDiff, yPosition + height + yDiff)
    end,
    
    resizeComponent = function (self, component, width, height)
        local componentWidth, componentHeight = component:Bounds()
        height = height or componentHeight
        width = width or componentWidth
    
        component:SetCanResizeHeight(true)
        component:SetCanResizeWidth(true)
        component:Resize(width, height)
        component:SetCanResizeHeight(false)
        component:SetCanResizeWidth(false)
    end,

    -- Button helper creation
    createButton = function (self, text, tooltipText, width, callback, content)
        width = width or 120
        tooltipText = tooltipText or ""
        content = content or self.component

        local name = self.frameName .. "_Button_" .. text

        content:CreateComponent(name, "script/ui/devtool/templates/square_medium_text_button_toggle")

        local button = UIComponent(content:Find(name))
        local buttonText = find_uicomponent(button, "dy_province")

        content:Adopt(button:Address())
        button:PropagatePriority(content:Priority())
        button:ResizeTextResizingComponentToInitialSize(width, button:Height())
        buttonText:SetStateText(text)
        buttonText:SetTooltipText(tooltipText, true)

        if type(callback) == "function" then   
            local listenerName = name .. "_Listener"
            core:add_listener(
                listenerName,
                "ComponentLClickUp",
                function(context) return button == UIComponent(context.component) end,    
                callback,
                true
            )
            table.insert(self.listeners, listenerName)
        end

        return button
    end
}

local function includeMixins(object, mixin)
    assert(type(mixin) == 'table', "mixin must be a table")

    for name, method in pairs(mixin) do
        object[name] = method
    end
end

return {
    includeMixins = includeMixins,
    ComponentMixin = ComponentMixin
}