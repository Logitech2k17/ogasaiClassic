script_warlock = {
	message = 'Shadowmaster - Warlock Combat Script',
	drinkMana = 70,
	eatHealth = 70,
	potionHealth = 10,
	potionMana = 20,
	healthStone = {},
	numStone = 0,
	stoneHealth = 40,
	isSetup = false,
	fearTimer = 0,
	cooldownTimer = 0,
	addFeared = false,
	fearAdds = true,
	waitTimer = 0,
	useWand = false,
	isChecked = true,
	useVoid = true,
	useImp = false,
	corruptionCastTime = 0, -- 0-2000 ms = 2000 with no improved corruption talent
}

function script_warlock:cast(spellName, target)
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

function script_warlock:getTargetNotFeared()
   	local unitsAttackingUs = 0; 
   	local currentObj, typeObj = GetFirstObject(); 
   	while currentObj ~= 0 do 
   		if typeObj == 3 then
			if (currentObj:CanAttack() and not currentObj:IsDead()) then
                		if ((script_grind:isTargetingMe(currentObj) or script_grind:isTargetingPet(currentObj)) and not currentObj:HasDebuff('Fear')) then 
                			return currentObj;
                		end 
            		end 
       		end
        	currentObj, typeObj = GetNextObject(currentObj); 
    	end
   	return nil;
end

function script_warlock:isAddFeared()
	local currentObj, typeObj = GetFirstObject(); 
	local localObj = GetLocalPlayer();
	while currentObj ~= 0 do 
		if typeObj == 3 then
			if (currentObj:HasDebuff("Fear")) then 
				return true; 
			end
		end
		currentObj, typeObj = GetNextObject(currentObj); 
	end
    	return false;
end

function script_warlock:fearAdd(targetObjGUID) 
	local currentObj, typeObj = GetFirstObject(); 
	local localObj = GetLocalPlayer();
	while currentObj ~= 0 do 
		if typeObj == 3 then
			if (currentObj:CanAttack() and not currentObj:IsDead()) then
				if (currentObj:GetGUID() ~= targetObjGUID and script_grind:isTargetingMe(currentObj)) then
					if (not currentObj:HasDebuff("Fear") and currentObj:GetCreatureType() ~= 'Elemental' and not currentObj:IsCritter()) then
						ClearTarget();
						if (script_warlock:cast('Fear', currentObj)) then 
							self.addFeared = true; 
							fearTimer = GetTimeEX() + 8000;
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
function script_warlock:runBackwards(targetObj, range) 
	local localObj = GetLocalPlayer();
 	if targetObj ~= 0 then
 		local xT, yT, zT = targetObj:GetPosition();
 		local xP, yP, zP = localObj:GetPosition();
 		local distance = targetObj:GetDistance();
 		local xV, yV, zV = xP - xT, yP - yT, zP - zT;	
 		local vectorLength = math.sqrt(xV^2 + yV^2 + zV^2);
 		local xUV, yUV, zUV = (1/vectorLength)*xV, (1/vectorLength)*yV, (1/vectorLength)*zV;		
 		local moveX, moveY, moveZ = xT + xUV*10, yT + yUV*10, zT + zUV*10;		
 		if (distance < range and targetObj:IsInLineOfSight()) then 
 			script_nav:moveToTarget(localObj, moveX, moveY, moveZ);
 			return true;
 		end
	end
	return false;
end

function script_warlock:addHealthStone(name)
	self.healthStone[self.numStone] = name;
	self.numStone = self.numStone + 1;
end

function script_warlock:setup()
	script_warlock:addHealthStone('Major Healthstone');
	script_warlock:addHealthStone('Greater Healthstone');
	script_warlock:addHealthStone('Healthstone');
	script_warlock:addHealthStone('Lesser Healthstone');
	script_warlock:addHealthStone('Minor Healthstone');

	self.waitTimer = GetTimeEX();
	self.fearTimer = GetTimeEX();
	self.cooldownTimer = GetTimeEX();

	if (not HasSpell("Summon Voidwalker")) then
		self.useImp = true;
		self.useVoid = false;
	end

	self.isSetup = true;
end

function script_warlock:draw()
	--script_warlock:window();
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

function script_warlock:run(targetGUID)
	
	if(not self.isSetup) then
		script_warlock:setup();
	end
	
	local localObj = GetLocalPlayer();
	local localMana = localObj:GetManaPercentage();
	local localHealth = localObj:GetHealthPercentage();
	local localLevel = localObj:GetLevel();
	local hasPet = false; if(GetPet() ~= 0) then hasPet = true; end
	
	if (localObj:IsDead()) then
		return 0;
	end
	
	-- Assign the target 
	targetObj =  GetGUIDObject(targetGUID);

	if(targetObj == 0 or targetObj == nil or targetObj:IsDead()) then
		ClearTarget();
		return 2;
	end

	-- Check: Do nothing if we are channeling, casting
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

		-- Check: When channeling, cancel Health Funnel when low HP
		if (hasPet) then
			if (GetPet():HasBuff("Health Funnel") and localHealth < 40) then
				local _x, _y, _z = localObj:GetPosition();
				script_nav:moveToTarget(localObj, _x + 1, _y + 1, _z); 
				return 0;
			end
		end

		-- Check: When channeling, cancel Drain Life when we get Nightfall buff
		if (GetTarget() ~= 0) then	
			if (GetTarget():HasDebuff("Drain Life") and localObj:HasBuff("Shadow Trance")) then
				local _x, _y, _z = localObj:GetPosition();
				script_nav:moveToTarget(localObj, _x + 1, _y + 1, _z); 
				return 0;
			end
		end

		-- Opener
		if (not IsInCombat()) then
			self.message = "Pulling " .. targetObj:GetUnitName() .. "...";
			-- Opener spell
			if (hasPet) then PetAttack(); end
			
			if(not targetObj:IsSpellInRange('Shadow Bolt') or not targetObj:IsInLineOfSight())  then
				return 3;
			end

			-- Dismount
			if(IsMounted()) then DisMount(); end
			-- In range:
			if (HasSpell("Siphon Life")) then
				if (Cast("Siphon Life", targetObj)) then self.waitTimer = GetTimeEX() + 1600; return 0; end
			elseif (HasSpell("Curse of Agony")) then
				if (Cast('Curse of Agony', targetObj)) then self.waitTimer = GetTimeEX() + 1600; return 0; end
			elseif (HasSpell("Immolate")) then
				if (Cast('Immolate', targetObj)) then self.waitTimer = GetTimeEX() + 2500; return 0; end
			else
				if (Cast('Shadow Bolt', targetObj)) then return 0; end
			end
	
		-- Combat
		else	
			self.message = "Killing " .. targetObj:GetUnitName() .. "...";

			-- Set the pet to attack
			if (hasPet) then PetAttack(); end

			-- Dismount
			if(IsMounted()) then DisMount(); end

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

			-- Check: If we got Nightfall buff then cast Shadow Bolt
			if (localObj:HasBuff("Shadow Trance")) then
				if (Cast('Shadow Bolt', targetObj)) then return 0; end
			end	

			-- Use Healthstone
			if (localHealth < self.stoneHealth) then
				for i=0,self.numStone do
					if(HasItem(self.healthStone[i])) then
						if (UseItem(self.healthStone[i])) then
							return 0;
						end
					end
				end
			end

			-- Check if add already feared
			if (not script_warlock:isAddFeared() and not (self.fearTimer < GetTimeEX())) then
				self.addFeared = false;
			end

			-- Check: Fear add
			if (targetObj ~= nil and self.fearAdds and script_grind:enemiesAttackingUs() > 1 and HasSpell('Fear') and not self.addFeared and self.fearTimer < GetTimeEX()) then
				self.message = "Fearing add...";
				script_warlock:fearAdd(targetObj:GetGUID());
			end 

			-- Check: Sort target selection if add is feared
			if (self.addFeared) then
				if(script_grind:enemiesAttackingUs() >= 1 and targetObj:HasDebuff('Fear')) then
					ClearTarget();
					targetObj = script_warlock:getTargetNotFeared();
					targetObj:AutoAttack();
				end
			end

			-- Check: If we don't got a soul shard, try to make one
			if (targetHealth < 25 and HasSpell("Drain Soul") and not HasItem('Soul Shard')) then
				if (Cast('Drain Soul', targetObj)) then return 0; end
			end

			-- Check: Heal the pet if it's below 50% and we are above 50%
			local petHP = 0; 
			if (hasPet) then local petHP = GetPet():GetHealthPercentage(); end
			if (hasPet and petHP > 0 and petHP < 50 and HasSpell("Health Funnel") and localHealth > 50) then
				if (GetPet():GetDistance() > 20 or not GetPet():IsInLineOfSight()) then
					script_nave:moveToTarget(localObj, GetPet():GetPosition()); 
					self.waitTimer = GetTimeEX() + 2000;
					return 0;
				else
					StopMoving();
				end
				CastSpellByName("Health Funnel"); return 0;
			end

			-- Wand if low mana or target is low
			if (self.useWand) then
				if ((localMana <= 5 or targetHealth <= 5) and localObj:HasRangedWeapon()) then
					self.message = "Using wand...";
					if (not IsAutoCasting("Shoot")) then
						targetObj:FaceTarget();
						targetObj:CastSpell("Shoot");
						self.waitTimer = GetTimeEX() + 1250; 
						return 0;
					end
					return 0;
				end
			end
			
			-- Check: Keep Siphon Life up (30 s duration)
			if (not targetObj:HasDebuff("Siphon Life") and targetHealth > 20) then
				if (Cast('Siphon Life', targetObj)) then self.waitTimer = GetTimeEX() + 1600; return 0; end
			end

			-- Check: Keep the Curse of Agony up (24 s duration)
			if (not targetObj:HasDebuff("Curse of Agony") and targetHealth > 20) then
				if (Cast('Curse of Agony', targetObj)) then self.waitTimer = GetTimeEX() + 1600; return 0; end
			end
	
			-- Check: Keep the Corruption DoT up (15 s duration)
			if (not targetObj:HasDebuff("Corruption") and targetHealth > 20) then
				if (Cast('Corruption', targetObj)) then self.waitTimer = GetTimeEX() + 1600 + self.corruptionCastTime; return 0; end
			end
	
			-- Check: Keep the Immolate DoT up (15 s duration)
			if (not targetObj:HasDebuff("Immolate") and targetHealth > 20) then
				if (Cast('Immolate', targetObj)) then self.waitTimer = GetTimeEX() + 2500; return 0; end
			end
	
			-- Cast: Life Tap if conditions are right, see the function
			if (script_warlock:lifeTap(localHealth, localMana)) then return 0; end

			-- Cast: Drain Life, don't use Drain Life we need a soul shard
			if (HasSpell("Drain Life") and HasItem("Soul Shard") and targetObj:GetCreatureType() ~= "Mechanic") then
				if (targetObj:GetDistance() < 20) then
					if (IsMoving()) then StopMoving(); return; end
					if (Cast('Drain Life', targetObj)) then return; end
				else
					script_nav:moveToTarget(localObj, targetObj:GetPosition()); 
					self.waitTimer = GetTimeEX() + 2000;
					return 0;
				end
			else	
				-- Cast: Shadow Bolt
				if (Cast('Shadow Bolt', targetObj)) then return 0; end
			end
		end
	end
end

function script_warlock:lifeTap(localHealth, localMana)
	if (localMana < localHealth and HasSpell("Life Tap") and localHealth > 50 and localMana < 90 and not IsMounted()) then
		if(IsSpellOnCD("Life Tap")) then 
			return false; 
		else 
			CastSpellByName("Life Tap"); 
			return true; 
		end
	end
end


function script_warlock:rest()

	if(not self.isSetup) then
		script_warlock:setup();
	end

	local localObj = GetLocalPlayer();
	local localMana = localObj:GetManaPercentage();
	local localHealth = localObj:GetHealthPercentage();
	local hasPet = false; if(GetPet() ~= 0) then hasPet = true; end

	if(localMana < self.drinkMana or localHealth < self.eatHealth) then
		if (IsMoving()) then
			StopMoving();
			return true;
		end	
	end

	-- Cast: Life Tap if conditions are right, see the function
	if (not IsDrinking() and not IsEating()) then
		if (script_warlock:lifeTap(localHealth, localMana)) then return true; end
	end

	-- Eat and Drink
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

	if((localMana < 98 and IsDrinking()) or (localHealth < 98 and IsEating())) then
		self.message = "Resting to full hp/mana...";
		return true;
	end

	-- Check: If the pet is an Imp, require Firebolt to be in slot 4
	local petIsImp = false;
	if (hasPet) then
		name, __, __, __, __, __, __ = GetPetActionInfo(4);
		if (name == "Firebolt") then petIsImp = true; end
	end
	
	-- Check: Summon our Demon if we are not in combat (Voidwalker is Summoned in favor of the Imp)
	if (not IsEating() and not IsDrinking()) then	
		if ((not hasPet or petIsImp) and HasSpell("Summon Voidwalker") and HasItem('Soul Shard') and self.useVoid) then
			if (not IsStanding() or IsMoving()) then StopMoving(); end
			if (localMana > 40) then CastSpellByName("Summon Voidwalker"); return true; end
		elseif (not hasPet and HasSpell("Summon Imp") and self.useImp) then
			if (not IsStanding() or IsMoving()) then StopMoving(); end
			if (localMana > 30) then
				CastSpellByName("Summon Imp"); return true; 
			end
		end
	end

	--Create Healthstone
	local stoneIndex = -1;
	for i=0,self.numStone do
		if (HasItem(self.healthStone[i])) then
			stoneIndex= i;
			break;
		end
	end
	if (stoneIndex == -1 and HasItem("Soul Shard")) then 
		if (localMana > 10 and not IsDrinking() and not IsEating() and not AreBagsFull()) then
			self.message = "Creating a healthstone...";
			if (HasSpell('Create Healthstone') and IsMoving()) then
				StopMoving();
				return true;
			end
			if (HasSpell('Create Healthstone') and CastSpellByName('Create Healthstone')) then
				return true;
			end
		end
	end

	-- Do buffs if we got some mana 
	if (localMana > 30) then
		if(HasSpell("Demon Armor")) then
			if (not localObj:HasBuff("Demon Armor")) then
				if (not Buff("Demon Armor", localObj)) then
					return false;
				else
					self.message = "Buffing...";
					return true;
				end
			end
		elseif (not localObj:HasBuff('Demon Skin') and HasSpell('Demon Skin')) then
			if (not Buff('Demon Skin', localObj)) then
				return false;
			else
				self.message = "Buffing...";
				return true;
			end
		end
		if (HasSpell("Unending Breath")) then
			if (not localObj:HasBuff('Unending Breath')) then
				if (not Buff('Unending Breath', localObj)) then
					return false;
				else
					self.message = "Buffing...";
					return true;
				end
			end
		end
	end

	-- Check: Health funnel on the pet or wait for it to regen if lower than 70%
	local petHP = 0;
	if (GetPet() ~= 0) then
		petHP = GetPet():GetHealthPercentage();
	end
	if (hasPet and petHP > 0) then
		if (petHP < 70) then
			if (GetPet():GetDistance() > 8) then
				PetFollow();
				self.waitTimer = GetTimeEX() + 1850; 
				return true;
			end
			if (GetPet():GetDistance() < 20 and localMana > 10) then
				if (hasPet and petHP < 70 and petHP > 0) then
					self.message = "Pet has lower than 70% HP, using health funnel...";
					if (IsMoving() or not IsStanding()) then StopMoving(); return true; end
					if (HasSpell('Health Funnel')) then CastSpellByName('Health Funnel'); end
					self.waitTimer = GetTimeEX() + 1850; 
					return true;
				end
			end
		end
	end

	-- No rest / buff needed
	return false;
end

function script_warlock:mount()

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

function script_warlock:window()

	if (self.isChecked) then
	
		--Close existing Window
		EndWindow();

		if(NewWindow("Class Combat Options", 200, 200)) then
			script_warlock:menu();
		end
	end
end

function script_warlock:menu()
	if (CollapsingHeader("[Warlock - Shadowmaster")) then
		local wasClicked = false;
		wasClicked, self.useImp = Checkbox("Use Imp", self.useImp);
		wasClicked, self.useVoid = Checkbox("Use Voidwalker over Imp", self.useVoid);
		Text('Drink below mana percentage');
		self.drinkMana = SliderFloat("M%", 1, 100, self.drinkMana);
		Text('Eat below health percentage');
		self.eatHealth = SliderFloat("H%", 1, 100, self.eatHealth);
		Text('Use health potions below percentage');
		self.potionHealth = SliderFloat("HP%", 1, 99, self.potionHealth);
		Text('Use mana potions below percentage');
		self.potionMana = SliderFloat("MP%", 1, 99, self.potionMana);
		Separator();
		Text('Skills options:');
		wasClicked, self.useWand = Checkbox("Use Wand", self.useWand);
		wasClicked, self.fearAdds = Checkbox("Fear Adds", self.fearAdds);
		Text("Corruption cast time (ms)");	
		self.corruptionCastTime = SliderFloat("CCT (ms)", 0, 2000, self.corruptionCastTime);
	end
end
