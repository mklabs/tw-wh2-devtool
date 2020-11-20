local function welcomeMessage()
    local text = [[

        <<col:help_page_link>>Environment<</col>>

        Here are the special variables and functions available to you while executing commands and scripts

        <<col:dark_g>>print()<</col>> / <<col:dark_g>>log()<</col>>   Use this with any number of variables to inspect them in the console

        <<col:dark_g>>_(path)<</col>>             Function helper to get an UI component by its path (eg. _("layout > child > child"))

        <<col:dark_g>>__(path)<</col>>           Function helper to get detailed information for an UI component (childs, path, position, states, ...)

        <<col:dark_g>>_0<</col>>                     Variable which returns the last UIComponent clicked within the game
        
        <<col:dark_g>>_1<</col>>                     Variable which returns detailed information about the last UIComponent clicked (childs, images, opacity, path, position, size, states, ...)

        <<col:help_page_link>>Files<</col>>

        You can now use the file <<col:dark_g>>console/input.lua<</col>> in the game's <<col:dark_g>>data/script<</col>> folder to automatically execute scripts
        when the file is saved as if you were using the command prompt.

        It is useful to workaround the limitation of the in-game UI textbox which has size limitation and issues with some special characters (like "[").

        Each command result is written to the <<col:dark_g>>console/output.txt<</col>> file, if you ever need to access it.

        Errors are written to the <<col:dark_g>>console/error.txt<</col>> file.
    ]]

    return text:gsub("<<", "[["):gsub(">>", "]]"):gsub("|t", "\t")
end

return welcomeMessage