AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
function ENT:Initialize()

    if not UF then return end

    self:DropToFloor()
    
    self:SetModel("models/lilly/uf/stations/dfi.mdl")
    self:DropToFloor()
    self.ValidLines = {
        ["01"] = true,
        ["02"] = true,
        ["03"] = true,
        ["04"] = true,
        ["05"] = true,
        ["06"] = true,
        ["08"] = true
    }

    self.DisplayedTrains = {}



    self.LastRefresh = CurTime()
    self.HasRefreshed = true

    self.NearestNodes = Metrostroi.NearestNodes(self:GetPos())
    self.Position = self:GetPos()

    self.TrackPosition = Metrostroi.GetPositionOnTrack(self.Position,
                                                       self:GetAngles())[1] -- Based on the Metrostroi tracking system, where is the display?

    self.ScannedTrains = {}

    self.Mode = 0

    self.WorkTable = {}
    self.FilteredTable = {}
    self.SortedTable = {}
    self.Themes = {
        [1] = "Frankfurt",
        [2] = "Duesseldorf",
        [3] = "Essen",
        [4] = "Hannover"
    }
    self.CurrentTheme = self:GetInternalVariable("Theme") or self.Themes[1]
    self.IgnoredTrains = {}

	self.ParentDisplay = self:GetInternalVariable("ParentDisplay") or nil
end

local function valueExists(table, value)
    for _, v in ipairs(table) do if v == value then return true end end
    return false
end

function ENT:DumpTable(table, indent)
    indent = indent or 0
    for key, value in pairs(table) do
        if type(value) == "table" then
            print(string.rep("  ", indent) .. key .. " = {")
            self:DumpTable(value, indent + 1)
            print(string.rep("  ", indent) .. "}")
        else
            print(string.rep("  ", indent) .. key .. " = " .. tostring(value))
        end
    end
end

function ENT:Think()
    self.BaseClass:Think()

    self.Time = os.date("%I%M",os.time())
    self:SetNW2String("Time",self.Time)
    
    self.TrackPosition = self.TrackPosition or Metrostroi.GetPositionOnTrack(self.Position,
                                                       self:GetAngles())[1]
    self:SetNW2Int("Mode", self.Mode)
    self:SetNW2String("Theme", self.CurrentTheme)

    if not next(UF.IBISRegisteredTrains) or not Metrostroi.Paths then -- either fall back to idle, train list, or current train display
        self.Mode = 0
    elseif next(UF.IBISRegisteredTrains) and Metrostroi.Paths then
        if CurTime() - self.LastRefresh > 10 then
            self.LastRefresh = CurTime()
            print("Refreshing DFI")
            self.SortedTable = {}
            self.WorkTable = {} -- reset the table for next run
            self.ScannedTrains = self:ScanForTrains() or {}
        end
    end

    self.EntitiesInProximity = ents.FindInSphere(self:GetPos(), 600) or {}

    for k, v in pairs(self.EntitiesInProximity) do
        local prefix = "gmod_subway_uf_"
        local prefix2 = "gmod_subway_mplr_"
        if string.sub(v:GetClass(), 1, #prefix) == prefix or
            string.sub(v:GetClass(), 1, #prefix2) == prefix2 then
            continue
        else
            self.EntitiesInProximity[k] = nil
        end
    end

    if not next(self.ScannedTrains) or not self.EntitiesInProximity then
        self.Mode = 0
        self:NextThink(CurTime() + 0.25)
        return
    end

    if not self.ParentDisplay then 
        self:ProcessResults() 
    else
        self:CopyResults()
    end

    if not next(UF.IBISRegisteredTrains) or not self.Train1ETA then -- either fall back to idle, train list, or current train display
        self.Mode = 0
        self.IgnoredTrains = {}

    elseif self.Train1ETA and tonumber(self.Train1ETA) > 0 then
        self.Mode = 1
    elseif self.Train1ETA and tonumber(self.Train1ETA) == 0 or self.Train1Dist and
        self.Train1Dist < 20 then

        self.Mode = 2

        local CourseRoute = self.Train1Ent.IBIS.Course .. "/" ..
                                self.Train1Ent.IBIS.Route
        if not valueExists(self.IgnoredTrains, CourseRoute) then
            table.insert(self.IgnoredTrains, CourseRoute)
        end

    end
    self:NextThink(CurTime() + 0.25)
end

function ENT:CopyResults()

    self.Mode = self.ParentTrain.Mode


    self.Train1Line = self.ParentDisplay.Train1Line
    self.Train1Destination = self.ParentDisplay.Train1Display
    self.Train1ETA = self.ParentDisplay.Train1ETA
    self.Train1ConsistLength = self.ParentDisplay.Train1ConsistLength

    self.Train2Line = self.ParentDisplay.Train2Line
    self.Train2Destination = self.ParentDisplay.Train2Display
    self.Train2ETA = self.ParentDisplay.Train2ETA

    self.Train3Line = self.ParentDisplay.Train3Line
    self.Train3Destination = self.ParentDisplay.Train3Display
    self.Train3ETA = self.ParentDisplay.Train3ETA

    self.Train4Line = self.ParentDisplay.Train4Line
    self.Train4Destination = self.ParentDisplay.Train4Display
    self.Train4ETA = self.ParentDisplay.Train4ETA

end

function ENT:ProcessResults()

    if not self.ScannedTrains then return end -- just quit if there's nothing to work with
    -- process everything into the list to be displayed on screen
    local subtables = {}
    -- Extract key-value pairs from the table and store them as subtables
    for key, value in pairs(self.ScannedTrains) do
        -- self.ScannedTrains[k] = math.abs(k)
        local subtable = {}
        subtable[key] = value
        table.insert(subtables, subtable)
    end
    self.Train1, self.Train2, self.Train3, self.Train4 = unpack(subtables) -- take apart that table
    if self.Train1 then
        for k, v in pairs(self.Train1) do
            local Train = v.train
            self.Train1Ent = Train
            if not IsValid(self.Train1Ent) then return end
            if not v.ETA then return end
            self.Train1Line = string.sub(Train.IBIS.Course, 1, 2)
            self.Train1Destination = Train:GetNW2String("IBIS:DestinationText",
                                                        "ERROR")
            self.Train1ETA = tostring(math.Round(math.Round(v.ETA / 60)))
            self.Train1Dist = v.DIST
            self.Train1ConsistLength = #Train.WagonList
            self.Train1Vector = Metrostroi.GetPositionOnTrack(
                                    self.Train1Ent:GetPos(),
                                    self.Train1Ent:GetAngles())[1]

        end
    end
    if self.Train2 then
        for k, v in pairs(self.Train2) do
            local Train = v.train
            if not IsValid(Train) then break end
            self.Train2Ent = Train
            self.Train2Line = string.sub(Train.IBIS.Course, 1, 2)
            self.Train2Destination = Train:GetNW2String("IBIS:DestinationText",
                                                        "ERROR")
            self.Train2ETA = tostring(math.Round(math.Round(v.ETA / 60)))
            self.Train2ConsistLength = #Train.WagonList
            self.Train2Vector = Metrostroi.GetPositionOnTrack(Train:GetPos(),
                                                              Train:GetAngles())[1]
        end
    else
        self.Train2Line = " "
        self.Train2Destination = " "
        self.Train2ETA = " "
    end
    if self.Train3 then
        for k, v in pairs(self.Train3) do
            local Train = v.train
            if not IsValid(Train) then break end
            self.Train3Line = string.sub(Train.IBIS.Course, 1, 2)
            self.Train3Destination = Train:GetNW2String("IBIS:DestinationText",
                                                        "ERROR")
            self.Train3ETA = tostring(math.Round(math.Round(v.ETA / 60)))
            self.Train3ConsistLength = #Train.WagonList
            self.Train3Vector = Metrostroi.GetPositionOnTrack(Train:GetPos(),
                                                              Train:GetAngles())[1]
        end
    else
        self.Train3Line = " "
        self.Train3Destination = " "
        self.Train3ETA = " "
    end
    if self.Train4 then
        for k, v in pairs(self.Train4) do
            local Train = v.train
            if not IsValid(Train) then break end
            self.Train4Line = string.sub(Train.IBIS.Course, 1, 2)
            self.Train4Destination = Train:GetNW2String("IBIS:DestinationText",
                                                        "ERROR")
            self.Train4ETA = tostring(math.Round(math.Round(v.ETA / 60)))
            self.Train4ConsistLength = #Train.WagonList
            self.Train4Vector = Metrostroi.GetPositionOnTrack(Train:GetPos(),
                                                              Train:GetAngles())[1]
        end
    else
        self.Train4Line = " "
        self.Train4Destination = " "
        self.Train4ETA = " "
    end
    self:SetNW2String("Train1Line", self.Train1Line)
    self:SetNW2String("Train1Destination", self.Train1Destination)
    self:SetNW2String("Train1Time", self.Train1ETA)
    self:SetNW2Int("Train1ConsistLength", self.Train1ConsistLength)

    self:SetNW2String("Train2Line", self.Train2Line)
    self:SetNW2String("Train2Destination", self.Train2Destination)
    self:SetNW2String("Train2Time", self.Train2ETA)

    self:SetNW2String("Train3Line", self.Train3Line)
    self:SetNW2String("Train3Destination", self.Train3Destination)
    self:SetNW2String("Train3Time", self.Train3ETA)

    self:SetNW2String("Train4Line", self.Train4Line)
    self:SetNW2String("Train4Destination", self.Train4Destination)
    self:SetNW2String("Train4Time", self.Train4ETA)
end

function ENT:ScanForTrains() -- scrape all trains that have been logged into RBL, sort by distance, and display sorted by ETA

    if not next(UF.IBISRegisteredTrains) then return end -- No point in doing anything if there isn't a single train registered / table is empty

    -- Copy a simple list of registered trains

    --[[for k,_ in pairs(UF.IBISRegisteredTrains) do
	if not k.IBIS or not tonumber(k.IBIS.Route) then break end --guard against invalid values on the IBIS
	for ke,val in pairs(self.WorkTable) do
		if self.WorkTable[ke] ~= k then
			table.insert(self.WorkTable,k)
			print(k,val)
		end
	end
end]]

    for k, _ in pairs(UF.IBISRegisteredTrains) do
        local trainpath = Metrostroi.GetPositionOnTrack(k:GetPos(),
                                                        k:GetAngles())[1]
        if trainpath.path ~= self.TrackPosition.path then
            continue
        elseif not valueExists(self.WorkTable, k) then
            table.insert(self.WorkTable, k)
        else
            break
        end
    end

    if #self.WorkTable < 1 then return end

    if #self.WorkTable > 4 then -- let's cut it short. The display only ever does four different trains.

        -- Iterate through the table and remove excess pairs
        local currentPairCount = 0
        for key, value in pairs(self.WorkTable) do
            currentPairCount = currentPairCount + 1
            if currentPairCount > 4 then self.WorkTable[key] = nil end
        end
    end

    if not next(self.WorkTable) then
        print("WorkTable Empty")
        return
    end -- if nothing came of that, just exit
    -- if next(self.WorkTable) then print("WorkTable Length:", #self.WorkTable) end

    for k, v in ipairs(self.WorkTable) do
        if not self.SortedTable[k] then
            local eta, Dist, path = self:TrackETA(v)
            table.insert(self.SortedTable, {train = v, ETA = eta, DIST = dist}) -- Insert a train and its ETA into the table
        else
            print("Train already exists in table; bailing")
            break
        end
    end

    -- now actually sort the table
    table.sort(self.SortedTable, function(a, b) return a.ETA < b.ETA end)

    --[[local count = 0
for _ in pairs(self.SortedTable) do
	count = count + 1
end


self.Train1Entry = count < 2 and count > 0
self.Train2Entry = count < 3 and count > 1
self.Train3Entry = count < 4 and count > 2
self.Train4Entry = count < 5 and count > 3]]

    self:SetNW2Bool("Train1Entry", self.Train1Entry) -- We only display the entries that actually exist. Tell the client.
    self:SetNW2Bool("Train2Entry", self.Train2Entry)
    self:SetNW2Bool("Train3Entry", self.Train3Entry)
    self:SetNW2Bool("Train4Entry", self.Train4Entry)

    return self.SortedTable -- return the shite

end

function ENT:TrackETA(train) -- universal function for having Metrostroi calculate the ETA

    if train then
        local TrainPosOnTrack = Metrostroi.GetPositionOnTrack(train:GetPos(),
                                                              train:GetAngles())[1] -- input the train's world vector and get its position on the node system
        if not TrainPosOnTrack then return end
        return
            UF.GetTravelTime(TrainPosOnTrack.node1, self.TrackPosition.node1) -- return the travel time between the train and the display
    else
        return nil
    end
end

function ENT:Compare(a, b) return a < b end

