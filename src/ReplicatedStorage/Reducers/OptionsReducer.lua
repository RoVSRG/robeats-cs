local Rodux = require(game.ReplicatedStorage.Packages.Rodux)
local Llama = require(game.ReplicatedStorage.Packages.Llama)
local createReducer = Rodux.createReducer

local Skins = require(game.ReplicatedStorage.Skins)

local join = Llama.Dictionary.join

local defaultState = {
    persistent = {
        --These values can be set in SettingsMenu
        Keybind1 = Enum.KeyCode.Q,
        Keybind2 = Enum.KeyCode.W,
        Keybind3 = Enum.KeyCode.O,
        Keybind4 = Enum.KeyCode.P,

        ToggleLeaderboardKeybind = Enum.KeyCode.Tab,
        QuickRetryKeybind = Enum.KeyCode.Backquote,
        QuickRetrySpeed = 2,

        AudioOffset = 0;
        NoteSpeed = 15;
        FOV = 70;
        LaneCover = 0;
        Hitsounds = true;

        --interface settings
        PlayfieldWidth = 45;
        PlayfieldHitPos = 10;
        Use2DLane = false;
        Skin2D = Skins:key_list():get(1);
        Lane2DAspectRatioConstraintMode = -1; -- -1 = Automatic. 
        Upscroll = false;
        ComboPosition = "Middle";
        NoteColorAffects2D = false;
        InGameLeaderboardPosition = "Left";
        NoteColor = Color3.fromRGB(255, 255, 255);
        ShowProgressBar = true;
        ProgressBarColor = Color3.new(1, 1, 1);
        CursorImageColor = Color3.fromRGB(194, 244, 106);
        CursorSize = 128;

        --Extra settings.
        TimeOfDay = 24;
        BaseTransparency = 0;
        ReceptorTransparency = 0;
        ReceptorOuterTransparency = 0.8;
        HideReceptorGlow = false;
        TransparentHeldNote = false;
        HitLighting = false;
        HideLNTails = false;
        HidePlayerList = false;
        HideChat = false;
        HideLeaderboard = false;

        --Custom judgements
        UseCustomJudgements = false;

        CustomMarvelousPreset = 22;
        CustomPerfectPreset = 45;
        CustomGreatPreset = 85;
        CustomGoodPreset = 112;
        CustomBadPreset = 136;

        --Mobile Settings
        DividersEnabled = true,

        --Change this to swap the timing preset
        TimingPreset = "Standard",

        --Change this to toggle the visibility of certain judgements
        JudgementVisibility = { true, true, true, true, true, true },

        --You probably won't need to modify these
        NoteRemoveTimeMS = -200;
        PostFinishWaitTimeMS = 300;
        PreStartCountdownTimeMS = 3000;
    },
    transient = {
        --This is used to determine the speed of the song
        SongRate = 100,
        SongKey = 1,
        Mods = {},
        Search = "",
        SortByDifficulty = true,
        ShowRetryCountAfterFastReset = true,
        RetryCount = 0,
        SongListScrollPosition = 0
    }
}

return createReducer(defaultState, {
    setPersistentOption = function(state, action)
        return join(state, {
            persistent = join(state.persistent, {
                [action.option] = action.value
            })
        })
    end,
    setTransientOption = function(state, action)
        return join(state, {
            transient = join(state.transient, {
                [action.option] = action.value
            })
        })
    end
})
