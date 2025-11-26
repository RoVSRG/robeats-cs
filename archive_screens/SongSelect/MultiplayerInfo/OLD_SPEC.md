This is how multiplayer was done in the old game. Obviously we aren't trying to copy the structure, but this is how the UI elements were manipulated. Make it so it visually behaves identically.

```lua
local events = {}
events[1] = ReplicatedStorage:FindFirstChild("SubmitScore")
events[2] = ReplicatedStorage:FindFirstChild("SubmitPP")
events[3] = ReplicatedStorage:FindFirstChild("SaveRating")
events[4] = ReplicatedStorage:FindFirstChild("UpdateStatus")
events[5] = ReplicatedStorage.Multiplayer:FindFirstChild("CreateRoom")
events[6] = ReplicatedStorage.Multiplayer:FindFirstChild("JoinRoom")
events[7] = ReplicatedStorage.Multiplayer:FindFirstChild("LeaveRoom")
events[8] = ReplicatedStorage.Multiplayer:FindFirstChild("ChangeName")
events[9] = ReplicatedStorage.Multiplayer:FindFirstChild("ChangePassword")
events[10] = ReplicatedStorage.Multiplayer:FindFirstChild("KickPlayer")
events[11] = ReplicatedStorage.Multiplayer:FindFirstChild("TransferHost")
events[12] = ReplicatedStorage.Multiplayer:FindFirstChild("SetMap")
events[13] = ReplicatedStorage.Multiplayer:FindFirstChild("SetPlayRate")
events[14] = ReplicatedStorage.Multiplayer:FindFirstChild("PlayMap")
events[15] = ReplicatedStorage.Multiplayer:FindFirstChild("Ready")
events[16] = ReplicatedStorage.Multiplayer:FindFirstChild("Finished")
events[17] = ReplicatedStorage.Multiplayer:FindFirstChild("UpdateMAValues")
events[18] = ReplicatedStorage.Multiplayer:FindFirstChild("SubmitNoteDeviance")
events[19] = ReplicatedStorage.Multiplayer:FindFirstChild("ShutdownRoom")

function InitializeMPRooms()
	print("INITIALIZING", debug.traceback())
	SongSelectScreen.MultiplayerInfo.RoomCustomField.Visible = false
	SongSelectScreen.MultiplayerInfo.RoomInfo.Visible = true
	SongSelectScreen.MultiplayerInfo.RoomInfo.Text = ""
	SongSelectScreen.MultiplayerInfo.RoomCustomField.Text = ""
	SongSelectScreen.MultiplayerInfo.LeaveJoinRoom.Text = "Create Room"
	SongSelectScreen.MultiplayerInfo.LeaveJoinRoom.BackgroundColor3 = Color3.new(1,1,1)
	if CurrentRoom == nil then
		local gr = GameRooms:GetChildren()
		for i=1,#gr do
			if gr[i] then
				CreateMPRoom(gr[i])
			end
		end
	end
end

function SelectMPRoom(room)
	local index = 0
	for i=1, #MPButtons do
		if MPButtons[i] == room then
			index = i
		end
	end
	if index == 0 then
		DebugLog("ERROR: [SelectMPRoom]: indexed room doesn't exist")
	elseif SelectedRoom ~= index then
		SelectedRoom = index
		for i=1, #MPButtons do
			MPButtons[i].BorderSizePixel = 0
		end
		SongSelectScreen.MultiplayerInfo.RoomInfo.Text = MPRooms[index].Value
		SongSelectScreen.MultiplayerInfo.RoomCustomField.Text = MPRooms[index].Value
		MPButtons[index].BorderSizePixel = 2
		SongSelectScreen.MultiplayerInfo.LeaveJoinRoom.Text = "Join Room"
		SongSelectScreen.MultiplayerInfo.LeaveJoinRoom.BackgroundColor3 = Color3.new(0.8,0.8,1)
		PlaySound("Click")
	else
		SelectedRoom = 0
		for i=1, #MPButtons do
			MPButtons[i].BorderSizePixel = 0
		end
		SongSelectScreen.MultiplayerInfo.RoomInfo.Text = ""
		SongSelectScreen.MultiplayerInfo.RoomCustomField.Text = ""
		SongSelectScreen.MultiplayerInfo.LeaveJoinRoom.Text = "Create Room"
		SongSelectScreen.MultiplayerInfo.LeaveJoinRoom.BackgroundColor3 = Color3.new(1,1,1)
		PlaySound("Click")
	end
end

function ShutdownMPRoom(room)
	events[19]:InvokeServer(room)
end

function JoinMPRoom()
	if CurrentRoom == nil then
		CurrentRoom = MPRooms[SelectedRoom]
	end
	if CurrentRoom ~= nil then
		print("Joining room...")

		local curpw = SongSelectScreen.MultiplayerInfo.PlayersInfo.PasswordInput.Text
		local tarpw = CurrentRoom:WaitForChild("Password").Value
		if curpw == "Enter Password" or curpw == " " then
			curpw = ""
		end
		if tarpw ==	"Enter Password" or tarpw == " " or tarpw == "" then
			curpw = ""
			tarpw = ""
		end
		if curpw ~= tarpw then
			DebugLog("Failed to join room: Incorrect Password")
			CurrentRoom = nil
		elseif CurrentRoom.InGame.Value == true then
			DebugLog("Failed to join room: Cannot join room while room is InGame")
			CurrentRoom = nil
		else
			events[6]:InvokeServer(CurrentRoom, curpw)
			PlaySound("Joined")
			MPRooms = {}
			MPButtons = {}
			for i, v in pairs(SongSelectScreen.MultiplayerInfo.PlayersInfo.PlayersWindow:GetChildren()) do
				if v.Name == "RoomPanel" then
					v.Visible = false
				end
			end
			SongSelectScreen.MultiplayerInfo.RoomInfo.Text = CurrentRoom.Value
			SongSelectScreen.MultiplayerInfo.RoomCustomField.Text = CurrentRoom.Value
			SongSelectScreen.MultiplayerInfo.LeaveJoinRoom.Text = "Leave Room"
			SongSelectScreen.MultiplayerInfo.LeaveJoinRoom.BackgroundColor3 = Color3.new(1,0,0)
			if isHost then
				SongSelectScreen.PlayButton.BackgroundColor3 = Color3.new(0,1,0)
				SongSelectScreen.MultiplayerInfo.PlayersInfo.KickButton.BackgroundColor3 = Color3.new(1,0,0)
				SongSelectScreen.MultiplayerInfo.PlayersInfo.TransferHostButton.BackgroundColor3 = Color3.new(0,1,0)
				SongSelectScreen.SongSelection.SongButtonContainer.BackgroundColor3 = Color3.new(0,0,0)
			else
				SongSelectScreen.PlayButton.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
				SongSelectScreen.MultiplayerInfo.PlayersInfo.KickButton.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
				SongSelectScreen.MultiplayerInfo.PlayersInfo.TransferHostButton.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
				SongSelectScreen.SongSelection.SongButtonContainer.BackgroundColor3 = Color3.new(1,1,0)
				map_Selected = CurrentRoom.SelectedSongIndex.Value
				playRate = CurrentRoom.SelectedSongRate.Value
				SelectMap(map_Selected, true)
				SongSelectScreen.MultiplayerInfo.SongInfo.RateSelector.RateInfo.Text = "Song Rate: " .. playRate .. "x"
			end

			local oa = CurrentRoom.Players:GetChildren()
			for i=1, #oa do
				CreateMPPlayer(oa[i], true)
			end

			UpdateScorePanel(false)

			CMPEvent = CurrentRoom.Players.ChildAdded:connect(CreateMPPlayer)
			DMPEvent = CurrentRoom.Players.ChildRemoved:connect(DeleteMPPlayer)
			HMPEvent = CurrentRoom.Players.Changed:connect(HostChangedMPPlayer)
			MapReadyEvent = CurrentRoom.SongStarted.Changed:connect(ChangedMPStart)
			MapSelectEvent = CurrentRoom.SelectedSongIndex.Changed:connect(ChangedMPMap)
			MapRateEvent = CurrentRoom.SelectedSongRate.Changed:connect(ChangedMPMap)
			InGameEvent = CurrentRoom.InGame.Changed:connect(ChangedMPMap)
		end
	end
end

function LeaveMPRoom(kicked)
	if CurrentRoom ~= nil then
		print("Leaving...")
		local ob = CurrentRoom.Players:FindFirstChild(Player.Name)
		CMPEvent:Disconnect()
		DMPEvent:Disconnect()
		HMPEvent:Disconnect()
		MapSelectEvent:Disconnect()
		MapReadyEvent:Disconnect()
		MapRateEvent:Disconnect()
		InGameEvent:Disconnect()

		for i, v in pairs(MPButtons) do
			v:Destroy()
		end
		for i, v in pairs(MPPlayers) do
			v:Destroy()
		end
		for i, v in pairs(MPPanels) do
			v:Destroy()
		end

		MPPlayers = {}
		MPPanels = {}
		MPButtons = {}

		CurrentRoom = nil
		SelectedPlayer = nil
		isHost = false
	end
	SongSelectScreen.PlayButton.BackgroundColor3 = Color3.new(0,1,0)
	SongSelectScreen.MultiplayerInfo.PlayersInfo.KickButton.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
	SongSelectScreen.MultiplayerInfo.PlayersInfo.TransferHostButton.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
	SongSelectScreen.SongSelection.SongButtonContainer.BackgroundColor3 = Color3.new(0,0,0)
	SongSelectScreen.MultiplayerInfo.LeaveJoinRoom.Text = "Create Room"
	SongSelectScreen.MultiplayerInfo.LeaveJoinRoom.BackgroundColor3 = Color3.new(1,1,1)
	SelectedRoom = 0
	InitializeMPRooms()
	UpdateScorePanel(false)
	PlaySound("Left")
end

function BuildMPRoom()
	isHost = true
	SongSelectScreen.PlayButton.BackgroundColor3 = Color3.new(0,1,0)
	SongSelectScreen.MultiplayerInfo.PlayersInfo.TransferHostButton.BackgroundColor3 = Color3.new(0,1,0)
	SongSelectScreen.MultiplayerInfo.PlayersInfo.KickButton.BackgroundColor3 = Color3.new(1,0,0)
	SongSelectScreen.SongSelection.SongButtonContainer.BackgroundColor3 = Color3.new(0,0,0)
	SongSelectScreen.MultiplayerInfo.RoomCustomField.Visible = true
	SongSelectScreen.MultiplayerInfo.RoomInfo.Visible = false

	local roomName = Player.Name.. "'s Room"
	CurrentRoom = events[5]:InvokeServer(roomName, "", map_Selected, playRate)	
	repeat wait() until CurrentRoom.Parent == GameRooms
	JoinMPRoom()
end

function PositionMPRooms()
	for i=1, #MPButtons do
		if SPVisible == false then
			MPButtons[i].Position = UDim2.new(0,0,0,80*(i-1))
		else
			if i < SPPosition then
				MPButtons[i].Position = UDim2.new(0,0,0,80*(i-1))
			else
				MPButtons[i].Position = UDim2.new(0,0,0,80*(i-1) + 180)
			end
		end
	end
	if SPVisible == true then
		SongSelectScreen.MultiplayerInfo.PlayersInfo.PlayersWindow.CanvasSize = UDim2.new(0,0,0,80*#MPButtons + 180)
	else
		SongSelectScreen.MultiplayerInfo.PlayersInfo.PlayersWindow.CanvasSize = UDim2.new(0,0,0,80*#MPButtons)
	end
end

function CreateMPRoom(room) -- adds a room to the list of rooms on song select
	if CurrentRoom == nil then
		local room_ = room
		local suc, err = pcall(function()
			table.insert(MPRooms,room_)
			local ro = game.ReplicatedStorage.RoomPanel:Clone()
			ro.BackgroundColor3 = Color3.new(math.random(), math.random(), math.random())
			ro.RoomName.Text = room_.Value
			table.insert(MPButtons,ro)
			ro.MouseButton1Click:connect(function() SelectMPRoom(ro) end)
			if game.Players.LocalPlayer:GetRankInGroup(5863946) >= 251 then
				ro.CloseMulti.Visible = true
				ro.CloseMulti.MouseButton1Click:connect(function() ShutdownMPRoom(ro) end)
			end
			local timeout = 0
			repeat
				timeout = timeout + wait()
			until timeout >= 1 or room_:FindFirstChild("Players") ~= nil
			local ra = room_
			local pwl = ro:FindFirstChild("PasswordLocked")
			if pwl then
				if room_.Password.Value == "Enter Password" or room_.Password.Value == "" or room_.Password.Value == " " then
					pwl.Visible = false
				else
					pwl.Visible = true
				end
			end
			local suc, err = pcall(function()
				ro.Parent = SongSelectScreen.MultiplayerInfo.PlayersInfo.PlayersWindow
			end)
			if not suc then
				warn(err)
			end
			ra.Players.ChildAdded:connect(function() ChangedMPRoom(ra.Value) end)
			ra.Players.ChildRemoved:connect(function() ChangedMPRoom(ra.Value) end)
			ra.InGame.Changed:connect(function() ChangedMPRoom(ra.Value) end)
			ra.Changed:connect(ChangedMPRoom)
			ra.Password.Changed:connect(function() ChangedMPRoom(ra.Value) end)
			ra.SelectedSongIndex.Changed:connect(function() ChangedMPRoom(ra.Value) end)
			ra.SelectedSongRate.Changed:connect(function() ChangedMPRoom(ra.Value) end)
			ChangedMPRoom(ra.Value)
			PositionMPRooms()
		end)
		if not suc then
			warn(err)
		end
	end
end

function DeleteMPRoom(room)
	if CurrentRoom == nil then
		if SelectedRoom == room then
			SelectedRoom = nil
			SelectMPRoom(nil) -- todo: let player create a room if rooms dont exist
		end
		local index = 0
		for i=1, #MPRooms do
			if MPRooms[i] == room then
				index = i
			end
		end
		if index == 0 then
			DebugLog("ERROR: [DeleteMPRoom] "..room.Value.." doesn't exist")
		else
			table.remove(MPRooms,index)
			local ro = MPButtons[index]
			table.remove(MPButtons, index)
			ro:Destroy()
			PositionMPRooms()
		end
	end
end

function ChangedMPRoom(room)
	if CurrentRoom == nil then
		for i=1,#MPButtons do
			-- remove pcall later
			pcall(function()
				if MPRooms[i].InGame.Value == true then
					MPButtons[i].RoomName.Text = "[IN-GAME] "..MPRooms[i].Value
				else
					MPButtons[i].RoomName.Text = MPRooms[i].Value
				end

				if MPRooms[i].Password.Value ~= "Enter Password" and MPRooms[i].Password.Value ~= "" and MPRooms[i].Password.Value ~= " " then
					MPButtons[i].PasswordLocked.Visible = true
				else
					MPButtons[i].PasswordLocked.Visible = false
				end
				local ob = MPRooms[i].Players:GetChildren() 
				for j=1, 5 do
					if j <= #ob then
						MPButtons[i]["Player"..j].Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..ob[j].Value.UserId.."&width=420&height=420&format=png"
					else
						MPButtons[i]["Player"..j].Image = "http://www.roblox.com/asset/?id=724192650"
					end
				end

				if #ob > 5 then
					MPButtons[i].ExtraPlayers.Text = "+"..(#ob - 5)
				else
					MPButtons[i].ExtraPlayers.Text = ""
				end

				local curmap = maps[MPRooms[i].SelectedSongIndex.Value]
				if (MPRooms[i].SelectedSongRate.Value ~= 1) then
					MPButtons[i].SongName.Text = "Map: ["..MPRooms[i].SelectedSongRate.Value.."x]["..curmap.SongDiff.Value.."]"..curmap.Name		
				else
					MPButtons[i].SongName.Text = "Map: ["..curmap.SongDiff.Value.."]"..curmap.Name	
				end
			end)
		end
	elseif isHost == false and room == CurrentRoom.Value then
		if CurrentRoom.InGame.Value == true then
			SongSelectScreen.MultiplayerInfo.RoomCustomField.Text = room.." [IN-GAME]"
			SongSelectScreen.MultiplayerInfo.RoomInfo.Text = room.." [IN-GAME]"
		else
			SongSelectScreen.MultiplayerInfo.RoomCustomField.Text = room
			SongSelectScreen.MultiplayerInfo.RoomInfo.Text = room
		end
	end
end

function UpdateMPRoom()
	if CurrentRoom ~= nil then
		for i=1, #MPPanels do
			if SPVisible == true then
				if i <= SPPosition then
					MPPanels[i].Position = UDim2.new(0,0,0,40*(i-1))
				else
					MPPanels[i].Position = UDim2.new(0,0,0,40*(i-1) + 180)
				end
			else
				MPPanels[i].Position = UDim2.new(0,0,0,40*(i-1))
			end
			local sRating = 0
			if MPPlayers[i]:FindFirstChild("leaderstats") and MPPlayers[i]["leaderstats"]:FindFirstChild("Rating") then
				sRating = MPPlayers[i].leaderstats["Rating"].Value
			end
			MPPanels[i].PlayerImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..MPPlayers[i].Value.UserId.."&width=420&height=420&format=png"
			MPPanels[i].PlayerName.Text = MPPlayers[i].Value.Name .. " ["..string.format("%02.2f",sRating).."]"
			MPPanels[i].PlayerName.TextColor3 = GetTierColor(sRating) --todo get player rating
			if CurrentRoom.Players.Value.Name == MPPlayers[i].Value.Name then
				MPPanels[i].PlayerImage.Host.Visible = true
			else
				MPPanels[i].PlayerImage.Host.Visible = false
			end
			if SPVisible == true then
				SongSelectScreen.MultiplayerInfo.PlayersInfo.PlayersWindow.CanvasSize = UDim2.new(0,0,0,40 * #MPPanels + 195)
			else
				SongSelectScreen.MultiplayerInfo.PlayersInfo.PlayersWindow.CanvasSize = UDim2.new(0,0,0,40 * #MPPanels)
			end
		end
	end
end
--1533
function UpdateMPGameEnd()
	local newOrder = { }
	for i=1,#MPPlayers do
		table.insert(newOrder,{MPPlayers[i].Value.Score.Value,MPPlayers[i],MPPanels[i]})
	end	

	table.sort(newOrder, compare1)
	MPPlayers = {}
	MPPanels = {}

	for i=1,#newOrder do
		table.insert(MPPlayers, newOrder[i][2])
		table.insert(MPPanels, newOrder[i][3])
	end	
	if CurrentRoom ~= nil then
		for i=1,#MPPanels do
			if MPPlayers[i].Value ~= nil then
				MPPanels[i].PrevScore.Text = i..". "
					..string.format("%0.2f",MPPlayers[i].Value.Accuracy.Value).."% | "
					..MPPlayers[i].Value.MaxCombo.Value.."x | "
					..MPPlayers[i].Value.Marvelouses.Value.." / "
					..MPPlayers[i].Value.Perfects.Value.." / "
					..MPPlayers[i].Value.Greats.Value.." / "
					..MPPlayers[i].Value.Goods.Value.." / "
					..MPPlayers[i].Value.Okays.Value.." / "
					..MPPlayers[i].Value.Misses.Value
			end
		end
	end

	MoveScorePanel(0, Player)
end

function compare1(a,b)
	return a[1] > b[1]
end

function CreateMPPlayer(player, dpsound)
	if dpsound == nil or dpsound == false then
		PlaySound("Joined")
	end
	local ob = game.ReplicatedStorage.PlayerPanel:Clone()
	ob.Parent = SongSelectScreen.MultiplayerInfo.PlayersInfo.PlayersWindow
	ob.Position = UDim2.new(0,0,0,40*#MPPlayers)
	ob.MouseButton1Click:connect(function() SelectMPPlayer(ob) end)
	table.insert(MPPlayers, player)
	table.insert(MPPanels, ob)
	UpdateMPRoom(CurrentRoom.Players)
	InfoLog("Player has joined room: "..player.Value.Name)
end

function DeleteMPPlayer(player)
	local index = 0
	for i=1,#MPPlayers do
		if MPPlayers[i] == player then
			index = i
		end
	end

	PlaySound("Left")
	if player == SelectedPlayer then
		SelectedPlayer = nil
	end

	if index ~= 0 and CurrentRoom then
		MPPanels[index]:Destroy()
		table.remove(MPPanels, index)
		table.remove(MPPlayers, index)
		if CurrentRoom.Players.Value == Player then
			isHost = true
			SongSelectScreen.PlayButton.BackgroundColor3 = Color3.new(0,1,0)
			SongSelectScreen.MultiplayerInfo.PlayersInfo.TransferHostButton.BackgroundColor3 = Color3.new(0,1,0)
			SongSelectScreen.MultiplayerInfo.PlayersInfo.KickButton.BackgroundColor3 = Color3.new(1,0,0)
			SongSelectScreen.SongSelection.SongButtonContainer.BackgroundColor3 = Color3.new(0,0,0)
			SongSelectScreen.MultiplayerInfo.RoomCustomField.Visible = true
			SongSelectScreen.MultiplayerInfo.RoomInfo.Visible = false
		end
	else
		InfoLog("Error CS123: Whoops, looks like the player doesn't exist anymore..? Creepy, huh?")
	end
	if CurrentRoom ~= nil then
		if player.Value == Player and already_left_room == false then
			ImportantNotification("You were kicked from the room.")
			LeaveMPRoom()
			already_left_room = true
		else
			UpdateMPRoom(CurrentRoom.Players)
			InfoLog("Player has left room: "..player.Value.Name)
		end
	end
end

function SelectMPPlayer(player)
	if ButtonCooldown == false then
		ButtonCooldown = true
		local index = 0
		for i=1, #MPPlayers do
			if MPPanels[i] == player then
				index = i
			end
		end
		if index ~= 0 then
			PlaySound("Click")
			if SelectedPlayer ~= nil and MPPlayers[index].Value.Name == SelectedPlayer.Value.Name then
				MPPanels[index].BorderSizePixel = 0
				UpdateScorePanel(false)
			else
				for i=1, #MPPanels do
					MPPanels[i].BorderSizePixel = 0
				end
				SelectedPlayer = MPPlayers[index]
				MPPanels[index].BorderSizePixel = 2
				MoveScorePanel(index, SelectedPlayer.Value)
			end
		end
		wait(0.25)
		ButtonCooldown = false
	end
end

function KickMPPlayer()
	if SelectedPlayer ~= nil and SelectedPlayer.Value ~= Player and isHost and CurrentRoom ~= nil then
		PlaySound("Tap")
		InfoLog("You kicked "..SelectedPlayer.Name.." from the game")
		events[10]:InvokeServer(CurrentRoom, SelectedPlayer.Value)
	else
		PlaySound("Error")
		SelectedPlayer = nil
	end
end

function TransferMPPlayer()
	if SelectedPlayer ~= nil and SelectedPlayer.Value.Name ~= Player.Name and isHost and CurrentRoom ~= nil then
		isHost = false
		SongSelectScreen.PlayButton.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
		SongSelectScreen.MultiplayerInfo.PlayersInfo.TransferHostButton.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
		SongSelectScreen.MultiplayerInfo.PlayersInfo.KickButton.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
		SongSelectScreen.SongSelection.SongButtonContainer.BackgroundColor3 = Color3.new(1,1,0)
		SongSelectScreen.MultiplayerInfo.RoomCustomField.Visible = false
		SongSelectScreen.MultiplayerInfo.RoomInfo.Visible = true
		events[11]:InvokeServer(CurrentRoom, SelectedPlayer.Value)
		PlaySound("Tap")
		UpdateMPRoom(CurrentRoom.Players)
	else
		PlaySound("Error")
	end
end

function HostChangedMPPlayer(player)
	if player.Name == Player.Name then
		SongSelectScreen.MultiplayerInfo.RoomCustomField.Visible = true
		SongSelectScreen.MultiplayerInfo.RoomInfo.Visible = false
		SongSelectScreen.MultiplayerInfo.PlayersInfo.PasswordInput.Text = CurrentRoom.Password.Value
		isHost = true
		SongSelectScreen.PlayButton.BackgroundColor3 = Color3.new(0,1,0)
		SongSelectScreen.MultiplayerInfo.PlayersInfo.TransferHostButton.BackgroundColor3 = Color3.new(0,1,0)
		SongSelectScreen.MultiplayerInfo.PlayersInfo.KickButton.BackgroundColor3 = Color3.new(1,0,0)
		SongSelectScreen.SongSelection.SongButtonContainer.BackgroundColor3 = Color3.new(0,0,0)
		PlaySound("Tap")
	end
	UpdateMPRoom(CurrentRoom.Players)
end

function JoinLeaveButtonClicked()
	if ButtonCooldown == false then
		ButtonCooldown = true
		if CurrentRoom == nil and SelectedRoom ~= 0 then
			JoinMPRoom()
			already_left_room = false
		elseif CurrentRoom ~= nil then
			already_left_room = true
			events[7]:InvokeServer(CurrentRoom)
			LeaveMPRoom()
		else
			BuildMPRoom()
		end
		wait(0.25)
		ButtonCooldown = false
	end
end
```