local fs = require("@lune/fs")

-- Test available fs methods
print("Available fs methods:")
for k, v in pairs(fs) do
    if type(v) == "function" then
        print("fs." .. k)
    end
end
