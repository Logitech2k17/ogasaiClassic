script_priest = {
	message = 'Disc - Priest Combat Script',
	drinkMana = 60,
	eatHealth = 80,
	isSetup = false,
	renewHP = 90,
	shieldHP = 80,
	flashHealHP = 75,
	lesserHealHP = 60,
	healHP = 45,
	greaterHealHP = 20,
	potionMana = 10,
	potionHealth = 10,
	waitTimer = 0,
	useWand = true,
	isChecked = true
}

function script_priest:healAndBuff(targetObject, localMana)

	local targetHealth = targetObject:GetHealthPercentage();
	
	-- Buff Fortitude
	if (localMana > 30 and not IsInCombat()) then
		if (Buff('Power Word: Fortitude', targetObject)) then 
			return true; 
		end
	end

	-- Renew
	if (localMana > 10 and targetHealth < self.renewHP and not targetObject:HasBuff("Renew")) then
		if (Buff('Renew', targetObject)) then
			return true;
		end
	end

	-- Shield
	if (localMana > 10 and targetHealth < self.shieldHP and not targetObject:HasDebuff("Weakened Soul") and IsInCombat()) then
		if (Buff('Power Word: Shield', targetObject)) then 
			return true; 
		end
	end

	-- Greater Heal
	if (localMana > 20 and targetHealth < self.greaterHealHP) then
		if (script_priest:heal('Heal', targetObject)) then
			return true;
		end
	end

	-- Heal
	if (localMana > 15 and targetHealth < self.healHP) then
		if (script_priest:heal('Heal', targetObject)) then
			return true;
		end
	end

	-- Lesser Heal
	if (localMana > 10 and targetHealth < self.lesserHealHP) then
		if (script_priest:heal('Lesser Heal', targetObject)) then
			return true;
		end
	end

	-- Flash Heal
	if (localMana > 8 and targetHealth < self.flashHealHP) then
		if (script_priest:heal('Flash Heal', targetObject)) then
			return true;
		end
	end
	
	return false;
end

function script_priest:heal(spellName, target)

	if (HasSpell(spellName)) then 
		if (target:IsSpellInRange(spellName)) then 
			if (not IsSpellOnCD(spellName)) then 
				if (not IsAutoCasting(spellName)) then
					target:TargetEnemy(); 
					CastSpellByName(spellName); 
					-- Wait for global CD before next spell cast
					local CastTime, MaxRange, MinRange, PowerType, Cost, SpellId, SpellObj = GetSpellInfo(spellName); 
					self.waitTimer = GetTimeEX() + CastTime + 1800;
					return true; 
				end 
			end 
		end 
	end

	return false;
end

function script_priest:cast(spellName, target)

	if (HasSpell(spellName)) then
		if (target:IsSpellInRange(spellName)) then
			if (not IsSpellOnCD(spellName)) then
				if (not IsAutoCasting(spellName)) then
					target:FaceTarget();
					target:TargetEnemy();
					return target:CastSpell(spellName);
				end
			end
		end
	end

	return false;
end

function script_priest:enemiesAttackingUs(range) -- returns number of enemies attacking us within range
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
function script_priest:runBackwards(targetObj, range) 

	local localObj = GetLocalPlayer();

 	if targetObj ~= 0 then
 		local xT, yT, zT = targetObj:GetPosition();
 		local xP, yP, zP = localObj:GetPosition();
 		local distance = targetObj:GetDistance();
 		local xV, yV, zV = xP - xT, yP - yT, zP - zT;	
 		local vectorLength = math.sqrt(xV^2 + yV^2 + zV^2);
 		local xUV, yUV, zUV = (1/vectorLength)*xV, (1/vectorLength)*yV, (1/vectorLength)*zV;		
 		local moveX, moveY, moveZ = xT + xUV*10, yT + yUV*10, zT + zUV;	
	
 		if (distance < range and targetObj:IsInLineOfSight()) then 
 			--script_nav:moveToTarget(localObj, moveX, moveY, moveZ);
			Move(moveX, moveY, moveZ);
 			return true;
 		end
	end

	return false;
end

function script_priest:setup()
	self.waitTimer = GetTimeEX();
	self.isSetup = true;

end

function script_priest:draw()
	--script_priest:window();
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
			5 - targeted player pet/totem  ]]--

function script_priest:run(targetGUID)
	
	if(not self.isSetup) then
		script_priest:setup();
	end
	
	local localObj = GetLocalPlayer();
	local localMana = localObj:GetManaPercentage();
	local localHealth = localObj:GetHealthPercentage();
	local localLevel = localObj:GetLevel();
	
	if (localObj:IsDead()) then
		return 0;
	end
	
	-- Assign the target 
	targetObj =  GetGUIDObject(targetGUID);

	if(targetObj == 0 or targetObj == nil or targetObj:IsDead()) then
		ClearTarget();
		return 2;
	end

	-- Check: Do nothing if we are channeling, casting or Ice Blocked
	if (IsChanneling() or IsCasting() or self.waitTimer > GetTimeEX()) then
		return 4;
	end

	--Valid Enemy
	if (targetObj ~= 0 and targetObj ~= nil) then
		
		-- Cant Attack dead targets
		if (targetObj:IsDead() or not targetObj:CanAttack()) then
			ClearTarget();
			return 2;
		end
		
		if (not IsStanding()) then
			StopMoving();
		end

		targetHealth = targetObj:GetHealthPercentage();

		-- Auto Attack
		if (targetObj:GetDistance() < 40) then
			targetObj:AutoAttack();
		end

		-- Check: if we target player pets/totems
		if (GetTarget() ~= nil and targetObj ~= nil) then
			if (UnitPlayerControlled("target") and GetTarget() ~= localObj) then 
				script_grind:addTargetToBlacklist(targetObj:GetGUID());
				return 5; 
			end
		end 
		
		-- Opener
		if (not IsInCombat()) then

			self.message = "Pulling " .. targetObj:GetUnitName() .. "...";
			
			-- Opener check
			if(not targetObj:IsSpellInRange('Smite'))  then
				return 3;
			end

			-- Dismount
			if (IsMounted()) then DisMount(); end

			if (script_priest:cast('Devouring Plague', targetObj)) then
				self.waitTimer = GetTimeEX() + 200;
				return 0;
			end

			-- Mind Blast when we are playing solo
			if (GetNumPartyMembers() == 0) then
				if (script_priest:cast('Mind Blast', targetObj)) then
					self.waitTimer = GetTimeEX() + 200;
					return 0;
				end
			end

			if (script_priest:cast('Smite', targetObj)) then
				self.waitTimer = GetTimeEX() + 200;
				return 0;
			end
			
			if (not targetObj:IsInLineOfSight()) then
				return 3;
			end
		-- Combat
		else	

			self.message = "Killing " .. targetObj:GetUnitName() .. "...";

			-- Dismount
			if (IsMounted()) then DisMount(); end

			if (script_priest:healAndBuff(localObj, localMana)) then
				return 0;
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

			if (script_priest:enemiesAttackingUs(5) > 1 and targetHealth > 20) then
				if (HasSpell('Psychic Scream') and not IsSpellOnCD('Psychic Scream')) then
					CastSpellByName('Psychic Scream');
					self.message = 'Adds close, use Psychic Scream...';
					return 0;
				end
			end

			-- Wand if low mana or target is low
			if (self.useWand) then
				if ((localMana <= 40 or targetHealth <= 5) and localObj:HasRangedWeapon()) then
					self.message = "Using wand...";
					if (not IsAutoCasting("Shoot")) then
						targetObj:FaceTarget();
						targetObj:CastSpell("Shoot");
						self.waitTimer = GetTimeEX() + 1650; 
						return 0;
					end
					return 0;
				end
			end

			-- Check: Keep Shadow Word: Pain up
			if (not targetObj:HasDebuff("Shadow Word: Pain")) then
				if (Cast('Shadow Word: Pain', targetObj)) then 
					return 0; 
				end
			end

			-- Check: Keep Inner Fire up
			if (not localObj:HasBuff('Inner Fire') and HasSpell('Inner Fire')) then
				if (Buff('Inner Fire', localObj)) then
					return 0;
				end
			end

			-- Cast: Smite (last choice e.g. at level 1)
			if (Cast('Smite', targetObj)) then 
				return 0; 
			end
		end
	end
end

function script_priest:rest()

	if(not self.isSetup) then
		script_priest:setup();
	end

	local localObj = GetLocalPlayer();
	local localMana = localObj:GetManaPercentage();
	local localHealth = localObj:GetHealthPercentage();

	-- Stop moving before we can rest
	if(localHealth < self.eatHealth or localMana < self.drinkMana) then
		if (IsMoving()) then
			StopMoving();
			return true;
		end
	end

	if (script_priest:healAndBuff(localObj, localMana)) then 
		return true;
	end

	-- Check: Drink
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

	-- Check: Eat
	if (not IsEating() and localHealth < self.eatHealth) then
		self.message = "Need to eat...";	
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
	
	-- Check: Keep resting
	if((localMana < 98 and IsDrinking()) or (localHealth < 98 and IsEating())) then
		self.message = "Resting to full hp/mana...";
		return true;
	end

	-- No rest / buff needed
	return false;
end

function script_priest:mount()

	if(not IsMounted() and not IsSwimming() and not IsIndoors() 
		and not IsLooting() and not IsCasting() and not IsChanneling() 
			and not IsDrinking() and not IsEating()) then
		
		if(IsMoving()) then
			return true;
		end
		
		return UseItem(self.mountName);
	end
	
	return false;
end

function script_priest:window()

	if (self.isChecked) then
	
		--Close existing Window
		EndWindow();

		if(NewWindow("Class Combat Options", 200, 200)) then
			script_priest:menu();
		end
	end
end


function script_priest:menu()

	if (CollapsingHeader("[Priest - Disc")) then
		local wasClicked = false;
		Text('Rest options:');
		self.drinkMana = SliderFloat("Drink below mana", 1, 100, self.drinkMana);
		self.eatHealth = SliderFloat("Eat below health", 1, 100, self.eatHealth);
		Separator();
		Text('Heal/sustain options:');
		self.renewHP = SliderFloat("Renew HP%", 1, 99, self.renewHP);	
		self.shieldHP = SliderFloat("Shiled HP%", 1, 99, self.shieldHP);
		self.flashHealHP = SliderFloat("Flash heal HP%", 1, 99, self.flashHealHP);	
		self.lesserHealHP = SliderFloat("Lesser heal HP%", 1, 99, self.lesserHealHP);	
		self.healHP = SliderFloat("Heal HP%", 1, 99, self.healHP);	
		self.greaterHealHP = SliderFloat("Greater Heal HP%", 1, 99, self.greaterHealHP);
		self.potionHealth = SliderFloat("Potion HP%", 1, 99, self.potionHealth);
		self.potionMana = SliderFloat("Potion Mana%", 1, 99, self.potionMana);
		Separator();	
		Text('Skill options:');
		wasClicked, self.useWand = Checkbox("Use Wand", self.useWand);	
	end
end
