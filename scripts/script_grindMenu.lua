script_grindMenu = {
	selectedHotspotID = 0;
	targetMenu = include("//scripts//script_targetMenu.lua");
}

function script_grindMenu:printHotspot()
	DEFAULT_CHAT_FRAME:AddMessage('script_grind: Add this hotspot to your database by adding the following line in the setup-function in hotspotDB.lua:');
	DEFAULT_CHAT_FRAME:AddMessage('You can copy the line from logs//.txt');
	local race, level = UnitRace("player"), GetLocalPlayer():GetLevel();
	local x, y, z = GetLocalPlayer():GetPosition();
	local hx, hy, hz = math.floor(x*100)/100, math.floor(y*100)/100, math.floor(z*100)/100;
	local addString = 'hotspotDB:addHotspot("' .. GetMinimapZoneText() .. ' ' .. level .. ' - ' .. level+2 .. '", "' .. race
					.. '", ' .. level .. ', ' .. level+2 .. ', ' .. hx .. ', ' .. hy .. ', ' .. hz .. ');'	
	DEFAULT_CHAT_FRAME:AddMessage(addString);
	ToFile(addString);
end

function script_grindMenu:menu()
	if (not script_grind.pause) then if (Button("Pause Bot")) then script_grind.pause = true; end
	else if (Button("Resume Bot")) then script_grind.myTime = GetTimeEX(); script_grind.pause = false; end end
	SameLine(); if (Button("Reload Scripts")) then coremenu:reload(); end
	SameLine(); if (Button("Exit Bot")) then StopBot(); end
	local wasClicked = false;
	-- Load combat menu by class
	local class = UnitClass("player");
	if (class == 'Mage') then
		script_mage:menu();
	elseif (class == 'Hunter') then
		script_hunter:menu();
	elseif (class == 'Warlock') then
		script_warlock:menu();
	elseif (class == 'Paladin') then
		script_paladin:menu();
	elseif (class == 'Druid') then
		script_druid:menu();
	elseif (class == 'Priest') then
		script_priest:menu();
	elseif (class == 'Warrior') then
		script_warrior:menu();
	elseif (class == 'Rogue') then
		script_rogue:menu();
	elseif (class == 'Shaman') then
		script_shaman:menu();
	end	
	if (CollapsingHeader("[Mount, Talents & Misc options")) then
		wasClicked, script_grind.useMount = Checkbox("Use Mount", script_grind.useMount); Text('Dismount range');
		script_grind.disMountRange = SliderInt("DR (yd)", 1, 100, script_grind.disMountRange); Separator();
		wasClicked, script_grind.autoTalent = Checkbox("Spend talent points", script_grind.autoTalent);
	Text("Change talents in script_talent.lua");
	if (script_grind.autoTalent) then Text("Spending next talent point in: " .. (script_talent:getNextTalentName() or " ")); end
	Separator();
		wasClicked, script_grind.paranoidOn = Checkbox("Enable Paranoia", script_grind.paranoidOn);
		wasClicked, script_grind.paranoidOnTargeted = Checkbox("Paranoid when targeted by players", script_grind.paranoidOnTargeted);
	 	Text('Paranoia Range'); script_grind.paranoidRange = SliderInt("P (yd)", 1, 120, script_grind.paranoidRange);
	end
	if (CollapsingHeader("[Vendor options")) then
		wasClicked, script_grind.useVendor = Checkbox("Vendor on/off", script_grind.useVendor);
		if (script_grind.useVendor) then 
			script_vendorMenu:menu(); Separator();
		else
			Separator(); Text("When bags are full");
			wasClicked, script_grind.hsWhenFull = Checkbox("Use Hearthstone", script_grind.hsWhenFull); SameLine();
			wasClicked, script_grind.stopWhenFull = Checkbox("Stop the bot", script_grind.stopWhenFull); Separator();
		end
	end
	if (CollapsingHeader("[Path options")) then
		local wasClicked = false;
		wasClicked, script_grind.autoPath = Checkbox("Auto pathing (disable to use walk paths)", script_grind.autoPath);
		if (script_grind.autoPath) then
			wasClicked, script_grind.staticHotSpot = Checkbox("Auto load hotspots from //db//hotspotDB.lua", script_grind.staticHotSpot);
			Text("Select a hotspot from database:");
			wasClicked, self.selectedHotspotID = 
				ComboBox("", self.selectedHotspotID, unpack(hotspotDB.selectionList));
			SameLine();
			if Button("Load") then script_grind.staticHotSpot = false; script_nav:loadHotspotDB(self.selectedHotspotID+1); end
			if (Button("Save current location as the new Hotspot")) then script_nav:newHotspot(GetMinimapZoneText() .. ' ' .. GetLocalPlayer():GetLevel() .. ' - ' .. GetLocalPlayer():GetLevel()+2); script_grind.staticHotSpot = false; script_grindMenu:printHotspot(); end
			Text('Distance to hotspot');
			script_grind.distToHotSpot = SliderInt("DHS (yd)", 1, 1000, script_grind.distToHotSpot); Separator();
		else
			Separator();
			Text("Current walk path"); Text("E.g. paths\\1-5 Durotar.xml"); script_grind.pathName = InputText(' ', script_grind.pathName); Separator();
			Text('Next node distance'); script_grind.nextToNodeDist = SliderFloat("ND (yd)", 1, 10, script_grind.nextToNodeDist); Separator();
		end
		wasClicked, script_grind.useUnstuck = Checkbox("Use Unstuck Feature (script_unstuck)", script_grind.useUnstuck);
		Separator()
		wasClicked, script_grind.safeRess = Checkbox("Try to ress on a safe spot", script_grind.safeRess);
		Text('Ress corpse distance'); script_grind.ressDistance = SliderFloat("RD (yd)", 1, 35, script_grind.ressDistance); Separator();
		Text("Script tick rate"); script_grind.tickRate = SliderFloat("TR (ms)", 0, 2000, script_grind.tickRate);
			
	end

	script_targetMenu:menu();

	if (CollapsingHeader("[Loot options")) then
		local wasClicked = false;
		wasClicked, script_grind.skipLooting = Checkbox("Skip Looting", script_grind.skipLooting);
		wasClicked, script_grind.skinning = Checkbox("Use Skinning", script_grind.skinning);
		Text('Search for Loot Distance'); script_grind.findLootDistance = SliderFloat("SFL (yd)", 1, 100, script_grind.findLootDistance); Text('Loot Corpse Distance');	 script_grind.lootDistance = SliderFloat("LCD (yd)", 1, 6, script_grind.lootDistance);
	end
	script_gather:menu();
	if (CollapsingHeader('[Display options')) then
		local wasClicked = false;
		wasClicked, script_grind.drawEnabled = Checkbox('Show status window', script_grind.drawEnabled);
		wasClicked, script_grind.drawGather = Checkbox('Show gather nodes', script_grind.drawGather);
		wasClicked, script_grind.drawAutoPath = Checkbox('Show auto path nodes', script_grind.drawAutoPath);
		wasClicked, script_grind.drawPath = Checkbox('Show move path', script_grind.drawPath);
		wasClicked, script_grind.drawUnits = Checkbox("Show unit info on screen", script_grind.drawUnits);
		wasClicked, script_grind.drawAggro = Checkbox('Show aggro range', script_grind.drawAggro);
	end
end