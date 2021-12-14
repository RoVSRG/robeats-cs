local Roact = require(game.ReplicatedStorage.Packages.Roact)
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
	
	self.backOutConnection = SPUtil:bind_to_key(Enum.KeyCode.Return, function()
		self.props.history:push("/select")
	end)
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

	local moment = DateTime.fromUnixTimestamp(state.TimePlayed):ToLocalTime()

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
			Position = UDim2.fromScale(0.832, 0.609),
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
			points = hits;
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
			Position = UDim2.fromScale(0.555, 0.609),
			Size = UDim2.fromScale(0.279, 0.305),
			Marvelouses = state.Marvelouses,
			Perfects = state.Perfects,
			Greats = state.Greats,
			Goods = state.Goods,
			Bads = state.Bads,
			Misses = state.Misses
		}),
		DataDisplay = Roact.createElement(DataDisplay, {
			data = {
				{
					Name = "Score";
					Value = string.format("%d", state.Score);
				};
				{
					Name = "Accuracy";
					Value = string.format("%0.2f%%", state.Accuracy);
				};
				{
					Name = "Rating";
					Value = string.format("%0.2f", state.Rating);
				};
				{
					Name = "Max Combo";
					Value = state.MaxChain
				};
				{
					Name = "Mean";
					Value = string.format("%0d ms", mean);
				};
			};
			Position = UDim2.fromScale(0.696, 0.34);
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
			Image = self.gradeImages[grade] or "http://www.roblox.com/asset/?id=168702873",
		}, {
			UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 1
			})
		}),
		PlayedAt = Roact.createElement(RoundedTextLabel, {
			Position = UDim2.fromScale(0.787, 0.306),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.728, 0.046),
			RichText = true,
			Text = string.format("Played by %s at %d:%02d:%02d %d/%d/%02d", state.PlayerName, moment.Hour, moment.Minute, moment.Second, moment.Month, moment.Day, moment.Year),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(218, 218, 218),
			BackgroundTransparency = 1,
			TextScaled = true
		}, {
			UITextSizeConstraint = Roact.createElement("UITextSizeConstraint", {
				MaxTextSize = 25
			})
		}),
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
				self.props.history:push("/select")
			end
		})
	})
end

return Results
