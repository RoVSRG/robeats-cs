local sdkModule = script.Parent:FindFirstChild("_sdk_bin")

if not sdkModule then
	warn(
		"SDK module not found. Please run `npm run sdk:generate` to generate the SDK. Online features will be disabled."
	)
end

return require(sdkModule)
