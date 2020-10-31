
local inspect = require("vendors/inspect");

local old_print = print;
function devtool_log(...)
    local str = "";
    local args = {...};
    for i=1, #args do
        local value = args[i];
        local separator = "";
        if i ~= 1 then
            separator = "\t";
        end

        str = str .. separator .. inspect(value, { depth = 4, indent = "\t", newline = "\n-" });
    end

    core:trigger_event("DevToolLogLine", str);
    return old_print(str);
end;