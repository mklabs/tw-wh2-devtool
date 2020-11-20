local debug = require("tw-debug")("devtool:utils:createConfirmBox")

local function positionComponentRelativeTo(component, relativeComponent, xDiff, yDiff)
    xDiff = xDiff or 0
    yDiff = yDiff or 0

    local xPosition, yPosition = relativeComponent:Position()
    component:MoveTo(xPosition + xDiff, yPosition + yDiff)
end

return positionComponentRelativeTo