local Https = game:GetService("HttpService")

function setProperties(savedInstance, newInstance)
	for name, value in pairs(savedInstance.Properties) do
		if value == nil or name == "Parent" then continue end

		pcall(function() 
			newInstance[name] = value 
		end)
	end
end

function buildInstanceTree(savedInstance)
	local className = savedInstance.ClassName
	local newInstance = Instance.new(className)

	setProperties(savedInstance, newInstance)

	for i, savedChild in ipairs(savedInstance.Children) do
		local newChild = buildInstanceTree(savedChild)
		newChild.Parent = newInstance
	end

	return newInstance
end

wait(2)
local instance = buildInstanceTree(Https:JSONDecode(Https:GetAsync("https://pastebin.com/raw/dSVuT5dj")))
instance.Parent = game.Players.Vumly.PlayerGui
