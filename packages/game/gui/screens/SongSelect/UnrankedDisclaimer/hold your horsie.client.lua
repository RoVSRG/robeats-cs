local Options = require(game.ReplicatedStorage.State.Options)

local function update()
	local od = Options.OverallDifficulty:get()

	script.Parent.Visible = od ~= 8
end

Options.OverallDifficulty:on(update)

update()
