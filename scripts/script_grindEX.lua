script_grindEX = {
	currMapID = GetMapID(), 
	avoidBlacklisted = false,
	unstuckTime = GetTimeEX();
}

function script_grindEX:doChecks() 
		-- Load vendors if we move into a new map zone
		if (GetMapID() ~= self.currMapID) then
			self.currMapID = GetMapID();
			vendorDB:loadDBVendors();
		end
	
		if (script_grind.waitTimer > GetTimeEX() or IsCasting() or IsChanneling()) then return true; end
		
		if (script_grind.avoidElite and not localObj:IsDead()) then 
			if (script_nav:avoidElite(script_grind.avoidRange)) then
				script_grind.message = "Elite within " .. script_grind.avoidRange .. " yd. running away...";
				script_grind.waitTimer = GetTimeEX() + 1500;
				return true; 
			end 
		end

		if (not IsUsingNavmesh()) then UseNavmesh(true); return true; end
		if (not LoadNavmesh()) then script_grind.message = "Make sure you have mmaps-files..."; return true; end
		if (GetLoadNavmeshProgress() ~= 1) then script_grind.message = "Loading the nav mesh... " return true; end

		if(localObj:IsDead()) then
			script_grind.waitTimer = GetTimeEX() + 150;
			script_grind.message = "Walking to corpse...";
			-- Release body
			if(not IsGhost()) then RepopMe(); script_grind.waitTimer = GetTimeEX() + 5000; return true; end
			-- Ressurrect within the ress distance to our corpse
			local _lx, _ly, _lz = localObj:GetPosition();
			if(GetDistance3D(_lx, _ly, _lz, GetCorpsePosition()) > script_grind.ressDistance) then
				script_nav:moveToNav(localObj, GetCorpsePosition());
				return true;
			else
				if (script_grind.safeRess) then
					local rx, ry, rz = GetCorpsePosition();
					if (script_aggro:safeRess(rx, ry, rz, script_grind.ressDistance)) then
						script_grind.message = "Finding a safe spot to ress...";
						return true;
					else
						if (script_aggro.rTime > GetTimeEX()) then
							script_nav:moveToNav(localObj, script_aggro.rX, script_aggro.rY, script_aggro.rZ);
							script_grind.message = "Finding a safe spot to ress...";
							return true;
						end
					end
				end
				RetrieveCorpse();
			end
			return true;
		end

		if (script_grind:getTargetAttackingUs() == nil) then
			if (GetLocalPlayer():HasBuff('Bloodrage')) then
				script_grind.message = "Waiting for bloodrage to fade...";
				return true;
			end
			if (not IsInCombat() and self.avoidBlacklisted) then
				if (script_aggro:avoidBlacklistedTargets()) then
					script_grind.message = "Avoiding blacklisted targets...";
					return true;
				end
			end
			local groupMana = 0;
			local manaUsers = 0;
			for i = 1, GetNumPartyMembers() do
				local partyMember = GetPartyMember(i);
				if (partyMember:GetManaPercentage() > 0) then
					groupMana = groupMana + partyMember:GetManaPercentage();
					manaUsers = manaUsers + 1;
				end
				if (partyMember:GetDistance() > 60 and not IsInCombat()) then
					if (IsMoving()) then StopMoving(); end
					script_grind.message = 'Waiting for group members...';
					ClearTarget();
					return true;
				end
			end
			if (groupMana/manaUsers < 75 and GetNumPartyMembers() >= 1 and not IsInCombat()) then
				if (IsMoving()) then StopMoving(); end
				script_grind.message = 'Waiting for group to regen mana (75%+)...';
				ClearTarget();
				return true;
			end
		end

		if (localObj:HasBuff("Vanish")) then if (script_nav:runBackwards(1, 30)) then 
			ClearTarget(); script_grind.message = "Moving away from enemies..."; return true; end 
		end
		
		local rest = true;
		if (script_grind.enemyObj ~= nil and script_grind.enemyObj ~= 0) then
			if (script_grind:enemiesAttackingUs() > 0 or script_grind.enemyObj:IsFleeing() or script_grind.enemyObj:IsStunned()) then
				rest = false;
			end
		end

		local vendorStatus = script_vendor:getStatus();
		if (vendorStatus >= 1 and not IsInCombat()) then
			if (script_grind:runRest()) then return true; end

			if (script_grind:lootAndSkin()) then return true; end

			if (script_grind.useMount and not IsInCombat()) then
				if (script_grind:mountUp()) then return true; end
			end
		end
		if (not IsInCombat() or IsMounted()) then
			if (vendorStatus == 1) then
				script_grind.message = "Repairing at vendor...";
				if (script_vendor:repair()) then script_grind:setWaitTimer(100); return true; end
			elseif (vendorStatus == 2) then
				script_grind.message = "Selling to vendor...";
				if (script_vendor:sell()) then script_grind:setWaitTimer(100); return true; end
			elseif (vendorStatus == 3) then
				script_grind.message = "Buying ammo at vendor...";
				if (script_vendor:continueBuyAmmo()) then 
					script_grind:setWaitTimer(100); return true; 
				end
			elseif (vendorStatus == 4) then
				script_grind.message = "Buying food/drink at vendor...";
				if (script_vendor:continueBuy()) then script_grind:setWaitTimer(100); return true; end
			end
		end

		-- Clear dead/blacklisted/tapped targets
		if (script_grind.enemyObj ~= 0 and script_grind.enemyObj ~= nil) then
			-- Save location for auto pathing
			if (script_grind.hotspotReached and script_grind.enemyObj:IsDead() and script_grind.enemyObj:GetLevel() >= script_grind.minLevel and script_grind.enemyObj:GetLevel() <= script_grind.maxLevel) then 
				script_nav:saveTargetLocation(script_grind.enemyObj, script_grind.enemyObj:GetLevel()); end
			if ((script_grind.enemyObj:IsTapped() and not script_grind.enemyObj:IsTappedByMe()) 
				or (script_grind:isTargetBlacklisted(script_grind.enemyObj:GetGUID()) and not IsInCombat())
				or script_grind.enemyObj:IsDead()) then
				script_grind.enemyObj = nil;
				ClearTarget();
			end
		end

		if (not IsInCombat() and not localObj:HasBuff('Feign Death')) then
			-- Move out of water before resting/mounting
			if (IsSwimming()) then 
				script_grind.message = "Moving out of the water..."; 
				if (script_grind.autoPath) then
					self.message = script_nav:moveToSavedLocation(localObj, script_grind.minLevel, script_grind.maxLevel, script_grind.staticHotSpot);
				else
					script_nav:navigate(GetLocalPlayer()); return true; end
				end
			if (rest) then
				if (script_grind:runRest()) then return true; end
			end
			
			if (script_grind:lootAndSkin()) then return true; end
		end

		if ((AreBagsFull() or script_grind.bagsFull) and not IsInCombat()) then
			if(script_grind.useVendor and script_vendor:sell()) then
				script_grind.message = "Running the vendor routine: sell..."; 
				return true;
			elseif (script_grind.hsWhenFull and HasItem("Hearthstone")) then
				script_vendor:removeShapeShift();
				script_grind.message = 'Inventory is full, using Hearthstone...';
				if (IsMounted()) then DisMount(); script_grind.waitTimer = GetTimeEX()+3000; return true; end
				UseItem("Hearthstone");
				return;
			elseif (script_grind.stopWhenFull) then
				script_grind.message = 'Bags are full, stopping...';
				Logout(); StopBot(); return true;
			else	
				script_grind.message = 'Warning bags are full...';
				if (script_grind.hsWHenFull) then script_grind.message = 'Warning bags are full, pausing...'; return true; end 
			end
		end

		-- Check: Vendor refill
		if (script_grind.useVendor and script_grind.vendorRefill and not IsInCombat()) then
			if (script_vendorMenu:checkVendor(script_grind.useMana)) then
				return true;
			end
		end

		-- Update pull levels if we leveled up
		if (script_grind.currentLevel < GetLocalPlayer():GetLevel()) then
			script_grind.currentLevel = GetLocalPlayer():GetLevel();
			script_grind.minLevel = script_grind.minLevel + 1;
			script_grind.maxLevel = script_grind.maxLevel + 1;
		end
		
		-- Update/load hot spot distance and location
		if (script_grind.autoPath) then 
			script_nav:updateHotSpot(GetLocalPlayer():GetLevel(), GetFaction(), script_grind.staticHotSpot);
			script_nav:setHotSpotDistance(script_grind.distToHotSpot); 
		end

	return false;
end