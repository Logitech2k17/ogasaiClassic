script_mage = {
	message = 'Frostbite - Mage Combat Script',
	drinkMana = 59,
	eatHealth = 59,
	potionHealth = 10,
	potionMana = 20,
	water = {},
	numWater = 0,
	food = {},
	numfood = 0,
	manaGem = {},
	numGem = 0,
	isSetup = false,
	polyTimer = 0,
	cooldownTimer = 0,
	addPolymorphed = false,
	useManaShield = true,
	iceBlockHealth = 35,
	iceBlockMana = 35,
	evocationMana = 15,
	evocationHealth = 40,
	manaGemMana = 20,
	polymorphAdds = true,
	useFireBlast = true,
	waitTimer = 0,
	useWand = false,
	gemTimer = 0,
	isChecked = true
}

function script_mage:window()

	if (self.isChecked) then
	
		--Close existing Window
		EndWindow();

		if(NewWindow("Class Combat Options", 200, 200)) then
			script_mage:menu();
		end
	end
end

function script_mage:cast(spellName, target)
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

function script_mage:getTargetNotPolymorphed()
   	local unitsAttackingUs = 0; 
   	local currentObj, typeObj = GetFirstObject(); 
   	while currentObj ~= 0 do 
   		if typeObj == 3 then
			if (currentObj:CanAttack() and not currentObj:IsDead()) then
                		if (script_grind:isTargetingMe(currentObj) and not currentObj:HasDebuff('Polymorphed')) then 
                			return currentObj;
                		end 
            		end 
       		end
        	currentObj, typeObj = GetNextObject(currentObj); 
    	end
   	return nil;
end

function script_mage:isAddPolymorphed()
	local currentObj, typeObj = GetFirstObject(); 
	local localObj = GetLocalPlayer();
	while currentObj ~= 0 do 
		if typeObj == 3 then
			if (currentObj:HasDebuff("Polymorph")) then 
				return true; 
			end
		end
		currentObj, typeObj = GetNextObject(currentObj); 
	end
    	return false;
end

function script_mage:polymorphAdd(targetObjGUID) 
    local currentObj, typeObj = GetFirstObject(); 
    local localObj = GetLocalPlayer();
    while currentObj ~= 0 do 
    	if typeObj == 3 then
			if (currentObj:CanAttack() and not currentObj:IsDead()) then
				if (currentObj:GetGUID() ~= targetObjGUID and script_grind:isTargetingMe(currentObj)) then
					if (not currentObj:HasDebuff("Polymorph") and currentObj:GetCreatureType() ~= 'Elemental' and not currentObj:IsCritter()) then
						ClearTarget();
						if (script_mage:cast('Polymorph', currentObj)) then 
							self.addPolymorphed = true; 
							polyTimer = GetTimeEX() + 8000;
							return true; 
						end
					end 
				end 
			end 
		end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return false;
end

-- Run backwards if the target is within range
function script_mage:runBackwards(targetObj, range) 
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

function script_mage:addWater(name)
	self.water[self.numWater] = name;
	self.numWater = self.numWater + 1;
end

function script_mage:addFood(name)
	self.food[self.numfood] = name;
	self.numfood = self.numfood + 1;
end

function script_mage:addManaGem(name)
	self.manaGem[self.numGem] = name;
	self.numGem = self.numGem + 1;
end

function script_mage:setup()
	script_mage:addWater('Conjured Crystal Water');
	script_mage:addWater('Conjured Sparkling Water');
	script_mage:addWater('Conjured Mineral Water');
	script_mage:addWater('Conjured Spring Water');
	script_mage:addWater('Conjured Purified Water');
	script_mage:addWater('Conjured Fresh Water');
	script_mage:addWater('Conjured Water');
	
	script_mage:addFood('Conjured Cinnamon Roll');
	script_mage:addFood('Conjured Sweet Roll');
	script_mage:addFood('Conjured Sourdough')
	script_mage:addFood('Conjured Pumpernickel');
	script_mage:addFood('Conjured Rye');
	script_mage:addFood('Conjured Bread');
	script_mage:addFood('Conjured Muffin');
	
	script_mage:addManaGem('Mana Agate');
	script_mage:addManaGem('Mana Citrine');
	script_mage:addManaGem('Mana Jade');
	script_mage:addManaGem('Mana Ruby');

	-- no more bugs first time we run the bot
	self.waitTimer = GetTimeEX();
	self.gemTimer = GetTimeEX();
	self.cooldownTimer = GetTimeEX();
	self.polyTimer = GetTimeEX();

	self.isSetup = true;
end

function script_mage:draw()
	--script_mage:window();
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

function script_mage:run(targetGUID)
	
	if(not self.isSetup) then
		script_mage:setup();
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
	if (IsChanneling() or IsCasting() or localObj:HasBuff('Ice Block') or self.waitTimer > GetTimeEX()) then
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

		-- Don't attack if we should rest first
		if ((localHealth < self.eatHealth or localMana < self.drinkMana) and not script_grind:isTargetingMe(targetObj)
			and not targetObj:IsFleeing() and not targetObj:IsStunned() and not script_mage:isAddPolymorphed()) then
			self.message = "Need rest...";
			return 4;
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

			-- Opener spell
			if (HasSpell("Frostbolt")) then
				if(not targetObj:IsSpellInRange('Frostbolt') or not targetObj:IsInLineOfSight())  then
					return 3;
				end

				-- Check: If in range and in line of sight stop moving
				if (targetObj:IsInLineOfSight()) then
					if(IsMoving()) then StopMoving(); end
				end

				-- Dismount
				if (IsMounted()) then DisMount(); end

				if (script_mage:cast('Frostbolt', targetObj)) then
					self.waitTimer = GetTimeEX() + 200;
					return 0;
				end

				if (not targetObj:IsInLineOfSight()) then
					return 3;
				end
				return 0;
				
			else
				if(not targetObj:IsSpellInRange('Fireball'))  then
					return 3;
				end

				if (script_mage:cast('Fireball', targetObj)) then
					self.waitTimer = GetTimeEX() + 200;
					return 0;
				end

				if (not targetObj:IsInLineOfSight()) then
					return 3;
				end
				return 0;
			end
			
		-- Combat
		else	
			self.message = "Killing " .. targetObj:GetUnitName() .. "...";
			-- Dismount
			if (IsMounted()) then DisMount(); end

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

			-- Check: Keep Ice Barrier up if possible
			if (HasSpell("Ice Barrier") and not IsSpellOnCD("Ice Barrier") and not localObj:HasBuff("Ice Barrier")) then
					CastSpellByName('Ice Barrier');
					return 0;
			-- Check: If we have Cold Snap use it to clear the Ice Barrier CD
			elseif (HasSpell("Ice Barrier") and IsSpellOnCD("Ice Barrier") and HasSpell('Cold Snap') and not IsSpellOnCD("Cold Snap") and not localObj:HasBuff('Ice Barrier')) then
					CastSpellByName('Cold Snap');
					return 0;
			end
			
			-- Check: Move backwards if the target is affected by Frost Nova or Frost Bite
			if (targetHealth > 10 and (targetObj:HasDebuff("Frostbite") or targetObj:HasDebuff("Frost Nova")) and not localObj:HasBuff('Evocation') and targetObj ~= 0 and IsInCombat()) then
				if (script_mage:runBackwards(targetObj, 7)) then -- Moves if the target is closer than 7 yards
					self.message = "Moving away from target...";
					CastSpellByName("Frost Nova");
					return 4; 
				end 
			end	

			-- Use Mana Gem when low on mana
			if (localMana < self.manaGemMana and GetTimeEX() > self.gemTimer) then
				for i=0,self.numGem do
					if(HasItem(self.manaGem[i])) then
						UseItem(self.manaGem[i]);
						self.gemTimer = GetTimeEX() + 120000;
						return 0;
					end
				end
			end

			-- Use Evocation if we have low Mana but still a lot of HP left
			if (localMana < self.evocationMana and localHealth > self.evocationHealth and HasSpell("Evocation") and not IsSpellOnCD("Evocation")) then		
				self.message = "Using Evocation...";
				CastSpellByName("Evocation"); 
				return 0;
			end

			-- Use Mana Shield if we more than 35 procent mana and no active Ice Barrier
			if (not localObj:HasBuff('Ice Barrier') and HasSpell('Mana Shield') and localMana > 35 and not localObj:HasBuff('Mana Shield') and targetObj:GetDistance() < 15) then
				if (not targetObj:HasDebuff('Frost Nova') and not targetObj:HasDebuff('Frostbite')) then
					CastSpellByName('Mana Shield');
					return 0;
				end
			end

			-- Check if add already polymorphed
			if (not script_mage:isAddPolymorphed() and not (self.polyTimer < GetTimeEX())) then
				self.addPolymorphed = false;
			end

			-- Check: Polymorph add
			if (targetObj ~= nil and self.polymorphAdds and script_grind:enemiesAttackingUs() > 1 and HasSpell('Polymorph') and not self.addPolymorphed and self.polyTimer < GetTimeEX()) then
				self.message = "Polymorphing add...";
				script_mage:polymorphAdd(targetObj:GetGUID());
			end 

			-- Check: Sort target selection if add is polymorphed
			if (self.addPolymorphed) then
				if(script_grind:enemiesAttackingUs() >= 1 and targetObj:HasDebuff('Polymorph')) then
					ClearTarget();
					targetObj = script_mage:getTargetNotPolymorphed();
					targetObj:AutoAttack();
				end
			end

			-- Check: Frostnova when the target is close, but not when we polymorhped one enemy or the target is affected by Frostbite
			if (not self.addPolymorphed and targetObj:GetDistance() < 5 and not targetObj:HasDebuff("Frostbite") and HasSpell("Frost Nova") and not IsSpellOnCD("Frost Nova")) then
				self.message = "Frost nova the target(s)...";
				CastSpellByName("Frost Nova");
				return 0;
			end

			if (HasSpell('Ice Block') and not IsSpellOnCD('Ice Block') and localHealth < self.iceBlockHealth and localMana < self.iceBlockMana) then
				self.message = "Using Ice Block...";
				CastSpellByName('Ice Block');
				return 0;
			end

			-- Wand if low mana or target is low
			if (self.useWand) then
				if ((localMana <= 5 or targetHealth <= 5) and localObj:HasRangedWeapon()) then
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

			-- Fire blast
			if (self.useFireBlast and targetObj:GetDistance() < 20 and HasSpell('Fire Blast')) then
				if (script_mage:cast('Fire Blast', targetObj)) then
					return 0;
				end
			end
			
			-- Main damage source
			if (HasSpell("Frostbolt")) then
				if(not targetObj:IsSpellInRange('Frostbolt')) then
					return 3;
				end
				if (script_mage:cast('Frostbolt', targetObj)) then
					return 0;
				end
				if (not targetObj:IsInLineOfSight()) then
					return 3;
				end	
			else
				if(not targetObj:IsSpellInRange('Fireball')) then
					return 3;
				end
				if (script_mage:cast('Fireball', targetObj)) then
					return 0;
				end
				if (not targetObj:IsInLineOfSight()) then
					return 3;
				end	
			end		
		end
	end
end

function script_mage:rest()

	if(not self.isSetup) then
		script_mage:setup();
	end

	local localObj = GetLocalPlayer();
	local localMana = localObj:GetManaPercentage();
	local localHealth = localObj:GetHealthPercentage();

	--Create Water
	local waterIndex = -1;
	for i=0,self.numWater do
		if (HasItem(self.water[i])) then
			waterIndex = i;
			break;
		end
	end
	
	if (waterIndex == -1 and HasSpell('Conjure Water')) then 
		self.message = "Conjuring water...";
		if (IsMoving()) then
			StopMoving();
			return true;
		end
		if (not IsStanding()) then
				StopMoving();
			return true;
		end
		if(IsMounted()) then 
			DisMount(); 
		end
		if (localMana > 10 and not IsDrinking() and not IsEating() and not AreBagsFull()) then
			if (HasSpell('Conjure Water')) then
				CastSpellByName('Conjure Water')
				return true;
			end
		end
	end

	--Create Food
	local foodIndex = -1;
	for i=0,self.numfood do
		if (HasItem(self.food[i])) then
			foodIndex = i;
			break;
		end
	end
	if (foodIndex == -1 and HasSpell('Conjure Food')) then 
		self.message = "Conjuring food...";
		if (IsMoving()) then
			StopMoving();
			return true;
		end
		if (not IsStanding()) then
			StopMoving();
			return true;
		end
		if(IsMounted()) then 
			DisMount(); 
			return true;
		end
		if (localMana > 10 and not IsDrinking() and not IsEating() and not AreBagsFull()) then
			if (HasSpell('Conjure Food')) then
				CastSpellByName('Conjure Food')
				return true;
			end
		end
	end

	--Create Mana Gem
	local gemIndex = -1;
	for i=0,self.numGem do
		if (HasItem(self.manaGem[i])) then
			gemIndex = i;
			break;
		end
	end
	if (gemIndex == -1 and (HasSpell('Conjure Mana Ruby') 
				or HasSpell('Conjure Mana Citrine') 
				or HasSpell('Conjure Mana Jade')
				or HasSpell('Conjure Mana Agate'))) then 
		self.message = "Conjuring mana gem...";
		if(IsMounted()) then 
			DisMount(); 
		end
		if (IsMoving()) then
			StopMoving();
			return true;
		end
		if (localMana > 20 and not IsDrinking() and not IsEating() and not AreBagsFull()) then
			if (HasSpell('Conjure Mana Ruby')) then
				CastSpellByName('Conjure Mana Ruby')
				return true;
			elseif (HasSpell('Conjure Mana Citrine')) then
				CastSpellByName('Conjure Mana Citrine')
				return true;
			elseif (HasSpell('Conjure Mana Jade')) then
				CastSpellByName('Conjure Mana Jade')
				return true;
			elseif (HasSpell('Conjure Mana Agate')) then
				CastSpellByName('Conjure Mana Agate')
				return true;
			end
		end
	end

	-- Stop moving before we can rest
	if(localHealth < self.eatHealth or localMana < self.drinkMana) then
		if (IsMoving()) then
			StopMoving();
			return true;
		end
	end

	-- Eat and Drink
	if (not IsDrinking() and localMana < self.drinkMana) then
		self.message = "Need to drink...";
		-- Dismount
		if(IsMounted()) then 
			DisMount(); 
			return true; 
		end
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
	if (not IsEating() and localHealth < self.eatHealth) then
		-- Dismount
		if(IsMounted()) then DisMount(); end
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
	
	if(localMana < self.drinkMana or localHealth < self.eatHealth) then
		if (IsMoving()) then
			StopMoving();
		end
		return true;
	end
	
	if((localMana < 98 and IsDrinking()) or (localHealth < 98 and IsEating())) then
		self.message = "Resting to full hp/mana...";
		return true;
	end

	-- Do buffs if we got some mana 
	if (localMana > 30 and not IsMounted()) then
		if (not Buff('Arcane Intellect', localObj)) then
			if (not Buff('Dampen Magic', localObj)) then
				if (HasSpell("Ice Armor")) then
					if (not Buff('Ice Armor', localObj)) then
						return false;
					end
				else	
					if (not Buff('Frost Armor', localObj)) then
						return false;
					end
				end
			end
		end
	end

	-- No rest / buff needed
	return false;
end

function script_mage:menu()
	if (CollapsingHeader("[Mage - Frostbite")) then
		local wasClicked = false;
		Text('Drink below mana percentage');
		self.drinkMana = SliderFloat("DM%", 1, 100, self.drinkMana);
		Text('Eat below health percentage');
		self.eatHealth = SliderFloat("EH%", 1, 100, self.eatHealth);
		Text('Use health potions below percentage');
		self.potionHealth = SliderFloat("HP%", 1, 99, self.potionHealth);
		Text('Use mana potions below percentage');
		self.potionMana = SliderFloat("MP%", 1, 99, self.potionMana);
		Separator();
		Text('Skills options:');
		wasClicked, self.useWand = Checkbox("Use Wand", self.useWand);
		wasClicked, self.useFireBlast = Checkbox("Use Fire Blast", self.useFireBlast);
		wasClicked, self.useManaShield = Checkbox("Use Mana Shield", self.useManaShield);
		wasClicked, self.polymorphAdds = Checkbox("Polymorph Adds", self.polymorphAdds);
		Text('Evocation above health percent');
		self.evocationHealth = SliderFloat("EH%", 1, 90, self.evocationHealth);
		Text('Evocation below mana percent');
		self.evocationMana = SliderFloat("EM%", 1, 90, self.evocationMana);
		Text('Ice Block below health percent');
		self.iceBlockHealth = SliderFloat("IBH%", 5, 90, self.iceBlockHealth);
		Text('Ice Block below mana percent');
		self.iceBlockMana = SliderFloat("IBM%", 5, 90, self.iceBlockMana);
		Text('Mana Gem below mana percent');
		self.manaGemMana = SliderFloat("MG%", 1, 90, self.manaGemMana);		
	end
end
