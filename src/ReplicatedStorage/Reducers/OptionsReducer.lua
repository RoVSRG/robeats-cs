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

        AudioOffset = 0;
        NoteSpeed = 15;
        FOV = 70;
        LaneCover = 0;

        --interface settings
        PlayfieldWidth = 45;
        PlayfieldHitPos = 10;
        Use2DLane = false;
        Skin2D = Skins:key_list():get(1);
        Upscroll = false;
        ComboPosition = "Middle";
        NoteColorAffects2D = false;
        InGameLeaderboardPosition = "Left";
        NoteColor = Color3.fromRGB(255, 255, 255);

        --Extra settings.
        TimeOfDay = 24;
        BaseTransparency = 0;
        TransparentHeldNote = false;
        HitLighting = false;
        HideLNTails = false;
        HidePlayerList = false;
        HideChat = false;
        HideLeaderboard = false;

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
        Mods = {}
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
