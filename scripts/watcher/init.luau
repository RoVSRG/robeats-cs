--!strict
-- Studio Place File Watcher - Auto-pulls GUI changes when Studio saves
-- Refactored modular version with improved error handling and debugging

local Watcher = require("@self/watcher")

-- Entry point - start the file watcher
local success = Watcher.startWatching()

if not success then
	print("❌ Failed to start watcher")
	os.exit(1)
end
