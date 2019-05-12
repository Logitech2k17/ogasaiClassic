script_followEX = {
	
}

function script_followEX:drawStatus()
	if (script_follow.drawPath) then script_nav:drawPath(); end

	if (script_follow.drawUnits) then script_nav:drawUnitsDataOnScreen(); end
	-- color
	local r, g, b = 255, 255, 0;
	-- position
	local y, x, width = 120, 25, 370;
	local tX, tY, onScreen = WorldToScreen(GetLocalPlayer():GetPosition());
	if (onScreen) then
		y, x = tY-25, tX+75;
	end
	DrawRect(x - 10, y - 5, x + width, y + 80, 255, 255, 0,  1, 1, 1);
	DrawRectFilled(x - 10, y - 5, x + width, y + 80, 0, 0, 0, 160, 0, 0);
	if (script_follow:GetPartyLeaderObject() ~= 0) then
		DrawText('[Follower - Range: ' .. math.floor(script_follow.followDistance) .. ' yd. ' .. 
			 	'Master target: ' .. script_follow:GetPartyLeaderObject():GetUnitName(), x-5, y-4, r, g, b) y = y + 15;
	else
		DrawText('[Follower - Follow range: ' .. math.floor(script_follow.followDistance) .. ' yd. ' .. 
			 	'Master target: ' .. '', x-5, y-4, r, g, b) y = y + 15;
	end 
	DrawText('Status: ', x, y, r, g, b); 
	y = y + 15; DrawText(script_follow.message or "error", x, y, 0, 255, 255);
	y = y + 20; DrawText('Combat script status: ', x, y, r, g, b); y = y + 15;
	RunCombatDraw();
end

function script_grindEX:doLoot(localObj)
	local _x, _y, _z = script_follow.lootObj:GetPosition();
	local dist = script_follow.lootObj:GetDistance();
	
	-- Loot checking/reset target
	if (GetTimeEX() > script_follow.lootCheck['timer']) then
		if (script_follow.lootCheck['target'] == script_follow.lootObj:GetGUID()) then
			script_follow.lootObj = nil; -- reset lootObj
			ClearTarget();
			script_follow.message = 'Reseting loot target...';
		end
		script_follow.lootCheck['timer'] = GetTimeEX() + 10000; -- 10 sec
		if (script_follow.lootObj ~= nil) then 
			script_follow.lootCheck['target'] = script_follow.lootObj:GetGUID();
		else
			script_follow.lootCheck['target'] = 0;
		end
		return;
	end

	if(dist <= script_follow.lootDistance) then
		script_follow.message = "Looting...";
		if(IsMoving() and not localObj:IsMovementDisabed()) then
			StopMoving();
			script_follow.waitTimer = GetTimeEX() + 450;
			return;
		end
		if(not IsStanding()) then
			StopMoving();
			script_follow.waitTimer = GetTimeEX() + 450;
			return;
		end
		
		-- If we reached the loot object, reset the nav path
		script_nav:resetNavigate();

		-- Dismount
		if (IsMounted()) then DisMount(); script_follow.waitTimer = GetTimeEX() + 450; return;  end

		if(not script_follow.lootObj:UnitInteract() and not IsLooting()) then
			script_follow.waitTimer = GetTimeEX() + 950;
			return;
		end
		if (not LootTarget()) then
			script_follow.waitTimer = GetTimeEX() + 650;
			return;
		else
			script_follow.lootObj = nil;
			script_follow.waitTimer = GetTimeEX() + 450;
			return;
		end
	end
	script_follow.message = "Moving to loot...";		
	script_nav:moveToTarget(localObj, _x, _y, _z);	
	script_grind:setWaitTimer(100);
	if (script_follow.lootObj:GetDistance() < 3) then script_follow.waitTimer = GetTimeEX() + 450; end
end

function script_followEX:menu()
	if (not script_follow.pause) then if (Button("Pause Bot")) then script_follow.pause = true; end
	else if (Button("Resume Bot")) then script_follow.myTime = GetTimeEX(); script_follow.pause = false; end end
	SameLine(); if (Button("Reload Scripts")) then coremenu:reload(); end
	SameLine(); if (Button("Exit Bot")) then StopBot(); end

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

	if (CollapsingHeader("[Follower - Options")) then
		local wasClicked = false;
		Text("Combat options:");
		script_follow.dpsHp  = SliderFloat("Monster health when we DPS", 1, 100, script_follow.dpsHp);
		Separator();
		Text("Loot options:");
		wasClicked, script_follow.skipLooting = Checkbox("Skip Looting", script_follow.skipLooting);
		script_follow.findLootDistance = SliderFloat("Find Loot Distance (yd)", 1, 100, script_follow.findLootDistance);	
		script_follow.lootDistance = SliderFloat("Loot Distance (yd)", 1, 6, script_follow.lootDistance);
		Separator();
		Text("Mount options:");
		wasClicked, script_follow.useMount = Checkbox("Use Mount", script_follow.useMount);
		script_follow.disMountRange = SliderInt("Dismount range", 1, 100, script_follow.disMountRange);
		Separator();
		Text("Script tick rate options:");
		script_follow.tickRate = SliderFloat("Tick rate (ms)", 0, 2000, script_follow.tickRate);
	end
end