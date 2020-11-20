local trim = require("devtool/utils/trim")
local split = require("devtool/utils/split")

-- little helper to query UIComponent a little bit easier
local function _(parent, path)
    if not is_uicomponent(parent) then
        path = parent
		parent = core:get_ui_root()
    end

    path = trim(path)
    local str = string.gsub(path, "%s*root%s*>%s+", "")
    local args = split(str, ">")
    for k, v in pairs(args) do
        args[k] = trim(v)
    end
    return find_uicomponent(parent, unpack(args))
end

return _