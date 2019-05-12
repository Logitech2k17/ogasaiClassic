script_warrior = {
	message = 'Warrior - Fury Combat Script',
	eatHealth = 75,
	bloodRageHealth = 70,
	potionHealth = 10,
	isSetup = false,
	meeleDistance = 3.5,
	throwOpener = false,
	throwName = "Heavy Throwing Dagger",
	waitTimer = 0,
	stopIfMHBroken = true,
	overpowerActionBarSlot = 72+5, -- Default: Overpower in slot 5 on the default Battle Stance Bar
}

function script_warrior:window()
	--Close existing Window
	EndWindow();

	if(NewWindow("Class Combat Options", 200, 200)) then
		script_warrior:menu();
	end
end

function script_warrior:setup()
	-- no more bugs first time we run the bot
	self.waitTimer = GetTimeEX(); 
	self.isSetup = true;

end

function script_warrior:spellAttack(spellName, target)
	if (HasSpell(spellName)) then
		if (target:IsSpellInRange(spellName)) then
			if (not IsSpellOnCD(spellName)) then
				if (not IsAutoCasting(spellName)) then
					target:FaceTarget();
					--target:TargetEnemy();
					return target:CastSpell(spellName);
				end
			end
		end
	end
	return false;
end

function script_warrior:enemiesAttackingUs(range) -- returns number of enemies attacking us within range
    local unitsAttackingUs = 0; 
    local currentObj, typeObj = GetFirstObject(); 
    while currentObj ~= 0 do 
    	if typeObj == 3 then
		if (currentObj:CanAttack() and not currentObj:IsDead()) then
                	if (script_grind:isTargetingMe(currentObj) and currentObj:GetDistance() <= range) then 
                		unitsAttackingUs = unitsAttackingUs + 1; 
                	end 
            	end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return unitsAttackingUs;
end

function script_warrior:addPotion(name)
	self.potion[self.numPotion] = name;
	self.numPotion = self.numPotion + 1;
end

function script_warrior:equipThrow()
	if (not GetLocalPlayer():HasRangedWeapon() and HasItem(self.throwName)) then
		UseItem(self.throwName);
		return true;
	elseif (GetLocalPlayer():HasRangedWeapon()) then
		return true;
	end
	return false;
end

function script_warrior:canOverpower()
	local isUsable, _ = IsUsableAction(self.overpowerActionBarSlot); 
	if (isUsable == 1 and not IsSpellOnCD('Overpower')) then 
		return true; 
	end 
	return false;
end

-- Run backwards if the target is within range
function script_warrior:runBackwards(targetObj, range) 
	local localObj = GetLocalPlayer();
 	if targetObj ~= 0 then
 		local xT, yT, zT = targetObj:GetPosition();
 		local xP, yP, zP = localObj:GetPosition();
 		local distance = targetObj:GetDistance();
 		local xV, yV, zV = xP - xT, yP - yT, zP - zT;	
 		local vectorLength = math.sqrt(xV^2 + yV^2 + zV^2);
 		local xUV, yUV, zUV = (1/vectorLength)*xV, (1/vectorLength)*yV, (1/vectorLength)*zV;		
 		local moveX, moveY, moveZ = xT + xUV*5, yT + yUV*5, zT + zUV;		
 		if (distance < range) then 
 			Move(moveX, moveY, moveZ);
			self.waitTimer = GetTimeEX() + 1500;
 			return true;
 		end
	end
	return false;
end

function script_warrior:draw()
	local tX, tY, onScreen = WorldToScreen(GetLocalPlayer():GetPosition());
	if (onScreen) then
		DrawText(self.message, tX+75, tY+40, 0, 255, 255);
	else
		DrawText(self.message, 25, 185, 0, 255, 255);
	end
	--script_warrior:window();
end

--[[ error codes: 	0 - All Good , 
			1 - missing arg , 
			2 - invalid target , 
			3 - not in range, 
			4 - do nothing , 
			5 - targeted player pet/totem
			6 - stop bot request from combat script  ]]--

function script_warrior:run(targetGUID)
	
	if(not self.isSetup) then
		script_warrior:setup();
	end
	
	local localObj = GetLocalPlayer();
	local localRage = localObj:GetRagePercentage();
	local localHealth = localObj:GetHealthPercentage();
	local localLevel = localObj:GetLevel();

	if (localObj:IsDead()) then
		return 0; 
	end

	-- Check: If Mainhand is broken stop bot
	isMainHandBroken = GetInventoryItemBroken("player", 16);
	
	if (self.stopIfMHBroken and isMainHandBroken) then
		self.message = "The main hand weapon is broken...";
		return 6;
	end

	-- Assign the target 
	targetObj =  GetGUIDObject(targetGUID);
	
	if(targetObj == 0 or targetObj == nil) then
		return 2;
	end

	-- Check: Do nothing if we are channeling or casting or wait timer
	if (IsChanneling() or IsCasting() or (self.waitTimer > GetTimeEX())) then
		return 4;
	end
	
	--Valid Enemy
	if (targetObj ~= 0) then
		
		-- Cant Attack dead targets
		if (targetObj:IsDead() or not targetObj:CanAttack()) then
			return 0;
		end
		
		if (not IsStanding()) then
			StopMoving();
		end
		
		-- Auto Attack
		if (targetObj:GetDistance() < 40) then
			targetObj:AutoAttack();
		end
	
		targetHealth = targetObj:GetHealthPercentage();

		-- Check: if we target player pets/totems
		if (GetTarget() ~= nil and targetObj ~= nil) then
			if (UnitPlayerControlled("target") and GetTarget() ~= localObj) then 
				script_grind:addTargetToBlacklist(targetObj:GetGUID());
				return 5; 
			end
		end 
		
		-- Opener
		if (not IsInCombat()) then
			self.targetObjGUID = targetObj:GetGUID();
			self.message = "Pulling " .. targetObj:GetUnitName() .. "...";
			
			-- Check: Open with throw weapon
			if (self.rangeOpener) then
				if (targetObj:GetDistance() > 30 or not targetObj:IsInLineOfSight()) then
					return 3;
				else
					-- Dismount
					if (IsMounted()) then DisMount(); return 0; end
					if (Cast("Throw", targetObj)) then
						self.waitTimer = GetTimeEX() + 4000;
						return 0;
					end
				end
			end

			-- Check: Charge if possible
			if (HasSpell("Charge") and not IsSpellOnCD("Charge") and targetObj:GetDistance() < 25 
				and targetObj:GetDistance() > 12 and targetObj:IsInLineOfSight()) then
				-- Dismount
				if (IsMounted()) then DisMount(); return 0; end
				if (Cast("Charge", targetObj)) then return 0; end
			end	

			-- Check move into meele range
			if (targetObj:GetDistance() > self.meeleDistance or not targetObj:IsInLineOfSight()) then
				return 3;
			end

		-- Combat
		else	
			self.message = "Killing " .. targetObj:GetUnitName() .. "...";
			-- Dismount
			if (IsMounted()) then DisMount(); end
			
			-- Run backwards if we are too close to the target
			if (targetObj:GetDistance() < 0.5) then 
				if (script_warrior:runBackwards(targetObj,3)) then 
					return 4; 
				end 
			end

			-- Check if we are in meele range
			if (targetObj:GetDistance() > self.meeleDistance or not targetObj:IsInLineOfSight()) then
				return 3;
			else
				if (IsMoving()) then StopMoving(); end
			end

			targetObj:FaceTarget();
			targetObj:AutoAttack();

			-- Check: Use Healing Potion 
			if (localHealth < self.potionHealth) then 
				if (script_helper:useHealthPotion()) then 
					return 0; 
				end 
			end
	
			-- Check: Thunder clap if 2 mobs or more
			if (script_warrior:enemiesAttackingUs(5) >= 2 and HasSpell('Thunder Clap') 
				and not IsSpellOnCD('Thunder Clap') and not targetObj:HasDebuff('Thunder Clap')) then 
				if (localRage < 20) then return 0; end
				CastSpellByName('Thunder Clap'); return 0;
			end

			-- Check: Use Retaliation if we have three or more mobs on us
			if (script_warrior:enemiesAttackingUs(10) >= 3 and HasSpell('Retaliation') and not IsSpellOnCD('Retaliation')) then 
				CastSpellByName('Retaliation'); return 0; 
			end

			-- Check: Use Orc Racial Blood Fury
			if (not IsSpellOnCD('Blood Fury') and HasSpell('Blood Fury')) then 
				CastSpellByName('Blood Fury'); return 0; 
			end 

			-- Check: Use Bloodrage when we have more than 70% HP
			if (not IsSpellOnCD('Bloodrage') and HasSpell('Bloodrage') and localHealth > self.bloodRageHealth) then 
				CastSpellByName('Bloodrage'); return 0; 
			end 

			-- Check: Keep Battle Shout up
			if (not localObj:HasBuff("Battle Shout")) then 
				if (localRage >= 10 and HasSpell("Battle Shout")) then 
					CastSpellByName('Battle Shout'); return 0; 
				end 
			end

			-- Check: If we are in meele range, do meele attacks
			if (targetObj:GetDistance() < self.meeleDistance) then

				-- Meele Skill: Overpower if possible
				if (script_warrior:canOverpower() and localRage >= 5 and not IsSpellOnCD('Overpower')) then 
					CastSpellByName('Overpower'); 
				end  

				-- Meele skill Execute the target if possible
				if (targetHealth < 20 and HasSpell('Execute')) then 
					if (Cast('Execute', targetObj)) then 
						return 0; 
					else 
						return 0; -- save rage for execute
					end 
				end 

				-- Meele skill: Bloodthirst, save rage for this attack
				if (HasSpell("Bloodthirst") and not IsSpellOnCD("Bloodthirst")) then 
					if (localRage >= 25) then 
						if (Cast('Bloodthirst', targetObj)) then return 0; end
					else 
						return 0; -- save rage for bloodthirst
					end 
				end  

				-- Humanoid use to flee, keep Hamstring up on them
				if (targetObj:GetCreatureType() == 'Humanoid' and localRage >= 10 and not targetObj:HasDebuff('Hamstring')) then 
					if (Cast('Hamstring', targetObj)) then return 0; end 
				end 

				-- Meele Skill: Rend if we got more than 10 rage
				if (targetObj:GetCreatureType() ~= 'Mechanical' and targetObj:GetCreatureType() ~= 'Elemental' and HasSpell('Rend') and not targetObj:HasDebuff("Rend") 
					and targetHealth > 30 and localRage >= 10) then 
					if (Cast('Rend', targetObj)) then return; end 
				end 

				-- Meele Skill: Heroic Strike if we got 15 rage
				if (localRage >= 15) then 
					if (Cast('Heroic Strike', targetObj)) then return 0; end 
				end 
				
				return 0; 
			end
			return 0;
		end
	end
end

function script_warrior:rest()
	if(not self.isSetup) then
		script_warrior:setup();
	end

	local localObj = GetLocalPlayer();
	local localHealth = localObj:GetHealthPercentage();

	-- Eat something
	if (not IsEating() and localHealth < self.eatHealth) then
		self.message = "Need to eat...";
		if (IsInCombat()) then
			return true;
		end
			
		if (IsMoving()) then
			StopMoving();
			return true;
		end

		if (script_helper:eat()) then 
			self.message = "Eating..."; 
			return true; 
		else 
			self.message = "No food! (or food not included in script_helper)";
			return true; 
		end		
	end

	-- Continue eating until we are full
	if(localHealth < 98 and IsEating()) then
		self.message = "Resting up to full health...";
		return true;
	end
		
	-- Stand upp if we are rested
	if (localHealth > 98 and (IsEating() or not IsStanding())) then
		StopMoving();
		return false;
	end
	
	-- Don't need to eat
	return false;
end

function script_warrior:menu()
	if (CollapsingHeader("[Warrior - Fury")) then
		local wasClicked = false;
		Text('Eat below health percentage');
		self.eatHealth = SliderFloat("EHP %", 1, 100, self.eatHealth);
		Text('Potion below health percentage');
		self.potionHealth = SliderFloat("PHP %", 1, 99, self.potionHealth);
		Separator();
		wasClicked, self.stopIfMHBroken = Checkbox("Stop bot if main hand is broken.", self.stopIfMHBroken);
		Text("Use Bloodrage above health percentage");
		self.bloodRageHealth = SliderFloat("BR%", 1, 99, self.bloodRageHealth);
		Text("Melee Range Distance");
		self.meeleDistance = SliderFloat("MR (yd)", 1, 6, self.meeleDistance);
		wasClicked, self.throwOpener = Checkbox("Pull with throw", self.throwOpener);
		Text("Throwing weapon");
		self.throwName = InputText("TW", self.throwName);
		Text("Overpower action bar slot");
		self.overpowerActionBarSlot = InputText("OPS", self.overpowerActionBarSlot);
		Text('E.g. 77 = (72 + 5) = slot 5');
	end
end
