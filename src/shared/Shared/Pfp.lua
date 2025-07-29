local Players = game:GetService("Players")
local thumbnailType = Enum.ThumbnailType.AvatarBust
local thumbnailSize = Enum.ThumbnailSize.Size420x420

local function getPfp(userId)
	local thumbUrl = Players:GetUserThumbnailAsync(userId, thumbnailType, thumbnailSize)
	return thumbUrl
end

return {
    getPfp = getPfp,
    thumbnailType = thumbnailType,
    thumbnailSize = thumbnailSize
}