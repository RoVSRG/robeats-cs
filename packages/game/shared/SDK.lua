local sdkModule = script.Parent:FindFirstChild("_sdk_bin")

local sdk = {}

if not sdkModule then
	warn(
		"SDK module not found. Please run `npm run sdk:generate` to generate the SDK. Online features will be disabled."
	)

	sdk.online = false

	return sdk
end

sdk = require(sdkModule) :: any
sdk.online = true

return sdk
