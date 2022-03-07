local Roact = require(game.ReplicatedStorage.Packages.Roact)
local e = Roact.createElement

local Llama = require(game.ReplicatedStorage.Packages.Llama)

local RoundedImageLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedImageLabel)

local Tier = Roact.Component:extend("Tier")

Tier.defaultProps = {
    tier = "Bronze",
    division = 1,
    imageLabelProps = {}
}

Tier.Images = {
    Tin = { "rbxassetid://8027526017", "rbxassetid://8027525773", "rbxassetid://8027525646" },
    Bronze = { "rbxassetid://8027529526", "rbxassetid://8027529397", "rbxassetid://8027529224" },
    Silver = { "rbxassetid://8027527118", "rbxassetid://8027526869", "rbxassetid://8027526667" },
    Gold = { "rbxassetid://8027527946", "rbxassetid://8027527771", "rbxassetid://8027527509" },
    Diamond = { "rbxassetid://8027528965", "rbxassetid://8027528758", "rbxassetid://8027528639" },
    Emerald = { "rbxassetid://8027528504", "rbxassetid://8027528214", "rbxassetid://8027528067" },
    Ultraviolet = { "rbxassetid://8027525523", "rbxassetid://8027525387", "rbxassetid://8027525045" },
    Prism = { "rbxassetid://8027527255" }
}

function Tier:render()
    local image = self.Images[self.props.tier][if self.props.division then self.props.division else 1]

    local props = Llama.Dictionary.join(self.props.imageLabelProps, {
        Image = image
    })

    return e(RoundedImageLabel, props, {
        UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
            AspectRatio = 1
        }),
        Roact.createFragment(self.props[Roact.Children])
    })
end

return Tier
