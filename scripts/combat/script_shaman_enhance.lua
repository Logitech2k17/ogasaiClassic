script_shaman = {
	message = 'Shaman - Enhancement Combat Script',
	eatHealth = 70,
	drinkMana = 50,
	healHealth = 70,
	potionHealth = 10,
	potionMana = 20,
	isSetup = false,
	meeleDistance = 4,
	waitTimer = 0,
	stopIfMHBroken = true,
	enhanceWeapon = 'Rockbiter Weapon',
	totem = 'no totem yet',
	totemBuff = '',
	healingSpell = 'Healing Wave',
	isChecked = true
}

function script_shaman:setup()

	-- Set weapon enhancement
	if (HasSpell('Windfury Weapon')) then
		self.enhanceWeapon = 'Windfury Weapon';
	elseif (HasSpell('Flametongue Weapon')) then
		self.enhanceWeapon = 'Flametongue Weapon';
	end

	-- Set totem
	if (HasSpell('Strength of Earth Totem') and HasItem('Earth Totem')) then
		self.totem = 'Strength of Earth Totem';
		self.totemBuff = 'Strength of Earth';
	elseif (HasSpell('Grace of Air Totem') and HasItem('Air Totem')) then
		self.totem = 'Grace of Air Totem';
		self.totemBuff = 'Grace of Air';
	end

	-- Set healing spell
	if (HasSpell('Lesser Healing Wave')) then
		self.healingSpell = 'Lesser Healing Wave';
	end

	self.waitTimer = GetTimeEX();

	self.isSetup = true;

end

-- Checks and apply enhancement on the meele weapon
function script_shaman:checkEnhancement()
	if (not IsInCombat() and not IsEating() and not IsDrinking()) then
		hasMainHandEnchant, _, _, _, _, _ = GetWeaponEnchantInfo();
		if (hasMainHandEnchant == nil) then 
			-- Apply enhancement
			if (HasSpell(self.enhanceWeapon)) then

				-- Check: Stop moving, sitting
				if (not IsStanding() or IsMoving()) then 
					StopMoving(); 
					return true;
				end 

				CastSpellByName(self.enhanceWeapon);
				self.message = "Applying " .. self.enhanceWeapon .. " on weapon...";
			else
				return false;
			end
			return true;
		end
	end 
	return false;
end

function script_shaman:spellAttack(spellName, target)
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

function script_shaman:enemiesAttackingUs(range) -- returns number of enemies attacking us within range
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

-- Run backwards if the target is within range
function script_shaman:runBackwards(targetObj, range) 
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

function script_shaman:draw()
	--script_shaman:window();
	local tX, tY, onScreen = WorldToScreen(GetLocalPlayer():GetPosition());
	if (onScreen) then
		DrawText(self.message, tX+75, tY+40, 0, 255, 255);
	else
		DrawText(self.message, 25, 185, 0, 255, 255);
	end
end

--[[ error codes: 	0 - All Good , 
			1 - missing arg , 
			2 - invalid target , 
			3 - not in range, 
			4 - do nothing , 
			5 - targeted player pet/totem
			6 - stop bot request from combat script  ]]--

function script_shaman:run(targetGUID)
	
	if(not self.isSetup) then
		script_shaman:setup();
	end
	
	local localObj = GetLocalPlayer();
	local localMana = localObj:GetManaPercentage();
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
	targetObj = GetGUIDObject(targetGUID);
	
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

			-- Dismount
			if (IsMounted() and targetObj:GetDistance() < 25) then DisMount(); return 0; end

			-- Check: Not in range
			if (not targetObj:IsSpellInRange('Lightning Bolt')) then
				return 3;
			end

			-- Check: If in range and in line of sight stop moving
			if (targetObj:IsInLineOfSight() and IsMoving()) then
				StopMoving(); 
				return 0;
			end

			-- Pull with: Lighting Bolt
			if (Cast("Lightning Bolt", targetObj)) then
				self.waitTimer = GetTimeEX() + 4000;
				return 0;
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
			if (targetObj:GetDistance() < 0.50) then 
				if (script_shaman:runBackwards(targetObj,3)) then 
					return 4; 
				end 
			end

			-- Check if we are in meele range
			if (targetObj:GetDistance() > self.meeleDistance or not targetObj:IsInLineOfSight()) then
				return 3;
			else
				if (IsMoving()) then StopMoving(); end
			end

			targetObj:AutoAttack();

			-- Check: Healing
			if (localHealth < self.healHealth) then 
				if (Cast(self.healingSpell, localObj)) then
					self.waitTimer = GetTimeEX() + 4000;
					return 0;
				end
			end

			-- Check: Lightning Shield
			if (not localObj:HasBuff('Lightning Shield')) then
				if (Buff("Lightning Shield", localObj)) then
					return 0;
				end
			end

			-- Check: Use Healing Potion 
			if (localHealth < self.potionHealth) then 
				if (script_helper:useHealthPotion()) then 
					return 0; 
				end 
			end

			-- Check: Use Mana Potion 
			if (localMana < self.potionMana) then 
				if (script_helper:useManaPotion()) then 
					return 0; 
				end 
			end

			-- Earth Shock
			if (targetObj:IsCasting()) then
				if (Cast("Earth Shock", targetObj)) then
					return 0;
				end
			end

			-- Check: If we are in meele range, do meele attacks
			if (targetObj:GetDistance() < self.meeleDistance) then
				targetObj:FaceTarget();

				-- Totem
				if (HasSpell(self.totem) and not localObj:HasBuff(self.totemBuff)) then
					CastSpellByName(self.totem);
					self.waitTimer = GetTimeEX() + 1500;
				end

				-- Stormstrike
				if (HasSpell('Stormstrike') and not IsSpellOnCD('Stormstrike')) then
					if (Cast("Stormstrike", targetObj)) then
						return 0;
					end
				end
			end

			return 0;
		end
	end
end

function script_shaman:rest()
	if(not self.isSetup) then
		script_shaman:setup();
	end

	local localObj = GetLocalPlayer();
	local localLevel = localObj:GetLevel();
	local localHealth = localObj:GetHealthPercentage();
	local localMana = localObj:GetManaPercentage();

	-- Stop moving before we can rest
	if(localHealth < self.eatHealth or localMana < self.drinkMana) then
		if (IsMoving()) then
			StopMoving();
			return true;
		end
	end

	-- Heal up
	if (localHealth < self.eatHealth and localMana > 20) then 
		if (Cast("Healing Wave", localObj)) then
			script_grind:setWaitTimer(5000);
			return true;
		end
	end

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

	-- Drink something
	if (not IsDrinking() and localMana < self.drinkMana) then
		self.message = "Need to drink...";
		if (IsMoving()) then
			StopMoving();
			return true;
		end

		if (script_helper:drinkWater()) then 
			self.message = "Drinking..."; 
			return true; 
		else 
			self.message = "No drinks! (or drink not included in script_helper)";
			return true; 
		end
	end

	-- Continue resting
	if(localHealth < 98 and IsEating() or localMana < 98 and IsDrinking()) then
		self.message = "Resting up to full HP/Mana...";
		return true;
	end
		
	-- Stand up if we are rested
	if (localHealth > 98 and (IsEating() or not IsStanding()) 
	    and localMana > 98 and (IsDrinking() or not IsStanding())) then
		StopMoving();
		return false;
	end

	-- Keep us buffed: Lightning Shield
	if (Buff("Lightning Shield", localObj)) then
		return true;
	end

	if (script_shaman:checkEnhancement()) then
		return true;
	end

	-- Don't need to rest
	return false;
end

function script_shaman:mount()
	return false;
end

function script_shaman:window()

	if (self.isChecked) then
	
		--Close existing Window
		EndWindow();

		if(NewWindow("Class Combat Options", 200, 200)) then
			script_shaman:menu();
		end
	end
end

function script_shaman:menu()
	if (CollapsingHeader("[Shaman - Enhancement")) then
		local wasClicked = false;
		Text('Rest options:');
		self.eatHealth = SliderFloat("Eat below HP%", 1, 100, self.eatHealth);
		self.drinkMana = SliderFloat("Drink below Mana%", 1, 100, self.drinkMana);
		Text('You can add more food/drinks in script_helper.lua');
		Separator();
		Text('Combat options:');
		wasClicked, self.stopIfMHBroken = Checkbox("Stop bot if main hand is broken (red)...", self.stopIfMHBroken);
		self.potionHealth = SliderFloat("Potion below HP%", 1, 99, self.potionHealth);
		self.potionMana = SliderFloat("Potion below Mana%", 1, 99, self.potionMana);
		self.healHealth = SliderFloat("Heal when below HP% (in combat)", 1, 99, self.healHealth);
		self.meeleDistance = SliderFloat("Meele range", 1, 6, self.meeleDistance);
	end
end
