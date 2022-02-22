local function welcomeMessage()
    local text = [[
        
        <col:help_page_link>Welcome to the Modding Console Devtool</col>

        This welcome message will dismiss on first execute.

        <col:help_page_link>Description</col>

        The purpose of this tool is to provide you with an UI that lets you execute LUA code while the game is running.
        It is inspired by browser developer tools console and aims to provide a basic REPL (read eval print loop) within the game.

        It has two UI mode, a minimized and maximized one. Both lets you enter any number of lines (limited to 150 char per line)
        and hit the "Execute" button to loadstring (eval) the code within the game.

        The code you enter has access to the global scope, so any function definition or variables defined globally within the game
        are accessible (core, cm, etc.). You can also require files as usual.

        <col:help_page_link>Automatically execute console_input.lua file</col>
        
        You can now use the file <col:dark_g>console_input.lua</col> in the game's <col:dark_g>data/text</col> folder to automatically input commands into the console.
        This file is "watched" so that the content of the file is executed on each save as if you were using the console textbox.

        You can click the link below the command prompt to open the file in your text editor.

        <col:help_page_link>Printing</col>

        You can use "print()" with any number of variables to inspect them in the console.

        <col:help_page_link>Options</col>

        The Options button in the top right lets you enable / disable file watching for the <col:dark_g>data/text/console_input.lua</col> file.

        <col:help_page_link>Help</col>

        Be sure to check the help tab to get some description about the LUA environment and special variables / functions available to you.
    ]]

    return text:gsub("<", "[["):gsub(">", "]]")
end

return welcomeMessage