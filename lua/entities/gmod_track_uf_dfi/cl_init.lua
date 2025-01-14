include("shared.lua")
surface.CreateFont("Lumino", {
	font = "Dot Matrix Umlaut",
	size = 100,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = false,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
	extended = true
})

surface.CreateFont("Lumino Dot", {
	font = "Dot Matrix Umlaut Dot",
	size = 100,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = false,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
	extended = true
})

surface.CreateFont("Lumino_Big", {
	font = "Dot Matrix Bold",
	size = 100,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = false,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
	extended = true
})

surface.CreateFont("Lumino_Cars", {
	font = "DFICustom Cars",
	size = 78,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = false,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
	extended = true
})

ENT.RTMaterial = CreateMaterial("UFRT1", "VertexLitGeneric", {["$vertexcolor"] = 0, ["$vertexalpha"] = 1, ["$nolod"] = 1})
ENT.RTMaterial2 = CreateMaterial("UFRT2", "VertexLitGeneric", {["$vertexcolor"] = 0, ["$vertexalpha"] = 0, ["$nolod"] = 1})

function ENT:CreateRT(name, w, h)
	local RT = GetRenderTarget("UF" .. self:EntIndex() .. ":" .. name, w or 512, h or 512)
	if not RT then Error("Can't create RT\n") end
	return RT
end

function ENT:DrawOnPanel(func)
	local panel = {
		pos = Vector(-22, 96.4, 166),
		ang = Angle(0, 0, 96), -- (0,44.5,-47.9),
		width = 117,
		height = 29.9,
		scale = 0.0311
	}
	local panel2 = {
		pos = Vector(-22, 96.4, 166),
		ang = Angle(0, 180, 96), -- (0,44.5,-47.9),
		width = 117,
		height = 29.9,
		scale = 0.0311
	}
	cam.Start3D2D(self:LocalToWorld(Vector(-22, 96.4, 166)), Angle(0, 0, 96), 0.03)
	func(panel)
	cam.End3D2D()
end

function ENT:DrawRTOnPanel()
	surface.SetMaterial(self.Overlay)
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawTexturedRectRotated(140, 155, 1690, 380, 0)
end




function ENT:ClockFace()
	
	local Time = self:GetNW2String("Time","0000")
	local hours = tonumber(string.sub(Time,1,2),10)
	local minutes = tonumber(string.sub(Time,3,4),10)
	
	self.MinutePos = ((minutes / 60) * 100) + 2
	self.HourPos = ((hours / 12) * 100 -4) + ((((minutes / 60) * 100) + 2)) / 12
	
	self.Hours:SetPoseParameter("position",self.HourPos)
	self.Hours:InvalidateBoneCache()
	self.Minutes:SetPoseParameter("position",self.MinutePos)
	self.Minutes:InvalidateBoneCache()
	
	
end




function ENT:Initialize()
	
	local ang = self:GetAngles() - Angle(0,0,-8)

	local pos = self:GetPos()  --+ Vector(0,0,-14)
	
	self.Hours = ents.CreateClientProp("models/lilly/uf/stations/dfi_hands_hours.mdl")
	self.Minutes = ents.CreateClientProp("models/lilly/uf/stations/dfi_hands_minutes.mdl")

	self.Hours:SetPos(pos)
	self.Hours:SetAngles(ang)
	self.Minutes:SetPos(pos)
	self.Minutes:SetAngles(ang)
	self.Hours:SetParent(self)
	self.Minutes:SetParent(self)
	self.Hours:Spawn()
	self.Minutes:Spawn()
	
	--self.Hours:SetPos(LocalToWorld(Vector(0,0,0)))
	--self.Minutes:SetPos(LocalToWorld(Vector(0,0,0)))
	
	
	
	
	self.AnnouncementPlayed = false
	--todo: Introduce a table so that this can be made more flexible. Hardcoding is nono.
	self.Abbreviations = {	
		["Ldstr"] = "Landstr.", 
		["Pl"] = "Platz",
		["Hhmrk"] = "Hohemark",
		["Bmmrsh"] = "Bommersheim",
	}	
	

	
end

function ENT:PrintText(x, y, text, font)
	local str = {utf8.codepoint(text, 1, -1)}
	for i = 1, #str do
		local char = utf8.char(str[i])
		draw.SimpleText(char, font, (x + i) * 55, y * 15 + 50, Color(255, 166, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
	end
end

function ENT:Think()
	self:ClockFace()

	
	
	
	local mode = self:GetNW2Int("Mode", 0)
	self.Theme = self:GetNW2String("Theme","Frankfurt")


	self.Train1Time = self:GetNW2String("Train1Time", "E")
	self.Train2Time = self:GetNW2String("Train2Time", "E")
	self.Train3Time = self:GetNW2String("Train3Time", "E")
	self.Train4Time = self:GetNW2String("Train4Time", "E")
	
	self.Train1Destination = self:GetNW2String("Train1Destination", "ERROR")
	self.Train2Destination = self:GetNW2String("Train2Destination", "ERROR")
	self.Train3Destination = self:GetNW2String("Train3Destination", "ERROR")
	self.Train4Destination = self:GetNW2String("Train4Destination", "ERROR")
	
	self.Train1Entry = self:GetNW2Bool("Train1Entry",false)
	self.Train2Entry = self:GetNW2Bool("Train2Entry",false)
	self.Train3Entry = self:GetNW2Bool("Train3Entry",false)
	self.Train4Entry = self:GetNW2Bool("Train4Entry",false)
	
	
	if self.Theme == "Frankfurt" or self.Theme == "Essen" or self.Theme == "Duesseldorf" then
		if string.sub(self:GetNW2String("Train1Line", "04"),1,1) == "0" then
			self.LineString1 = "U" .. string.sub(self:GetNW2String("Train1Line", "U4"), 2,2)
		elseif string.sub(self:GetNW2String("Train1Line", "U4"),1,1) ~= "0" then
			self.LineString1 = "U" .. self:GetNW2String("Train1Line", "U4")
		end
		
		if string.sub(self:GetNW2String("Train2Line", "U4"),1,1) == "0" then
			self.LineString2 = "U" .. string.sub(self:GetNW2String("Train2Line", "U4"), 2,2)
		elseif string.sub(self:GetNW2String("Train2Line", "U4"),1,1) ~= "0" then
			self.LineString2 = "U" .. self:GetNW2String("Train2Line", "U4")
		end
		
		if string.sub(self:GetNW2String("Train3Line", "U4"),1,1) == "0" then
			self.LineString3 = "U" .. string.sub(self:GetNW2String("Train3Line", "U4"), 2,2)
		elseif string.sub(self:GetNW2String("Train3Line", "U4"),1,1) ~= "0" then
			self.LineString3 = "U" .. self:GetNW2String("Train3Line", "U4")
		end
		
		if string.sub(self:GetNW2String("Train4Line", "U4"),1,1) == "0" then
			self.LineString4 = "U" .. string.sub(self:GetNW2String("Train4Line", "U4"), 2,2)
		elseif string.sub(self:GetNW2String("Train4Line", "U4"),1,1) ~= "0" then
			self.LineString4 = "U" .. self:GetNW2String("Train4Line", "U4")
		end
	elseif self.Theme == "Koeln" or self.Theme == "Hannover" then
		if string.sub(self:GetNW2String("Train1Line", "E0"),1,1) == "0" then
			self.LineString1 = string.sub(self:GetNW2String("Train1Line", "E0"), 2,2)
		elseif string.sub(self:GetNW2String("Train1Line", "E0"),1,1) ~= "0" then
			self.LineString1 = self:GetNW2String("Train1Line", "E0")
		end
		if string.sub(self:GetNW2String("Train2Line", "E0"),1,1) == "0" then
			self.LineString2 = string.sub(self:GetNW2String("Train2Line", "E0"), 2,2)
		elseif string.sub(self:GetNW2String("Train2Line", "E0"),1,1) ~= "0" then
			self.LineString2 = self:GetNW2String("Train2Line", "E0")
		end
		if string.sub(self:GetNW2String("Train3Line", "E0"),1,1) == "0" then
			self.LineString3 = string.sub(self:GetNW2String("Train3Line", "E0"), 2,2)
		elseif string.sub(self:GetNW2String("Train3Line", "E0"),1,1) ~= "0" then
			self.LineString3 = self:GetNW2String("Train3Line", "E0")
		end
		if string.sub(self:GetNW2String("Train4Line", "E0"),1,1) == "0" then
			self.LineString4 = string.sub(self:GetNW2String("Train4Line", "E0"), 2,2)
		elseif string.sub(self:GetNW2String("Train4Line", "E0"),1,1) ~= "0" then
			self.LineString4 = self:GetNW2String("Train4Line", "E0")
		end
	end
	if mode == 2 and self.AnnouncementPlayed == false then
		self.AnnouncementPlayed = true
		if self.Theme == "Frankfurt" then --todo implement other themes
			if self.Train1Destination and self.Train1Destination ~= "Leerfahrt" and self.Train1Destination ~= "PROBEWAGEN NICHT EINSTEIGEN" and self.Train1Destination ~= "FAHRSCHULE NICHT EINSTEIGEN" and self.Train1Destination ~= "SONDERWAGEN NICHT EINSTEIGEN" and self.Train1Destination ~= " " then
				self:PlayOnceFromPos("lilly/uf/DFI/frankfurt/"..self.LineString1.." ".."Richtung".." "..self.Train1Destination1..".mp3", 2, 1, 1, 1, self:GetPos())
			else
				self:PlayOnceFromPos("lilly/uf/DFI/frankfurt/Bitte Nicht Einsteigen.mp3", 2, 1, 1, 1, self:GetPos())
			end
		end
	elseif mode == 1 or mode == 0 then
		self.AnnouncementPlayed = false
	end
	
	

	
	self.Train1DestinationString = self:SubstituteAbbreviation(self.Train1Destination) and self:SubstituteAbbreviation(self.Train1Destination) or self.Train1Destination
	self.Train2DestinationString = self:SubstituteAbbreviation(self.Train2Destination) and self:SubstituteAbbreviation(self.Train2Destination) or self.Train2Destination
	self.Train3DestinationString = self:SubstituteAbbreviation(self.Train3Destination) and self:SubstituteAbbreviation(self.Train3Destination) or self.Train3Destination
	self.Train4DestinationString = self:SubstituteAbbreviation(self.Train4Destination) and self:SubstituteAbbreviation(self.Train4Destination) or self.Train4Destination
end

function ENT:SubstituteAbbreviation(Input)
	local output = nil
	if Input == "ERROR" then return end
	if not self.Abbreviations then return nil end
	for k,v in pairs(self.Abbreviations) do
		if string.find(Input,k,1,true) then
			output = string.gsub(Input,k,self.Abbreviations[k],1)
		end
	end
	--print(output)
	return output
end

function ENT:Draw()
	self:DrawModel()
	
	local mode = self:GetNW2Int("Mode", 0)
	if mode == 2 then
		
		local pos = self:LocalToWorld(Vector(-25, 96, 169))
		local pos2 = self:LocalToWorld(Vector(-10, 106, 169))
		local ang = self:LocalToWorldAngles(Angle(0, 0, 96))
		local ang2 = self:LocalToWorldAngles(Angle(0, 180, 95.6))
		cam.Start3D2D(pos, ang, 0.03)
		self:PrintText(-8, 0, self.LineString1, "Lumino_Big")
		self:PrintText(-5.1, 0, self.Train1DestinationString, "Lumino_Big")
		--self:PrintText(-5, 6, self:GetNW2String("TrainVia", "über Testplatz"), "Lumino")
		self:PrintText(10, 11.6, string.rep("ó",self:GetNW2Int("Train1ConsistLength", 1)), "Lumino_Cars")
		self:PrintText(10.3, 12.5, "____", "Lumino")
		self:PrintText(9.1, 13.1, ".", "Lumino")
		cam.End3D2D()
		cam.Start3D2D(pos2, ang2, 0.03)
		self:PrintText(-8, 0, self.LineString1, "Lumino_Big")
		self:PrintText(-5.1, 0, self.Train1DestinationString, "Lumino_Big")
		--self:PrintText(-5, 6, self:GetNW2String("TrainVia", "über Testplatz"), "Lumino")
		self:PrintText(10, 11.6, string.rep("ó",self:GetNW2Int("Train1ConsistLength", 1)), "Lumino_Cars")
		self:PrintText(10.3, 12.5, "____", "Lumino")
		self:PrintText(9.1, 13.1, ":", "Lumino")
		
		cam.End3D2D()
	elseif mode == 1 then
		
		local pos = self:LocalToWorld(Vector(-38.5, 96, 169.2))
		local pos2 = self:LocalToWorld(Vector(5, 105.99, 169))
		local ang = self:LocalToWorldAngles(Angle(0, 0, 96))
		local ang2 = self:LocalToWorldAngles(Angle(0, 180, 96))
		cam.Start3D2D(pos, ang, 0.03)
		
		---------------------------------------------------------------------------------
		self:PrintText(-1.5, 0, self.LineString1, "Lumino_Big")
		self:PrintText(1, 0, self.Train1DestinationString, "Lumino")
		if #self.Train1Time == 2 then
			self:PrintText(25, 0, self:GetNW2String("Train1Time", "10"), "Lumino")
		elseif #self.Train1Time == 1 then
			self:PrintText(26, 0, self:GetNW2String("Train1Time", "5"), "Lumino")
		end
		---------------------------------------------------------------------
		if self.Train2Entry == true then
			self:PrintText(-1.5, 6, self.LineString2, "Lumino_Big")
			self:PrintText(1, 6, self.Train2DestinationString, "Lumino")
			if #self.Train2Time == 2 then
				self:PrintText(25, 6, self.Train2Time, "Lumino")
			elseif #self.Train2Time == 1 then
				self:PrintText(26, 6, self.Train2Time, "Lumino")
			end
		end
		----------------------------------------------------------------------
		if self.Train3Entry == true then
			self:PrintText(-1.5, 12, self.LineString3, "Lumino_Big")
			self:PrintText(1, 12, self.Train3DestinationString, "Lumino")
			if #self.Train3Time == 2 then
				self:PrintText(25, 12, self.Train3Time, "Lumino")
			elseif #self.Train3Time == 1 then
				self:PrintText(26, 12, self.Train3Time, "Lumino")
			end
		end
		-------------------------------------------------------------------------------
		if self.Train4Entry == true then
			self:PrintText(-1.5, 18, self.LineString4, "Lumino_Big")
			self:PrintText(1, 18, self.Train4DestinationString, "Lumino")
			if #self.Train4Time == 2 then
				self:PrintText(25, 18, self.Train4Time, "Lumino")
			elseif #self.Train4Time == 1 then
				self:PrintText(26, 18, self.Train4Time, "Lumino")
			end
		end
		
		cam.End3D2D()
		cam.Start3D2D(pos2, ang2, 0.03)
		
		---------------------------------------------------------------------------------
		self:PrintText(-1.5, 0, self.LineString1, "Lumino_Big")
		self:PrintText(1, 0, self.Train1DestinationString, "Lumino")
		if #self.Train1Time == 2 then
			self:PrintText(25, 0, self:GetNW2String("Train1Time", "10"), "Lumino")
		elseif #self.Train1Time == 1 then
			self:PrintText(26, 0, self:GetNW2String("Train1Time", "5"), "Lumino")
		end
		---------------------------------------------------------------------
		if self.Train2Entry == true then
			self:PrintText(-1.5, 6, self.LineString2, "Lumino_Big")
			self:PrintText(1, 6, self.Train2DestinationString, "Lumino")
			if #self.Train2Time == 2 then
				self:PrintText(25, 6, self.Train2Time, "Lumino")
			elseif #self.Train2Time == 1 then
				self:PrintText(26, 6, self.Train2Time, "Lumino")
			end
		end
		----------------------------------------------------------------------
		if self.Train3Entry == true then
			self:PrintText(-1.5, 12, self.LineString3, "Lumino_Big")
			self:PrintText(1, 12, self.Train3DestinationString, "Lumino")
			if #self.Train3Time == 2 then
				self:PrintText(25, 12, self.Train3Time, "Lumino")
			elseif #self.Train3Time == 1 then
				self:PrintText(26, 12, self.Train3Time, "Lumino")
			end
		end
		-------------------------------------------------------------------------------
		if self.Train4Entry == true then
			self:PrintText(-1.5, 18, self.LineString4, "Lumino_Big")
			self:PrintText(1, 18, self.Train4DestinationString, "Lumino")
			if #self.Train4Time == 2 then
				self:PrintText(25, 18, self.Train4Time, "Lumino")
			elseif #self.Train4Time == 1 then
				self:PrintText(26, 18, self.Train4Time, "Lumino")
			end
		end
		
		cam.End3D2D()
		
		
	elseif mode == 0 then
		local pos = self:LocalToWorld(Vector(-25, 96, 169))
		local pos2 = self:LocalToWorld(Vector(-12, 106, 169))
		local ang = self:LocalToWorldAngles(Angle(0, 0, 96))
		local ang2 = self:LocalToWorldAngles(Angle(0, 180, 96.8))
		cam.Start3D2D(pos, ang, 0.03)
		-- surface.SetDrawColor(255, 255, 255, 255)
		-- surface.DrawRect(0, 0, 256, 320)
		
		draw.Text({
			text = "Auf Zugschild achten!",
			font = "Lumino", -- ..self:GetNW2Int("Style", 1),
			pos = {204, 110},
			xalign = TEXT_ALIGN_CENTER,
			yalign = TEXT_ALIGN_LEFT,
			color = Color(255, 136, 0)
		})
		cam.End3D2D()
		cam.Start3D2D(pos2, ang2, 0.03)
		-- surface.SetDrawColor(255, 255, 255, 255)
		-- surface.DrawRect(0, 0, 256, 320)
		
		draw.Text({
			text = "Auf Zugschild achten!",
			font = "Lumino", -- ..self:GetNW2Int("Style", 1),
			pos = {204, 110},
			xalign = TEXT_ALIGN_CENTER,
			yalign = TEXT_ALIGN_LEFT,
			color = Color(255, 136, 0)
		})
		
		cam.End3D2D()
		
	end
	
end

