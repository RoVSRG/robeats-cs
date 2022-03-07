local Rodux = require(game.ReplicatedStorage.Packages.Rodux)
local Llama = require(game.ReplicatedStorage.Packages.Llama)
local createReducer = Rodux.createReducer

local join = Llama.Dictionary.join
local copyDeep = Llama.Dictionary.copyDeep
local set = Llama.Dictionary.set
local removeKey = Llama.Dictionary.removeKey
local map = Llama.Dictionary.map

local push = Llama.List.push
local findWhere = Llama.List.findWhere
local removeValue = Llama.List.removeValue
local removeIndex = Llama.List.removeIndex

local function createPlayer(player)
    return {
        player = player,
        score = 0,
        accuracy = 0,
        rating = 0,
        marvelouses = 0,
        perfects = 0,
        greats = 0,
        goods = 0,
        bads = 0,
        misses = 0,
        mean = 0,
        loaded = false,
        finished = false
    }
end

local defaultState = {
    rooms = {}
}

return createReducer(defaultState, {
    createRoom = function(state, action)
        local room = {
            name = action.player and (action.name or string.format("%s's room", action.player.Name)),
            image = action.image or "rbxassetid://6800827231",
            players = {
                [tostring(action.player and action.player.UserId or "0")] = createPlayer(action.player) -- Add the player that created the room to the list of players
            },
            host = action.player,
            selectedSongKey = 1,
            inProgress = false,
            songRate = 100,
            locked = action.locked,
        }

        return join(state, {
            rooms = set(state.rooms, action.id, room)
        })
    end,
    addPlayer = function(state, action)
        local players = set(state.rooms[action.roomId].players, tostring(action.player.UserId), createPlayer(action.player))

        return join(state, {
            rooms = join(state.rooms, {
                [action.roomId] = join(state.rooms[action.roomId], {
                    players = players
                })
            })
        })
    end,
    removePlayer = function(state, action)
        local roomPlayers = removeKey(state.rooms[action.roomId].players, tostring(action.player.UserId))

        return join(state, {
            rooms = join(state.rooms, {
                [action.roomId] = join(state.rooms[action.roomId], {
                    players = roomPlayers
                })
            })
        })
    end,
    removeRoom = function(state, action)
        return join(state, {
            rooms = join(state.rooms, {
                [action.roomId] = Llama.None
            })
        })
    end,
    startMatch = function(state, action)
        local players = copyDeep(state.rooms[action.roomId].players)

        table.foreach(players, function(_, player)
            player.loaded = false
            player.finished = false

            -- Reset stats
            for k, v in pairs(player) do
                if typeof(v) == "number" then
                    player[k] = v
                end
            end
        end)

        return join(state, {
            rooms = join(state.rooms, {
                [action.roomId] = join(state.rooms[action.roomId], {
                    players = players,
                    inProgress = true,
                })
            })
        })
    end,
    abortMatch = function(state, action)
        local players = copyDeep(state.rooms[action.roomId].players)

        table.foreach(players, function(_, player)
            player.finished = true
        end)

        return join(state, {
            rooms = join(state.rooms, {
                [action.roomId] = join(state.rooms[action.roomId], {
                    players = players,
                    inProgress = false
                })
            })
        }) 
    end,
    setLoaded = function(state, action)
        local mutableState = copyDeep(state)

        local room = mutableState.rooms[action.roomId]
        room.players[tostring(action.userId)].loaded = action.value

        return mutableState
    end,
    setFinished = function(state, action)
        local mutableState = copyDeep(state)

        local room = mutableState.rooms[action.roomId]
        room.players[tostring(action.userId)].finished = action.value

        local finished = 0

        for _, player in pairs(room.players) do
            if player.finished == true then
                finished += 1
            end
        end

        if finished == Llama.Dictionary.count(room.players) then
            room.inProgress = false
        end

        return mutableState
    end,
    setMatchStats = function(state, action)
        local mutableState = copyDeep(state)

        local userId = tostring(action.userId)

        local room = mutableState.rooms[action.roomId]

        room.players[userId] = join(room.players[userId], {
            score = action.score,
            accuracy = action.accuracy,
            rating = action.rating,
            marvelouses = action.marvelouses,
            perfects = action.perfects,
            greats = action.greats,
            goods = action.goods,
            bads = action.bads,
            misses = action.misses,
            mean = action.mean,
            maxChain = action.maxChain,
            hits = action.hits
        })

        return mutableState
    end,
    setHost = function(state, action)
        return join(state, {
            rooms = join(state.rooms, {
                [action.roomId] = join(state.rooms[action.roomId], {
                    host = action.host
                })
            })
        })
    end,
    setSongKey = function(state, action)
        return join(state, {
            rooms = join(state.rooms, {
                [action.roomId] = join(state.rooms[action.roomId], {
                    selectedSongKey = action.songKey
                })
            })
        })
    end,
    setSongRate = function(state, action)
        return join(state, {
            rooms = join(state.rooms, {
                [action.roomId] = join(state.rooms[action.roomId], {
                    songRate = action.songRate
                })
            })
        })
    end
})
