local Val = require(game.ReplicatedStorage.Libraries.Val)

local Options = Val.scope {
    -- Game Options
    Keybinds = Val.new({
        "A", "S", "Semicolon", "Quote"
    })
}

return Options