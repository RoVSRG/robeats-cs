local Roact = require(game.ReplicatedStorage.Packages.Roact)
local RoactRodux = require(game.ReplicatedStorage.Packages.RoactRodux)
local Llama = require(game.ReplicatedStorage.Packages.Llama)
local e = Roact.createElement

local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local RobeatsGame = require(game.ReplicatedStorage.RobeatsGameCore.RobeatsGame)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local GameSlot = require(game.ReplicatedStorage.RobeatsGameCore.Enums.GameSlot)
local Rating = require(game.ReplicatedStorage.RobeatsGameCore.Enums.Rating)
local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local NoteResult= require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)

local Leaderboard = require(script.Leaderboard)
local StatCard = require(script.StatCard)

local AnimatedNumberLabel = require(game.ReplicatedStorage.UI.Components.Base.AnimatedNumberLabel)
local RoundedTextLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextLabel)
local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)
local RoundedTextButton = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextButton)
local LoadingWheel = require(game.ReplicatedStorage.UI.Components.Base.LoadingWheel)

local ComboPositions = require(game.ReplicatedStorage.ComboPositions)
local LeaderboardPositions = require(game.ReplicatedStorage.LeaderboardPositions)

local withHitDeviancePoint = require(script.Decorators.withHitDeviancePoint)

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local Lighting = game:GetService("Lighting")

local Gameplay = Roact.Component:extend("Gameplay")

Gameplay.SpreadString = "<font color=\"rgb(125, 125, 125)\">%d</font> <font color=\"rgb(55, 55, 55)\">/</font> <font color=\"rgb(99, 91, 15)\">%d</font> <font color=\"rgb(55, 55, 55)\">/</font> <font color=\"rgb(23, 99, 15)\">%d</font> <font color=\"rgb(55, 55, 55)\">/</font> <font color=\"rgb(15, 39, 99)\">%d</font> <font color=\"rgb(55, 55, 55)\">/</font> <font color=\"rgb(91, 15, 99)\">%d</font> <font color=\"rgb(55, 55, 55)\">/</font> <font color=\"rgb(99, 15, 21)\">%d</font> | %0.1f M/P"

function Gameplay:init()
    -- Get the score service
    
    local ScoreService = Knit.GetService("ScoreService")
    
    -- Set gameplay state
    
    self:setState({
        accuracy = 0,
        score = 0,
        chain = 0,
        marvelouses = 0,
        perfects = 0,
        greats = 0,
        goods = 0,
        bads = 0,
        misses = 0,
        loaded = false
    })
    
    -- Set up time left bib
    
    self.timeLeft, self.setTimeLeft = Roact.createBinding(0)
    
    -- Set up hit deviance parent reference
    
    self.hitDevianceRef = Roact.createRef()
    
    if not self.props.options.Use2DLane then
        local stagePlat = EnvironmentSetup:get_element_protos_folder().NoteTrackSystemProto.TrackBG.Union
        stagePlat.Transparency = self.props.options.BaseTransparency
    end
    
    -- Set FOV and Time of Day
    
    workspace.CurrentCamera.FieldOfView = self.props.options.FOV
    Lighting.TimeOfDay = self.props.options.TimeOfDay
    
    -- Turn PlayerList & Chat off
    game.StarterGui:SetCoreGuiEnabled("PlayerList", not self.props.options.HidePlayerList)
    game.StarterGui:SetCoreGuiEnabled("Chat", not self.props.options.HideChat)

    EnvironmentSetup:set_gui_inset(true);
    
    -- 2D Properties
    local use_upscroll = self.props.options.Upscroll
    local lane_2d = self.props.options.Use2DLane
    
    -- Create the game instance
    
    local _game = RobeatsGame:new(EnvironmentSetup:get_game_environment_center_position())
    _game._input:set_keybinds({
        (lane_2d and use_upscroll) and self.props.options.Keybind4 or self.props.options.Keybind1,
        (lane_2d and use_upscroll) and self.props.options.Keybind3 or self.props.options.Keybind2,
        (lane_2d and use_upscroll) and self.props.options.Keybind2 or self.props.options.Keybind3,
        (lane_2d and use_upscroll) and self.props.options.Keybind1 or self.props.options.Keybind4
    })
    _game:set_hit_lighting(self.props.options.HitLighting)
    _game:set_ln_tails(self.props.options.HideLNTails)
    _game:set_judgement_visibility(self.props.options.JudgementVisibility)
    _game:set_note_color(self.props.options.NoteColor)
    _game:set_ln_transparent(self.props.options.TransparentHeldNote)
    _game:set_2d_mode(lane_2d)
    if lane_2d then
        _game:set_upscroll_mode(self.props.options.Upscroll);
    end
    
    -- Load the map
    
    _game:load(self.props.options.SongKey, GameSlot.SLOT_1, self.props.options)
    
    -- Bind the game loop to every frame
    
    self.everyFrameConnection = SPUtil:bind_to_frame(function(dt)
        if _game._audio_manager:get_just_finished() then
            _game:set_mode(RobeatsGame.Mode.GameEnded)
        end
        
        -- Handle starting the game if the audio and its data has loaded!
        
        if _game._audio_manager:is_ready_to_play() and not self.state.loaded then
            self:setState({
                loaded = true
            })
            _game:start_game()
        end
        
        -- If we have reached the end of the game, trigger cleanup
        
        if _game:get_mode() == RobeatsGame.Mode.GameEnded then
            self.everyFrameConnection:Disconnect()
            
            local marvelouses, perfects, greats, goods, bads, misses, maxChain = _game._score_manager:get_end_records()
            local hits = _game._score_manager:get_hits()
            local mean = _game._score_manager:get_mean()
            local rating = Rating:get_rating_from_song_key(self.props.options.SongKey, self.state.accuracy, self.props.options.SongRate / 100)
            
            if (not self.forcedQuit) and (self.props.options.TimingPreset == "Standard") then
                local md5Hash = SongDatabase:get_md5_hash_for_key(self.props.options.SongKey)
                ScoreService:SubmitScore(
                    md5Hash,
                    rating,
                    self.state.score,
                    marvelouses,
                    perfects,
                    greats,
                    goods,
                    bads,
                    misses,
                    self.state.accuracy,
                    maxChain,
                    mean,
                    self.props.options.SongRate,
                    self.props.options.Mods)
                    :andThen(function()
                        local moment = DateTime.now():ToLocalTime()
                        DebugOut:puts("Score submitted at %d:%d:%d", moment.Hour, moment.Minute, moment.Second)
                    end)
                    :andThen(function()
                        ScoreService:SubmitGraph(md5Hash, hits)
                    end)
            end

            self.props.history:push("/results", {
                Score = self.state.score,
                Accuracy = self.state.accuracy,
                Marvelouses = marvelouses,
                Perfects = perfects,
                Greats = greats,
                Goods = goods,
                Bads = bads,
                Misses = misses,
                MaxChain = maxChain,
                Hits = hits,
                Mean = mean,
                Rating = rating,
                SongKey = self.props.options.SongKey,
                PlayerName = game.Players.LocalPlayer.DisplayName,
                Rate = self.props.options.SongRate,
                TimePlayed = DateTime.now().UnixTimestamp
            })
            return
        end

        local dt_scale = CurveUtil:DeltaTimeToTimescale(dt)
        _game:update(dt_scale)

        self.setTimeLeft(_game._audio_manager:get_song_length_ms() - _game._audio_manager:get_current_time_ms())
    end)

    -- Hook into onStatsChanged to monitor when stats change in ScoreManager

    self.onStatsChangedConnection = _game._score_manager:get_on_change():Connect(function(...)
        local args = {...}

        local hit = args[10]

        if hit then
            local bar = Instance.new("Frame")
            bar.AnchorPoint = Vector2.new(0.5, 0)
            bar.Position = UDim2.fromScale(SPUtil:inverse_lerp(150, -150, hit.time_left), 0)
            bar.Size = UDim2.fromScale(0.005, 1)
            bar.BorderSizePixel = 0
            bar.ZIndex = 20
            bar.BackgroundTransparency = 1
            bar.BackgroundColor3 = NoteResult:result_to_color(hit.judgement)

            bar.Parent = self.hitDevianceRef:getValue()

            withHitDeviancePoint(bar)
        end

        self:setState({
            score = _game._score_manager:get_score(),
            accuracy = _game._score_manager:get_accuracy() * 100,
            chain = _game._score_manager:get_chain(),
            marvelouses = args[1],
            perfects = args[2],
            greats = args[3],
            goods = args[4],
            bads = args[5],
            misses = args[6]
        })
    end)

    -- Expose the game instance to the rest of the component

    self._game = _game
end

function Gameplay:render()
    if not self.state.loaded then
        return Roact.createFragment({
            LoadingWheel = e(LoadingWheel, {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.fromScale(0.39, 0.5),
                Size = UDim2.fromScale(0.07, 0.07)
            }),
            LoadingText = e(RoundedTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.54, 0.5),
                Size = UDim2.fromScale(0.2, 0.2),
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 20,
                Text = "Please wait for the game to load..."
            }),
            Back = e(RoundedTextButton, {
                Size = UDim2.fromScale(0.1, 0.05),
                AnchorPoint = Vector2.new(0.5, 0.5),
                HoldSize = UDim2.fromScale(0.08, 0.05),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundColor3 = Color3.fromRGB(230, 19, 19),
                HighlightBackgroundColor3 = Color3.fromRGB(187, 53, 53),
                Position = UDim2.fromScale(0.5, 0.68),
                Text = "Back out",
                OnClick = function()
                    self.forcedQuit = true
                    self._game:set_mode(RobeatsGame.Mode.GameEnded)
                end
            })
        })
    end

    local laneCoverY
    local laneCoverPosY
    local laneCoverRotation

    if self.props.options.LaneCover > 0 then
        laneCoverY = SPUtil:lerp(0.32, 0.8, self.props.options.LaneCover / 100)

        if self.props.options.Use2DLane and self.props.options.Upscroll then
            laneCoverPosY = 0.6
            laneCoverRotation = 180
        else
            laneCoverPosY = 0
            laneCoverRotation = 0
        end
    else
        laneCoverY = 0
        laneCoverPosY = 0
        laneCoverRotation = 0
    end

    local leaderboard

    if not self.props.options.HideLeaderboard then
        leaderboard = e(Leaderboard, {
            SongKey = self.props.options.SongKey,
            LocalRating = Rating:get_rating_from_song_key(self.props.options.SongKey, self.state.accuracy, self.props.options.SongRate / 100),
            LocalAccuracy = self.state.accuracy,
            Position = LeaderboardPositions[self.props.options.InGameLeaderboardPosition]
        })
    end

    local statCardPosition = UDim2.fromScale(0.7, 0.2)

    if self.props.options.Use2DLane then
        statCardPosition =  UDim2.fromScale((self.props.options.PlayfieldWidth / 100 / 2) + 0.53, 0.2)
    end

    return Roact.createFragment({
        Score = e(AnimatedNumberLabel, {
            Size = UDim2.fromScale(0.2, 0.12),
            TextColor3 = Color3.fromRGB(240, 240, 240),
            Position = UDim2.fromScale(0.98, 0),
            TextXAlignment = Enum.TextXAlignment.Right,
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Value = self.state.score,
            FormatValue = function(a)
                return string.format("%07d", a)
            end,
            TextScaled = true
        }, {
            UITextSizeConstraint = Roact.createElement("UITextSizeConstraint", {
                MaxTextSize = 40
            })
        }),
        StatCard = e(StatCard, {
            Position = statCardPosition,
            Marvelouses = self.state.marvelouses,
            Perfects = self.state.perfects,
            Greats = self.state.greats,
            Goods = self.state.goods,
            Bads = self.state.bads,
            Misses = self.state.misses,
            Accuracy = self.state.accuracy
        }),
        TimeLeft = e(RoundedTextLabel, {
            Size = UDim2.fromScale(0.115, 0.035),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Position = UDim2.fromScale(0.02, 0.98),
            AnchorPoint = Vector2.new(0, 1),
            BackgroundTransparency = 1,
            TextScaled = true,
            Text = self.timeLeft:map(function(a)
                return SPUtil:format_ms_time(math.clamp(a, 0, math.huge))
            end)
        }),
        Combo = e(RoundedTextLabel, {
            Size = UDim2.fromScale(0.13, 0.07),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Position = ComboPositions[self.props.options.ComboPosition],
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            TextScaled = true,
            Text = "x"..self.state.chain,
            ZIndex = 2
        }),
        Back = e(RoundedTextButton, {
            Size = UDim2.fromScale(0.1, 0.05),
            HoldSize = UDim2.fromScale(0.08, 0.05),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundColor3 = Color3.fromRGB(230, 19, 19),
            HighlightBackgroundColor3 = Color3.fromRGB(187, 53, 53),
            Position = UDim2.fromScale(0.02, 0.09),
            Text = "Back (No save)",
            TextSize = 11,
            OnClick = function()
                self.forcedQuit = true
                self._game:set_mode(RobeatsGame.Mode.GameEnded)
            end
        }),
        Leaderboard = leaderboard,
        HitDeviance = e(RoundedFrame, {
           Position = self.props.options.Use2DLane and UDim2.fromScale(0.5, 0.635) or UDim2.fromScale(0.5, 0.95),
           Size = self.props.options.Use2DLane and UDim2.fromScale(0.15, 0.014) or UDim2.fromScale(0.15, 0.05),
           BackgroundTransparency = self.props.options.Use2DLane and 1,
           AnchorPoint = Vector2.new(0.5, 1),
           ZIndex = 5, -- This needed to overlap the 2D Lane's ZIndex
           [Roact.Ref] = self.hitDevianceRef
        }),
        LaneCover = e(RoundedFrame, {
            Size = UDim2.fromScale(1, laneCoverY),
            Position = UDim2.fromScale(0, laneCoverPosY),
            ZIndex = 0,
            Rotation = laneCoverRotation or 0,
            BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        }, {
            UIGradient = e("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.87, 0),
                    NumberSequenceKeypoint.new(0.93, 0.85),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Rotation = 90
            })
        })
    })
end

function Gameplay:willUnmount()
    EnvironmentSetup:set_gui_inset(false);
    self._game:teardown()
    self.everyFrameConnection:Disconnect()
end

return RoactRodux.connect(function(state, props)
    return Llama.Dictionary.join(props, {
        options = Llama.Dictionary.join(state.options.persistent, state.options.transient)
    })
end)(Gameplay)