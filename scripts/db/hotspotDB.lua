hotspotDB = {
	hotspotList = {},
	selectionList = {},
	numHotspots = 0,
	isSetup = false	
}

function hotspotDB:addHotspot(name, race, minLevel, maxLevel, posX, posY, posZ)
	self.hotspotList[self.numHotspots] = {};
	self.hotspotList[self.numHotspots]['name'] = name;
	self.hotspotList[self.numHotspots]['race'] = race;
	self.hotspotList[self.numHotspots]['faction'] = faction;
	self.hotspotList[self.numHotspots]['minLevel'] = minLevel;
	self.hotspotList[self.numHotspots]['maxLevel'] = maxLevel;
	self.hotspotList[self.numHotspots]['pos'] = {};
	self.hotspotList[self.numHotspots]['pos']['x'] = posX;
	self.hotspotList[self.numHotspots]['pos']['y'] = posY;
	self.hotspotList[self.numHotspots]['pos']['z'] = posZ;

	self.selectionList[self.numHotspots] = name;

	self.numHotspots = self.numHotspots + 1;
end


function hotspotDB:setup()

	-- You can set a hotspot for all races by setting the race to 'All'
	-- You can set a hotspot to only Horde or Alliance by setting race to "Horde" or "Alliance"

	-- Human 1-25
	hotspotDB:addHotspot('North Shire 1 - 2', 'Human', 1, 2, -8903.322, -69.84078, 86.58018);
	hotspotDB:addHotspot('North Shire 3 - 4', 'Human', 3, 4, -8724.425, -137.0334, 86.89613);
	hotspotDB:addHotspot('North Shire 5 - 6', 'Human', 5, 6, -9005.23, -316.80, 74.46);
	hotspotDB:addHotspot('Elvynn Forest 7 - 9', 'Human', 7, 9, -9202.76, 62.19, 77.55);
	hotspotDB:addHotspot('Westfall 10-12', 'Human', 10, 12, -9799.12, 931.79, 29.87);
	hotspotDB:addHotspot('Westfall 13-15', 'Human', 13, 15, -10254.38, 882.43, 36.67);
	hotspotDB:addHotspot('Westfall 16-17', 'Human', 16, 17, -10630.80, 797.73, 51.10);
	hotspotDB:addHotspot('Westfall 18-20', 'Human', 18, 20, -10874.41, 907.17, 37.3);
	hotspotDB:addHotspot('Duskwood 21 - 25', 'Human', 21, 25, -10759.08, 479.45, 35.19);	

	-- Night Elf 1-25
	hotspotDB:addHotspot("Teldrassil 6-8", 'Night Elf', 6, 8, 9672.04, 1014.01, 1287.04); 
	hotspotDB:addHotspot("Teldrassil 9-10", 'Night Elf', 9, 10, 9411.51, 1121.82, 1249.81); 
	hotspotDB:addHotspot("Teldrassil 11-12", 'Night Elf', 11, 12, 9428.69, 1693.50, 1304.38);
	hotspotDB:addHotspot("Darkshore 12-15", 'Night Elf', 12, 15, 6236.8, 40.65, 36.4);
	hotspotDB:addHotspot("Darkshore 16-18", 'Night Elf', 16, 18, 5314.11, 368.79, 28.98);
	hotspotDB:addHotspot("Darkshore 19-21", 'Night Elf', 19, 21, 4832.35, 423.87, 36.13);
	hotspotDB:addHotspot("Ashenvale 22-24", 'Night Elf', 22, 24, 2647.01, 168.43, 92.14);
	
	hotspotDB:addHotspot("Wetlands 25 - 28", 'Night Elf', 25, 28, -3462.16, -1414.47, 9.38);
	hotspotDB:addHotspot("Wetlands 25 - 28", 'Human', 25, 28, -3462.16, -1414.47, 9.38);

	-- Hillsbrad all races
	hotspotDB:addHotspot("Nethander Stead 29-30", "All", 29, 30, -1032.62, -927.97, 43.63);

	-- Arathi Highland all races
	hotspotDB:addHotspot("Arathi Highlands 31-35", "All", 31, 35, -1084.77, -2679.63, 46.65);
	hotspotDB:addHotspot("Arathi Highlands 36-39", "All", 36, 39, -823.66, -2276.62, 54.24);

	-- Tanaris
	

	DEFAULT_CHAT_FRAME:AddMessage('hotspotDB: loaded...');
	self.isSetup = true;
end

function hotspotDB:getHotSpotByID(id)
	return self.hotspotList[id];
end

function hotspotDB:getHotspotID(race, level)
	local hotspotID = -1;

	for i=0, self.numHotspots - 1 do
		if (level >= self.hotspotList[i]['minLevel'] and level <= self.hotspotList[i]['maxLevel']) then
			
			-- Race specific or all races or faction
			if (self.hotspotList[i]['race'] == race or 
				self.hotspotList[i]['race'] == 'All' or
				self.hotspotList[i]['race'] == UnitFactionGroup("player") ) then
				hotspotID = i;
			end
		end
	end

	return hotspotID;
end