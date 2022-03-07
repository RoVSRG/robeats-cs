local Roact = require(game.ReplicatedStorage.Packages.Roact)
local RoactRouter = require(game.ReplicatedStorage.Packages.RoactRouter)
local Results = require(game.ReplicatedStorage.UI.Screens.Results)

return function(target)
    local history = RoactRouter.History.new()
    history:push("/", {
        Score = 900000,
        Accuracy = 96,
        Rating = 67.85,
        MaxChain = 0,
        Marvelouses = 0,
        Perfects = 0,
        Greats = 0,
        Goods = 0,
        Bads = 0,
        Misses = 0,
        Hits = {},
        Rate = 100,
        SongKey = 1,
        Mean = 0,
        PlayerName = "lol",
        TimePlayed = 0,
        Match = {
            players = {
                {
                    player = {
                        UserId = 1,
                        Name = "best player"
                    },
                    score = 25490872,
                    rating = 33.45,
                    accuracy = 97.65,
                    marvelouses = 4536,
                    perfects = 2341,
                    greats = 546,
                    goods = 37,
                    bads = 1,
                    misses = 36,
                    mean = -3,
                    maxChain = 312
                },
                {
                    player = {
                        UserId = 135,
                        Name = "not the best player but still good"
                    },
                    score = 21294563,
                    rating = 31.23,
                    accuracy = 96.1,
                    marvelouses = 4375,
                    perfects = 2599,
                    greats = 433,
                    goods = 90,
                    bads = 12,
                    misses = 57,
                    mean = 2,
                    maxChain = 233
                },
                {
                    player = {
                        UserId = 236,
                        Name = "bad player"
                    },
                    score = 19294563,
                    rating = 26.99,
                    accuracy = 93.27,
                    marvelouses = 3765,
                    perfects = 2700,
                    greats = 785,
                    goods = 130,
                    bads = 25,
                    misses = 234,
                    mean = 2,
                    maxChain = 233
                }
            }
        },
    })

    local app = Roact.createElement(RoactRouter.Router, {
        history = history
    }, {
        Results = Roact.createElement(RoactRouter.Route, {
            component = Results,
            path = "/",
            exact = true
        })
    })
    local handle = Roact.mount(app, target)

    return function()
        Roact.unmount(handle)
    end
end