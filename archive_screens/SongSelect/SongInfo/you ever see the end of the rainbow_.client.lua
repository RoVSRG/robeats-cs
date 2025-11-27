local SongDatabase = require(game.ReplicatedStorage.SongDatabase)

local Transient = require(game.ReplicatedStorage.State.Transient)

local Root = script.Parent
local NpsGraph = Root.NpsGraph

local rate = 100
local key = nil

function getNpsGraphColor(num)
	local x = 0
	if num < 7 then
		x = num/7
		return Color3.new(0.1 + x * 0.1, 0.1 + x * 0.1, 0.8 + x * 0.2)
	elseif num < 14 then
		x = (num - 7)/7
		return Color3.new(0.2 + 0.4 * x, 0.2 + 0.2 * x, 1.0)
	elseif num < 21 then
		x = (num - 14)/7
		return Color3.new(0.6 + 0.4 * x, 0.4 - 0.2 * x, 1.0 - 0.3 * x)
	elseif num < 28 then
		x = (num - 21)/7
		return Color3.new(1.0, 0.2 + 0.2 * x, 0.7 - 0.5 * x)
	elseif num < 35 then
		x = (num - 28)/7
		return Color3.new(1.0, 0.4 - 0.3 * x, 0.2 - 0.15 * x)
	elseif num < 42 then
		x = (num - 35)/7
		return Color3.new(1.0- 0.3 * x, 0.1 - x * 0.1, 0.05 - 0.05 * x)
	else
		return Color3.new(0.7, 0.0, 0.0)	
	end
end

local function updateGraph(data)
	local npsGraphData = data.NPSGraph
	
	if not npsGraphData then
		return
	end
	
	local container = NpsGraph.GraphContainer
	
	for _, child in container:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	npsGraphData = string.split(npsGraphData, ",")
	
	for i, point in ipairs(npsGraphData) do
		npsGraphData[i] = tonumber(point)
	end
	
	local slices = #npsGraphData
	local MAX_NPS = 35
	
	for i, slice in npsGraphData do
		slice *= rate / 100
		
		local frame = Instance.new("Frame")
		frame.BorderSizePixel = 0
		frame.Size = UDim2.fromScale(1 / slices, slice / MAX_NPS)
		frame.BackgroundColor3 = getNpsGraphColor(slice)
		frame.LayoutOrder = i
		
		frame.Parent = NpsGraph.GraphContainer
	end
end

local function updateMetadata(data)
	Root.AverageNpsInfo.Text = string.format("Avg. Nps: %0.1f", data.AverageNPS * rate / 100)
	Root.MaxNpsInfo.Text = string.format("Max Nps: %0.1f", data.MaxNPS * rate / 100)
	Root.NotesInfo.Text = string.format("Total Notes: %d", data.TotalSingleNotes)
	Root.ReleasesInfo.Text = string.format("Total Holds: %d", data.TotalHoldNotes)
end

local function update()
	if not key then
		return
	end
	
	local data = SongDatabase:GetSongByKey(key)

	updateMetadata(data)
	updateGraph(data)
end

Transient.song.rate:on(function(value)
	rate = value
	update()
end)

Transient.song.selected:on(function(value)
	key = value
	update()
end)