-- Modern multiplayer system for the new game structure
local MultiplayerRooms = workspace:FindFirstChild("MultiplayerRooms") or Instance.new("Folder")
MultiplayerRooms.Name = "MultiplayerRooms"
MultiplayerRooms.Parent = workspace

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

-- Get remote functions from the new structure
local remoteFunctions = ReplicatedStorage.Remotes.Functions
local remoteEvents = ReplicatedStorage.Remotes.Events

-- Rate limiting
local rateLimits = {}

-- Utility functions
local function round(number, digits)
	local newnum = number * (10^digits)
	local remainder = newnum - math.floor(newnum)
	newnum = newnum - remainder
	if remainder >= 0.5 then
		newnum = newnum + 1
	end
	return newnum/(10^digits)
end

local function getTextObject(message, fromPlayerId)
	local textObject
	local success, errorMessage = pcall(function()
		textObject = TextService:FilterStringAsync(message, fromPlayerId)
	end)
	if success then
		return textObject
	elseif errorMessage then
		warn("Error generating TextFilterResult:", errorMessage)
	end
	return false
end

local function getFilteredMessage(textObject)
	local filteredMessage
	local success, errorMessage = pcall(function()
		filteredMessage = textObject:GetNonChatStringForBroadcastAsync()
	end)
	if success then
		return filteredMessage
	elseif errorMessage then
		warn("Error filtering message:", errorMessage)
	end
	return false
end

local function isRateLimited(userId)
	local now = tick()
	if rateLimits[userId] and now - rateLimits[userId] < 1 then
		return true
	end
	rateLimits[userId] = now
	return false
end

-- Core multiplayer functions (camelCase)
local function createRoom(player, roomName, password, mapSelected, playRate)
    print("Creating room for player:", player.Name)

	if isRateLimited(player.UserId) then
		return false, "Rate limited"
	end
	
	-- Check if player is already in a room
	for _, room in pairs(MultiplayerRooms:GetChildren()) do
		if room.Players.Value == player then
			return false, "Already in a room"
		end
	end
	
	-- Create new room
	local currentRoom = Instance.new("StringValue")
	currentRoom.Name = roomName
	currentRoom.Parent = MultiplayerRooms
	
	-- Filter room name
	local textObject = getTextObject(roomName, player.UserId)
	if textObject then
		local filteredName = getFilteredMessage(textObject)
		if filteredName then
			currentRoom.Value = filteredName
		end
	end
	
	-- Room properties
	local password_obj = Instance.new("StringValue")
	password_obj.Name = "Password"
	password_obj.Value = password or ""
	password_obj.Parent = currentRoom
	
	local selectedSongIndex = Instance.new("IntValue")
	selectedSongIndex.Name = "SelectedSongIndex"
	selectedSongIndex.Value = mapSelected or 1
	selectedSongIndex.Parent = currentRoom
	
	local selectedSongRate = Instance.new("NumberValue")
	selectedSongRate.Name = "SelectedSongRate"
	selectedSongRate.Value = round(playRate or 1, 2)
	selectedSongRate.Parent = currentRoom
	
	local songStarted = Instance.new("BoolValue")
	songStarted.Name = "SongStarted"
	songStarted.Value = false
	songStarted.Parent = currentRoom
	
	local inGame = Instance.new("BoolValue")
	inGame.Name = "InGame"
	inGame.Value = false
	inGame.Parent = currentRoom
	
	local players = Instance.new("ObjectValue")
	players.Name = "Players"
	players.Value = player -- Host
	players.Parent = currentRoom
	
	return currentRoom
end

local function joinRoom(player, currentRoom, password)
	if not currentRoom then
		return false, "Room not found"
	end
	
	local roomPassword = currentRoom.Password.Value
	local hasPassword = roomPassword and roomPassword ~= ""
	
	if hasPassword and password ~= roomPassword then
		return false, "Incorrect password"
	end
	
	-- Add player to room
	local playerObj = Instance.new("ObjectValue")
	playerObj.Name = player.Name
	playerObj.Value = player
	playerObj.Parent = currentRoom.Players
	
	local isReady = Instance.new("BoolValue")
	isReady.Name = "IsReady"
	isReady.Value = false
	isReady.Parent = playerObj
	
	return true
end

local function leaveRoom(player, currentRoom)
	if not currentRoom then
		return false
	end
	
	local playerObj = currentRoom.Players:FindFirstChild(player.Name)
	local host = currentRoom.Players.Value
	
	if playerObj then
		playerObj:Destroy()
	end
	
	-- If no players left, delete room
	if #currentRoom.Players:GetChildren() == 0 then
		currentRoom:Destroy()
		return true
	end
	
	-- If host left, transfer to random player
	if player == host and #currentRoom.Players:GetChildren() > 0 then
		local children = currentRoom.Players:GetChildren()
		currentRoom.Players.Value = children[math.random(1, #children)].Value
	end
	
	return true
end

local function setMap(player, currentRoom, songIndex)
	if not currentRoom then
		return false
	end
	
	local host = currentRoom.Players.Value
	if player == host then
		currentRoom.SelectedSongIndex.Value = songIndex
		return true
	end
	
	return false, "Not host"
end

local function setPlayRate(player, currentRoom, songRate)
	if not currentRoom then
		return false
	end
	
	local host = currentRoom.Players.Value
	if player == host then
		currentRoom.SelectedSongRate.Value = round(songRate, 2)
		return true
	end
	
	return false, "Not host"
end

local function transferHost(player, currentRoom, targetPlayer)
	if not currentRoom then
		return false
	end
	
	local host = currentRoom.Players.Value
	if player == host then
		currentRoom.Players.Value = targetPlayer
		return true
	end
	
	return false, "Not host"
end

local function changeName(player, currentRoom, newName)
	if not currentRoom then
		return false
	end
	
	local host = currentRoom.Players.Value
	if player == host then
		local textObject = getTextObject(newName, player.UserId)
		if textObject then
			local filteredName = getFilteredMessage(textObject)
			if filteredName then
				currentRoom.Value = filteredName
				return true
			end
		end
	end
	
	return false, "Failed to change name"
end

local function changePassword(player, currentRoom, newPassword)
	if not currentRoom then
		return false
	end
	
	local host = currentRoom.Players.Value
	if player == host then
		currentRoom.Password.Value = newPassword or ""
		return true
	end
	
	return false, "Not host"
end

local function kickPlayer(player, currentRoom, kickedPlayer)
	if not currentRoom then
		return false
	end
	
	local host = currentRoom.Players.Value
	if player == host and kickedPlayer ~= player then
		local playerObj = currentRoom.Players:FindFirstChild(kickedPlayer.Name)
		if playerObj then
			playerObj:Destroy()
		end
		
		-- Check if room should be deleted
		if #currentRoom.Players:GetChildren() == 0 then
			currentRoom:Destroy()
		end
		
		return true
	end
	
	return false, "Cannot kick player"
end

local function ready(player, currentRoom)
	if not currentRoom then
		return false
	end
	
	local playerObj = currentRoom.Players:FindFirstChild(player.Name)
	local host = currentRoom.Players.Value
	
	if player == host then
		currentRoom.SongStarted.Value = false
	end
	
	if playerObj then
		playerObj.IsReady.Value = true
		return true
	end
	
	return false
end

local function playMap(player, currentRoom)
	if not currentRoom then
		return false
	end
	
	local host = currentRoom.Players.Value
	if player == host then
		-- Reset all ready states
		for _, playerObj in pairs(currentRoom.Players:GetChildren()) do
			if playerObj:FindFirstChild("IsReady") then
				playerObj.IsReady.Value = false
			end
		end
		
		currentRoom.SongStarted.Value = true
		currentRoom.InGame.Value = true
		return true
	end
	
	return false, "Not host"
end

local function finished(player, currentRoom, leftGame)
	if not currentRoom or leftGame then
		return false
	end
	
	local host = currentRoom.Players.Value
	if player == host then
		currentRoom.InGame.Value = false
		return true
	end
	
	return false
end

local function updatePlayerStats(player, statsData)
	-- Update player statistics from game results
	if not statsData then
		return
	end
	
	-- This is a simplified version - extend as needed
	for statName, value in pairs(statsData) do
		local statObj = player:FindFirstChild(statName)
		if statObj then
			statObj.Value = value
		end
	end
end

-- Player management
local function setupPlayerStats(player)
	-- Create basic stat values for the player
	local stats = {
		"Accuracy", "Score", "Combo", "MaxCombo"
	}
	
	for _, statName in ipairs(stats) do
		local stat = Instance.new("NumberValue")
		stat.Name = statName
		stat.Value = 0
		stat.Parent = player
	end
end

-- Event connections
Players.PlayerAdded:Connect(setupPlayerStats)

Players.PlayerRemoving:Connect(function(player)
	-- Clean up player from all rooms
	for _, room in pairs(MultiplayerRooms:GetChildren()) do
		local playerObj = room.Players:FindFirstChild(player.Name)
		if playerObj then
			playerObj:Destroy()
			
			-- Transfer host if needed
			if room.Players.Value == player and #room.Players:GetChildren() > 0 then
				local children = room.Players:GetChildren()
				room.Players.Value = children[math.random(1, #children)].Value
			end
			
			-- Delete room if empty
			if #room.Players:GetChildren() == 0 then
				room:Destroy()
			end
		end
	end
end)

-- Connect remote functions
remoteFunctions.CreateRoom.OnServerInvoke = createRoom
remoteFunctions.JoinRoom.OnServerInvoke = joinRoom
remoteFunctions.LeaveRoom.OnServerInvoke = leaveRoom
remoteFunctions.SetMap.OnServerInvoke = setMap
remoteFunctions.SetPlayRate.OnServerInvoke = setPlayRate
remoteFunctions.TransferHost.OnServerInvoke = transferHost
remoteFunctions.ChangeName.OnServerInvoke = changeName
remoteFunctions.ChangePassword.OnServerInvoke = changePassword
remoteFunctions.KickPlayer.OnServerInvoke = kickPlayer
remoteFunctions.Ready.OnServerInvoke = ready
remoteFunctions.PlayMap.OnServerInvoke = playMap
remoteFunctions.Finished.OnServerInvoke = finished

-- Connect remote events
remoteEvents.UpdatePlayerStats.OnServerEvent:Connect(updatePlayerStats)