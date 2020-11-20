-- version 1.1.1
local debug = require("tw-debug")("devtool")
local inspect = require("devtool/vendors/inspect")

local getLength = require("devtool/utils/getLength")
local split = require("devtool/utils/split")
local slice = require("devtool/utils/slice")

local inspectOptions = { depth = 2, indent = "\t", newline = "\n-" }

local INPUT_FILEPATH = "data/script/console/input.lua"
local ERROR_FILEPATH = "data/script/console/error.txt"
local OUTPUT_FILEPATH = "data/script/console/output.txt"
local CALLBACK_TIMER = 0.5
local EXEC_COMPILE_ERROR = "EXEC_COMPILE_ERROR"
local EXEC_RUNTIME_ERROR = "EXEC_RUNTIME_ERROR"
local EXEC_SUCCESS = "EXEC_SUCCESS"

local shouldWatchFile = true
local files = {}
local prints = {}
local _0 = nil
local _1 = nil

local function log(...)
    local str = ""
    local args = {...}
    for i=1, #args do
        local value = args[i]
        local separator = ""
        if i ~= 1 then
            separator = "\t"
        end

        str = str .. separator .. inspect(value, { depth = 4, indent = "\t", newline = "\n-" })
    end

    table.insert(prints, str)
    core:trigger_event("devtoolLogline", str)
end

--- @function output_uicomponent
--- @desc Returns extensive debug information about a supplied uicomponent to the console as a table
--- @p uicomponent subject uic, Subject uicomponent.
--- @p [opt=false] boolean omit children, Do not show information about the uicomponent's children.
local function info_uicomponent(uic)
	if not is_uicomponent(uic) then
		debug("ERROR: output_uicomponent() called but supplied object [" .. tostring(uic) .. "] is not a ui component")
		return
	end
	
	-- not sure how this can happen, but it does ...
	if not pcall(function() out.ui("uicomponent " .. tostring(uic:Id()) .. ":") end) then
		debug("output_uicomponent() called but supplied component seems to not be valid, so aborting")
		return
	end
	
    local pathFromRoot = uicomponent_to_str(uic)
	
	local pos_x, pos_y = uic:Position()
    local size_x, size_y = uic:Bounds()
    local position = { tostring(pos_x), tostring(pos_y) }
    local size = { tostring(size_x), tostring(size_y) }
    local state = tostring(uic:CurrentState())
    local priority = tostring(uic:Priority())
    local opacity = tostring(uic:Opacity())
	
	local childs = {}
    for i = 0, uic:ChildCount() - 1 do
        local child = UIComponent(uic:Find(i))
        table.insert(childs, child:Id())
    end

    local states = {}
    for i = 0, uic:NumStates() - 1 do
        table.insert(states, uic:GetStateByIndex(i))
    end

    local imgs = {}
    for i = 0, uic:NumImages() - 1 do
        table.insert(imgs, uic:GetImagePath(i))
    end

    return {
        path = pathFromRoot,
        position = position,
        size = size,
        state = state,
        priority = priority,
        opacity = opacity,
        childs = childs,
        states = states,
        images = imgs
    }
end

local function _(path)
    local str = string.gsub(path, "%s*root%s*>%s+", "")
    local args = split(str, " > ")
    return find_uicomponent(core:get_ui_root(), unpack(args))
end

local function __(path)
    local uic = _(path)
    return info_uicomponent(uic)
end

local function write(filename, text)
    local file, err_str = io.open(filename, "w")
	
	if not file then
		debug("ERROR: tried to create file with filename", filename, "but operation failed with error: ", tostring(err_str))
	else
		file:write(text)
		file:close()
	end
end

local function getContent(filename)
    local file = io.open(filename, 'r')
    if not file then return nil end

    local result = file:read("*all")
    file:close()

    return result
end

local function writeError(text, status)
    write(ERROR_FILEPATH, text)

    if status == EXEC_COMPILE_ERROR then
        core:trigger_event("devtoolErrorFileChanged_compile", text)
    elseif status == EXEC_RUNTIME_ERROR then
        core:trigger_event("devtoolErrorFileChanged_runtime", text)
    end
end

local function writeOutput(text)
    write(OUTPUT_FILEPATH, text)
    core:trigger_event("devtoolOutputFileChanged")
end

local function readOutput()
    return getContent(OUTPUT_FILEPATH)
end

local function shouldPrependWithReturn(text)
    -- checks begining with return
    if string.match(text, '^%s*return') then
        return false
    end

    -- checks has assignment
    if string.match(text, '^%s*=%s*') then
        return false
    end

    -- checks if has any keyword
    local keywords = { "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"}

    local hasKeyword = false
    local count = getLength(keywords)
    for i = 1, count do
        if string.match(text, '%s+' .. keywords[i] .. '%s+') then
            hasKeyword = true
            break
        end
    end

    if hasKeyword then
        return false
    end

    return true
end

local function buildCodeFromText(text)
    local sep = "\n"
    local lines = split(text, sep)
    local length = getLength(lines)

    local firsts = slice(lines, 0, length - 1)
    local lasts = slice(lines, length)
    local last = lasts[1]

    local str = ""
    str = str .. table.concat(firsts, "\n")

    if getLength(firsts) ~= 0 then
        str = str .. "\n"
    end

    if shouldPrependWithReturn(last) then
        str = str .. "\nreturn " .. last
    else
        str = str .. "\n" .. last        
    end

    return str
end

local function getEnv()
    local _env = getfenv(1)

    local env = { print = log, log = log, _ = _, __ = __, _0 = _0, _1 = _1 }
    setmetatable(env, {__index = _env})
    return env
end

local function exec(text)
    prints = {}

    local str = buildCodeFromText(text)
    debug("Trying to exec\n", str)

    local func, err = loadstring(str)

    if not func then
        debug("Something went wrong. Error is:", err)
        writeError(err, EXEC_COMPILE_ERROR)
        return EXEC_COMPILE_ERROR, err
    end

    setfenv(func, getEnv())

    local ok, result = pcall(func)

    if not ok then 
        debug("Something went wrong. Result is:", result)
        writeError(result, EXEC_RUNTIME_ERROR)
        return EXEC_RUNTIME_ERROR, result
    end

    debug("Exec inspect result is:", result)
    debug("Prints status:", prints)

    local output = ""
    for i = 1, getLength(prints) do
        output = output .. prints[i] .. '\n'
    end

    writeOutput(output .. inspect(result, inspectOptions))

    return EXEC_SUCCESS, result
end

local function watchFile(filename)
    if not shouldWatchFile then
        return
    end

    cm:callback(function()
        local previous = files[filename] or ''

        local content = getContent(filename)
        files[filename] = content
        
        if content ~= previous then
            debug("%s changed.", filename)

            core:trigger_event("devtoolInputFileChanged", content)
            exec(content)
        end

        watchFile(filename)
    end, CALLBACK_TIMER, 'watch.timer.' .. filename)
end

local function initWatchFile()
    debug("Init watchFile")
    local content = getContent(INPUT_FILEPATH)
    files[INPUT_FILEPATH] = content

    shouldWatchFile = cm:get_saved_value("devtool_options_fileWatch")
    if shouldWatchFile == nil then
        shouldWatchFile = true
    end
    watchFile(INPUT_FILEPATH)
end

local function init()
    debug("Init devtool")
    initWatchFile()

    core:remove_listener("console_store_uicomponent_on_click")
    core:add_listener(
		"console_store_uicomponent_on_click",
		"ComponentLClickUp",
		true,
        function(context) 
            _0 = UIComponent(context.component)
            _1 = info_uicomponent(_0)
        end,
		true
    )
    
    core:remove_listener("devtool_options_fileWatch_changed_listener")
    core:add_listener(
		"devtool_options_fileWatch_changed_listener",
		"devtool_options_fileWatch_changed",
		true,
        function(context)
            debug("devtool_options_fileWatch_changed", context, context.bool)
            shouldWatchFile = context.bool

            if shouldWatchFile then
                initWatchFile()
            end
        end,
		true
	)
end

return {
    init = init,
    getEnv = getEnv,
    exec = exec,
    readOutput = readOutput,
    EXEC_COMPILE_ERROR = EXEC_COMPILE_ERROR,
    EXEC_RUNTIME_ERROR = EXEC_RUNTIME_ERROR,
    EXEC_SUCCESS = EXEC_SUCCESS,
    INPUT_FILEPATH = INPUT_FILEPATH
}