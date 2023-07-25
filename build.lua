local Https = game:GetService('HttpService')

local conversionList = {
	number = tonumber,

	string = tostring,

	boolean = function(value)
		return value == "true" 
	end,

	Vector2 = function(value)
		local x, y = value:match("([^,]+),([^,]+)")
		return Vector2.new(tonumber(x), tonumber(y))
	end,

	Color3 = function(value)
		local r, g, b = value:match("([^,]+),([^,]+),([^,]+)")
		return Color3.new(tonumber(r), tonumber(g), tonumber(b))
	end,
		
	UDim2 = function(value)
		local xScale, xOffset, yScale, yOffset = value:match("{(%-?%d+%.?%d*), (%-?%d+%.?%d*)}, {(%-?%d+%.?%d*), (%-?%d+%.?%d*)}")
		return UDim2.new(tonumber(xScale), tonumber(xOffset), tonumber(yScale), tonumber(yOffset))
	end,

	Font = function(value)
		local path, weight, style = value:match("Family = (.-), Weight = (.-), Style = (.-) }$")
		return Font.new(path, Enum.FontWeight[weight], Enum.FontStyle[style])
	end,

	ColorSequence = function(keypoints)
		local keypointObjects = {}
		local decodedKeypoints = Https:JSONDecode(keypoints)

		for _, keypoint in ipairs(decodedKeypoints) do
			local time = keypoint.Time
			local value = keypoint.Value
			local rgbValues = {}
			for rgb in value:gmatch("%d+%.?%d*") do
				table.insert(rgbValues, tonumber(rgb))
			end

			if #rgbValues == 3 then
				local color = Color3.new(rgbValues[1], rgbValues[2], rgbValues[3])
				local keypointObject = ColorSequenceKeypoint.new(tonumber(time), color)
				table.insert(keypointObjects, keypointObject)
			else
				warn("Incorrect number of RGB components")
				return
			end
		end

		if #keypointObjects < 2 then
			warn("Color sequence requires at least 2 keypoints")
			return
		end

		return ColorSequence.new(keypointObjects)
	end,

	NumberSequence = function(keypoints)
		local keypointObjects = {}
		local decodedKeypoints = game:GetService('HttpService'):JSONDecode(keypoints)

		for _, keypoint in ipairs(decodedKeypoints) do
			local time = keypoint.Time
			local value = keypoint.Value

			local keypointObject = NumberSequenceKeypoint.new(tonumber(time), tonumber(value))
			table.insert(keypointObjects, keypointObject)
		end

		if #keypointObjects < 2 then
			warn("Number sequence requires at least 2 keypoints")
			return
		end

		return NumberSequence.new(keypointObjects)
	end,

	UDim = function(value)
		local scale, offset = value:match("([%-]?%d+%.?%d*),%s*([%-]?%d+%.?%d*)")
		return UDim.new(tonumber(scale), tonumber(offset))
	end,
	
	Rect = function(value)
		local old = value
		local minX, minY, maxX, maxY = value:match("(%d+%.?%d*), (%d+%.?%d*), (%d+%.?%d*), (%d+%.?%d*)")
		return Rect.new(tonumber(minX), tonumber(minY), tonumber(maxX), tonumber(maxY))
	end
}


function getConvertedValue(propertyType, propertyValue)
	local toType = conversionList[propertyType]
	
	if toType 	then  
		return toType(propertyValue)
	else
		warn("Couldn't find "..tostring(propertyType).." in table")
		return
	end
end


function getConvertedEnum(propertyValue)
	local enumName, enumValue = propertyValue:match("Enum.([^.]+).(.+)")
	if enumName and enumValue and Enum[enumName] then
		return Enum[enumName][enumValue]
	else
		warn("Couldn't convert enum: " .. propertyValue)
		return 
	end
end

function setProperties(savedInstance, newInstance)
	for name, property in pairs(savedInstance.Properties) do
		if name == "Parent" then continue end
		
		local value
		
		if (property.type == "EnumItem") then
			value = getConvertedEnum(property.value)
		else
			value = getConvertedValue(property.type, property.value)
		end

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

function onRequest(json)
	local decodedJson = Https:JSONDecode(json)
	local instanceTree = buildInstanceTree(decodedJson)
	
	instanceTree.Parent = game.Players.Vumly.PlayerGui
end

return onRequest(...)
