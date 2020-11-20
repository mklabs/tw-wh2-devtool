local function trim(s)
    return s:match'^%s*(.*%S)' or ''
end

return trim