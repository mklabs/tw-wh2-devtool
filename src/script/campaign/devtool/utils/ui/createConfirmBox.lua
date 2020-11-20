local debug = require("tw-debug")("devtool:utils:createConfirmBox")
local removeComponent = require("devtool/utils/ui/removeComponent")

local function createConfirmBox(id, on_accept_callback, on_cancel_callback)
	local confirmation_box = core:get_or_create_component(id, "ui/common ui/dialogue_box")
	confirmation_box:SetVisible(true)
	confirmation_box:LockPriority()
	confirmation_box:RegisterTopMost()
	confirmation_box:SequentialFind("ok_group"):SetVisible(false)

    -- local text = "foo"
    -- local dy_text = find_uicomponent(confirmation_box, "DY_text")
    -- dy_text:SetStateText(text, text)
    removeComponent(find_uicomponent(confirmation_box, "DY_text"))
    
    local accept_fn = function()
        confirmation_box:UnLockPriority()
        core:remove_listener(id .. "_confirmation_box_reject")

        if core:is_campaign() then
            cm:release_escape_key_with_callback(id .. "_confirmation_box_esc")
        elseif core:is_battle() then
            bm:release_escape_key_with_callback(id .. "_confirmation_box_esc")
        else
            effect.disable_all_shortcuts(false)
        end

        if on_accept_callback then
            on_accept_callback()
        end

        removeComponent(confirmation_box)
    end

    local cancel_fn = function()
        confirmation_box:UnLockPriority()
        core:remove_listener(id .. "_confirmation_box_accept")

        if core:is_campaign() then
            cm:release_escape_key_with_callback(id .. "_confirmation_box_esc")
        elseif core:is_battle() then
            bm:release_escape_key_with_callback(id .. "_confirmation_box_esc")
        else
            effect.disable_all_shortcuts(false)
        end

        if on_cancel_callback then
            on_cancel_callback()
        end

        removeComponent(confirmation_box)
    end

    core:remove_listener(id .. "_confirmation_box_accept")
	core:add_listener(
		id .. "_confirmation_box_accept",
		"ComponentLClickUp",
        function(context)
			return context.string == "button_tick"
		end,
		accept_fn,
		false
    )
    
    core:remove_listener(id .. "_confirmation_box_reject")
	core:add_listener(
		id .. "_confirmation_box_reject",
		"ComponentLClickUp",
        function(context)
			return context.string == "button_cancel"
		end,
		cancel_fn,
		false
	)

	if core:is_campaign() then
		cm:steal_escape_key_with_callback(id .. "_confirmation_box_esc", cancel_fn)
	elseif core:is_battle() then
		bm:steal_escape_key_with_callback(id .. "_confirmation_box_esc", cancel_fn)
	else
		effect.disable_all_shortcuts(true)
    end
    
    return confirmation_box
end

return createConfirmBox