script_hunter = {
	message = 'Beastmaster - Hunter Combat Script',
	hunterExtra = include("scripts\\combat\\script_hunterEX.lua"),
	drinkMana = 50,
	eatHealth = 50,
	potionHealth = 10,
	potionMana = 20,
	feedTimer = 0,
	waitTimer = 0,
	hasPet = true,
	bagWithPetFood = 4,
	slotWithPetFood = GetContainerNumSlots(3), -- last slot in the bag
	foodName = 'PET FOOD NAME',
	stopWhenNoPetFood = true,
	quiverBagNr = 5,
	ammoIsArrow = true,
	useVendor = true,
	buyWhenQuiverEmpty = true,
	stopWhenQuiverEmpty = false,
	stopWhenBagsFull = false,
	hsWhenStop = true,
	hsBag = 1, -- HS in backpack (1rst bag)
	hsSlot = 1, -- HS in slot 1 of the bag: hsBag
	ammoName = 0,
	isSetup = false,
	dontRest = false,
	isChecked = true
}	

function script_hunter:setup()
	-- no more bug first time
	self.feedTimer = GetTimeEX();
	self.waitTimer = GetTimeEX();
	
	-- Save the name of ammo we use
	local bagSlots = GetContainerNumSlots(self.quiverBagNr-1);
	if (GetContainerItemLink(self.quiverBagNr-1, bagSlots)  ~= nil) then
		_,_,itemLink = string.find(GetContainerItemLink(self.quiverBagNr-1, bagSlots),"(item:%d+)");
		itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
   		itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink);
		self.ammoName = itemName;
	end

	DEFAULT_CHAT_FRAME:AddMessage('script_hunter: Ammo name is set to: "' .. self.ammoName .. '" ...');
	if (not strfind(itemName, "Arrow")) then
		DEFAULT_CHAT_FRAME:AddMessage('script_hunter: Ammo will be bought at "Bullet" vendors...');
		script_vendor.itemIsArrow = false;
		self.ammoIsArrow = false;
		script_vendor.ammoName = itemName;
	else
		DEFAULT_CHAT_FRAME:AddMessage('script_hunter: Ammo will be bought at "Arrow" vendors...');
		script_vendor.ammoName = itemName;
		self.ammoIsArrow = true;
	end	

	-- Save the name of pet food we use
	if (GetContainerItemLink(self.bagWithPetFood-1, self.slotWithPetFood)  ~= nil) then
		local _, _, iLink = string.find(GetContainerItemLink(self.bagWithPetFood-1, self.slotWithPetFood), "(item:%d+)");
		local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
   		itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(iLink);
		self.foodName = itemName;
		DEFAULT_CHAT_FRAME:AddMessage('script_hunter: Pet food name is set to: "' .. self.foodName .. '" ...');
	else
		DEFAULT_CHAT_FRAME:AddMessage('script_hunter: Please set the pet food name in hunter options...');
	end

	if (GetLocalPlayer():GetLevel() < 3) then
		self.buyWhenQuiverEmpty = false;
	end
		
	self.isSetup = true;
end

function script_hunter:cast(spellName, target)
	if (HasSpell(spellName)) then
		if (target:IsSpellInRange(spellName)) then
			if (not IsSpellOnCD(spellName)) then
				if (not IsAutoCasting(spellName)) then
					target:TargetEnemy();
					if (targetObj:IsInLineOfSight()) then
						target:FaceTarget();
					elseif (target:CastSpell(spellName)) then
						return true;
					elseif (not target:CastSpell(spellName)) then
						return false;
					end
					return target:CastSpell(spellName);
				end
			end
		end
	end
	return false;
end

function script_hunter:enemiesAttackingMe() -- returns number of enemies attacking me
	local unitsAttackingUs = 0; 
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
    	if typeObj == 3 then
		if (currentObj:CanAttack() and not currentObj:IsDead()) then
                	if (script_grind:isTargetingMe(currentObj)) then 
                		unitsAttackingUs = unitsAttackingUs + 1; 
                	end 
            	end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return unitsAttackingUs;
end

-- Run backwards if the target is within range
function script_hunter:runBackwards(targetObj, range) 
	local localObj = GetLocalPlayer();
 	if targetObj ~= 0 then
 		local xT, yT, zT = targetObj:GetPosition();
 		local xP, yP, zP = localObj:GetPosition();
 		local distance = targetObj:GetDistance();
 		local xV, yV, zV = xP - xT, yP - yT, zP - zT;	
 		local vectorLength = math.sqrt(xV^2 + yV^2 + zV^2);
 		local xUV, yUV, zUV = (1/vectorLength)*xV, (1/vectorLength)*yV, (1/vectorLength)*zV;		
 		local moveX, moveY, moveZ = xT + xUV*20, yT + yUV*20, zT + zUV;		
 		if (distance < range and targetObj:IsInLineOfSight()) then 
 			script_nav:moveToTarget(localObj, moveX, moveY, moveZ);
 			return true;
 		end
	end
	return false;
end

function script_hunter:draw()
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
 ]]--

function script_hunter:run(targetGUID)
	local localObj = GetLocalPlayer();
	local localMana = localObj:GetManaPercentage();
	local localHealth = localObj:GetHealthPercentage();
	local localLevel = localObj:GetLevel();
	
	if (localObj:IsDead()) then
		return 0;
	end

	-- Assign the target 
	targetObj = GetGUIDObject(targetGUID);

	if(targetObj == 0 or targetObj == nil) then
		ClearTarget();
		return 2;
	end

	-- Check: Do we have a pet?
	if (self.hasPet) then
		if (localLevel < 10) then
			self.hasPet = false;
		end
	end

	local pet = GetPet();
	local petHP = 0;
	if (pet ~= nil and pet ~= 0) then
		petHP = pet:GetHealthPercentage();
	end

	if (self.hasPet and not IsInCombat()) then
		if (script_hunterEX:petChecks()) then
			return 0;
		end
	end

	-- Check: Do nothing if we are channeling, casting or wait timer
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

		script_hunterEX:chooseAspect(targetObj);

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
			self.dontRest = true;
			if (script_hunter:doOpenerRoutine(targetGUID, pet)) then
				self.waitTimer = GetTimeEX() + 1850;
				return 4; -- return 0 bugs turning around cause of StopMoving();
			else
				return 3;
			end
			
		-- Combat
		else	
			self.dontRest = false;

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

			if (script_hunter:mendPet(localMana, petHP)) then
				self.waitTimer = GetTimeEX() + 1850;
				return 0;
			end

			if (targetHealth < 95 and self.hasPet and petHP > 20 and HasSpell("Feign Death") 
				and not IsSpellOnCD("Feign Death") and script_hunter:enemiesAttackingMe() >= 1) then
				CastSpellByName("Feign Death");
				self.waitTimer = GetTimeEX() + 3850;
				return 0;
			end
	
			if (targetObj:GetDistance() < 0.50) then
				if (script_hunter:runBackwards(targetObj, 2)) then
					self.waitTimer = GetTimeEX() + 1850;
					return 0;
				end
			end

			if (targetObj:GetDistance() < 14 and not script_grind:isTargetingMe(targetObj) and targetObj:GetUnitsTarget() ~= 0) then
				if (targetObj:GetUnitsTarget():GetGUID() == pet:GetGUID()) then
					if (script_hunter:runBackwards(targetObj, 15)) then
						PetAttack();
						self.message = "Moving away from target for range attacks...";
						return 4;
					end
				end
			end
			
			if (script_hunter:doInCombatRoutine(targetObj, localMana)) then
				self.waitTimer = GetTimeEX() + 1850;
				return 0;
			else
				return 3;
			end
		end
	end
end

function script_hunter:mendPet(localMana, petHP)
	local mendPet = HasSpell("Mend Pet");
	if (mendPet and IsInCombat() and self.hasPet and petHP > 0) then
		if (GetPet():GetHealthPercentage() < 35) then
			self.message = "Pet has lower than 35% HP, mending pet...";
			-- Check: If in range to mend the pet 
			if (GetPet():GetDistance() < 20 and localMana > 10 and GetPet():IsInLineOfSight()) then 
				if (IsMoving()) then StopMoving(); return true; end 
				CastSpellByName("Mend Pet"); 
				self.waitTimer = GetTimeEX() + 1850;
				return true;
			elseif (localMana > 10) then 
				script_nav:moveToTarget(GetLocalPlayer(), GetPet():GetPosition()); 
				return true; 
			end 
			
		end
	end
	return false;
end

function script_hunter:doOpenerRoutine(targetGUID, pet) 
	local targetObj = GetGUIDObject(targetGUID);
	self.message = "Pulling " .. targetObj:GetUnitName() .. "...";

	-- Let pet loose early to get aggro (even before we are in range ourselves)
	if (self.hasPet and targetObj:GetDistance() < 50) then 
		if (pet:GetUnitsTarget() ~= nil and pet:GetUnitsTarget() ~= 0) then
			if (pet:GetUnitsTarget():GetGUID() ~= targetObj:GetGUID()) then
				PetFollow(); 
			end
		else
			PetAttack();
		end
	end	
	
	-- Check: If we can auto attack, before moving "in line of sight"
	local canDoRangeAttacks = false;

	-- Attack: Use Auto Shot 
	if (not IsAutoCasting('Auto Shot') and targetObj:GetDistance() < 35 and targetObj:GetDistance() > 13) then
		-- Dismount
		if (IsMounted()) then DisMount(); end
		if (script_hunter:cast('Auto Shot', targetObj)) then canDoRangeAttacks = true; end
	elseif (IsAutoCasting('Auto Shot')) then
		canDoRangeAttacks = true;
	end
	
	if (canDoRangeAttacks) then
		if (script_hunter:doPullAttacks(targetObj, localMana)) then
			self.waitTimer = GetTimeEX() + 1850;
			return true;
		end
	end
	
	-- Check: If we are already in meele range before pull, use Raptor Strike
	if (targetObj:GetDistance() < 5) then
		if (not script_hunter:cast('Raptor Strike', targetObj)) then
			targetObj:FaceTarget(); 
			return true; 
		end 
	end
	
	-- Move to the target if not in line of sight or not in range
	if (not targetObj:IsInLineOfSight() or targetObj:GetDistance() > 35 or targetObj:GetDistance() < 14) then 
		return false;
	end 
	
	if (script_hunter:doPullAttacks(targetObj)) then
		self.waitTimer = GetTimeEX() + 1850;
		return true;
	end

	return true; -- return true so we dont move closer to the mob
end

function script_hunter:doPullAttacks(targetObj)
	-- Dismount
	if (IsMounted()) then DisMount(); end
	-- Pull with Concussive Shot to make it easier for pet to get aggro
	if (script_hunter:cast('Concussive Shot', targetObj)) then return true; end
	-- If no concussive shot pull with Serpent Sting
	if (targetObj:GetCreatureType() ~= 'Elemental') then
		if (script_hunter:cast('Serpent Sting', targetObj)) then return true; end
	end
	-- If no special attacks available for pull use Auto Shot
	if (script_hunter:cast('Auto Shot', targetObj)) then return true; end
	return false;
end

function script_hunter:doInCombatRoutine(targetObj, localMana) 
	self.message = "Killing " .. targetObj:GetUnitName() .. "...";
	local targetHealth = targetObj:GetHealthPercentage(); -- update target's HP
	local pet = GetPet(); -- get pet

	-- Dismount
	if (IsMounted()) then DisMount(); end

	-- Check: If pet is too far away set it to follow us, else attack
	if (self.hasPet and GetPet() ~= 0) then
		if (pet:GetDistance() > 34) then 
			PetFollow(); 
		else 
			if (pet:GetUnitsTarget() ~= nil and pet:GetUnitsTarget() ~= 0) then
				if (pet:GetUnitsTarget():GetGUID() ~= targetObj:GetGUID()) then
					PetFollow(); 
				end
			else
				PetAttack();
			end
		end
	end

	-- Check: Use Rapid Fire if we have adds
	if (script_grind:enemiesAttackingUs() > 1 and HasSpell('Rapid Fire') and not IsSpellOnCD('Rapid Fire')) then
		CastSpellByName('Rapid Fire');
		return 0;
	end

	-- Check: If pet is stunned, feared etc use Bestial Wrath
	if (self.hasPet and GetPet() ~= 0 and GetPet() ~= nil) then
		if ((pet:IsStunned() or pet:IsConfused() or pet:IsFleeing()) and 
			UnitExists("Pet") and HasSpell('Bestial Wrath')) then 
			if (script_hunter:cast('Bestial Wrath', targetObj)) then 
				return true; 
			end
		end
	end

	-- Check: If in range, try to use range attacks before moving "in line of sight"
	if (targetObj:GetDistance() < 35 and targetObj:GetDistance() > 13) then
		if(script_hunter:doRangeAttack(targetObj, localMana)) then
			return true;
		end
	end

	if (not targetObj:IsInLineOfSight() or targetObj:GetDistance() > 35) then
		return false;
	elseif (targetObj:GetDistance() < 12 and targetObj:GetDistance() > 5) then
		return false;
	else
		if(targetObj:IsInLineOfSight() and (targetObj:GetDistance() < 35 or targetObj:GetDistance() < 4)) then 
			targetObj:FaceTarget();
			if (IsMoving()) then
				StopMoving(); 
			end
		end
	end

	-- Check: If we are in meele range and have no pet or rotation use meele abilities
	if (targetObj:GetDistance() < 5) then
		-- Meele Skill: Raptor Strike
		if (localMana > 10 and not IsSpellOnCD('Raptor Strike')) then 
			if (script_hunter:cast('Raptor Strike', targetObj)) then 
				return true; 
			end 
		end
		-- Meele Skill: Wing Clip (keeps the debuff up)
		if (localMana > 10 and not targetObj:HasDebuff('Wing Clip') and HasSpell('Wing Clip')) then 
			if (script_hunter:cast('Wing Clip', targetObj)) then 
				return true; 
			end 
		end
	end

	if (not targetObj:IsInLineOfSight() or targetObj:GetDistance() > 35) then 
		return false;
	else 
		if (IsMoving() and targetObj:GetDistance() > 15) then 
			return true;
		end
	end

	if (targetObj:GetDistance() < 5) then 
		return true; -- so we dont walk around when we meele mobs
	end

	if (script_hunter:doRangeAttack(targetObj, localMana)) then
		return true;
	else
		return false;
	end
end

function script_hunter:doRangeAttack(targetObj, localMana)
	-- Keep up the debuff: Hunter's Mark 
	if (not targetObj:HasDebuff("Hunter's Mark") and not IsSpellOnCD("Hunter's Mark")) then 
		if (script_hunter:cast("Hunter's Mark", targetObj)) then return true; end end
	-- Attack: Use Auto Shot 
	if (not IsAutoCasting('Auto Shot')) then
		if (script_hunter:cast('Auto Shot', targetObj)) then return true; else return false; end
	end
	-- Check: Let pet get aggro, dont use special attacks before the mob has less than 95% HP
	if (targetObj:GetHealthPercentage() > 95 and UnitExists("Pet")) then return true; end
	-- Check: Intimidation is ready and mob HP high
	if (not IsSpellOnCD('Intimidation') and targetObj:GetHealthPercentage() > 50) then 
		if (script_hunter:cast('Intimidation', targetObj)) then return true; end end		
	-- Special attack: Serpent Sting (Keep the DOT up!)
	if (not targetObj:HasDebuff('Serpent Sting') and not IsSpellOnCD('Serpent Sting') and targetObj:GetCreatureType() ~= 'Elemental') then 
		if (script_hunter:cast('Serpent Sting', targetObj)) then return true; end end
	-- Special attack: Arcane Shot (Only when mana above 70% mana)
	if (not IsSpellOnCD('Arcane Shot') and localMana > 70) then 
		if (script_hunter:cast('Arcane Shot', targetObj)) then return true; end end
	-- Check if we are able to attack
	if (IsAutoCasting('Auto Shot')) then
		return true;
	end
end

function script_hunter:rest()
	if (not self.isSetup) then
		script_hunter:setup();
	end

	if (self.dontRest) then
		return false;
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

	-- Check: Let the feed pet duration last, don't engage new targets
	if (self.feedTimer > GetTimeEX() and not IsInCombat() and self.hasPet and GetPet() ~= 0) then 
		self.message = "Feeding the pet, pausing...";
		if (GetPet():GetDistance() > 8) then
			PetFollow();
			self.waitTimer = GetTimeEX() + 1750;
			return true;
		end
		return true;
	end

	-- Eat and Drink
	if (not IsDrinking() and localMana < self.drinkMana) then
		self.message = "We need to drink...";
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
		self.message = "We need to eat...";
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
		self.message = "Resting, eating and/or drinking...";
		return true;
	end

	-- Check hunter bags if they are full
	local inventoryFull = true;
	-- Check bags 1-5, except the quiver bag (quiverBagNr)
	for i=1,5 do 
		if (i ~= self.quiverBagNr) then 
			for y=1,GetContainerNumSlots(i-1) do 
				local texture, itemCount, locked, quality, readable = GetContainerItemInfo(i-1,y);
				if (itemCount == 0 or itemCount == nil) then 
					inventoryFull = false; 
				end 
			end 
		end 
	end

	-- Tell the grinder we cant loot
	if (inventoryFull) then
		script_grind.bagsFull = true;
	end

	if (self.useVendor and inventoryFull) then
		script_vendor:sell();
		return false;
	end

	-- Check: If Mainhand is broken stop bot
	local isRangedBroken = GetInventoryItemBroken("player", 18);
	
	if (isRangedBroken and self.useVendor) then
		self.message = "Our weapon is broken, go to reapir...";
		script_vendor:repair();
		return false;
	end

	if (inventoryFull and self.stopWhenBagsFull) then
		self.message = "Inventory is full...";
		if (IsMoving()) then StopMoving(); end
		
		if (self.hsWhenStop) then
			if (GetContainerItemCooldown(self.hsBag-1, self.hsSlot) == 0) then 
				UseItem('Hearthstone'); 
				self.message = "Inventory is full, using hearthstone...";
				return true; 
			else 
				Logout(); StopBot(); return true; 
			end 	
		end
		return true;
	end

	-- Quiver check : should we go buy ammo?
	if (self.buyWhenQuiverEmpty and self.ammoName ~= 0 and not IsInCombat()) then
		local ammoNr = 0;
		for y=1,GetContainerNumSlots(self.quiverBagNr-1) do
			local texture, itemCount, locked, quality, readable = GetContainerItemInfo(self.quiverBagNr-1,y);
			if (itemCount ~= nil) then 
				ammoNr = ammoNr + 1; 
			end 
		end

		-- Go buy ammo if we have just 1 stack of ammo left
		if (ammoNr <= 1 and self.ammoName ~= 0) then
			script_vendor:buyAmmo(self.quiverBagNr-1, self.ammoName, self.ammoIsArrow);
			return false;
		end 
	end

	-- Quiver check : Stop when out of ammo?
	if (self.stopWhenQuiverEmpty and not IsInCombat()) then
		local quiverEmpty = true;
		for y=1,GetContainerNumSlots(self.quiverBagNr-1) do
			local texture, itemCount, locked, quality, readable = GetContainerItemInfo(self.quiverBagNr-1,y);
			if (itemCount ~= nil) then 
				quiverEmpty = false; 
			end 
		end

		if (quiverEmpty and self.hsWhenStop) then
			if (GetContainerItemCooldown(self.hsBag-1, self.hsSlot) == 0) then 
				UseItem('Hearthstone'); 
				self.message = "Quiver is empty, using hearthstone...";
				return true; 
			else 
				Logout(); StopBot(); return true; 
			end 	
		end
		if (quiverEmpty) then
			Logout(); StopBot(); return true;
		end
	end

	-- Check pet food, change bag and/or slot if the stack ran out
	script_hunterEX:checkPetFood();

	-- Pet checks
	if (script_hunterEX:petChecks()) then return true; end

	-- Aspect check
	if (not IsMounted()) then if (script_hunterEX:chooseAspect(script_grind:getTarget())) then return false; end end

	-- No rest / buff needed
	return false;
end

function script_hunter:mount()

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

function script_hunter:menu()
	if (CollapsingHeader("[Hunter - Beastmaster")) then
		local wasClicked = false;
		Text('Use Pet or not:');
		wasClicked, self.hasPet = Checkbox("Do we have an active pet?", self.hasPet);
		Separator();
		Text('Drink below mana percentage');
		self.drinkMana = SliderFloat("M%", 1, 100, self.drinkMana);
		Text('Eat below health percentage');
		self.eatHealth = SliderFloat("H%", 1, 100, self.eatHealth);
		Text('Use health potions below percentage');
		self.potionHealth = SliderFloat("HP%", 1, 99, self.potionHealth);
		Text('Use mana potions below percentage');
		self.potionMana = SliderFloat("MP%", 1, 99, self.potionMana);
		Separator();
		Text('Vendor/Bag settings:');
		wasClicked, self.useVendor = Checkbox("Vendor when full inventory.", self.useVendor);	
		wasClicked, self.buyWhenQuiverEmpty = Checkbox("Buy ammo when only 1 stack left.", self.buyWhenQuiverEmpty);	
		Text("Bag# with pet food (2-5)");
		self.bagWithPetFood = InputText("BPF", self.bagWithPetFood);
		Text("Bagslot# with pet food (1-Maxslot)");
		self.slotWithPetFood = InputText("SPF", self.slotWithPetFood);
		Text("Pet Food Name:");
		self.foodName = InputText("PFN", self.foodName);
		Text('Always put the pet food in the last slot of the bag.');
		Separator();
		self.quiverBagNr = InputText("Bag# for quiver (2-5)", self.quiverBagNr);
		self.hsBag = InputText("Bag# for HS", self.hsBag);
		self.hsSlot = InputText("Bag-slot (1-X) for HS", self.hsSlot);
		Separator();	
		Text('Stop settings:');
		wasClicked, self.stopWhenBagsFull = Checkbox("Stop when bags are full", self.stopWhenBagsFull);
		wasClicked, self.stopWhenQuiverEmpty = Checkbox("Stop when we run out of ammo", self.stopWhenQuiverEmpty);
		wasClicked, self.stopWhenNoPetFood = Checkbox("Stop when we run out of pet food", self.stopWhenNoPetFood);
		wasClicked, self.hsWhenStop = Checkbox("Use HS before stopping the bot, if not on CD", self.hsWhenStop);
	end
end