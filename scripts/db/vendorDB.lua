vendorDB = {
	vendorList = {},
	numVendors = 0	
}

--[[
	todo:
		- Add class trainers
--]]

function vendorDB:addVendor(name, faction, continentID, mapID, canRepair, hasFood, hasWater, hasArrow, hasBullet, posX, posY, posZ)

	--[[
		faction:              !  GetFaction() returns 1 for humans, 3 for dwarf, 4 for NE, and 115 for gnome)  !
			0 = Alliance
			1 = Horde
	--]]

	self.vendorList[self.numVendors] = {};
	self.vendorList[self.numVendors]['name'] = name;
	self.vendorList[self.numVendors]['faction'] = faction;
	self.vendorList[self.numVendors]['continentID'] = continentID;
	self.vendorList[self.numVendors]['mapID'] = mapID;
	self.vendorList[self.numVendors]['canRepair'] = canRepair;
	self.vendorList[self.numVendors]['hasFood'] = hasFood;
	self.vendorList[self.numVendors]['hasWater'] = hasWater;
	self.vendorList[self.numVendors]['hasArrow'] = hasArrow;
	self.vendorList[self.numVendors]['hasBullet'] = hasBullet;
	self.vendorList[self.numVendors]['pos'] = {};
	self.vendorList[self.numVendors]['pos']['x'] = posX;
	self.vendorList[self.numVendors]['pos']['y'] = posY;
	self.vendorList[self.numVendors]['pos']['z'] = posZ;
	self.numVendors = self.numVendors + 1;
end

function vendorDB:setup()
	-- Ally: Human
	vendorDB:addVendor('Brother Danil', 0, 0, 12, false, true, true, true, true, -8901.59, -112.72, 81.85);
	vendorDB:addVendor("Godric Rothgar", 0, 0, 12, true, false, false, false, false, -8898.23, -119.84, 81.83); -- Repair -- 
	vendorDB:addVendor("Innkeeper Farley", 0, 0, 12, false, true, false, false, false, -9462.67, 16.19, 56.96); -- bread goldshire
	vendorDB:addVendor("Innkeeper Farley", 0, 0, 12, false, false, true, false, false, -9462.67, 16.19, 56.96); -- drinks goldshire
	vendorDB:addVendor("Andrew Krighton", 0, 0, 12, true, false, false, false, false, -9462.3, 87.81, 58.33); -- Repair Goldshire
	
	-- Barrens - Horde
	vendorDB:addVendor('Sanuye Runetotem', 0, 1, 1111, true, false, false, false, false, -2374.26, -1948.79, 96.09); -- Repair Vendor 
	
	-- Ally: Night Elf
	vendorDB:addVendor("Keina", 0, 1, 141, true, false, false, true, false, 10436.70, 794.83, 1322.7); -- Repair, Arrows vendor
	vendorDB:addVendor("Jeena Featherbow", 0, 1, 141, true, false, false, true, false, 9821.98, 968.83, 1308.77); -- Repair, Arrows vendor
	vendorDB:addVendor("Mydrannul", 0, 1, 1657, false, false, true, true, true, 9821.98, 968.83, 1308.77); -- General - ammo/shots/drinks Darnassus
	vendorDB:addVendor("Naram Longclaw", 0, 1, 148, true, false, false, false, false, 6571.59, 480.53, 8.25); -- Repair - Darkshore
	vendorDB:addVendor("Xai'ander", 0, 1, 331, true, false, false, false, false, 2672.31, -363.60, 110.73); -- Repair - Astranaar

	-- Ally: Westfall 
	vendorDB:addVendor("Innkeeper Heather", 0, 0, 40, false, true, true, false, false, -10653.41, 1166.52, 34.46); -- drinks, fish
	vendorDB:addVendor("William MacGregor", 0, 0, 40, true, false, false, true, false, -10658.5, 996.85, 32.87); -- rep, arrows
	vendorDB:addVendor("Mike Miller", 0, 0, 40, false, true, false, false, false, -10653.3, 995.39, 32.87); -- bread

	-- Ally: Gnome & Dwarf
	vendorDB:addVendor('Kreg Bilmn', 0, 0, 1, false, false, false, true, true, -5597.66, -521.85, 399.66); -- general bullets/ammo
	vendorDB:addVendor('Grawn Thromwyn', 0, 0, 1, true, false, false, false, false, -5590.67, -428.415, 397.326); -- repair Northshire
	vendorDB:addVendor('Morhan Coppertongue', 0, 0, 38, true, false, false, false, false, -5343.68, -2932.13, 324.36); -- repair Lock Modan

	-- Ally: Wetlands
	vendorDB:addVendor('Gruham Rumbnul', 0, 0, 11, false, false, false, true, true, -3746.03, 888.59, 11.01); -- Ammo, Bullets, General
	vendorDB:addVendor('Murndan Derth', 0, 0, 11, true, false, false, false, false, -3790.13, -858.47, 11.60); -- Repair

	-- Ally: Hillsbrad
	vendorDB:addVendor('Sarah Raycroft', 0, 0, 267, false, false, true, true, true, -774.52, -505.75, 23.63); -- ammo drinks hillsbrad
	vendorDB:addVendor('Robert Aebischer', 0, 0, 267, true, false, false, false, false, -815.53, -572.19, 15.23); -- repair

	-- Tanaris - Ally + Horde
	vendorDB:addVendor('Krinkle Goodsteel', 0, 1, 440, true, false, false, false, false, -7200.40, -3769.75, 8.68); -- Repair Vendor
	vendorDB:addVendor('Krinkle Goodsteel', 1, 1, 440, true, false, false, false, false, -7200.40, -3769.75, 8.68); -- Repair Vendor
	vendorDB:addVendor('Blizrlk Buckshot', 0, 1, 440, true, false, false, false, true, -7141.79, -3719.82, 8.49); -- Bullets (not arrows) ammo, repair
	
	-- Azshara Alliance
	vendorDB:addVendor('Brinna Valanaar', 0, 1, 16, true, false, false, true, false, 2691.28, -3885.87, 109.22); -- Repair + Arrows (no ammo)

	-- Arathi Highlands - Alliance
	vendorDB:addVendor('Jannos Ironwill', 0, 0, 45, true, false, false, false, false, -1277.01, -2522.03, 21.36); -- Repair Vendor
	vendorDB:addVendor('Vikki Lonsav', 0, 0, 45, false, false, true, true, true, -1274.51, -2537.41, 21.43); -- General Trade for Ammo & Drinks

	-- Winterspring - Ally + Horde
	vendorDB:addVendor('Wixxrak', 0, 1, 618, true, false, false, false, false, 6733.39, -4699.04, 721.37); -- Repair Vendor
	vendorDB:addVendor('Wixxrak', 1, 1, 618, true, false, false, false, false, 6733.39, -4699.04, 721.37); -- Repair Vendor
	vendorDB:addVendor('Himmik', 0, 1, 618, false, true, true, false, false, 6679.62, -4670.89, 721.71); -- Food + Drink Vendor
	vendorDB:addVendor('Himmik', 1, 1, 618, false, true, true, false, false, 6679.62, -4670.89, 721.71); -- Food + Drink Vendor 

	DEFAULT_CHAT_FRAME:AddMessage('vendorDB: loaded...');
end

function vendorDB:GetVendorByID(id)
	return self.vendorList[id];
end

function vendorDB:GetVendor(faction, continentID, mapID, canRepair, needFood, needWater, needArrow, needBullet, posX, posY, posZ)
	local bestDist = 10000;
	local bestIndex = -1;
	
	for i=0,self.numVendors - 1 do
		if(self.vendorList[i]['faction'] == faction and self.vendorList[i]['continentID'] == continentID) then			
			if((needFood and self.vendorList[i]['hasFood'] or not needFood) and (needWater and self.vendorList[i]['hasWater'] or not needWater)
			and (needArrow and self.vendorList[i]['hasArrow'] or not needArrow) and (needBullet and self.vendorList[i]['hasBullet'] or not needBullet)
			and (canRepair and self.vendorList[i]['canRepair'] or not canRepair)) then
				local _dist = GetDistance3D(posX, posY, posZ, self.vendorList[i]['pos']['x'], self.vendorList[i]['pos']['y'], self.vendorList[i]['pos']['z']);
				if(_dist < bestDist) then
					bestDist = _dist;
					bestIndex = i;
				end
			end
		end
	end
	return bestIndex;
end

function vendorDB:loadDBVendors()
	local localObj = GetLocalPlayer();
	local x, y, z = localObj:GetPosition();
	local factionID = 1; -- horde
	local factionNr = GetFaction();
	if (factionNr == 1 or factionNr == 3 or factionNr == 4 or factionNr == 115) then
		factionID = 0; -- alliance
	end
	
	local repID, sellID, foodID, drinkID, arrowID, bulletID = -1, -1, -1, -1, -1, -1;

	repID = vendorDB:GetVendor(factionID, GetContinentID(), GetMapID(), true, false, false, false, false, x, y, z);
	sellID = vendorDB:GetVendor(factionID, GetContinentID(), GetMapID(), false, false, false, false, false, x, y, z);
	foodID = vendorDB:GetVendor(factionID, GetContinentID(), GetMapID(), false, true, false, false, false, x, y, z);
	drinkID = vendorDB:GetVendor(factionID, GetContinentID(), GetMapID(), false, false, true, false, false, x, y, z);
	arrowID = vendorDB:GetVendor(factionID, GetContinentID(), GetMapID(), false, false, false, true, false, x, y, z);
	bulletID = vendorDB:GetVendor(factionID, GetContinentID(), GetMapID(), false, false, false, false, true, x, y, z);

	if (repID ~= -1) then
		script_vendor.repairVendor = vendorDB:GetVendorByID(repID);
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Repair vendor ' .. script_vendor.repairVendor['name'] .. ' loaded from DB...');
	end

	if (sellID ~= -1) then
		script_vendor.sellVendor = vendorDB:GetVendorByID(sellID);
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Sell vendor ' .. script_vendor.sellVendor['name'] .. ' loaded from DB...');
	end

	if (foodID ~= -1) then
		script_vendor.foodVendor = vendorDB:GetVendorByID(foodID);
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Food vendor ' .. script_vendor.foodVendor['name'] .. ' loaded from DB...');
	end

	if (drinkID ~= -1) then
		script_vendor.drinkVendor = vendorDB:GetVendorByID(drinkID);
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Drink vendor ' .. script_vendor.drinkVendor['name'] .. ' loaded from DB...');
	end

	if (arrowID ~= -1) then
		script_vendor.arrowVendor = vendorDB:GetVendorByID(arrowID);
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Arrow vendor ' .. script_vendor.arrowVendor['name'] .. ' loaded from DB...');
	end

	if (bulletID ~= -1) then
		script_vendor.bulletVendor = vendorDB:GetVendorByID(bulletID);
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Bullet vendor ' .. script_vendor.bulletVendor['name'] .. ' loaded from DB...');
	end

	if (repID == -1 and sellID == -1 and foodID == -1 and drinkID == -1 and arrowID == -1 and bulletID == -1) then
		DEFAULT_CHAT_FRAME:AddMessage('script_vendor: No Vendor found close to our location in vendorDB...');
	end 
end