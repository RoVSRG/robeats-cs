local function TryRequire(module, on_fail)
    on_fail = on_fail or function() end
    local data
    local suc, err = pcall(function()
        data = require(module)
    end)

    if not suc then
        on_fail(err)
    end

    return data
end

return TryRequire
