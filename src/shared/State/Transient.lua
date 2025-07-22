local Val = require(game.ReplicatedStorage.Libraries.Val)

local Transient = {}

----------------------------------------------------------------
-- SONG SELECTION STATE
----------------------------------------------------------------

-- Currently selected song (key/index in SongDatabase)
Transient.selectedSongKey = Val.new(nil) 

-- Currently selected song metadata (table w/ Name, Artist, Difficulty, etc.)
Transient.selectedSongData = Val.new(nil)

-- Currently selected song rate (1.0x default)
Transient.selectedSongRate = Val.new(1.0)

-- Currently selected sort mode ("Default", "ReleaseDate", "Difficulty")
Transient.sortMode = Val.new("Default")

-- Current search query (string)
Transient.searchQuery = Val.new("")

-- Cached filtered song list (list of SongDatabase entries matching sort/search)
Transient.filteredSongList = Val.new({})

----------------------------------------------------------------
-- PLAYER PROFILE STATE
----------------------------------------------------------------

-- Player’s username
Transient.playerUsername = Val.new("")

-- Player’s avatar thumbnail URL
Transient.playerAvatarUrl = Val.new("")

-- Player’s current tier (e.g. "Tier 10 - Legendary")
Transient.playerTier = Val.new("")

-- Player’s global rank (e.g. "#213")
Transient.playerRank = Val.new("")

-- Player’s rating (float)
Transient.playerRating = Val.new(0)

-- XP progress for next tier
Transient.xpProgress = Val.new(0.0) -- 0.0 to 1.0

----------------------------------------------------------------
-- UI PANEL STATE
----------------------------------------------------------------

-- Whether profile panel is expanded/collapsed
Transient.profilePanelOpen = Val.new(true)

-- Whether settings menu is open
Transient.settingsOpen = Val.new(false)

-- Whether the song info panel is open
Transient.songInfoPanelOpen = Val.new(false)

----------------------------------------------------------------
-- SESSION / GAMEPLAY STATE
----------------------------------------------------------------

-- Whether a song is currently loading
Transient.isSongLoading = Val.new(false)

-- Whether a song is currently running
Transient.isSongPlaying = Val.new(false)

-- Active game session results (score/accuracy after finish)
Transient.lastGameResult = Val.new(nil)

----------------------------------------------------------------
-- HELPER METHODS
----------------------------------------------------------------

-- Shortcut: update selected song key + metadata together
function Transient:setSelectedSong(songKey, songData)
	Transient.selectedSongKey:set(songKey)
	Transient.selectedSongData:set(songData)
end

return Transient
