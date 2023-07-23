local Http = game:GetService("HttpService")

local rawJSON = game:HttpGet("https://raw.githubusercontent.com/cunly1/test/main/properties.json")
local decoded = Http:JSONDecode(rawJSON)

function saveInstanceTree(instance)
	local className = instance.ClassName
	local classData = decoded[className]

	assert(classData, "Couldn't find class with ClassName: ".. className)

	local savedProperties = {}
	local visitedClasses = {}

	gatherProperties(instance, classData, savedProperties, visitedClasses)

	local savedChildren = {}

	for i, child in ipairs(instance:GetChildren()) do
		savedChildren[i] = saveInstanceTree(child)
	end

	return {
		ClassName = className,
		Properties = savedProperties,
		Children = savedChildren
	}
end

function gatherProperties(instance, classData, savedProperties, visitedClasses)
	if visitedClasses[classData] then return end
	visitedClasses[classData] = true

	for _, property in ipairs(classData.Properties) do
		savedProperties[property] = getPropertyValue(instance, property)
	end

	if classData.Inherits then
		for _, inheritedClass in ipairs(classData.Inherits) do
			gatherProperties(instance, decoded[inheritedClass], savedProperties, visitedClasses)
		end
	end
end

function getPropertyValue(instance, propertyName)
	local success, value = pcall(function() 
		return instance[propertyName] 
	end)

	if success then 
		return value 
	end
end

local result = Http:JSONEncode(saveInstanceTree(game.Players.LocalPlayer.PlayerGui.Leaderboard))

writefile("save.txt", result)

return result
