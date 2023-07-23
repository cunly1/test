local rawJSON = game:HttpGet("https://raw.githubusercontent.com/cunly1/test/main/properties.json")
print("hi")
local decoded = game.HttpService:JSONDecode(rawJSON)

local result = game.HttpService:JSONEncode(saveInstanceTree(...))

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

print(result)

return result
