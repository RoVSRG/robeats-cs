local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)
local SongDatabase = require(game.ReplicatedStorage.SongDatabase)
local Players = game:GetService("Players")

local Remotes = game.ReplicatedStorage.Remotes
local MultiplayerInfo = script.Parent.MultiplayerInfo
local SongSelectScreen = script.Parent

local Player = Players.LocalPlayer
local Rooms = workspace:WaitForChild("MultiplayerRooms")
local templates = ScreenChief:GetTemplates("SongSelect")

-- State variables matching the old system structure
local CurrentRoom = nil
local SelectedRoom = 0
local SelectedPlayer = nil
local isHost = false
local MPRooms = {}
local MPButtons = {}
local MPPlayers = {}
local MPPanels = {}
local ButtonCooldown = false

-- Event connections for cleanup
local roomConnections = {}

-- Utility functions
local function playSFX(soundName)
	-- Placeholder for sound effects
	print("Playing sound:", soundName)
end

-- Initialize multiplayer UI state
local function initializeMPRooms()
	print("Initializing multiplayer rooms...")
	MultiplayerInfo.RoomCustomField.Visible = false
	MultiplayerInfo.RoomInfo.Visible = true
	MultiplayerInfo.RoomInfo.Text = ""
	MultiplayerInfo.RoomCustomField.Text = ""
	MultiplayerInfo.LeaveJoinRoom.Text = "Create Room"
	MultiplayerInfo.LeaveJoinRoom.BackgroundColor3 = Color3.new(1, 1, 1)
	
	if CurrentRoom == nil then
		local roomsList = Rooms:GetChildren()
		for _, room in pairs(roomsList) do
			if room then
				createMPRoom(room)
			end
		end
	end
end

-- Create a room UI element
local function createMPRoom(room)
	if CurrentRoom == nil then
		local success, err = pcall(function()
			table.insert(MPRooms, room)
			local roomPanel = templates.RoomPanel:Clone()
			roomPanel.BackgroundColor3 = Color3.new(math.random(), math.random(), math.random())
			roomPanel.RoomName.Text = room.Value
			table.insert(MPButtons, roomPanel)
			
			-- Connect room selection
			roomPanel.MouseButton1Click:Connect(function() 
				selectMPRoom(roomPanel) 
			end)
			
			roomPanel.Parent = MultiplayerInfo.PlayersInfo.PlayersWindow
			
			-- Setup room monitoring
			local passwordLocked = roomPanel:FindFirstChild("PasswordLocked")
			if passwordLocked then
				local hasPassword = room.Password.Value ~= "" and room.Password.Value ~= "Enter Password"
				passwordLocked.Visible = hasPassword
			end
			
			-- Connect room change events
			local connections = {}
			connections[#connections + 1] = room.Players.ChildAdded:Connect(function() 
				updateMPRoom(room) 
			end)
			connections[#connections + 1] = room.Players.ChildRemoved:Connect(function() 
				updateMPRoom(room) 
			end)
			connections[#connections + 1] = room.InGame.Changed:Connect(function() 
				updateMPRoom(room) 
			end)
			connections[#connections + 1] = room.Changed:Connect(function()
				updateMPRoom(room.Value)
			end)
			connections[#connections + 1] = room.Password.Changed:Connect(function() 
				updateMPRoom(room.Value) 
			end)
			connections[#connections + 1] = room.SelectedSongIndex.Changed:Connect(function() 
				updateMPRoom(room.Value) 
			end)
			connections[#connections + 1] = room.SelectedSongRate.Changed:Connect(function() 
				updateMPRoom(room.Value) 
			end)
			
			roomConnections[room] = connections
			updateMPRoom(room.Value)
			positionMPRooms()
		end)
		
		if not success then
			warn("Error creating room:", err)
		end
	end
end

-- Update room display
local function updateMPRoom(roomValue)
	if CurrentRoom == nil then
		for i = 1, #MPButtons do
			pcall(function()
				local room = MPRooms[i]
				local button = MPButtons[i]
				
				if room.InGame.Value then
					button.RoomName.Text = "[IN-GAME] " .. room.Value
				else
					button.RoomName.Text = room.Value
				end
				
				-- Update password lock indicator
				local passwordLocked = button:FindFirstChild("PasswordLocked")
				if passwordLocked then
					local hasPassword = room.Password.Value ~= "" and room.Password.Value ~= "Enter Password"
					passwordLocked.Visible = hasPassword
				end
				
				-- Update player indicators
				local players = room.Players:GetChildren()
				for j = 1, 5 do
					local playerIcon = button:FindFirstChild("Player" .. j)
					if playerIcon then
						if j <= #players then
							playerIcon.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. players[j].Value.UserId .. "&width=420&height=420&format=png"
						else
							playerIcon.Image = "http://www.roblox.com/asset/?id=724192650" -- Default empty
						end
					end
				end
				
				-- Update extra players count
				local extraPlayers = button:FindFirstChild("ExtraPlayers")
				if extraPlayers then
					if #players > 5 then
						extraPlayers.Text = "+" .. (#players - 5)
					else
						extraPlayers.Text = ""
					end
				end
				
				-- Update song name
				local songName = button:FindFirstChild("SongName")
				if songName then
					local songData = SongDatabase:GetSongByKey(room.SelectedSongIndex.Value)
					if songData then
						local rateText = room.SelectedSongRate.Value ~= 1 
							and ("[" .. room.SelectedSongRate.Value .. "x]") 
							or ""
						songName.Text = "Map: " .. rateText .. "[" .. songData.Difficulty .. "]" .. songData.SongName
					else
						songName.Text = "Map: Unknown"
					end
				end
			end)
		end
	elseif isHost == false and roomValue == CurrentRoom.Value then
		if CurrentRoom.InGame.Value then
			MultiplayerInfo.RoomCustomField.Text = roomValue .. " [IN-GAME]"
			MultiplayerInfo.RoomInfo.Text = roomValue .. " [IN-GAME]"
		else
			MultiplayerInfo.RoomCustomField.Text = roomValue
			MultiplayerInfo.RoomInfo.Text = roomValue
		end
	end
end

-- Position room panels
local function positionMPRooms()
	for i = 1, #MPButtons do
		MPButtons[i].Position = UDim2.new(0, 0, 0, 80 * (i - 1))
	end
	
	MultiplayerInfo.PlayersInfo.PlayersWindow.CanvasSize = UDim2.new(0, 0, 0, 80 * #MPButtons)
end

-- Select a room
local function selectMPRoom(roomButton)
	local index = 0
	for i = 1, #MPButtons do
		if MPButtons[i] == roomButton then
			index = i
		end
	end
	
	if index == 0 then
		warn("ERROR: Selected room doesn't exist")
		return
	end
	
	if SelectedRoom ~= index then
		SelectedRoom = index
		
		-- Update button borders
		for i = 1, #MPButtons do
			MPButtons[i].BorderSizePixel = 0
		end
		
		MultiplayerInfo.RoomInfo.Text = MPRooms[index].Value
		MultiplayerInfo.RoomCustomField.Text = MPRooms[index].Value
		MPButtons[index].BorderSizePixel = 2
		MultiplayerInfo.LeaveJoinRoom.Text = "Join Room"
		MultiplayerInfo.LeaveJoinRoom.BackgroundColor3 = Color3.new(0.8, 0.8, 1)
		playSFX("Click")
	else
		-- Deselect
		SelectedRoom = 0
		for i = 1, #MPButtons do
			MPButtons[i].BorderSizePixel = 0
		end
		MultiplayerInfo.RoomInfo.Text = ""
		MultiplayerInfo.RoomCustomField.Text = ""
		MultiplayerInfo.LeaveJoinRoom.Text = "Create Room"
		MultiplayerInfo.LeaveJoinRoom.BackgroundColor3 = Color3.new(1, 1, 1)
		playSFX("Click")
	end
end

-- Join a multiplayer room
local function joinMPRoom()
	if CurrentRoom == nil then
		CurrentRoom = MPRooms[SelectedRoom]
	end
	
	if CurrentRoom ~= nil then
		print("Joining room...")
		
		local currentPassword = MultiplayerInfo.PlayersInfo.PasswordInput.Text
		local targetPassword = CurrentRoom:WaitForChild("Password").Value
		
		if currentPassword == "Enter Password" or currentPassword == " " then
			currentPassword = ""
		end
		if targetPassword == "Enter Password" or targetPassword == " " or targetPassword == "" then
			currentPassword = ""
			targetPassword = ""
		end
		
		if currentPassword ~= targetPassword then
			warn("Failed to join room: Incorrect Password")
			CurrentRoom = nil
			return
		elseif CurrentRoom.InGame.Value == true then
			warn("Failed to join room: Cannot join room while in game")
			CurrentRoom = nil
			return
		else
			local success, result = Remotes.Functions.JoinRoom:InvokeServer(CurrentRoom, currentPassword)
			if not success then
				warn("Failed to join room:", result)
				CurrentRoom = nil
				return
			end
			
			playSFX("Joined")
			
			-- Clear room list since we're now in a room
			MPRooms = {}
			MPButtons = {}
			for _, button in pairs(MultiplayerInfo.PlayersInfo.PlayersWindow:GetChildren()) do
				if button.Name == "RoomPanel" or button.ClassName == "TextButton" then
					button.Visible = false
				end
			end
			
			MultiplayerInfo.RoomInfo.Text = CurrentRoom.Value
			MultiplayerInfo.RoomCustomField.Text = CurrentRoom.Value
			MultiplayerInfo.LeaveJoinRoom.Text = "Leave Room"
			MultiplayerInfo.LeaveJoinRoom.BackgroundColor3 = Color3.new(1, 0, 0)
			
			-- Setup host/player UI
			local host = CurrentRoom.Players.Value
			if Player == host then
				isHost = true
				SongSelectScreen.PlayButton.BackgroundColor3 = Color3.new(0, 1, 0)
				MultiplayerInfo.PlayersInfo.KickButton.BackgroundColor3 = Color3.new(1, 0, 0)
				MultiplayerInfo.PlayersInfo.TransferHostButton.BackgroundColor3 = Color3.new(0, 1, 0)
				-- Enable song selection for host
			else
				isHost = false
				SongSelectScreen.PlayButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
				MultiplayerInfo.PlayersInfo.KickButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
				MultiplayerInfo.PlayersInfo.TransferHostButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
				-- Sync song selection from host
			end
			
			-- Create player panels for all current players
			local existingPlayers = CurrentRoom.Players:GetChildren()
			for _, playerObj in pairs(existingPlayers) do
				createMPPlayer(playerObj, true)
			end
			
			-- Setup room event listeners
			roomConnections.currentRoom = {}
			roomConnections.currentRoom[#roomConnections.currentRoom + 1] = CurrentRoom.Players.ChildAdded:Connect(createMPPlayer)
			roomConnections.currentRoom[#roomConnections.currentRoom + 1] = CurrentRoom.Players.ChildRemoved:Connect(deleteMPPlayer)
			roomConnections.currentRoom[#roomConnections.currentRoom + 1] = CurrentRoom.Players.Changed:Connect(hostChangedMPPlayer)
			roomConnections.currentRoom[#roomConnections.currentRoom + 1] = CurrentRoom.SongStarted.Changed:Connect(songStartedChanged)
			roomConnections.currentRoom[#roomConnections.currentRoom + 1] = CurrentRoom.SelectedSongIndex.Changed:Connect(mapSelectionChanged)
			roomConnections.currentRoom[#roomConnections.currentRoom + 1] = CurrentRoom.SelectedSongRate.Changed:Connect(mapSelectionChanged)
			roomConnections.currentRoom[#roomConnections.currentRoom + 1] = CurrentRoom.InGame.Changed:Connect(mapSelectionChanged)
		end
	end
end

-- Leave multiplayer room
local function leaveMPRoom(kicked)
	if CurrentRoom ~= nil then
		print("Leaving room...")
		
		-- Disconnect all room events
		if roomConnections.currentRoom then
			for _, connection in pairs(roomConnections.currentRoom) do
				connection:Disconnect()
			end
			roomConnections.currentRoom = nil
		end
		
		-- Clean up UI elements
		for _, button in pairs(MPButtons) do
			button:Destroy()
		end
		for _, player in pairs(MPPlayers) do
			player:Destroy()
		end
		for _, panel in pairs(MPPanels) do
			panel:Destroy()
		end
		
		MPPlayers = {}
		MPPanels = {}
		MPButtons = {}
		CurrentRoom = nil
		SelectedPlayer = nil
		isHost = false
	end
	
	-- Reset UI state
	SongSelectScreen.PlayButton.BackgroundColor3 = Color3.new(0, 1, 0)
	MultiplayerInfo.PlayersInfo.KickButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	MultiplayerInfo.PlayersInfo.TransferHostButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	MultiplayerInfo.LeaveJoinRoom.Text = "Create Room"
	MultiplayerInfo.LeaveJoinRoom.BackgroundColor3 = Color3.new(1, 1, 1)
	SelectedRoom = 0
	
	initializeMPRooms()
	playSFX("Left")
end

-- Create room
local function buildMPRoom()
	isHost = true
	SongSelectScreen.PlayButton.BackgroundColor3 = Color3.new(0, 1, 0)
	MultiplayerInfo.PlayersInfo.TransferHostButton.BackgroundColor3 = Color3.new(0, 1, 0)
	MultiplayerInfo.PlayersInfo.KickButton.BackgroundColor3 = Color3.new(1, 0, 0)
	MultiplayerInfo.RoomCustomField.Visible = true
	MultiplayerInfo.RoomInfo.Visible = false
	
	local roomName = Player.Name .. "'s Room"
	local success, result = Remotes.Functions.CreateRoom:InvokeServer(roomName, "", 1, 1) -- Default song index 1, rate 1x
	
	if success then
		CurrentRoom = result
		joinMPRoom()
	else
		warn("Failed to create room:", result)
		isHost = false
		SongSelectScreen.PlayButton.BackgroundColor3 = Color3.new(0, 1, 0)
		MultiplayerInfo.PlayersInfo.TransferHostButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		MultiplayerInfo.PlayersInfo.KickButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		MultiplayerInfo.RoomCustomField.Visible = false
		MultiplayerInfo.RoomInfo.Visible = true
	end
end

-- Create player panel
function createMPPlayer(playerObj, silent)
	if not silent then
		playSFX("Joined")
	end
	
	local playerPanel = templates.PlayerPanel:Clone()
	playerPanel.Parent = MultiplayerInfo.PlayersInfo.PlayersWindow
	playerPanel.Position = UDim2.new(0, 0, 0, 40 * #MPPlayers)
	
	playerPanel.MouseButton1Click:Connect(function() 
		selectMPPlayer(playerPanel) 
	end)
	
	table.insert(MPPlayers, playerObj)
	table.insert(MPPanels, playerPanel)
	
	updateMPPlayerList()
	print("Player joined room:", playerObj.Value.Name)
end

-- Delete player panel
function deleteMPPlayer(playerObj)
	local index = 0
	for i = 1, #MPPlayers do
		if MPPlayers[i] == playerObj then
			index = i
			break
		end
	end
	
	playSFX("Left")
	if playerObj == SelectedPlayer then
		SelectedPlayer = nil
	end
	
	if index ~= 0 and CurrentRoom then
		MPPanels[index]:Destroy()
		table.remove(MPPanels, index)
		table.remove(MPPlayers, index)
		
		-- Check if we became host
		if CurrentRoom.Players.Value == Player then
			isHost = true
			SongSelectScreen.PlayButton.BackgroundColor3 = Color3.new(0, 1, 0)
			MultiplayerInfo.PlayersInfo.TransferHostButton.BackgroundColor3 = Color3.new(0, 1, 0)
			MultiplayerInfo.PlayersInfo.KickButton.BackgroundColor3 = Color3.new(1, 0, 0)
			MultiplayerInfo.RoomCustomField.Visible = true
			MultiplayerInfo.RoomInfo.Visible = false
		end
	end
	
	if CurrentRoom ~= nil then
		if playerObj.Value == Player then
			-- We were kicked
			leaveMPRoom(true)
		else
			updateMPPlayerList()
			print("Player left room:", playerObj.Value.Name)
		end
	end
end

-- Update player list display
function updateMPPlayerList()
	if CurrentRoom ~= nil then
		for i = 1, #MPPanels do
			local panel = MPPanels[i]
			local playerObj = MPPlayers[i]
			
			panel.Position = UDim2.new(0, 0, 0, 40 * (i - 1))
			
			-- Update player info
			if playerObj and playerObj.Value then
				local player = playerObj.Value
				panel.PlayerImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
				panel.PlayerName.Text = player.Name
				
				-- Show host indicator
				local hostIndicator = panel.PlayerImage:FindFirstChild("Host")
				if hostIndicator then
					hostIndicator.Visible = (CurrentRoom.Players.Value == player)
				end
			end
		end
		
		MultiplayerInfo.PlayersInfo.PlayersWindow.CanvasSize = UDim2.new(0, 0, 0, 40 * #MPPanels)
	end
end

-- Select player
function selectMPPlayer(playerPanel)
	if ButtonCooldown then return end
	ButtonCooldown = true
	
	local index = 0
	for i = 1, #MPPanels do
		if MPPanels[i] == playerPanel then
			index = i
			break
		end
	end
	
	if index ~= 0 then
		playSFX("Click")
		
		if SelectedPlayer and MPPlayers[index].Value.Name == SelectedPlayer.Value.Name then
			-- Deselect
			MPPanels[index].BorderSizePixel = 0
			SelectedPlayer = nil
		else
			-- Clear previous selection
			for i = 1, #MPPanels do
				MPPanels[i].BorderSizePixel = 0
			end
			
			-- Select new player
			SelectedPlayer = MPPlayers[index]
			MPPanels[index].BorderSizePixel = 2
		end
	end
	
	wait(0.25)
	ButtonCooldown = false
end

-- Event handlers
function hostChangedMPPlayer(newHost)
	if newHost == Player then
		MultiplayerInfo.RoomCustomField.Visible = true
		MultiplayerInfo.RoomInfo.Visible = false
		MultiplayerInfo.PlayersInfo.PasswordInput.Text = CurrentRoom.Password.Value
		isHost = true
		SongSelectScreen.PlayButton.BackgroundColor3 = Color3.new(0, 1, 0)
		MultiplayerInfo.PlayersInfo.TransferHostButton.BackgroundColor3 = Color3.new(0, 1, 0)
		MultiplayerInfo.PlayersInfo.KickButton.BackgroundColor3 = Color3.new(1, 0, 0)
		playSFX("Tap")
	end
	updateMPPlayerList()
end

function songStartedChanged()
	-- Handle song start/stop
end

function mapSelectionChanged()
	-- Handle map/rate changes
end

-- Button click handlers
local function joinLeaveButtonClicked()
	if ButtonCooldown then return end
	ButtonCooldown = true
	
	if CurrentRoom == nil and SelectedRoom ~= 0 then
		joinMPRoom()
	elseif CurrentRoom ~= nil then
		Remotes.Functions.LeaveRoom:InvokeServer(CurrentRoom)
		leaveMPRoom()
	else
		buildMPRoom()
	end
	
	wait(0.25)
	ButtonCooldown = false
end

-- Kick player
local function kickPlayer()
	if SelectedPlayer and SelectedPlayer.Value ~= Player and isHost and CurrentRoom then
		playSFX("Tap")
		print("Kicking player:", SelectedPlayer.Value.Name)
		Remotes.Functions.KickPlayer:InvokeServer(CurrentRoom, SelectedPlayer.Value)
	else
		playSFX("Error")
		SelectedPlayer = nil
	end
end

-- Transfer host
local function transferHost()
	if SelectedPlayer and SelectedPlayer.Value ~= Player and isHost and CurrentRoom then
		isHost = false
		SongSelectScreen.PlayButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		MultiplayerInfo.PlayersInfo.TransferHostButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		MultiplayerInfo.PlayersInfo.KickButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		MultiplayerInfo.RoomCustomField.Visible = false
		MultiplayerInfo.RoomInfo.Visible = true
		
		Remotes.Functions.TransferHost:InvokeServer(CurrentRoom, SelectedPlayer.Value)
		playSFX("Tap")
		updateMPPlayerList()
	else
		playSFX("Error")
	end
end

-- Connect UI events
MultiplayerInfo.LeaveJoinRoom.MouseButton1Click:Connect(joinLeaveButtonClicked)
MultiplayerInfo.PlayersInfo.KickButton.MouseButton1Click:Connect(kickPlayer)
MultiplayerInfo.PlayersInfo.TransferHostButton.MouseButton1Click:Connect(transferHost)

-- Clean up when rooms are removed
Rooms.ChildRemoved:Connect(function(room)
	local index = 0
	for i = 1, #MPRooms do
		if MPRooms[i] == room then
			index = i
			break
		end
	end
	
	if index ~= 0 then
		-- Disconnect room events
		if roomConnections[room] then
			for _, connection in pairs(roomConnections[room]) do
				connection:Disconnect()
			end
			roomConnections[room] = nil
		end
		
		-- Remove UI elements
		table.remove(MPRooms, index)
		local button = MPButtons[index]
		table.remove(MPButtons, index)
		button:Destroy()
		positionMPRooms()
	end
end)

-- Add new rooms when they appear
Rooms.ChildAdded:Connect(function(room)
	createMPRoom(room)
end)

-- Initialize the multiplayer system
initializeMPRooms()