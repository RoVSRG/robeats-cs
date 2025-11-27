local Mods = {
    Mirror = 1,
    Sway = 2,
}

local mod_to_string = {
    [Mods.Mirror] = "MR",
    [Mods.Sway] = "SW",
}

function Mods:get_string_for_mods(mods)
    local names = {}

    for i, mod in ipairs(mods) do
        names[i] = mod_to_string[mod]
    end

    return table.concat(names, ", ")
end

return Mods
