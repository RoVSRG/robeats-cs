local SongDatabase = require(game.ReplicatedStorage.Shared.SongDatabase)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)

local Replay = {}

Replay.HitType = {
    Press = 1,
    Release = 2,
}

type Config = {
    viewing: boolean,
}

function Replay:new(config: Config)
    local self = {}

    self.viewing = not not config.viewing
    self.hits = {}
    self.scoreChanged = Instance.new("BindableEvent")

    local hitsSinceLastSend = {}

    local minIndex = 1

    function self:add_replay_hit(time, track, action, judgement: any?, scoreData: any?)
        local hit = {
            time = time,
            track = track,
            action = action,
            judgement = judgement,
            scoreData = scoreData,
        }

        table.insert(self.hits, hit)
        table.insert(hitsSinceLastSend, hit)
    end

    function self:set_hits(hits)
        self.hits = hits
    end

    function self:get_hits()
        return self.hits
    end

    function self:get_actions_this_frame(time: number)
        local actions = {}
        local lastScoreData

        for i = minIndex, #self.hits do
            local hit = self.hits[i]

            if time >= hit.time then
                if hit.action then
                    table.insert(actions, hit)
                end

                lastScoreData = hit.scoreData

                minIndex += 1
            else
                break
            end
        end

        if lastScoreData then
            self.scoreChanged:Fire(lastScoreData)
        end

        return actions
    end

    -- function self:send_last_hits()
    --     SpectatingService:DisemminateHits(hitsSinceLastSend)
    --     table.clear(hitsSinceLastSend)
    -- end

    return self
end

function Replay.perfect(hash, rate)
    local hitObjects = SongDatabase:get_hit_objects_for_key(SongDatabase:get_key_for_hash(hash), rate / 100)

    local replay = Replay:new({ viewing = true })

    for _, hitObject in ipairs(hitObjects) do
        if hitObject.Type == 1 then
            replay:add_replay_hit(hitObject.Time, hitObject.Track, Replay.HitType.Press, NoteResult.Marvelous)
            replay:add_replay_hit(hitObject.Time, hitObject.Track, Replay.HitType.Release)
        else
            replay:add_replay_hit(hitObject.Time, hitObject.Track, Replay.HitType.Press, NoteResult.Marvelous)
            replay:add_replay_hit(hitObject.Time + hitObject.Duration, hitObject.Track, Replay.HitType.Release, NoteResult.Marvelous)
        end
    end

    local hits = replay:get_hits()

    table.sort(hits, function(a:{ action: any, time: any }, b:{ action: any, time: any })
        if a.time == b.time then
            return a.action < b.action
        end

        return a.time < b.time
    end)

    return replay
end

return Replay

