local function resizeComponent(component, width, height)
    local componentWidth, componentHeight = component:Bounds()
    width = width or componentWidth
    height = height or componentHeight
    
    component:SetCanResizeHeight(true)
    component:SetCanResizeWidth(true)
    component:Resize(width, height)
    component:SetCanResizeHeight(false)
    component:SetCanResizeWidth(false)
end

return resizeComponent