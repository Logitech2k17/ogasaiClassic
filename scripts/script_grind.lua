script_grind = {
	jump = false,
	useVendor = true,
	repairWhenYellow = true,
	stopWhenFull = false,
	hsWhenFull = false,
	useMount = true,
	disMountRange = 32,
	mountTimer = GetTimeEX(),
	enemyObj = nil,
	lootObj = nil,
	timer = GetTimeEX(),
	tickRate = 200,
	waitTimer = GetTimeEX(),
	pullDistance = 150,
	avoidElite = false,
	avoidRange = 40,
	findLootDistance = 60,
	lootDistance = 3,
	skipLooting = false,
	lootCheck = {},
	minLevel = GetLocalPlayer():GetLevel()-5,
	maxLevel = GetLocalPlayer():GetLevel()+1,
	ressDistance = 34,
	combatError = 0,
	autoTalent = true,
	myX = 0,
	myY = 0,
	myZ = 0,
	myTime = GetTimeEX(),
	message = 'Starting the grinder...',
	skipHumanoid = false,
	skipElemental = false,
	skipUndead = false,
	skipDemon = false,
	skipBeast = false,
	skipAberration = false,
	skipDragonkin = false,
	skipGiant = false,
	skipMechanical = false,
	skipElites = true,
	paranoidOn = false,
	paranoidOnTargeted = true,
	paranoidRange = 60,
	navFunctionsLoaded = include("scripts\\script_nav.lua"),
	helperLoaded = include("scripts\\script_helper.lua"),
	talentLoaded = include("scripts\\script_talent.lua"),
	vendorLoaded = include("scripts\\script_vendor.lua"),
	gatherLoaded = include("scripts\\script_gather.lua"),
	grindExtra = include("scripts\\script_grindEX.lua"),
	grindMenu = include("scripts\\script_grindMenu.lua"),
	aggroLoaded = include("scripts\\script_aggro.lua"),
	unstuckLoaded = include("scripts\\script_unstuck.lua"),
	nextToNodeDist = 4, -- (Set to about half your nav smoothness)
	blacklistedTargets = {},
	blacklistedNum = 0,
	isSetup = false,
	drawUnits = true,
	pathName = "", -- set to e.g. "paths\1-5 Durator.xml" for auto load at startup
	pathLoaded = "",
	drawPath = true,
	autoPath = true,
	drawAutoPath = true,
	distToHotSpot = 200,
	staticHotSpot = true,
	hotSpotTimer = GetTimeEX(),
	currentLevel = GetLocalPlayer():GetLevel(),
	skinning = true,
	gather = true,
	lastTarget = 0,
	newTargetTime = GetTimeEX(),
	blacklistTime = 30,
	drawEnabled = true,
	showClassOptions = true,
	pause = false,
	bagsFull = false,
	vendorRefill = true,
	useMana = true,
	drawGather = true,
	hotspotReached = false,
	drawAggro = false,
	safeRess = true,
	skipHardPull = true,
	useUnstuck = true
}

function script_grind:setup()
	self.lootCheck['target'] = 0;
	self.lootCheck['timer'] = GetTimeEX();

	-- Classes that doesn't use mana
	local class, classFileName = UnitClass("player");
	if (strfind("Warrior", class) or strfind("Rogue", class)) then self.useMana = false; self.restMana = 0; end
	
	-- No refill as mage or at level 1
	if (strfind("Mage", class)) then self.vendorRefill = false; end

	if (GetLocalPlayer():GetLevel() < 3) then self.vendorRefill = false; end

	if (GetLocalPlayer():GetLevel() < 8) then self.skipHardPull = false; end

	self.drawEnabled = true;
	script_helper:setup();
	script_talent:setup();
	script_vendor:setup();
	script_gather:setup();
	DEFAULT_CHAT_FRAME:AddMessage('script_grind_logitech: loaded...');
	vendorDB:setup();
	hotspotDB:setup();
	vendorDB:loadDBVendors();
	script_nav:setup();
	self.isSetup = true;
	
end

function script_grind:window()
	EndWindow();
	if(NewWindow("Logitech's Grinder", 320, 300)) then script_grindMenu:menu(); end
end

function script_grind:setWaitTimer(ms)
	self.waitTimer = GetTimeEX() + ms;
end

function script_grind:addTargetToBlacklist(targetGUID)
	if (targetGUID ~= nil and targetGUID ~= 0 and targetGUID ~= '') then	
		self.blacklistedTargets[self.blacklistedNum] = targetGUID;
		self.blacklistedNum = self.blacklistedNum + 1;
	end
end

function script_grind:isTargetBlacklisted(targetGUID) 
	for i=0,self.blacklistedNum do
		if (targetGUID == self.blacklistedTargets[i]) then
			return true;
		end
	end
	return false;
end

function script_grind:run()
	script_grind:window();

	-- Set next to node distance and nav-mesh smoothness to double that number
	if (IsMounted()) then
		script_nav:setNextToNodeDist(5); NavmeshSmooth(10);
	else
		script_nav:setNextToNodeDist(self.nextToNodeDist); NavmeshSmooth(self.nextToNodeDist*2);
	end

	if (not self.isSetup) then script_grind:setup(); end

	if (not self.navFunctionsLoaded) then self.message = "Error script_nav not loaded..."; return; end
	if (not self.helperLoaded) then self.message = "Error script_helper not loaded..."; return; end

	if (self.useUnstuck and IsMoving()) then
		if (not script_unstuck:pathClearAuto(2)) then
			script_unstuck:unstuck();
			return true;
		end
	end

	if (self.pause) then self.message = "Paused by user..."; return; end

	-- Check: Spend talent points
	if (not IsInCombat() and not GetLocalPlayer():IsDead() and self.autoTalent) then
		if (script_talent:learnTalents()) then
			self.message = "Checking/learning talent: " .. script_talent:getNextTalentName();
			return;
		end
	end
	
	localObj = GetLocalPlayer();

	-- Check: Paranoid feature
	if (not localObj:IsDead() and self.paranoidOn and not IsInCombat()) then 
		if (self.paranoidOnTargeted and script_grind:playersTargetingUs() > 0) then
			self.message = "Player(s) targeting us, pausing...";
			ClearTarget();
			return;
		end
		if (script_grind:playersWithinRange(self.paranoidRange)) then
			self.message = "Player(s) within paranoid range, pausing...";
			ClearTarget();
			return;
		end
	end

	if(GetTimeEX() > self.timer) then
		self.timer = GetTimeEX() + self.tickRate;

		-- Do all checks
		if (script_grindEX:doChecks()) then
			return;
		end

		-- Check: If our gear is yellow
		for i = 1, 16 do
		local status = GetInventoryAlertStatus('' .. i);
			if (status ~= nil) then 
				if (status >= 3 and script_grind.repairWhenYellow and script_grind.useVendor and script_vendor.repairVendor ~= 0 and not IsInCombat()) then
					script_vendor:repair(); 
					return true;
				end
			end
		end

		-- Jump
		if (self.jump) then
			local jr = random(1, 100);
			if (jr > 90 and IsMoving()) then
				JumpOrAscendStart();
			end
		end

		-- Gather
		if (self.gather and not IsInCombat() and not AreBagsFull() and not self.bagsFull) then
			if (script_gather:gather()) then
				self.message = 'Gathering ' .. script_gather:currentGatherName() .. '...';
				return;
			end
		end
		
		-- Auto path: keep us inside the distance to the current hotspot, if mounted keep running even if in combat
		if ((not IsInCombat() or IsMounted()) and self.autoPath and script_vendor:getStatus() == 0 and
			(script_nav:getDistanceToHotspot() > self.distToHotSpot or self.hotSpotTimer > GetTimeEX())) then
			if (not (self.hotSpotTimer > GetTimeEX())) then self.hotSpotTimer = GetTimeEX() + 20000; end
			if (script_grind:mountUp()) then return; end
			-- Druid cat form is faster if you specc talents
			if (self.currentLevel < 40 and HasSpell('Cat Form') and not localObj:HasBuff('Cat Form')) then
				CastSpellByName('Cat Form');
			end
			-- Shaman Ghost Wolf 
			if (self.currentLevel < 40 and HasSpell('Ghost Wolf') and not localObj:HasBuff('Ghost Wolf')) then
				CastSpellByName('Ghost Wolf');
			end
			self.message = script_nav:moveToHotspot(localObj);
			script_grind:setWaitTimer(100);
			return;
		end
		
		-- Assign the next valid target to be killed within the pull range
		if (self.enemyObj ~= 0 and self.enemyObj ~= nil) then
			self.lastTarget = self.enemyObj:GetGUID();
		end
		self.enemyObj = script_grind:assignTarget();
		
		if (self.enemyObj ~= 0 and self.enemyObj ~= nil) then
			-- Fix bug, when not targeting correctly
			if (self.lastTarget ~= self.enemyObj:GetGUID()) then
				self.newTargetTime = GetTimeEX();
				ClearTarget();
			elseif (self.lastTarget == self.enemyObj:GetGUID() and not IsStanding() and not IsInCombat()) then
				self.newTargetTime = GetTimeEX(); -- reset time if we rest
			-- blacklist the target if we had it for a long time and hp is high
			elseif (((GetTimeEX()-self.newTargetTime)/1000) > self.blacklistTime and self.enemyObj:GetHealthPercentage() > 80) then 
				script_grind:addTargetToBlacklist(self.enemyObj:GetGUID());
				ClearTarget();
				return;
			end
		end

		-- Dont pull mobs before we reached our hotspot
		if (not IsInCombat() and not self.hotspotReached) then
			self.enemyObj = nil;
		end

		-- Dont pull if more than 1 add will be pulled
		if (self.enemyObj ~= nil and self.enemyObj ~= 0 and self.skipHardPull) then
			if (not script_aggro:safePull(self.enemyObj) and not IsInCombat()) then
				script_grind:addTargetToBlacklist(self.enemyObj:GetGUID());
				DEFAULT_CHAT_FRAME:AddMessage('script_grind: Blacklisting ' .. self.enemyObj:GetUnitName() .. ', too many adds...');
				self.enemyObj = nil;
			end
		end

		-- Finish loot before we engage new targets or navigate
		if (self.lootObj ~= nil and not IsInCombat()) then 
			return; 
		else
			-- reset the combat status
			self.combatError = nil; 
			-- Run the combat script and retrieve combat script status if we have a valid target
			if (self.enemyObj ~= nil and self.enemyObj ~= 0) then
				self.combatError = RunCombatScript(self.enemyObj:GetGUID());
			end
		end

		if(self.enemyObj ~= nil or IsInCombat()) then
			self.message = "Running the combat script...";
			-- In range: attack the target, combat script returns 0
			if(self.combatError == 0) then
				script_nav:resetNavigate();
				if IsMoving() then StopMoving(); return; end
				-- Dismount
				if (IsMounted()) then DisMount(); return; end
			end
			-- Invalid target: combat script return 2
			if(self.combatError == 2) then
				-- TODO: add blacklist GUID here
				self.enemyObj = nil;
				ClearTarget();
				return;
			end
			-- Move in range: combat script return 3
			if (self.combatError == 3) then
				self.message = "Moving to target...";
				if (self.enemyObj:GetDistance() < self.disMountRange) then
					-- Dismount
					if (IsMounted()) then DisMount(); return; end
				end
				local _x, _y, _z = self.enemyObj:GetPosition();
				local localObj = GetLocalPlayer();
				if (_x ~= 0 and x ~= 0) then
					self.message = script_nav:moveToTarget(localObj, _x, _y, _z);
					script_grind:setWaitTimer(100);
				end
				return;
			end
			-- Do nothing, return : combat script return 4
			if(self.combatError == 4) then return; end
			-- Target player pet/totem: pause for 5 seconds, combat script should add target to blacklist
			if(self.combatError == 5) then
				self.message = "Targeted a player pet pausing 5s...";
				ClearTarget(); self.waitTimer = GetTimeEX()+5000; return;
			end
			-- Stop bot, request from a combat script
			if(self.combatError == 6) then self.message = "Combat script request stop bot..."; Logout(); StopBot(); return; end
		end

		-- Pre checks before navigating
		if(IsLooting() or IsCasting() or IsChanneling() or IsDrinking() or IsEating() or IsInCombat()) then return; end

		-- Mount before we navigate through the path, error check to get around indoors
		if (script_grind:mountUp()) then return; end	

		-- Use auto pathing or walk paths
		if (self.autoPath) then
			if (script_nav:getDistanceToHotspot() < 10 and not self.hotspotReached) then
				self.message = "Hotspot reached... (No targets around?)";
				self.hotspotReached = true;
				return;
			else
				self.message = script_nav:moveToSavedLocation(localObj, self.minLevel, self.maxLevel, self.staticHotSpot);
				script_grind:setWaitTimer(100);
			end
		else
			-- Check: Load/Refresh the walk path
			if (self.pathName ~= self.pathLoaded) then
				if (not LoadPath(self.pathName, 0)) then self.message = "No walk path has been loaded..."; return; end
				self.pathLoaded = self.pathName;
			end
			-- Navigate
			self.message = script_nav:navigate(localObj);
		end
	end 
end

function script_grind:mountUp()
	local __, lastError = GetLastError();
	if (lastError ~= 75 and self.mountTimer < GetTimeEX()) then
		if(GetLocalPlayer():GetLevel() >= 40 and self.useMount and not IsSwimming() and not IsIndoors() and not IsMounted() and self.lootObj == nil) then
			self.message = "Mounting...";
			if (not IsStanding()) then StopMoving(); end
			if (script_helper:useMount()) then self.waitTimer = GetTimeEX() + 4000; return true; end
		end
	else
		ClearLastError();
		self.mountTimer = GetTimeEX() + 15000;
		return false;
	end
end

function script_grind:getTarget()
	return self.enemyObj;
end

function script_grind:getTargetAttackingUs() 
    local currentObj, typeObj = GetFirstObject(); 
    while currentObj ~= 0 do 
    	if typeObj == 3 then
		if (currentObj:CanAttack() and not currentObj:IsDead()) then
			local localObj = GetLocalPlayer();
			local targetTarget = currentObj:GetUnitsTarget();
			if (targetTarget ~= 0 and targetTarget ~= nil) then
				if (targetTarget:GetGUID() == localObj:GetGUID()) then
					return currentObj:GetGUID();
				end
			end	
                	if (script_grind:isTargetingGroup(currentObj)) then 
                		return currentObj:GetGUID();
                	end 
            	end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return nil;
end

function script_grind:assignTarget() 
	-- Return a target attacking our group
	local i, targetType = GetFirstObject();
	while i ~= 0 do
		if (script_grind:isTargetingGroup(i)) then
			return i;
		end
		i, targetType = GetNextObject(i);
	end

	-- Instantly return the last target if we attacked it and it's still alive and we are in combat
	if (self.enemyObj ~= 0 and self.enemyObj ~= nil and not self.enemyObj:IsDead() and IsInCombat()) then
		if (script_grind:isTargetingMe(self.enemyObj) 
			or script_grind:isTargetingPet(self.enemyObj) 
			or self.enemyObj:IsTappedByMe()) then
			return self.enemyObj;
		end
	end

	-- Find the closest valid target if we have no target or we are not in combat
	local mobDistance = self.pullDistance;
	local closestTarget = nil;
	local i, targetType = GetFirstObject();
	while i ~= 0 do
		if (targetType == 3 and not i:IsCritter() and not i:IsDead() and i:CanAttack()) then
			if (script_grind:enemyIsValid(i)) then
				-- save the closest mob or mobs attacking us
				if (mobDistance > i:GetDistance()) then
					local _x, _y, _z = i:GetPosition();
					if(not IsNodeBlacklisted(_x, _y, _z, self.nextNavNodeDistance)) then
						mobDistance = i:GetDistance();	
						closestTarget = i;
					end
				end
			end
		end
		i, targetType = GetNextObject(i);
	end
	
	-- Check: If we are in combat but no valid target, kill the "unvalid" target attacking us
	if (closestTarget == nil and IsInCombat()) then
		if (GetTarget() ~= 0) then
			return GetTarget();
		end
	end

	-- Return the closest valid target or nil
	return closestTarget;
end

function script_grind:isTargetingPet(i) 
	local pet = GetPet();
	if (pet ~= nil and pet ~= 0 and not pet:IsDead()) then
		if (i:GetUnitsTarget() ~= nil and i:GetUnitsTarget() ~= 0) then
			return i:GetUnitsTarget():GetGUID() == pet:GetGUID();
		end
	end
	return false;
end

function script_grind:isTargetingGroup(y) 
	for i = 1, GetNumPartyMembers() do
		local partyMember = GetPartyMember(i);
		if (partyMember ~= nil and partyMember ~= 0 and not partyMember:IsDead()) then
			if (y:GetUnitsTarget() ~= nil and y:GetUnitsTarget() ~= 0 and not script_grind:isTargetingPet(y)) then
				return y:GetUnitsTarget():GetGUID() == partyMember:GetGUID();
			end
		end
	end

	return false;
end

function script_grind:isTargetingMe(i) 
	local localPlayer = GetLocalPlayer();
	if (localPlayer ~= nil and localPlayer ~= 0 and not localPlayer:IsDead()) then
		if (i:GetUnitsTarget() ~= nil and i:GetUnitsTarget() ~= 0) then
			return i:GetUnitsTarget():GetGUID() == localPlayer:GetGUID();
		end
	end
	return false;
end

function script_grind:enemyIsValid(i)
	if (i ~= 0) then
		-- Valid Targets: Tapped by us, or is attacking us or our pet
		if (script_grind:isTargetingMe(i)
			or (script_grind:isTargetingPet(i) and (i:IsTappedByMe() or not i:IsTapped())) 
			or (script_grind:isTargetingGroup(i) and (i:IsTappedByMe() or not i:IsTapped())) 
			or (i:IsTappedByMe() and not i:IsDead())) then 
				return true; 
		end
		-- Valid Targets: Within pull range, levelrange, not tapped, not skipped etc
		if (not i:IsDead() and i:CanAttack() and not i:IsCritter()
			and ((i:GetLevel() <= self.maxLevel and i:GetLevel() >= self.minLevel))
			and i:GetDistance() < self.pullDistance and (not i:IsTapped() or i:IsTappedByMe())
			and (not script_grind:isTargetBlacklisted(i:GetGUID()) and not script_grind:isTargetingMe(i)) 
			and not (self.skipHumanoid and i:GetCreatureType() == 'Humanoid')
			and not (self.skipDemon and i:GetCreatureType() == 'Demon')
			and not (self.skipBeast and i:GetCreatureType() == 'Beast')
			and not (self.skipElemental and i:GetCreatureType() == 'Elemental')
			and not (self.skipUndead and i:GetCreatureType() == 'Undead') 
			and not (skipAberration and i:GetCreatureType() == 'Abberration') 
			and not (skipDragonkin and i:GetCreatureType() == 'Dragonkin') 
			and not (skipGiant and i:GetCreatureType() == 'Giant') 
			and not (skipMechanical and i:GetCreatureType() == 'Mechanical') 
			and not (self.skipElites and (i:GetClassification() == 1 or i:GetClassification() == 2))
			) then
			return true;
		end
	end
	return false;
end

function script_grind:enemiesAttackingUs() -- returns number of enemies attacking us
	local unitsAttackingUs = 0; 
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
    	if typeObj == 3 then
		if (currentObj:CanAttack() and not currentObj:IsDead()) then
                	if (script_grind:isTargetingMe(currentObj) or script_grind:isTargetingPet(currentObj)) then 
                		unitsAttackingUs = unitsAttackingUs + 1; 
                	end 
            	end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return unitsAttackingUs;
end

function script_grind:playersTargetingUs() -- returns number of players attacking us
	local nrPlayersTargetingUs = 0; 
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
	if typeObj == 4 then
		if (script_grind:isTargetingMe(currentObj)) then 
                	nrPlayersTargetingUs = nrPlayersTargetingUs + 1; 
                end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return nrPlayersTargetingUs;
end

function script_grind:playersWithinRange(range)
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
    	if (typeObj == 4 and not currentObj:IsDead()) then
		if (currentObj:GetDistance() < range) then 
			local localObj = GetLocalPlayer();
			if (localObj:GetGUID() ~= currentObj:GetGUID()) then
                		return true;
			end
                end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return false;
end

function script_grind:getDistanceDif()
	local x, y, z = GetLocalPlayer():GetPosition();
	local xV, yV, zV = self.myX-x, self.myY-y, self.myZ-z;
	return math.sqrt(xV^2 + yV^2 + zV^2);
end

function script_grind:drawStatus()
	if (self.drawAggro) then script_aggro:drawAggroCircles(100); end
	if (self.autoPath and self.drawAutoPath) then script_nav:drawSavedTargetLocations(); end
	if (self.drawGather) then script_gather:drawGatherNodes(); end
	if (self.drawPath) then if (IsMoving()) then script_nav:drawPath(); end end
	if (self.drawUnits) then script_nav:drawUnitsDataOnScreen(); end
	if (not self.drawEnabled and self.showClassOptions) then RunCombatDraw() end
	if (not self.drawEnabled) then return; end

	-- color
	local r, g, b = 255, 255, 0;
	-- position
	local y, x, width = 120, 25, 370;
	local tX, tY, onScreen = WorldToScreen(GetLocalPlayer():GetPosition());
	if (onScreen) then
		y, x = tY-25, tX+75;
	end
	-- info
	if (not self.pause) then
	DrawRect(x - 10, y - 5, x + width, y + 140, 255, 255, 0,  1, 1, 1);
	DrawRectFilled(x - 10, y - 5, x + width, y + 140, 0, 0, 0, 100, 0, 0);
	DrawText('[Grinder - Pull range: ' .. math.floor(self.pullDistance) .. ' yd. ' .. 
			 	'Level range: ' .. self.minLevel .. '-' .. self.maxLevel, x-5, y-4, r, g, b) y = y + 15;
	
	DrawText('Grinder status: ', x, y, r, g, b); y = y + 15;
	DrawText(self.message or "error", x, y, 0, 255, 255);
	y = y + 20; DrawText('Combat script status: ', x, y, r, g, b); y = y + 15;
	if (self.showClassOptions) then RunCombatDraw(); end
	 y = y + 20;
	if (self.autoPath) then 
		DrawText('Auto path: ON! Hotspot: ' .. script_nav:getHotSpotName(), x, y, r, g, b); y = y + 20;
	else
		DrawText('Auto path: OFF!', x, y, r, g, b); y = y + 20;
	end
	DrawText('Vendor - ' .. script_vendorMenu:getInfo(), x, y, r, g, b); y = y + 15;
	DrawText('Status: ', x, y, r, g, b);
	DrawText(script_vendor:getMessage(), x+52, y, 0, 255, 255); 
	local time = ((GetTimeEX()-self.newTargetTime)/1000); 
	if (self.enemyObj ~= 0 and self.enemyObj ~= nil and not self.enemyObj:IsDead()) then
		DrawRect(x - 10, y + 19, x + width, y + 45, 255, 255, 0,  1, 1, 1);
		DrawRectFilled(x-10, y+20, x + width, y + 45, 0, 0, 0, 100, 0, 0);
		DrawText('Blacklist-timer: ' .. self.enemyObj:GetUnitName() .. ': ' .. time .. ' s.', x, y+20, 0, 255, 255); 
		DrawText('Blacklisting target after ' .. self.blacklistTime .. " s. (If above 80% HP.)", x, y+30, 255, 255, 0);
	end
	else
		DrawText('Grinder paused by user...', x-5, y-4, r, g, b);
	end
end

function script_grind:draw()
	script_grind:drawStatus();
end

function script_grind:doLoot(localObj)
	local _x, _y, _z = self.lootObj:GetPosition();
	local dist = self.lootObj:GetDistance();
	
	-- Loot checking/reset target
	if (GetTimeEX() > self.lootCheck['timer']) then
		if (self.lootCheck['target'] == self.lootObj:GetGUID()) then
			self.lootObj = nil; -- reset lootObj
			ClearTarget();
			self.message = 'Reseting loot target...';
		end
		self.lootCheck['timer'] = GetTimeEX() + 10000; -- 10 sec
		if (self.lootObj ~= nil) then 
			self.lootCheck['target'] = self.lootObj:GetGUID();
		else
			self.lootCheck['target'] = 0;
		end
		return;
	end

	if(dist <= self.lootDistance) then
		self.message = "Looting...";
		if(IsMoving() and not localObj:IsMovementDisabed()) then
			StopMoving();
			self.waitTimer = GetTimeEX() + 450;
			return;
		end
		if(not IsStanding()) then
			StopMoving();
			self.waitTimer = GetTimeEX() + 450;
			return;
		end
		
		-- If we reached the loot object, reset the nav path
		script_nav:resetNavigate();

		-- Dismount
		if (IsMounted()) then DisMount(); self.waitTimer = GetTimeEX() + 450; return;  end

		if(not self.lootObj:UnitInteract() and not IsLooting()) then
			self.waitTimer = GetTimeEX() + 950;
			return;
		end
		if (not LootTarget()) then
			self.waitTimer = GetTimeEX() + 650;
			return;
		else
			self.lootObj = nil;
			self.waitTimer = GetTimeEX() + 450;
			return;
		end
	end

	-- Blacklist loot target if swimming or we are close to aggro blacklisted targets and not close to loot target
	if (self.lootObj ~= nil) then
		if (IsSwimming() or (script_aggro:closeToBlacklistedTargets() and self.lootObj:GetDistance() > 5)) then
			script_grind:addTargetToBlacklist(self.lootObj:GetGUID());
			DEFAULT_CHAT_FRAME:AddMessage('script_grind: Blacklisting loot target to avoid aggro/swimming...');
			return;
		end
	end
	self.message = "Moving to loot...";		
	script_nav:moveToTarget(localObj, _x, _y, _z);	
	script_grind:setWaitTimer(100);
	if (self.lootObj:GetDistance() < 3) then self.waitTimer = GetTimeEX() + 450; end
end

function script_grind:getSkinTarget(lootRadius)
	local targetObj, targetType = GetFirstObject();
	local bestDist = lootRadius;
	local bestTarget = nil;
	while targetObj ~= 0 do
		if (targetType == 3) then -- Unit
			if(targetObj:IsDead()) then
				if (targetObj:IsSkinnable() and targetObj:IsTappedByMe() and not targetObj:IsLootable()) then
					local dist = targetObj:GetDistance();
					if(dist < lootRadius and bestDist > dist) then
						bestDist = dist;
						bestTarget = targetObj;
					end
				end
			end
		end
		targetObj, targetType = GetNextObject(targetObj);
	end
	return bestTarget;
end

function script_grind:lootAndSkin()
	-- Loot if there is anything lootable and we are not in combat and if our bags aren't full
	if (not self.skipLooting and not AreBagsFull() and not self.bagsFull) then 
		self.lootObj = script_nav:getLootTarget(self.findLootDistance);
	else
		self.lootObj = nil;
	end
	if (self.lootObj == 0) then self.lootObj = nil; end
	if (self.lootObj ~= nil) then
		if (IsSwimming() or (script_grind:isTargetBlacklisted(self.lootObj:GetGUID()) and self.lootObj:GetDistance() > 5)) then
			self.lootObj = nil; -- don't loot blacklisted targets	
		end
	end
	local isLoot = not IsInCombat() and not (self.lootObj == nil);
	if (isLoot and not AreBagsFull() and not self.bagsFull) then
		script_grind:doLoot(localObj);
		return true;
	elseif ((self.bagsFull or AreBagsFull()) and not hsWhenFull) then
		self.lootObj = nil;
		self.message = "Warning the bags are full...";
		return false;
	end
	-- Skin if there is anything skinnable within the loot radius
	if (HasSpell('Skinning') and self.skinning and HasItem('Skinning Knife')) then
		self.lootObj = nil;
		self.lootObj = script_grind:getSkinTarget(self.findLootDistance);
		if (not AreBagsFull() and not self.bagsFull and self.lootObj ~= nil) then
			script_grind:doLoot(localObj);
			return true;
		end
	end
	return false;
end

function script_grind:runRest()
	if(RunRestScript()) then
		self.message = "Resting...";
		self.newTargetTime = GetTimeEX();
		-- Stop moving
		if (IsMoving() and not localObj:IsMovementDisabed()) then StopMoving(); return true; end
		-- Dismount
		if (IsMounted()) then DisMount(); return true; end
		-- Add 2500 ms timer to the rest script rotations (timer could be set already)
		if ((self.waitTimer - GetTimeEX()) < 2500) then self.waitTimer = GetTimeEX()+2500 end;
		return true;	
	end

	return false;
end