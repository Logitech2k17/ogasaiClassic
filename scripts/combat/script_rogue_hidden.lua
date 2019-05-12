script_rogue = {
	message = 'Rogue - Hidden Combat Script',
	eatHealth = 75,
	potionHealth = 10,
	isSetup = false,
	cpGenerator = 'Sinister Strike',
	cpGeneratorCost = 45,
	meeleDistance = 3.5,
	throwOpener = false,
	throwName = "Heavy Throwing Dagger",
	useStealth = false,
	stealthOpener = "Sinister Strike",
	stealthRange = 30,
	usePoison = true,
	mainhandPoison = "Instant Poison",
	offhandPoison = "Instant Poison",
	useSliceAndDice = true,
	waitTimer = 0,
	vanishHealth = 10,
	evasionHealth = 50,
	stopIfMHBroken = true
}

function script_rogue:setup()
	-- no more bugs first time we run the bot
	self.waitTimer = GetTimeEX(); 

	-- Set Cheap Shot as default opener if we have it
	if (HasSpell("Cheap Shot")) then
		self.stealthOpener = "Cheap Shot";
	end

	-- Set Hemorrhage as default CP builder if we have it
	if (HasSpell("Hemorrhage")) then
		self.cpGenerator = "Hemorrhage";
	end

	-- Set the energy cost for the CP builder ability (does not recognize talent e.g. imp. sinister strike)
	_, _, _, _, self.cpGeneratorCost = GetSpellInfo(self.cpGenerator);
	self.isSetup = true;
end

function script_rogue:spellAttack(spellName, target)
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

function script_rogue:equipThrow()
	if (not GetLocalPlayer():HasRangedWeapon() and HasItem(self.throwName)) then
		UseItem(self.throwName);
		return true;
	elseif (GetLocalPlayer():HasRangedWeapon()) then
		return true;
	end
	return false;
end

function script_rogue:checkPoisons()
	if (not IsInCombat() and not IsEating()) then
		hasMainHandEnchant, _, _,  hasOffHandEnchant, _, _ = GetWeaponEnchantInfo();
		if (hasMainHandEnchant == nil and HasItem(self.mainhandPoison)) then 
			-- Check: Stop moving, sitting
			if (not IsStanding() or IsMoving()) then 
				StopMoving(); 
				return; 
			end 
			-- Check: Dismount
			if (IsMounted()) then DisMount(); return true; end
			-- Apply poison to the main-hand
			self.message = "Applying poison to main hand..."
			UseItem(self.mainhandPoison); 
			PickupInventoryItem(16);  
			self.waitTimer = GetTimeEX() + 6000; 
			return true;
		end
		
		if (hasOffHandEnchant == nil and HasItem(self.offhandPoison)) then
			-- Check: Stop moving, sitting
			if (not IsStanding() or IsMoving()) then 
				StopMoving(); 
				return; 
			end 
			-- Check: Dismount
			if (IsMounted()) then DisMount(); return true; end
			-- Apply poison to the off-hand
			self.message = "Applying poison to off hand..."
			UseItem(self.offhandPoison); 
			PickupInventoryItem(17); 
			self.waitTimer = GetTimeEX() + 6000; 
			return true; 
		end
	end 
	return false;
end

function script_rogue:canRiposte()
	for i=1,132 do 
		local texture = GetActionTexture(i); 
		if texture ~= nil and string.find(texture,"Ability_Warrior_Challange") then
			local isUsable, _ = IsUsableAction(i); 
			if (isUsable == 1 and not IsSpellOnCD(Riposte)) then 
				return true; 
			end 
		end 
	end 
	return false;
end

-- Run backwards if the target is within range
function script_rogue:runBackwards(targetObj, range) 
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

function script_rogue:draw()
	local tX, tY, onScreen = WorldToScreen(GetLocalPlayer():GetPosition());
	if (onScreen) then
		DrawText(self.message, tX+75, tY+40, 0, 255, 255);
	else
		DrawText(self.message, 25, 185, 0, 255, 255);
	end
end

function script_rogue:run(targetGUID)
	
	if (not self.isSetup) then script_rogue:setup(); end
	
	local localObj = GetLocalPlayer();
	local localEnergy = localObj:GetEnergy();
	local localHealth = localObj:GetHealthPercentage();
	local localLevel = localObj:GetLevel();

	if (localObj:IsDead()) then return 0; end

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

	-- Apply poisons if we are not in combat
	if (not IsInCombat() and self.usePoison) then
		if (script_rogue:checkPoisons()) then
			return 4;
		end
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

		-- Don't attack if we should rest first
		if (localHealth < self.eatHealth and not script_grind:isTargetingMe(targetObj)
			and targetHealth > 99 and not targetObj:IsStunned()) then
			self.message = "Need rest...";
			return 4;
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
			self.targetObjGUID = targetObj:GetGUID();
			self.message = "Pulling " .. targetObj:GetUnitName() .. "...";
			
			-- Stealth in range if enabled
			if (self.useStealth and targetObj:GetDistance() <= self.stealthRange) then
				if (not localObj:HasBuff("Stealth") and not IsSpellOnCD("Stealth")) then
					CastSpellByName("Stealth");
					return 3;
				end
				-- Use sprint (when stealthed for pull)
				if (HasSpell("Sprint") and not IsSpellOnCD("Sprint")) then
					CastSpellByName("Sprint");
					return 3;
				end
			elseif (not self.useStealth and localObj:HasBuff("Stealth")) then
				CastSpellByName("Stealth");
			end

			-- Open with stealth opener
			if (targetObj:GetDistance() < 6 and self.useStealth and HasSpell(self.stealthOpener) and localObj:HasBuff("Stealth")) then
				if (script_rogue:spellAttack(self.stealthOpener, targetObj)) then
					return 0;
				end
			end
			
			if (not self.useStealth and self.throwOpener and script_rogue:equipThrow()) then
				if (targetObj:GetDistance() > 30 or not targetObj:IsInLineOfSight()) then
					return 3;
				else
					-- Dismount
					if (IsMounted()) then DisMount(); end
					if (Cast("Throw", targetObj)) then
						self.waitTimer = GetTimeEX() + 4000;
						return 0;
					end
				end
			end

			-- Check if we are in meele range
			if (targetObj:GetDistance() > self.meeleDistance or not targetObj:IsInLineOfSight()) then
				return 3;
			end
			
			-- Use CP generator attack 
			if ((localEnergy >= self.cpGeneratorCost) and HasSpell(self.cpGenerator)) then
				if(script_rogue:spellAttack(self.cpGenerator, targetObj)) then
					return 0;
				end
			end
			
		-- Combat
		else	
			self.message = "Killing " .. targetObj:GetUnitName() .. "...";
			-- Dismount
			if (IsMounted()) then DisMount(); end

			-- Check: Do we have the right target (in UI) ??
			if (GetTarget() ~= 0 and GetTarget() ~= nil) then
				if (GetTarget():GetGUID() ~= targetObj:GetGUID()) then
					ClearTarget();
					targetObj = 0;
					return 0;
				end
			end

			local localCP = GetComboPoints("player", "target");

			-- Run backwards if we are too close to the target
			if (targetObj:GetDistance() < 0.5) then 
				if (script_rogue:runBackwards(targetObj,3)) then 
					return 4; 
				end 
			end

			-- Check if we are in meele range
			if (targetObj:GetDistance() > self.meeleDistance or not targetObj:IsInLineOfSight()) then
				return 3;
			else
				if (IsMoving()) then
					StopMoving();
				end
			end

			targetObj:FaceTarget();

			-- Check: Use Vanish 
			if (HasSpell('Vanish') and HasItem('Flash Powder') and localHealth < self.vanishHealth and not IsSpellOnCD('Vanish')) then 
				CastSpellByName('Vanish'); 
				ClearTarget(); 
				self.targetObj = 0;
				return 4;
			end 

			-- Check: Use Healing Potion 
			if (localHealth < self.potionHealth) then 
				if (script_helper:useHealthPotion()) then 
					return 0; 
				end 
			end

			-- Check: Kick if the target is casting
			if (HasSpell("Kick") and targetObj:IsCasting() and not IsSpellOnCD("Kick")) then
				if (localEnergy <= 25) then return 0; end
				if (not Cast("Kick", targetObj)) then
					return 0; -- return until we kick the enemy
				end
			end

			-- Set available skills variables
			hasEvasion = HasSpell('Evasion');
			
			-- Talent specific skills variables
			hasBladeFlurry = HasSpell('Blade Flurry');  
			hasAdrenalineRush = HasSpell('Adrenaline Rush'); 

			-- Check: Use Riposte whenever we can
			if (script_rogue:canRiposte() and not IsSpellOnCD("Riposte")) then 
				if (localEnergy < 10) then return 0; end -- return until we have energy
				if (not script_rogue:spellAttack("Riposte", targetObj)) then 
					return 0; -- return until we cast Riposte
				end 
			end
			
			-- Check: Use Evasion if low HP or more than one enemy attack us
			if ((localHealth < self.evasionHealth and localHealth < targetHealth) or (script_helper:enemiesAttackingUs(5) >= 2 and localHealth < self.evasionHealth)) then 
				if (HasSpell('Evasion') and not IsSpellOnCD('Evasion')) then
					CastSpellByName('Evasion');
					return 0;
				end
			end 
			
			-- Check: Blade Flurry when 2 or more targets within 10 yards
			if (hasBladeFlurry and script_helper:enemiesAttackingUs(10) >= 2 and not IsSpellOnCD('Blade Flurry')) then 
				if (targetObj:GetDistance() < 5) then 
					CastSpellByName('Blade Flurry');
					return 0;
				end 
			end 

			-- Check: Adrenaline Rush if more than 2 enemies attacks us or we fight an elite enemy
			if (hasAdrenalineRush and (script_helper:enemiesAttackingUs(10) >= 3 or UnitIsPlusMob("target"))) then 
				if (targetObj:GetDistance() < 5) then 
					CastSpellByName('Adrenaline Rush');
					return 0;
				end 
			end 
			
			-- Eviscerate with 5 CPs
			if (localCP == 5) then
				if (localEnergy < 35) then return 0; end -- return until we have energy
				if (not script_rogue:spellAttack('Eviscerate', targetObj)) then 
					return 0; -- return until we use Eviscerate
				end 
			end
			
			-- Keep Slice and Dice up
			if (self.useSliceAndDice and not localObj:HasBuff('Slice and Dice') and targetHealth > 50 and localCP > 1) then
				if (localEnergy < 25) then return 0; end -- return until we have energy
				if (not script_rogue:spellAttack('Slice and Dice', targetObj) or localEnergy <= 25) then
					return 0;
				end
			end
			
			-- Dynamic health check when using Eviscerate between 1 and 4 CP
			if (targetHealth < (10*localCP)) then
				if (localEnergy < 35) then return 0; end -- return until we have energy
				if (not script_rogue:spellAttack('Eviscerate', targetObj)) then 
					return 0; -- return until we use Eviscerate
				end
			end

			-- Use CP generator attack 
			if ((localEnergy >= self.cpGeneratorCost) and HasSpell(self.cpGenerator)) then
				if(script_rogue:spellAttack(self.cpGenerator, targetObj)) then
					return 0;
				end
			end

			return 0;
		end
	end
end

function script_rogue:rest()
	if(not self.isSetup) then script_rogue:setup(); end

	local localObj = GetLocalPlayer();
	local localHealth = localObj:GetHealthPercentage();

	-- Eat something
	if (not IsEating() and localHealth < self.eatHealth) then
		self.message = "Need to eat...";
		if (IsInCombat()) then
			return true;
		end
			
		if (IsMoving()) then StopMoving(); return true; end

		if (script_helper:eat()) then 
			self.message = "Eating..."; 
			return true; 
		else 
			self.message = "No food! (or food not included in script_helper)";
			return true; 
		end		
	end

	-- Stealth when we eat if we dont use stealth at opening
	if (not self.useStealth and HasSpell("Stealth") and not IsSpellOnCD("Stealth") and IsEating() and not localObj:HasDebuff("Touch of Zanzil")) then
		if (not localObj:HasBuff("Stealth")) then
			CastSpellByName("Stealth");
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

function script_rogue:menu()
	if (CollapsingHeader("[Hidden - Rogue Combat Options")) then
		local wasClicked = false;
		Text('Eat below health percent');
		self.eatHealth = SliderFloat('EHP %', 1, 100, self.eatHealth);
		Text("Potion below health percent");
		self.potionHealth = SliderFloat('PHP %', 1, 99, self.potionHealth);
		Separator();
		wasClicked, self.stopIfMHBroken = Checkbox("Stop bot if main hand is broken", self.stopIfMHBroken);
		Text("Combo Point ability");
		self.cpGenerator = InputText("CPA", self.cpGenerator);
		Text("Energy cost of CP-ability");
		self.cpGeneratorCost = SliderFloat("AC", 10, 50, self.cpGeneratorCost);
		Text("Melee Range to target");
		self.meeleDistance = SliderFloat('MR (yd)', 1, 6, self.meeleDistance);
		wasClicked, self.useSliceAndDice = Checkbox("Use Slice & Dice", self.useSliceAndDice);
		wasClicked, self.useStealth = Checkbox("Use Stealth", self.useStealth);
		Text("Stealth ability oponer");
		self.stealthOpener = InputText("STO", self.stealthOpener);
		Text("Stealth - Distance to target"); 
		self.stealthRange = SliderFloat('SR (yd)', 1, 100, self.stealthRange);
		wasClicked, self.throwOpener = Checkbox("Pull with throw (if stealth disabled)", self.throwOpener);
		Text("Throwing weapon");
		self.throwName = InputText("TW", self.throwName);	
		wasClicked, self.usePoison = Checkbox("Use poison on weapons", self.usePoison);
		Text("Poison on Main Hand");
		self.mainhandPoison = InputText("PMH", self.mainhandPoison);
		Text("Poison on Off Hand");
		self.offhandPoison = InputText("POH", self.offhandPoison);
	end
end