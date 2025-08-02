local Function = {}

function Function.create(func)
    return function(...)
        local args = { ... }

        local success, result = pcall(func, table.unpack(args))
        
        if not success then
            warn("Function execution failed: " .. tostring(result))
            return { success = false, error = tostring(result) }
        end

        return { success = true, result = result }
    end
end

return Function