local Https = game:GetService('HttpService')
local rawJSON = game:HttpGet("https://raw.githubusercontent.com/cunly1/test/main/properties.json")
local properties = Https:JSONDecode(rawJSON)

local customValues = {
	ColorSequence = function(sequence)
		local keypoints = {}
		for _, keypoint in ipairs(sequence.Keypoints) do
			local savedKeypoint = {
				Time = keypoint.Time,
				Value = tostring(keypoint.Value)
			}
			table.insert(keypoints, savedKeypoint)
		end
		return Https:JSONEncode(keypoints)
	end,
	
	NumberSequence = function(sequence)
		local keypoints = {}
		for _, keypoint in ipairs(sequence.Keypoints) do
			local savedKeypoint = {
				Time = keypoint.Time,
				Value = tostring(keypoint.Value)
			}
			table.insert(keypoints, savedKeypoint)
		end
		return Https:JSONEncode(keypoints)
	end
}

function getPropertyValue(instance, propertyName)
	local _, value = pcall(function() 
		return instance[propertyName] 
	end)
	
	if value == nil then return end
	
	local type = typeof(value)
	local hasCustomValue = customValues[tostring(type)]
	
	return {
		type = type, 
		value = (hasCustomValue and hasCustomValue(value)) or tostring(value), 
	}
end

function gatherProperties(instance, classData, savedProperties, visitedClasses)
	if visitedClasses[classData] then return end
	visitedClasses[classData] = true

	for _, propertyName in ipairs(classData.Properties) do
		local tab = getPropertyValue(instance, propertyName)
		if not tab then continue end

		savedProperties[propertyName] = tab
	end

	if classData.Inherits then
		for _, inheritedClass in ipairs(classData.Inherits) do
			gatherProperties(instance, properties[inheritedClass], savedProperties, visitedClasses)
		end
	end
end

function saveInstanceTree(instance)
	local className = instance.ClassName
	local classData = properties[className]

	--assert(classData, "Couldn't find class with ClassName: ".. className)
	if not classData then return end

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

function onRequest(instance)
	local savedInstanceTree = saveInstanceTree(instance)
	local encodedInstanceTree = Https:JSONEncode(savedInstanceTree)
	
	writefile("save.txt", encodedInstanceTree) 
end

return onRequest(...)
