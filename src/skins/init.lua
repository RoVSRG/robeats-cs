local SPDict = require(game.ReplicatedStorage.Shared.SPDict)

local Skins = {}

function Skins:new()
    local self = {}

    local _all_skins = SPDict:new()

    function self:cons()
        for _, skin in ipairs(script:GetChildren()) do
            if skin:IsA("Folder") then
                _all_skins:add(skin.Name, skin)
            end
        end
    end

    function self:get_skin(name)
        return _all_skins:get(name)
    end

    function self:key_itr()
        return _all_skins:key_itr()
    end

    function self:key_list()
        return _all_skins:key_list()
    end

    self:cons()

    return self
end

return Skins:new()
