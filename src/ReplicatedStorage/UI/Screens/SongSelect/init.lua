local Roact = require(game.ReplicatedStorage.Packages.Roact)
local Llama = require(game.ReplicatedStorage.Packages.Llama)
local RoactRodux = require(game.ReplicatedStorage.Packages.RoactRodux)
local e = Roact.createElement

local RunService = game:GetService("RunService")

local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)
local Mods = require(game.ReplicatedStorage.RobeatsGameCore.Enums.Mods)

local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)

local Actions = require(game.ReplicatedStorage.Actions)

local Trove = require(game.ReplicatedStorage.Packages.Trove)

local withInjection = require(game.ReplicatedStorage.UI.Components.HOCs.withInjection)

local RoundedTextButton = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextButton)
local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)
local ButtonLayout = require(game.ReplicatedStorage.UI.Components.Base.ButtonLayout)

local SongInfoDisplay = require(script.SongInfoDisplay)
local SongList = require(script.SongList)
local Leaderboard = require(script.Leaderboard)
local ModSelection = require(script.ModSelection)

local SongSelect = Roact.Component:extend("SongSelect")

function SongSelect:init()
    self.scoreService = self.props.scoreService
    self.previewController = self.props.previewController

    self:setState({
        modSelectionVisible = false,
        filterByRate = false,
        songListRobloxInstance = nil -- Used for scrolling frame manipulation
    })

    self.Trove = Trove.new()

    self.uprate = function()
        if self.props.options.SongRate < 200 then
            self.props.setSongRate(self.props.options.SongRate + 5)
        end
    end

    self.downrate = function()
        if self.props.options.SongRate > 5 then
            self.props.setSongRate(self.props.options.SongRate - 5)
        end
    end

    local onUprateKeyPressed = SPUtil:bind_to_key(Enum.KeyCode.Equals, self.uprate)
    local onDownrateKeyPressed = SPUtil:bind_to_key(Enum.KeyCode.Minus, self.downrate)

    local onOptionsKeyPressed = SPUtil:bind_to_key_combo({Enum.KeyCode.O, Enum.KeyCode.LeftControl}, function()
        self.props.history:push("/options")
    end)

    self.Trove:Add(onUprateKeyPressed)
    self.Trove:Add(onDownrateKeyPressed)
    self.Trove:Add(onOptionsKeyPressed)
end

function SongSelect:onPlay()
    if self.props.location.state.roomId then
        self.props.multiplayerService:SetSongKey(self.props.location.state.roomId, self.props.options.SongKey)
        self.props.multiplayerService:SetSongRate(self.props.location.state.roomId, self.props.options.SongRate)
        self.props.history:goBack()
    else
        self.props.history:push("/play")
    end
end

function SongSelect:render()
    return e(RoundedFrame, {

    }, {
        SongInfoDisplay = e(SongInfoDisplay, {
            Size = UDim2.fromScale(0.985, 0.2),
            Position = UDim2.fromScale(0.01, 0.01),
            SongKey = self.props.options.SongKey,
            SongRate = self.props.options.SongRate,
            OnUprate = self.uprate,
            OnDownrate = self.downrate
        }),
        SongList = e(SongList, {
            Size = UDim2.fromScale(0.64, 0.77),
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.fromScale(0.995, 0.985),
            OnSongSelected = function(key)
                if self.props.options.SongKey == key then
                    self:onPlay()
                else
                    self.props.setSongKey(key)
                end
            end,
            SelectedSongKey = self.props.options.SongKey
        }),
        Leaderboard = e(Leaderboard, {
            Size = UDim2.fromScale(0.325, 0.665),
            Position = UDim2.fromScale(0.02, 0.255),
            SongKey = self.props.options.SongKey,
            SongRate = self.state.filterByRate and self.props.options.SongRate or nil,
            IsAdmin = self.props.permissions.isAdmin,
            OnLeaderboardSlotClicked = function(stats)
                if self.props.location.state.roomId then
                    return
                end

                local _, hits = self.scoreService:GetGraph(stats.UserId, stats.SongMD5Hash)
                    :await()

                self.props.history:push("/results", Llama.Dictionary.join(stats, {
                    SongKey = SongDatabase:get_key_for_hash(stats.SongMD5Hash),
                    TimePlayed = if stats._updated_at then DateTime.fromIsoDate(stats._updated_at).UnixTimestamp else nil,
                    Hits = hits,
                    Viewing = true
                }))
            end,
            OnDelete = function(id)
                self.props.history:push("/moderation/delete", {
                    scoreId = id
                })
            end,
            OnBan = function(userId, playerName)
                self.props.history:push("/moderation/ban", {
                    userId = userId,
                    playerName = playerName
                })
            end
        }),
        ButtonContainer = e(ButtonLayout, {
            Size = UDim2.fromScale(0.3325, 0.042),
            Position = UDim2.fromScale(0.02, 0.975),
            AnchorPoint = Vector2.new(0, 1),
            Padding = UDim.new(0, 8),
            MaxTextSize = 14,
            DefaultSpace = 4,
            Buttons = {
                {
                    Text = self.props.location.state.roomId and "Select" or "Play",
                    Color = self.props.location.state.roomId and Color3.fromRGB(50, 77, 94) or Color3.fromRGB(8, 153, 32),
                    OnClick = function()
                        self:onPlay()
                    end
                },
                {
                    Text = "Options",
                    Color = Color3.fromRGB(37, 37, 37),
                    OnClick = function()
                        if not self.props.location.state.OptionsVisible then
                            self.props.history:push("/select", {
                                OptionsVisible = true
                            })
                        end
                    end
                },
                {
                    Text = "Mods",
                    Color = Color3.fromRGB(33, 126, 83),
                    OnClick = function()
                        self:setState({
                            modSelectionVisible = not self.state.modSelectionVisible
                        })
                    end
                },
                if not self.props.location.state.roomId then {
                    Text = "Main Menu",
                    Color = Color3.fromRGB(37, 37, 37),
                    OnClick = function()
                        self.props.history:push("/")
                    end
                } else nil
            }
        }),
        ModSelection = e(ModSelection, {
            ActiveMods = self.props.options.Mods,
            OnModSelected = function(mods)
                self.props.setMods(mods)
            end,
            Visible = self.state.modSelectionVisible,
            OnBackClicked = function()
                self:setState({
                    modSelectionVisible = false
                })
            end
        }),
        ShowOnlyCurrentRate = Roact.createElement(RoundedTextButton, {
            BackgroundColor3 = self.state.filterByRate and Color3.fromRGB(41, 176, 194) or Color3.fromRGB(41, 41, 41),
            Position = UDim2.fromScale(0.02, 0.25),
            Size = UDim2.fromScale(0.14, 0.035),
            HoldSize = UDim2.fromScale(0.14, 0.035),
            AnchorPoint = Vector2.new(0, 1),
            TextScaled = true,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Text = "Show Only Current Rate",
            OnClick = function()
                self:setState({
                    filterByRate = not self.state.filterByRate
                })
            end
        }, {
            UITextSizeConstraint = e("UITextSizeConstraint", {
                MaxTextSize = 13
            })
        })
    })
end

function SongSelect:didMount()
    self.previewController:PlayId(SongDatabase:get_data_for_key(self.props.options.SongKey).AudioAssetId, function(audio)
        audio.TimePosition = audio.TimeLength * 0.33
    end, 0.5, true)
end

function SongSelect:didUpdate(oldProps)
    if self.props.options.SongKey ~= oldProps.options.SongKey then
        self.previewController:PlayId(SongDatabase:get_data_for_key(self.props.options.SongKey).AudioAssetId, function(audio)
            audio.TimePosition = audio.TimeLength * 0.33
        end)
    end

    if self.props.options.SongRate ~= oldProps.options.SongRate then
        self.previewController:SetRate(self.props.options.SongRate / 100)
    end
end

function SongSelect:willUnmount()
    self.previewController:Silence()
    self.Trove:Destroy()
end

local Injected = withInjection(SongSelect, {
    scoreService = "ScoreService",
    previewController = "PreviewController",
    multiplayerService = "MultiplayerService"
})

return RoactRodux.connect(function(state, props)
    return {
        options = Llama.Dictionary.join(state.options.persistent, state.options.transient),
        permissions = state.permissions
    }
end, function(dispatch)
    return {
        setSongKey = function(songKey)
            dispatch(Actions.setTransientOption("SongKey", songKey))
        end,
        setSongRate = function(songRate)
            dispatch(Actions.setTransientOption("SongRate", songRate))
        end,
        setMods = function(mods)
            dispatch(Actions.setTransientOption("Mods", mods))
        end
    }
end)(Injected)