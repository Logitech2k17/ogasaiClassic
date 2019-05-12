script_fish = {
	PoleName = 'Fishing Pole', 
	useVendor = true,
	wasInCombat = false,
	weaponMainHand = '',
	weaponOffHand = '',
	lureName = 'Shiny Bauble',
	timer = 0,
	bobberInfo = {},
	message = 'Fishing...',
	pause = false,
	setup = false
}

function script_fish:GetBobber()
	local localGUID = GetLocalPlayer():GetGUID();
	local bObj, bType = GetFirstObject();
	while bObj ~= 0 do
		if (bType == 5) then
			if (bObj:GetCreatorsGUID() == localGUID and bObj:GetObjectDisplayID() == 668) then
				if (bObj:GetGUID() == self.bobberInfo.GUID) then
					if (not self.bobberInfo.looted) then
						return bObj;
					end	
				else
					if (bObj:GetObjectState() ~= 0) then
						return bObj;
					end
				end
			end
		end
		bObj, bType = GetNextObject(bObj);
	end
	return 0;
end

function script_fish:DeBugInfo()
	-- color
	local r = 255;
	local g = 2;
	local b = 233;
	
	-- position
	local y = 152;
	local x = 25;
	
	-- info
	DrawRectFilled(x - 10, y - 2, x + 230, y + 16, 0, 0, 0, 160, 10, -10);
	DrawLine(x - 10, y - 2, x - 10, y + 16, r, g, b, 2);
	DrawText(self.message, x, y, r, g, b); y = y + 15;
	
	local tX, tY, onScreen = WorldToScreen(self.bobberInfo.x, self.bobberInfo.y, self.bobberInfo.z);
	if(onScreen) then
		DrawText('^', tX, tY, r, g, b);
	end
end

function script_fish:draw()

	script_fish:DeBugInfo();

	EndWindow();
	if(NewWindow("Fishing options", 320, 300)) then 
		script_fish:menu(); 
	end
	
end

function script_fish:run()

	if (not self.setup) then
		script_vendor:setup();
		
		DEFAULT_CHAT_FRAME:AddMessage('script_fish: loaded...');
		self.setup = true;
		return;
	end
	
	local localObj = GetLocalPlayer();
	local isInCombat = IsInCombat();

	if (self.pause) then
		self.message = "Paused by user...";
		return;
	end
	
	--[[Spawn Weapon]]--
	if (isInCombat and not self.wasInCombat) then
	
		self.wasInCombat = true;

		UseItem(weaponMainHand);
		UseItem(weaponOffHand);
		
	elseif(not isInCombat and self.wasInCombat) then
	
		self.wasInCombat = false;
		
	end
	
	if(isInCombat) then
	
		self.message = "In Combat!";
		
		--IMPROVE
		if(GetTarget() ~= 0) then
			RunCombatScript(GetTarget():GetGUID());
		end
		
		return
	else
	
		if (RunRestScript()) then
			
			self.message = "Resting!";
			
			return;
		end
	end

	if(self.timer > GetTime()) then
		return;
	end

	if (script_vendor.status == 2) then
		if(script_vendor:sell()) then
			self.timer = GetTime() + 0.2;
			self.message = script_vendor.message;
			return;
		end
		
	end
	
	if (AreBagsFull()) then
	
		if(self.useVendor) then
			if (script_vendor.sellVendor ~= 0) then
				script_vendor:sell();
				return;
			else
				self.message = "No sell vendor loaded...";
				return;
			end
		else
			SetSatusText("Fishing", "Bot Stopped, Bags are Full!");
			
			StopBot();
			
			return;
		end

	end
	
	----------------------------------------
	
	bobberobj = script_fish:GetBobber();
	
	if (bobberobj ~= 0) then		
		if (self.bobberInfo.GUID ~= bobberobj:GetGUID()) then
			self.bobberInfo.x, self.bobberInfo.y, self.bobberInfo.z = bobberobj:GetObjectPosition();
			self.bobberInfo.obj = bobberobj;
			self.bobberInfo.GUID = bobberobj:GetGUID();
			self.bobberInfo.looted = false;
		end
	end
	
	if (bobberobj == 0 and not IsMoving() and not IsChanneling() and not IsCasting() and not IsLooting()) then
		
		if (IsMounted()) then
		
			self.message = "Dismount!";
			
			DisMount();
			
			self.timer = GetTime() + 1;
			
			return;
		end		

		self.message = "Cast Fishing Rod!";
		
		UseItem(self.PoleName);

		if (script_fish:checkLure(self.lureName)) then
			self.timer = GetTime() + 6;
			return;
		end	
	
		CastSpellByName("Fishing");

		self.timer = GetTime() + 1;
		
	elseif (bobberobj ~= 0) then		
		if (bobberobj:GetObjectState() == 0) then
		
			self.message = "Loot Fish!";
			
			if (not IsLooting()) then		
				bobberobj:GameObjectInteract();
				self.timer = GetTime() + 0.5;
			else
				LootTarget();
				self.timer = GetTime() + 0.2;
				self.bobberInfo.looted = true;
			end
		else
			self.message = "Waiting for bobber to move...";
		end
	end
end


function script_fish:menu()

	--if (CollapsingHeader("[Fishing options")) then

		if (not self.pause) then 
			if (Button("Pause Bot")) then 
				self.pause = true; 
			end
		else 
			if (Button("Resume Bot")) then 
				self.pause = false; 
			end 
		end
		SameLine(); if (Button("Reload Scripts")) then coremenu:reload(); end
		SameLine(); if (Button("Exit Bot")) then StopBot(); end

		Separator();
		
		self.PoleName = InputText("Pole Name", self.PoleName);
		self.lureName = InputText("Lure Name", self.lureName);

		Separator();

		self.weaponMainHand = InputText("Main Weapon Name", self.weaponMainHand);
		self.weaponOffHand = InputText("OffHand Weapon Name", self.weaponOffHand);
		
		Separator();
		
		local wasClicked = false;
		
		wasClicked, self.useVendor = Checkbox("Use Vendor", self.useVendor);

		if (self.useVendor) then

			Text("Sell Vendor:");
			if (script_vendor.sellVendor ~= 0) then
				SameLine();
				Text('' .. script_vendor.sellVendor['name'] .. ' loaded.');
				if Button("Sell Now") then script_vendor.status = 2; end
			end

			if Button("Set current target as sell vendor") then 
				script_vendorMenu:setSellVendor(); 
			end

			if (CollapsingHeader("[Selling options:")) then
				local wasClicked = false;
				local keepBox = false;
				wasClicked, script_vendor.sellPoor = Checkbox("Sell poor items (grey)", script_vendor.sellPoor);
				wasClicked, script_vendor.sellCommon = Checkbox("Sell common items (white)", script_vendor.sellCommon);
				wasClicked, script_vendor.sellUncommon = Checkbox("Sell uncommon items (green)", script_vendor.sellUncommon);
				wasClicked, script_vendor.sellRare = Checkbox("Sell rare items (blue)", script_vendor.sellRare);
				wasClicked, script_vendor.sellEpic = Checkbox("Sell epic items (purple)", script_vendor.sellEpic);
				Separator();
				Text("Unique Keep Items:");
				wasClicked, script_vendor.selectedKeepItemNr = ComboBox("", script_vendor.selectedKeepItemNr, unpack(script_vendor.keepItems));
				if Button("Remove") then
					script_vendor:deleteKeepItem(script_vendor.selectedKeepItemNr+1);
				end
				SameLine();
				Text(" - Removes selected item from the keep list...");
				if Button("Add Item") then
					script_vendor:addSaveItem(script_vendor.addItemName);
				end
				SameLine();
				script_vendor.addItemName = InputText("", script_vendor.addItemName);
				Separator();
				Text("Tip: All items in your bag will be added to the");
				Text("keep item list when reloading scripts...");
			end
		end
	--end
end

function script_fish:checkLure(lureName)
	hasMainHandEnchant, _, _, _, _, _ = GetWeaponEnchantInfo();
	if (hasMainHandEnchant == nil) then 
		-- Apply enhancement
		if (HasItem(lureName)) then

			-- Check: Stop moving, sitting
			if (not IsStanding() or IsMoving()) then 
				StopMoving(); 
				return true;
			end 

			UseItem(lureName);
			PickupInventoryItem(16);
			message = "Applying " .. lureName .. " on fish pole.";
		else
			return false;
		end
		return true;
	end
	return false;
end