local debug = require("tw-debug")("devtool:utils:insertComponentAt")

local function insertComponentAt(component, parent, index)
    index = index or 0
    if index > parent:ChildCount() - 1 then
        index = parent:ChildCount() - 1
    elseif index < 0 then
        index = 0
    end

    debug("Insert component (%s) at %d position in %s (child count: %d)", component:Id(), index, parent:Id(), parent:ChildCount() - 1)
    local childs = {}
    for i = 0, parent:ChildCount() - 1 do
        local child = UIComponent(parent:Find(i))
        table.insert(childs, child)
    end

    for k, child in pairs(childs) do
        debug("Divorce", child:Id())
        parent:Divorce(child:Address())
    end

    table.insert(childs, index + 1, component)
    for k, child in pairs(childs) do
        debug("Adopt", child:Id())
        parent:Adopt(child:Address())
    end
end

return insertComponentAt