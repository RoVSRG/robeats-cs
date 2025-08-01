local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local textSource = message.TextSource
	if textSource then
		local player = Players:GetPlayerByUserId(textSource.UserId)
		if player then
			local role = player:GetRoleInGroup(5863946)
			local overrideProperties = Instance.new("TextChatMessageProperties")
			if role == "Owner/Dev" then
				overrideProperties.PrefixText = string.format("<font color='rgb(%d, %d, %d)'>%s</font> %s", 227, 45, 45, "[OWNER]", message.PrefixText)
				return overrideProperties
			elseif role == "Developer" then
				overrideProperties.PrefixText = string.format("<font color='rgb(%d, %d, %d)'>%s</font> %s", 255, 142, 144, "[DEV]", message.PrefixText)
				return overrideProperties
			elseif role == "Admin+" or role == "Admin" then
				overrideProperties.PrefixText = string.format("<font color='rgb(%d, %d, %d)'>%s</font> %s", 174, 235, 175, "[ADMIN]", message.PrefixText)
				return overrideProperties
			elseif role == "Moderator" then
				overrideProperties.PrefixText = string.format("<font color='rgb(%d, %d, %d)'>%s</font> %s", 150, 183, 227, "[MOD]", message.PrefixText)
				return overrideProperties
			end
		end
	end

	return nil
end