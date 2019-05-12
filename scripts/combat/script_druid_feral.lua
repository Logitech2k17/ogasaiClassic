script_druid = {
	message = 'Druid - Feral',
	eatHealth = 60,
	drinkMana = 50,
	healHealth = 40,
	rejuHealth = 80,
	regrowthHealth = 60,
	healHealthWhenShifted = 40,
	potionHealth = 12,
	potionMana = 20,
	isSetup = false,
	meeleDistance = 4,
	waitTimer = 0,
	stopIfMHBroken = true,
	cat = false,
	bear = false,
	stayCat = false,
	isChecked = true
}

function script_druid:setup()
	-- Sort forms
	if (HasSpell('Cat Form')) then
		self.cat = true;
	elseif (HasSpell('Bear Form')) then
		self.bear = true;
	end
	
	self.waitTimer = GetTimeEX();	

	self.isSetup = true;
end

function script_druid:getSpellCost(spell)
	_, _, _, _, cost, _, _ = GetSpellInfo(spell);
	return cost;
end

function script_druid:spellAttack(spellName, target)
	if (HasSpell(spellName)) then
		if (target:IsSpellInRange(spellName)) then
			if (not IsSpellOnCD(spellName)) then
				if (not IsAutoCasting(spellName)) then
					target:FaceTarget();
					return target:CastSpell(spellName);
				end
			end
		end
	end
	return false;
end

function script_druid:enemiesAttackingUs(range) -- returns number of enemies attacking us within range
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
function script_druid:runBackwards(targetObj, range) 
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

function script_druid:draw()
	--script_druid:window();
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

function script_druid:run(targetGUID)
	
	if(not self.isSetup) then
		script_druid:setup();
	end
	
	local localObj = GetLocalPlayer();
	local localHealth = localObj:GetHealthPercentage();
	local localMana = localObj:GetManaPercentage();
	local localLevel = localObj:GetLevel();

	if (localObj:IsDead()) then
		return 0; 
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
			self.message = "Pulling " .. targetObj:GetUnitName() .. "...";

			-- Dismount
			if (IsMounted() and targetObj:GetDistance() < 25) then 
				DisMount(); 
				return 4; 
			end

			-- Go Cat Form
			if (self.cat and not localObj:HasBuff('Cat Form')) then
				-- Dismount
				if (IsMounted()) then 
					DisMount(); 
				end
				CastSpellByName('Cat Form');
				self.stayCat = true;
				return 3;
			end

			if(targetObj:GetDistance() > 30 or not targetObj:IsInLineOfSight()) then
				return 3;
			end

			-- Go human form if in bear to pull
			if (localObj:HasBuff('Bear Form')) then
				CastSpellByName('Bear Form');
				return 3;
			end

			-- Pull with Faerie Fire
			if (HasSpell('Faerie Fire (Feral)') and localObj:HasBuff('Cat Form')) then
				if (Cast('Faerie Fire (Feral)', targetObj)) then 
					self.message = "Pulling with Faerie Fire...";
					return 3;
				end
			end

			-- Wrath
			if (targetObj:GetDistance() < 30  and targetObj:IsInLineOfSight() and not self.cat) then
				-- Dismount
				if (IsMounted()) then 
					DisMount(); 
				end
					
				if (IsMoving()) then
					StopMoving();
					return 0;
				end

				if (localObj:HasBuff('Bear Form')) then
					return 4;
				end

				if (Cast('Wrath', targetObj)) then
					self.message = "Pulling with Wrath...";
					return 0;
				end
			end
				

			-- Pull with Claw
			if (self.cat and localObj:HasBuff('Cat Form') and targetObj:GetDistance() < 5) then
				if (Cast('Claw', targetObj)) then
					return 0;
				end
			end

			-- Check move into meele range
			if (targetObj:GetDistance() > self.meeleDistance or not targetObj:IsInLineOfSight()) then
				return 3;
			end

		-- Combat
		else	
			self.message = "Killing " .. targetObj:GetUnitName() .. "...";

			-- Reset stay cat after combat
			self.stayCat = false;
			
			-- Dismount
			if (IsMounted()) then 
				DisMount();
			end
			
			-- Run backwards if we are too close to the target
			if (targetObj:GetDistance() < 0.5) then 
				if (script_druid:runBackwards(targetObj,3)) then 
					return 4; 
				end 
			end

			targetObj:FaceTarget();
			targetObj:AutoAttack();

			-- Check: Rejuvenation
			if (localHealth < self.rejuHealth and localMana > 10 and not localObj:HasBuff('Rejuvenation') and HasSpell('Rejuvenation')) then
				if (localObj:HasBuff('Bear Form') and localHealth < self.healHealthWhenShifted and localMana > 20) then
					CastSpellByName('Bear Form');
					return 0;
				elseif(localObj:HasBuff('Cat Form') and localHealth < self.healHealthWhenShifted and localMana > 35) then
					CastSpellByName('Cat Form');
					return 0;
				end
			
				if (not localObj:HasBuff('Cat Form') and not localObj:HasBuff('Bear Form')) then
					if ((self.cat and localMana > 35) or (self.bear and localMana > 20) or (not self.cat and not self.bear)) then
						if (Buff("Rejuvenation", localObj)) then
							return 0;
						end
					end
				end
			end

			-- Check: Regrowth
			if (localHealth < self.regrowthHealth and localMana > 15 and not localObj:HasBuff('Regrowth') and HasSpell('Regrowth')) then
				
				-- Bash the target before we heal
				if (localObj:HasBuff('Bear Form') and HasSpell('Bash') and not IsSpellOnCD('Bash')) then
					if(Cast('Bash', targetObj)) then
						return 0;
					end
				end

				if (localObj:HasBuff('Bear Form') and localHealth < self.healHealthWhenShifted and localMana > 20) then
					CastSpellByName('Bear Form');
					return 0;
				elseif(localObj:HasBuff('Cat Form') and localHealth < self.healHealthWhenShifted and localMana > 35) then
					CastSpellByName('Cat Form');
					return 0;
				end

				if (not localObj:HasBuff('Cat Form') and not localObj:HasBuff('Bear Form')) then
					if ((self.cat and localMana > 35) or (self.bear and localMana > 20) or (not self.cat and not self.bear)) then
						if (Buff("Regrowth", localObj)) then
							return 0;
						end
					end
				end
			end

			-- Check: Heal ourselves if below heal health, if we have mana for heal & shapeshift back
			if (localHealth < self.healHealth) then

				-- Bash the target before we heal
				if (localObj:HasBuff('Bear Form') and HasSpell('Bash') and not IsSpellOnCD('Bash')) then
					if(Cast('Bash', targetObj)) then
						return 0;
					end
				end

				-- Shapeshift
				if (localObj:HasBuff('Bear Form') and localHealth < self.healHealthWhenShifted and localMana > 20) then
					CastSpellByName('Bear Form');
					return 0;
				elseif(localObj:HasBuff('Cat Form') and localHealth < self.healHealthWhenShifted and localMana > 35) then
					CastSpellByName('Cat Form');
					return 0;
				end
				
				if (not localObj:HasBuff('Cat Form') and not localObj:HasBuff('Bear Form')) then
					if ((self.cat and localMana > 35) or (self.bear and localMana > 20) or (not self.cat and not self.bear)) then
						-- Heal
						if (Buff('Healing Touch', localObj)) then 
							self.waitTimer = GetTimeEX() + 4000;
							self.message = "Healing: Healing Touch...";
							return 0;
						end
					end
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

			-- When we are not shapeshifted , but save mana for shapeshift
			if (not localObj:HasBuff('Bear Form') and not localObj:HasBuff('Cat Form')) then

				-- Rejuvenation if not full HP
				if (localHealth < 98 and localMana and localMana > 35) then
					if (Buff("Rejuvenation", localObj)) then
						return 0;
					end
				end
				
				-- Check: Remove poison
				if (localObj:HasDebuff('Poison') or localObj:HasDebuff('Dark Sludge') 
					or localObj:HasDebuff('Corrosive Poison') or localObj:HasDebuff('Slowing Poison')) then
					if(HasSpell('Cure Poison') and localMana > 35) then
						if (Buff('Cure Poison', localObj)) then 
							self.message = 'Cleansing...'; 
							self.waitTimer = GetTimeEX() + 1750; 
							return 0; 
						end
					end
				end

				-- TODO : Remove Curse

				-- In range for casts?
				if (targetObj:IsSpellInRange('Wrath') and targetObj:IsInLineOfSight()) then

					-- Stop moving
					if (IsMoving()) then
						StopMoving();
						return 0;
					end

					-- Moonfire before shapeshift
					if (not targetObj:HasDebuff('Moonfire') and HasSpell('Moonfire') and localMana > 35) then
						if (Cast('Moonfire', targetObj)) then
							return 0;
						end
					end

					-- Wrath if we don't have bear or cat
					if (not self.cat and not self.bear) then
						if (Cast('Wrath', targetObj)) then
							return 0;
						end
					end
				end
			end

			-- Shapeshift
			if (self.cat and not localObj:HasBuff('Cat Form')) then
				CastSpellByName('Cat Form');
				return 0;
			elseif (self.bear and not localObj:HasBuff('Bear Form')) then
				CastSpellByName('Bear Form');
				return 0;
			end

			-- Check if we are in meele range
			if (targetObj:GetDistance() > self.meeleDistance or not targetObj:IsInLineOfSight()) then
				return 3;
			else
				if (IsMoving()) then 
					StopMoving(); 
				end
			end

			-- Check: If we are in meele range, do meele attacks
			if (targetObj:GetDistance() < self.meeleDistance) then
				if (IsMoving()) then
					StopMoving();
				end

				-- Cat form
				if (self.cat) then
					local energy = GetLocalPlayer():GetEnergyPercentage();
					local cp = GetComboPoints("player", "target");

					-- Buff: Tiger Fury
					if (HasSpell("Tiger's Fury") and not IsSpellOnCD("Tiger's Fury") and not localObj:HasBuff("Tiger's Fury")) then
						if (targetHealth > 50 and energy >= 30) then
							self.message = "Buffing with Tiger's Fury...";
							CastSpellByName("Tiger's Fury");
							return 0;
						end
					end

					-- Finisher Logic, when 5 CPs or target has low HP
					if (cp == 5 or (cp*10) >= targetHealth) then

						-- Ferocious Bite
						if (HasSpell('Ferocious Bite')) then
							if (energy < 45) then
								self.message = "Saving energy for Ferocious Bite...";
								return 0; -- save energy
							else
								if (Cast('Ferocious Bite', targetObj)) then
									self.message = "Using Ferocious Bite...";
									return 0;
								end
							end
							
						
						else	
							-- Rip 
							if (energy < 30) then
								self.message = "Saving energy for Rip...";
								return 0;
							else
								if (Cast('Rip', targetObj)) then
									self.message = "Using Rip...";
									return 0;
								end
							end
						end
					end

					-- Keep Rake Up
					if (HasSpell('Rake') and not targetObj:HasDebuff('Rake')) then
						if (energy <= 40) then
							self.message = "Saving energy for Rake...";
							return 0; -- save energy for rake
						else
							if (Cast('Rake', targetObj)) then
								self.message = "Using Rake...";
								return 0;
							end
						end
					end

					-- Claw to get CP's
					if (not IsSpellOnCD('Claw') and energy >= 45) then
						if (Cast('Claw', targetObj)) then
							self.message = "Using Claw...";
							return 0;
						end
					end


				-- Bear form
				elseif (self.bear) then

					local rage = GetLocalPlayer():GetRagePercentage();

					-- If we fight more than one target
					if (script_druid:enemiesAttackingUs(5) > 1) then
						-- Demoralizing roar
						if (not targetObj:HasDebuff('Demoralizing Roar') and HasSpell('Demoralizing Roar') and rage >= 10) then
							CastSpellByName('Demoralizing Roar');
							self.message = "Using Demoralizing Roar...";
							return 0;
						end
						
						-- Swipe
						if (HasSpell('Swipe') and rage >= 20) then
							CastSpellByName('Swipe');
							self.message = "Using Swipe...";
							return 0;
						elseif (rage < 20) then
							self.message = "Saving rage for Swipe...";
							return 0; -- save rage for swipe
						end
					end
				
					-- Maul
					if (not IsSpellOnCD('Maul') and rage >= 15) then
						if(Cast('Maul', targetObj)) then
							return 0;
						end
					end
					
				end

				-- Always face the target
				targetObj:FaceTarget(); 
				return 0; 
			end

			return 0;
		end
	end
end

function script_druid:rest()
	if(not self.isSetup) then
		script_druid:setup();
	end

	local localObj = GetLocalPlayer();
	local localLevel = localObj:GetLevel();
	local localHealth = localObj:GetHealthPercentage();
	local localMana = localObj:GetManaPercentage();

	-- Stay shapeshifted if we have hp!
	if (localObj:HasBuff('Cat Form') or localObj:HasBuff('Bear Form')) then
		if (localHealth > 90) then
			return false;
		end
	end

	-- Stop moving and shapeshift before we can rest
	if((localHealth < self.eatHealth or localMana < self.drinkMana) and not self.stayCat) then
		if (IsMoving()) then
			StopMoving();
			return true;
		end
	end

	-- Leave shape shift form
	if ((localHealth < self.eatHealth or localMana < self.drinkMana) and not self.stayCat) then
		if (localObj:HasBuff('Cat Form')) then
			CastSpellByName('Cat Form');
			return true;
		end
		if (localObj:HasBuff('Bear Form')) then
			CastSpellByName('Bear Form');
			return true;
		end
	end

	-- Heal if we are not shapeshifted
	if (not localObj:HasBuff('Cat Form') and not localObj:HasBuff('Bear Form')) then
		-- Stand up before healing
		if (not IsStanding() and not IsDrinking()) then
			StopMoving();
			return true;
		end
	
		-- Heal up: Healing Touch
		if (localMana > 20 and localHealth < self.healHealth) then
			if (Buff('Healing Touch', localObj)) then
				script_grind:setWaitTimer(5000);
				self.message = "Healing: Healing Touch...";
			end
			return true;
		end

		-- Heal up: Regrowth
		if (localMana > 20 and localHealth < self.regrowthHealth and not localObj:HasBuff('Regrowth')) then
			if (Buff('Regrowth', localObj)) then
				return true;
			end
		end

		-- Heal up: Rejuvenation
		if (localMana > 20 and localHealth < self.rejuHealth and not localObj:HasBuff('Rejuvenation')) then
			if (Buff('Rejuvenation', localObj)) then
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
	
	-- Buff
	if (not IsMounted() and not localObj:HasBuff('Cat Form') and not localObj:HasBuff('Bear Form')) then
		if (not localObj:HasBuff('Mark of the Wild') and HasSpell('Mark of the Wild')) then
			if (not Buff('Mark of the Wild', localObj)) then
				return true;
			end
		end
		
		if (not localObj:HasBuff('Thorns') and HasSpell('Thorns')) then
			if (not Buff('Thorns', localObj)) then
				return true;
			end
		end
	end

	-- Don't need to rest
	return false;
end

function script_druid:mount()
	return false;
end

function script_druid:window()

	if (self.isChecked) then
	
		--Close existing Window
		EndWindow();

		if(NewWindow("Class Combat Options", 200, 200)) then
			script_druid:menu();
		end
	end
end

function script_druid:menu()
	if (CollapsingHeader("[Druid - Feral")) then
		local wasClicked = false;
		Text('Rest options:');
		self.eatHealth = SliderFloat("Eat below HP%", 1, 100, self.eatHealth);
		self.drinkMana = SliderFloat("Drink below Mana%", 1, 100, self.drinkMana);
		Text('You can add more food/drinks in script_helper.lua');
		Separator();
		Text('Combat options:');
		wasClicked, self.stopIfMHBroken = Checkbox("Stop bot if main hand is broken (red)...", self.stopIfMHBroken);
		self.healHealthWhenShifted = SliderFloat("Shapeshift to heal HP%", 1, 99, self.healHealthWhenShifted);
		self.potionHealth = SliderFloat("Potion below HP%", 1, 99, self.potionHealth);
		self.potionMana = SliderFloat("Potion below Mana%", 1, 99, self.potionMana);
		self.healHealth = SliderFloat("Healing Touch HP% (in combat)", 1, 99, self.healHealth);
		self.regrowthHealth = SliderFloat("Regrowth HP% (in combat)", 1, 99, self.regrowthHealth);
		self.rejuHealth = SliderFloat("Rejuvenation HP% (in combat)", 1, 99, self.rejuHealth);
		self.meeleDistance = SliderFloat("Meele range", 1, 6, self.meeleDistance);
	end
end
