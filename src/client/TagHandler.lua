local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local textSource = message.TextSource
	if textSource then
		local player = Players:GetPlayerByUserId(textSource.UserId)
		if player then
			if player:GetRoleInGroup(5863946) == "Developer" then
				local overrideProperties = Instance.new("TextChatMessageProperties")
				overrideProperties.PrefixText = string.format("<font color='rgb(%d, %d, %d)'>%s</font> %s", 255, 142, 144, "[DEV]", message.PrefixText)
				return overrideProperties
			end
		end
	end

	return nil
end