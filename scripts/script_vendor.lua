script_vendor = {
	message = "Idle...",
	isSetup = false,
	keepItems = {},
	keepNum = 0,
	sellQuality = 2, -- 0-7 (1 = white, 2 = green)	
	timer = 0,
	status = 0, --  0 = idle, 1 = repair, 2 = sell, 3 = buy ammo, 4 = buy food/drink
	error = "",
	currentBag = 0,
	currentSlot = 0,
	sellPoor = true,
	sellCommon = true,
	sellUncommon = false,
	sellRare = false,
	sellEpic = false,
	quiverBag = nil,
	ammoName = 0,
	itemName = 0,
	itemNum = 0,
	itemIsFood = 0,
	itemIsDrink = 0,
	itemIsArrow = 0,
	itemIsBullet = 0,
	selectedKeepItemNr = 0,
	addItemName = "",
	repairVendor = 0,
	sellVendor = 0,
	foodVendor = 0,
	drinkVendor = 0,
	arrowVendor = 0,
	bulletVendor = 0,
	foodName = "",
	drinkName = "",
	foodNr = 8,
	drinkNr = 8,
	arrowName = "",
	arrowNr = 7,
	bulletName = "",
	bulletNr = 7,
	menu = include("scripts\\script_vendorMenu.lua"),
	dontBuyTime = 0
}

function script_vendor:setSellQuality(sellPoor, sellCommon, sellUncommon, sellRare, sellEpic)
	if (sellEpic) then
		self.sellQuality = 4;
		return;
	elseif (sellRare) then
		self.sellQuality = 3;
		return;
	elseif (sellUncommon) then
		self.sellQuality = 2;
		return;
	elseif (sellCommon) then
		self.sellQuality = 1;
		return;
	elseif (sellPoor) then
		self.sellQuality = 0;
		return;
	else
		self.sellQuality = -1;
		return;
	end
end

function script_vendor:getStatus()
	return self.status;
end

function script_vendor:addSaveItem(name)
	-- Don't add multiple entries of the same item name
	if (not script_vendor:keepItem(name)) then
		self.keepItems[self.keepNum] = name;
		self.keepNum = self.keepNum + 1;
	end	
end

function script_vendor:deleteKeepItem(itemNr)
	local tempList = self.keepItems;
	self.keepItems = {};
	local x = 0;
	local y = 0;
	for i=0, self.keepNum-1 do
		if (i ~= itemNr) then
			self.keepItems[x] = tempList[y];
			x = x+1;
			y = y+1;
		else
			y = y+1;
		end
	end
	
	-- Correct the number of keep items
	self.keepNum = self.keepNum - 1;
	if (self.keepNum < 0) then
		self.keepNum = 0;
	end
end

function script_vendor:keepItem(name)
	for i = 0,self.keepNum-1 do
		if (strfind(self.keepItems[i], name)) then
			return true;
		end
	end
	
	return false; 
end

function script_vendor:findFood()
	for i = 0,4 do 
		for y=0,GetContainerNumSlots(i) do 
			if (GetContainerItemLink(i,y) ~= nil) then
				_,_,itemLink=string.find(GetContainerItemLink(i,y),"(item:%d+)");
				itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
   				itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink);
				for u=0,script_helper.numFood-1 do
					if (strfind(itemName, script_helper.food[u])) then
						DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Food name is set to: "' .. script_helper.food[u] .. '" ...');
						return script_helper.food[u];
					end	
				end	
			end	
		end
	end

	return " ";
end

function script_vendor:findDrink()
	for i = 0,4 do 
		for y=0,GetContainerNumSlots(i) do 
			if (GetContainerItemLink(i,y) ~= nil) then
				_,_,itemLink=string.find(GetContainerItemLink(i,y),"(item:%d+)");
				itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
   				itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink);
				for u=0,script_helper.numWater-1 do
					if (strfind(itemName, script_helper.water[u])) then
						DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Drink name is set to: "' .. script_helper.water[u] .. '" ...');
						return script_helper.water[u];
					end	
				end	
			end	
		end
	end

	return " ";
end

function script_vendor:setup()
	self.timer = GetTimeEX();
	self.dontBuyTime = GetTimeEX();
	self.keepItems = {};
	self.keepNum = 0;

	self.foodName = script_vendor:findFood();
	self.drinkName = script_vendor:findDrink();

	-- Put everything in our inventory at startup as "keep items" (won't be sold)
	for i = 0,4 do 
		for y=0,GetContainerNumSlots(i) do 
			if (GetContainerItemLink(i,y) ~= nil) then
				_,_,itemLink=string.find(GetContainerItemLink(i,y),"(item:%d+)");
				itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
   				itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink);
				script_vendor:addSaveItem(itemName);
			end
		end 
	end

	self.isSetup = true;
	DEFAULT_CHAT_FRAME:AddMessage('script_vendor: loaded...');
end

function script_vendor:getMessage()
	if (not self.isSetup) then
		script_vendor:setup();
	end
	return self.message;
end

function script_vendor:repair()
	if (not self.isSetup) then
		script_vendor:setup();
	end

	local localObj = GetLocalPlayer();
	local x, y, z = localObj:GetPosition();
	local factionID = 1; -- horde
	local factionNr = GetFaction();
	if (factionNr == 1 or factionNr == 3 or factionNr == 4 or factionNr == 115) then
		factionID = 0; -- alliance
	end
	
	local vendor = nil;
	local vendorID = -1;

	if (self.repairVendor ~= 0) then
		vendor = self.repairVendor;
	else
		local vendorID = vendorDB:GetVendor(factionID, GetContinentID(), GetMapID(), true, false, false, false, false, x, y, z);
	
		if (vendorID ~= -1) then
			vendor = vendorDB:GetVendorByID(vendorID);
		else
			self.message = "No vendor found, see scripts\\VendorDB.lua...";
			return false;
		end
	end
	
	if (vendor ~= nil) then
		local vX, vY, vZ = vendor['pos']['x'], vendor['pos']['y'], vendor['pos']['z'];
		
		if (GetDistance3D(x, y, z, vX, vY, vZ) > 3.5) then
			self.status = 1; -- moving to a repair vendor
			script_nav:moveToTarget(localObj, vX, vY, vZ);
			self.message = 'Moving to ' .. vendor['name'] .. '...';
			return true;
		end

		script_vendor:removeShapeShift();
	
		local vendorTarget = nil;
		TargetByName(vendor['name']);
		if (GetTarget() ~= 0 and GetTarget() ~= nil) then
			vendorTarget = GetTarget();
		end

		if (vendorTarget ~= nil) then
			
			self.message = 'Repairing...';
			if (not IsVendorWindowOpen()) then
				SkipGossip();
				if (vendorTarget:UnitInteract()) then
					return true;
				end
			else

				if (CanMerchantRepair()) then
					RepairAllItems(); 
					self.message = 'Finished repairing...';
					-- sell
					script_vendorMenu:sellLogic();
					return true;
				else
					-- sell
					self.currentBag = 0;
					self.currentSlot = 0;
					script_vendorMenu:sellLogic();
					return true;
				end
			end
			return true;
		end
	end

	return false;
end

function script_vendor:sell()
	if (not self.isSetup) then
		script_vendor:setup();
	end

	-- Update sell quality rule
	script_vendor:setSellQuality(self.sellPoor, self.sellCommon, self.sellUncommon, self.sellRare, self.sellEpic);

	if (self.sellQuality == -1) then
		self.message = "Sell disabled, see vendor options...";
		return false;
	end	

	if (self.timer > GetTimeEX()) then
		return true;
	end

	local localObj = GetLocalPlayer();
	local x, y, z = localObj:GetPosition();
	local factionID = 1; -- horde
	local factionNr = GetFaction();
	if (factionNr == 1 or factionNr == 3 or factionNr == 4 or factionNr == 115) then
		factionID = 0; -- alliance
	end

	local vendor = nil;
	local vendorID = -1;

	if (self.sellVendor ~= 0) then
		vendor = self.sellVendor;
	else
		local vendorID = vendorDB:GetVendor(factionID, GetContinentID(), GetMapID(), false, false, false, false, false, x, y, z);
	
		if (vendorID ~= -1) then
			vendor = vendorDB:GetVendorByID(vendorID);
		else
			self.message = "No vendor found, see scripts\\VendorDB.lua...";
			return false;
		end
	end
	
	if (vendor ~= nil) then
		local vX, vY, vZ = vendor['pos']['x'], vendor['pos']['y'], vendor['pos']['z'];
	
		if (GetDistance3D(x, y, z, vX, vY, vZ) > 3.5) then
			script_nav:moveToTarget(localObj, vX, vY, vZ);
			self.status = 2; -- moving to sell at a vendor
			self.message = 'Moving to ' .. vendor['name'] .. '...';
			-- Reset bag and slot numbers before we sell
			self.currentBag = 0;
			self.currentSlot = 0;
			return true;
		end

		script_vendor:removeShapeShift();

		local vendorTarget = nil;
		TargetByName(vendor['name']);
		if (GetTarget() ~= 0 and GetTarget() ~= nil) then
			vendorTarget = GetTarget();
		end

		if (vendorTarget ~= nil) then
			
			self.message = 'Selling...';
			if (not IsVendorWindowOpen()) then
				SkipGossip();
				if (vendorTarget:UnitInteract()) then
					return true;
				end
			else
				if (CanMerchantRepair()) then
					RepairAllItems(); 
					-- sell
					script_vendorMenu:sellLogic();
					return true;
				else
					script_vendorMenu:sellLogic();
					return true;
				end
				
				
			end
			return true;
		end
	end
	return false;
end

function script_vendor:continueBuyAmmo()
	if (self.ammoName == 0 or self.quiverBag == nil) then
		self.status = 0; -- idle
		return false;
	end
	return script_vendor:buyAmmo(self.quiverBag, self.ammoName, self.itemIsArrow);
end

function script_vendor:buyAmmo(quiverBagSlot, ammoName, itemIsArrow)
	if (not self.isSetup) then
		script_vendor:setup();
	end

	self.quiverBag = quiverBagSlot;
	self.ammoName = ammoName;
	self.itemIsArrow = itemIsArrow;

	if (self.timer > GetTimeEX()) then
		return true;
	end

	local localObj = GetLocalPlayer();
	local x, y, z = localObj:GetPosition();
	local factionID = 1; -- horde
	local factionNr = GetFaction();
	if (factionNr == 1 or factionNr == 3 or factionNr == 4 or factionNr == 115) then
		factionID = 0; -- alliance
	end

	local vendorID = vendorDB:GetVendor(factionID, GetContinentID(), GetMapID(), false, false, false, itemIsArrow, not itemIsArrow, x, y, z);
	local vendor = nil;

	if (itemIsArrow and self.arrowVendor ~= 0) then
		vendor = self.arrowVendor;
	elseif (not itemIsArrow and self.bulletVendor ~= 0) then
		vendor = self.bulletVendor;
	else
		if (vendorID ~= -1) then
			vendor = vendorDB:GetVendorByID(vendorID);
		else
			self.message = "No vendor found, see scripts\\VendorDB.lua...";
			return false;
		end
	end
	
	if (vendor ~= nil) then
		local vX, vY, vZ = vendor['pos']['x'], vendor['pos']['y'], vendor['pos']['z'];
		
		-- Move to vendor
		if (GetDistance3D(x, y, z, vX, vY, vZ) > 3.5) then
			script_nav:moveToTarget(localObj, vX, vY, vZ);
			self.status = 3; -- moving to buy ammo at a vendor
			self.message = 'Moving to ' .. vendor['name'] .. '...';
			self.currentSlot = 0;
			return true;
		end

		script_vendor:removeShapeShift();

		-- Get Vendor Target
		local vendorTarget = nil;
		TargetByName(vendor['name']);
		if (GetTarget() ~= 0 and GetTarget() ~= nil) then
			vendorTarget = GetTarget();
		end

		-- Open the vendor window
		if (vendorTarget ~= nil) then
			
			self.message = 'Buying ammo...';
			if (not IsVendorWindowOpen()) then
				SkipGossip();
				if (vendorTarget:UnitInteract()) then
					return true;
				end
			else

				-- Repair if possible
				if (CanMerchantRepair()) then
					RepairAllItems(); 
				end

				-- BUY AMMO LOGIC
				for y=self.currentSlot,GetContainerNumSlots(quiverBagSlot) do 
					self.currentSlot = self.currentSlot + 1;
					-- At the last slot change status to idle again (buy routine done)
					if (y == GetContainerNumSlots(quiverBagSlot)) then
						self.message = 'Finished buying ammo...';
						self.currentSlot = 0;
						self.currentBag = 0;
						self.sellVendor = vendor;
						self.status = 2;
						return true;
					end

					if (GetContainerItemLink(quiverBagSlot, y) == nil) then
						if (BuyItem(ammoName, 1)) then
							return true;
						else
							self.message = 'Vendor does not have this ammo...';
							-- Vendor doesnt have the type of ammo
							DEFAULT_CHAT_FRAME:AddMessage('script_vendor: Vendor does not have this ammo, pausing...');
							script_grind.pause = true;
							if (self.itemIsArrow) then 
								self.arrowName = "";
							elseif (self.itemIsBullet) then 
								self.bulletName = "";
							end
							return true; 
						end
					end
				end
			end
			return true;
		end
	end

	return false;
end

function script_vendor:continueBuy()
	if (self.itemName == 0 or self.itemNum == 0) then
		self.status = 0; -- idle
		self.message = 'Idle...';
		return false;
	end

	return script_vendor:buy(self.itemName, self.itemNum, self.itemIsFood, self.itemIsDrink);
end

function script_vendor:buy(itemName, itemNum, isFood, isDrink)
	if (not self.isSetup) then
		script_vendor:setup();
	end

	self.itemName = itemName;
	self.itemNum = itemNum;
	self.itemIsFood = isFood;
	self.itemIsDrink = isDrink;

	if (self.timer > GetTimeEX()) then
		return true;
	end

	local localObj = GetLocalPlayer();
	local x, y, z = localObj:GetPosition();
	
	-- Set faction ID (Horde = 1, Alliance = 0)
	local factionID = 1; -- horde
	local factionNr = GetFaction();
	if (factionNr == 1 or factionNr == 3 or factionNr == 4 or factionNr == 115) then
		factionID = 0; -- alliance
	end
	
	local vendor = nil;

	if (isFood and self.foodVendor ~= 0) then
		vendor = self.foodVendor;
	elseif (isDrink and self.drinkVendor ~= 0) then
		vendor = self.drinkVendor;
	else
		-- Fetch a food/drink vendor
		local vendorID = vendorDB:GetVendor(factionID, GetContinentID(), GetMapID(), false, isFood, isDrink, false, x, y, z);

		if (vendorID ~= -1) then
			vendor = vendorDB:GetVendorByID(vendorID);
		else
			self.message = "No vendor found, see core\\VendorDB.lua...";
			return false;
		end
	end
	
	
	if (vendor ~= nil) then
		local vX, vY, vZ = vendor['pos']['x'], vendor['pos']['y'], vendor['pos']['z'];
		
		-- Move to vendor
		if (GetDistance3D(x, y, z, vX, vY, vZ) > 3.5) then
			script_nav:moveToTarget(localObj, vX, vY, vZ);
			self.status = 4; 
			self.message = 'Moving to ' .. vendor['name'] .. '...';
			self.currentSlot = 0;
			return true;
		end

		script_vendor:removeShapeShift();

		-- Get Vendor Target
		local vendorTarget = nil;
		TargetByName(vendor['name']);
		if (GetTarget() ~= 0 and GetTarget() ~= nil) then
			vendorTarget = GetTarget();
		end

		-- Open the vendor window
		if (vendorTarget ~= nil and self.dontBuyTime < GetTimeEX()) then
			
			self.message = 'Buying...';
			if (not IsVendorWindowOpen()) then
				SkipGossip();
				if (vendorTarget:UnitInteract()) then
					return true;
				end
			else
				-- Repair if possible
				if (CanMerchantRepair()) then
					RepairAllItems(); 
				end			

				-- BUY LOGIC
				if (BuyItem(itemName, itemNum)) then
					self.dontBuyTime = GetTimeEX() + 10000;
					self.message = 'Finished buying...';
					-- sell
					self.currentBag = 0;
					self.currentSlot = 0;
					self.status = 2;
					script_vendorMenu:sellLogic();
					return true;
				else
					self.message = 'Vendor does not have this item...';
					self.dontBuyTime = GetTimeEX() + 10000;
					-- If no vendor or vendor doesnt have the type of food/drink
					if (self.itemIsFood) then 
						self.foodName = "";
					elseif (self.itemIsDrink) then 
						self.drinkName = "";
					end
					-- sell
					self.currentBag = 0;
					self.currentSlot = 0;
					self.status = 2;
					script_vendorMenu:sellLogic();
					return true;
				end 
			end
			return true;
		end
	end

	return false;
end

function script_vendor:removeShapeShift()
	if (localObj:HasBuff('Bear Form')) then
		CastSpellByName('Bear Form');
	elseif (localObj:HasBuff('Cat Form')) then
		CastSpellByName('Cat Form');
	elseif (localObj:HasBuff('Travel Form')) then
		CastSpellByName('Travel Form');
	end
end