local ProximityPromptService = game:GetService("ProximityPromptService")
local Roact = require(game.ReplicatedStorage.Packages.Roact)
local RoactRodux = require(game.ReplicatedStorage.Packages.RoactRodux)
local Llama = require(game.ReplicatedStorage.Packages.Llama)
local e = Roact.createElement

local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)

local RunService = game:GetService("RunService")

local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)

local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local Grade = require(game.ReplicatedStorage.RobeatsGameCore.Enums.Grade)

local RoundedTextButton = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextButton)
local RoundedTextLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextLabel)
local RoundedImageLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedImageLabel)

local Results = Roact.Component:extend("Results")

local DotGraph = require(game.ReplicatedStorage.UI.Components.Graph.DotGraph)
local SpreadDisplay = require(script.SpreadDisplay)
local DataDisplay = require(script.DataDisplay)
local SongInfoDisplay = require(game.ReplicatedStorage.UI.Screens.SongSelect.SongInfoDisplay)
local PlayerSelection = require(script.PlayerSelection)
local Ranking = require(script.Ranking)

function noop() end


function Results:init()
	if RunService:IsRunning() then
		self.knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
	end

	self.gradeImages = {
		[Grade.SS] = "http://www.roblox.com/asset/?id=5702584062",
		[Grade.S] = "http://www.roblox.com/asset/?id=5856075566",
		[Grade.A] = "http://www.roblox.com/asset/?id=5856075367",
		[Grade.B] = "http://www.roblox.com/asset/?id=5856075113",
		[Grade.C] = "http://www.roblox.com/asset/?id=5856074951",
		[Grade.D] = "http://www.roblox.com/asset/?id=5896147796",
		[Grade.F] = "http://www.roblox.com/asset/?id=5896148143"
	}
	
	self.backOutConnection = SPUtil:bind_to_key(Enum.KeyCode.Tilde, function()
		if self.props.location.state.Match then
			return
		end

		if self.props.location.state.goToMultiSelect then
			self.props.history:push("/multiplayer")
			return
		end
		self.props.history:goBack()
	end)
end

function Results:didUpdate(prevProps)
	if self.props.room and (prevProps.inProgress ~= self.props.inProgress) and self.props.inProgress then
		self.props.history:push("/play", {
            roomId = self.props.location.state.RoomId
        })
	end
end

function Results:didMount()
	if self.knit then
		local PreviewController = self.knit.GetController("PreviewController")

		PreviewController:PlayId("rbxassetid://6419511015", function(audio)
			audio.TimePosition = 0
		end, 0.12)
	end
end

function Results:willUnmount()
	self.backOutConnection:Disconnect()
end

function Results:render()
	local state = self.props.location.state

	local grade = Grade:get_grade_from_accuracy(state.Accuracy)

	local hits = state.Hits or {}
	local mean = state.Mean or 0

	local moment = if state.TimePlayed then DateTime.fromUnixTimestamp(state.TimePlayed):ToLocalTime() else nil

	local playerSelection

	local room = self.props.room

	if room then
		playerSelection = e(PlayerSelection, {
			Players = room.players,
			SelectedPlayer = self.state.selectedScoreUserId,
			OnPlayerSelected = function(id)
				self:setState({
					selectedScoreUserId = id
				})
			end
		})
	end

	local scoreData

	if self.state.selectedScoreUserId and self.state.selectedScoreUserId ~= (game.Players.LocalPlayer and game.Players.LocalPlayer.UserId or 0) and room.players[tostring(self.state.selectedScoreUserId)] then
		local player = room.players[tostring(self.state.selectedScoreUserId)]

		scoreData = {
			score = player.score,
			rating = player.rating,
			accuracy = player.accuracy,
			marvelouses = player.marvelouses,
			perfects = player.perfects,
			greats = player.greats,
			goods = player.goods,
			bads = player.bads,
			misses = player.misses,
			mean = player.mean,
			maxChain = player.maxChain,
			playerName = player.player.Name,
			hits = player.hits
		}
	else
		scoreData = {
			score = state.Score,
			rating = state.Rating,
			accuracy = state.Accuracy,
			marvelouses = state.Marvelouses,
			perfects = state.Perfects,
			greats = state.Greats,
			goods = state.Goods,
			bads = state.Bads,
			misses = state.Misses,
			mean = state.Mean,
			maxChain = state.MaxChain,
			playerName = state.PlayerName
		}
	end

	scoreData.grade = Grade:get_grade_from_accuracy(scoreData.accuracy)

	scoreData.hits = scoreData.hits or state.Hits or {}

	local viewing = self.props.location.state.Viewing

    return Roact.createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(0,0,0),
		BorderSizePixel = 0;
		Size = UDim2.new(1, 0, 1, 0);
	}, {
		SongInfoDisplay = e(SongInfoDisplay, {
            Size = UDim2.fromScale(0.985, 0.2),
            Position = UDim2.fromScale(0.01, 0.01),
			BackgroundColor3 = Color3.fromRGB(10, 10, 10),
            SongKey = state.SongKey,
            SongRate = state.Rate,
			ShowRateButtons = false
        }),
		HitGraph = Roact.createElement(DotGraph, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(22, 22, 22),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.832, 0.609 - (if not viewing then 0.05 else 0)),
			Size = UDim2.fromScale(0.279, 0.305),
			bounds = {
				min = {
					y = -350;
				};
				max = {
					y = 350;
				}
			};
			interval = {
				y = 50;
			};
			points = scoreData.hits;
			formatPoint = function(hit)
				return {
					x = (hit.hit_object_time + hit.time_left) / (SongDatabase:get_song_length_for_key(state.SongKey, state.Rate / 100) + 3300),
					y = SPUtil:inverse_lerp(-300, 300, hit.time_left),
					color = NoteResult:result_to_color(hit.judgement)
				}
			end
		}),
		SpreadDisplay = Roact.createElement(SpreadDisplay, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.555, 0.609 - (if not viewing then 0.05 else 0)),
			Size = UDim2.fromScale(0.279, 0.305),
			Marvelouses = scoreData.marvelouses,
			Perfects = scoreData.perfects,
			Greats = scoreData.greats,
			Goods = scoreData.goods,
			Bads = scoreData.bads,
			Misses = scoreData.misses
		}),
		DataDisplay = Roact.createElement(DataDisplay, {
			data = {
				{
					Name = "Score";
					Value = string.format("%d", scoreData.score);
				};
				{
					Name = "Accuracy";
					Value = string.format("%0.2f%%", scoreData.accuracy);
				};
				{
					Name = "Rating";
					Value = string.format("%0.2f", scoreData.rating);
				};
				{
					Name = "Max Combo";
					Value = scoreData.maxChain
				};
				{
					Name = "Mean";
					Value = string.format("%0d ms", scoreData.mean);
				};
			};
			Position = UDim2.fromScale(0.696, 0.34 - (if not viewing then 0.05 else 0));
			Size = UDim2.fromScale(0.551, 0.09);
			AnchorPoint = Vector2.new(0.5,0);
		});
		Grade = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.2, 0.522),
			Selectable = true,
			Size = UDim2.fromScale(0.331, 0.605),
			Image = self.gradeImages[scoreData.grade] or "http://www.roblox.com/asset/?id=168702873",
		}, {
			UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 1
			})
		}),
		PlayedAt = if moment then Roact.createElement(RoundedTextLabel, {
			Position = UDim2.fromScale(0.787, 0.306 - (if not viewing then 0.05 else 0)),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.728, 0.046),
			RichText = true,
			Text = string.format("Played by %s at %d:%02d:%02d %d/%d/%02d", scoreData.playerName, moment.Hour, moment.Minute, moment.Second, moment.Month, moment.Day, moment.Year),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(218, 218, 218),
			BackgroundTransparency = 1,
			TextScaled = true
		}, {
			UITextSizeConstraint = Roact.createElement("UITextSizeConstraint", {
				MaxTextSize = 25
			})
		}) else nil,
		Background = Roact.createElement(RoundedImageLabel, {
			Position = UDim2.fromScale(1, 0),
			AnchorPoint = Vector2.new(1, 0),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 0,
			Image = "rbxassetid://6803695820",
			ZIndex = 0,
			ScaleType = Enum.ScaleType.Crop
		}, {
			UIGradient = Roact.createElement("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, .75),
					NumberSequenceKeypoint.new(0.5, 0.75),
					NumberSequenceKeypoint.new(1, 0),
				})
			})
		}),


		GoBack = Roact.createElement(RoundedTextButton, {
			BackgroundColor3 = Color3.fromRGB(236, 33, 33);
			AnchorPoint = Vector2.new(0, 1);
			Position = UDim2.fromScale(0.0135, 0.98);
			Size = UDim2.fromScale(0.15,0.065);
			HoldSize = UDim2.fromScale(0.14, 0.065);
			Text = "Return to Menu";
			TextColor3 = Color3.fromRGB(255, 255, 255);
			TextSize = 16,
			ZIndex = 5,
			OnClick = function()
				if room then
					self.props.history:push("/room", {
						roomId = state.RoomId,
						goToMultiSelect = true
					})
				else
					self.props.history:push("/select")
				end
			end
		});

		RestartMap = if (not viewing and not room) then Roact.createElement(RoundedTextButton, {
			BackgroundColor3 = Color3.fromRGB(50, 144, 50);
			AnchorPoint = Vector2.new(0, 1);
			Position = UDim2.fromScale(0.175, 0.98);
			Size = UDim2.fromScale(0.15,0.065);
			HoldSize = UDim2.fromScale(0.14, 0.065);
			Text = "Restart Map";
			TextColor3 = Color3.fromRGB(255, 255, 255);
			TextSize = 16,
			ZIndex = 5,
			OnClick = function()
				self.props.history:push("/play")
			end
		}) else nil,

		Ranking = if (self.props.profile and not viewing and not room) then Roact.createElement(Ranking, {
			Rating = self.props.profile.Rating,
			Position = UDim2.fromScale(0.6, 0.95),
			Size = UDim2.fromScale(0.5, 0.2),
			AnchorPoint = Vector2.new(0.5, 1)
		}) else nil,

		PlayerSelection = playerSelection
	})
end

return RoactRodux.connect(function(state, props)
	local roomId = props.location.state.RoomId
	local room = if roomId then state.multiplayer.rooms[roomId] else nil

	return {
		profile = state.profiles[tostring(game.Players.LocalPlayer.UserId)],
		roomId = roomId,
		room = room,
		inProgress = if room then room.inProgress else nil,
	}
end)(Results)
