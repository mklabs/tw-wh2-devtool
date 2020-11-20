local debug = require("tw-debug")("devtool:utils:troy:setupTroyPanels")
local removeComponent = require("devtool/utils/ui/removeComponent")
local _ = require("devtool/utils/ui/_")

local function setupTroyPanels(component)
    debug("setupTroyPanels", _)
    local tabChild = _(component, "panel > TabGroup > tab_victory_conditions > tab_child")
    local tabChildW, tabChildH = tabChild:Bounds()
    tabChild:SetCanResizeWidth(true)
    tabChild:SetCanResizeHeight(true)

    local parentWidth, parentHeight = _(component, "panel > TabGroup"):Bounds()

    local leftPanel = _(component, "panel > TabGroup > tab_victory_conditions")
    leftPanel:SetCanResizeWidth(true)
    leftPanel:SetCanResizeHeight(true)
    leftPanel:Resize(parentWidth, parentHeight)

    _(component, "panel > TabGroup > tab_victory_conditions > inner_frame_old"):Resize(tabChildW - 20, tabChildH)

    local w, h = _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame"):Bounds()
    local x, y = _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame"):Position()
    _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame"):SetCanResizeWidth(true)
    _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame"):SetCanResizeHeight(true)
    _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame"):Resize(tabChildW * 0.7, h)
    _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame"):MoveTo(x - 50, y)
    
    local listviewW, listviewH = _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame > listview"):Bounds()
    w, h = _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame > listview > list_clip"):Bounds()
    _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame > listview > list_clip"):SetCanResizeWidth(true)
    _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame > listview > list_clip"):SetCanResizeHeight(true)
    _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame > listview > list_clip"):Resize(listviewW - 18, h)

    w, h = _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame > listview > list_clip > list_box"):Bounds()
    _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame > listview > list_clip > list_box"):SetCanResizeWidth(true)
    _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame > listview > list_clip > list_box"):SetCanResizeHeight(true)
    _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame > listview > list_clip > list_box"):Resize(listviewW - 28, h)

    _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame > listview"):Resize(listviewW, listviewH - 60)

    -- remove panel children
    removeComponent(_(component, "panel > TabGroup > tab_victory_conditions > tab_child > objective_header"))
    local listbox = _(component, "panel > TabGroup > tab_victory_conditions > tab_child > chapter_frame > listview > list_clip > list_box")
    debug("Remove child in", listbox, listbox:ChildCount())
    removeComponent(_(listbox, "condition"))
    removeComponent(_(listbox, "objective"))
    removeComponent(_(listbox, "condition")) 
end

return setupTroyPanels