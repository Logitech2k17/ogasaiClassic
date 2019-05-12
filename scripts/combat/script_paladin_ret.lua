script_paladin = {
	message = 'Paladin - Retribution Combat Script',
	bopHealth = 20,
	lohHealth = 8,
	consecrationMana = 50,
	eatHealth = 60,
	drinkMana = 60,
	healHealth = 40,
	potionHealth = 12,
	potionMana = 20,
	isSetup = false,
	meeleDistance = 3.5,
	waitTimer = 0,
	stopIfMHBroken = true,
	aura = 0,
	blessing = 0,
	isChecked = true
}

function script_paladin:setup()
	-- Sort Aura  
	if (not HasSpell('Retribution Aura') and not HasSpell('Sanctity Aura')) then
		self.aura = 'Devotion Aura';	
	elseif (not HasSpell('Sanctity Aura') and HasSpell('Retribution Aura')) then
		self.aura = 'Retribution Aura';
	elseif (HasSpell('Sanctity Aura')) then
		self.aura = 'Sanctity Aura';	
	end

	-- Sort Blessing  
	if (HasSpell('Blessing of Wisdom')) then
		self.blessing = 'Blessing of Wisdom';
	elseif (HasSpell("Blessing of Might")) then
		self.blessing = 'Blessing of Might';
	end
	
	self.waitTimer = GetTimeEX();

	self.isSetup = true;

end

function script_paladin:spellAttack(spellName, target)
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

function script_paladin:enemiesAttackingUs(range) -- returns number of enemies attacking us within range
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
function script_paladin:runBackwards(targetObj, range) 
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

function script_paladin:draw()
	--script_paladin:window();
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

function script_paladin:run(targetGUID)
	
	if(not self.isSetup) then
		script_paladin:setup();
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

			-- Dismount
			if (IsMounted() and targetObj:GetDistance() < 25) then DisMount(); return 0; end

			-- Check: Exorcism
			if (targetObj:GetCreatureType() == "Demon" or targetObj:GetCreatureType() == "Undead") then
				if (targetObj:GetDistance() < 30 and HasSpell('Exorcism') and not IsSpellOnCD('Exorcism')) then
					if (Cast('Exorcism', targetObj)) then 
						self.message = "Pulling with Exocism...";
						return 0;
					end
				end
			end

			-- Check: Seal of the Crusader until we used judgement
			if (not targetObj:HasDebuff("Judgement of the Crusader") and targetObj:GetDistance() < 15
				and not localObj:HasBuff("Seal of the Crusader")) then
				if (Buff('Seal of the Crusader', localObj)) then return 3; end
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
				if (script_paladin:runBackwards(targetObj,3)) then 
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

			-- Check: Use Lay of Hands
			if (localHealth < self.lohHealth and HasSpell('Lay on Hands') and not IsSpellOnCD('Lay on Hands')) then 
				if (Cast('Lay on Hands', localObj)) then 
					self.message = "Cast Lay on Hands...";
					return 0;
				end
			end
		
			-- Buff with Blessing
			if (self.blessing ~= 0 and HasSpell(self.blessing)) then
				if (localMana > 10 and not localObj:HasBuff(self.blessing)) then
					Buff(self.blessing, localObj);
					return 0;
				end
			end
			
			-- Check: Divine Protection if BoP on CD
			if(localHealth < self.bopHealth and not localObj:HasDebuff('Forbearance')) then
				if (HasSpell('Divine Shield') and not IsSpellOnCD('Divine Shield')) then
					CastSpellByName('Divine Shield');
					self.message = "Cast Divine Shield...";
					return 0;
				elseif (HasSpell('Divine Protection') and not IsSpellOnCD('Divine Protection')) then
					CastSpellByName('Divine Protection');
					self.message = "Cast Divine Protection...";
					return 0;
				elseif (HasSpell('Blessing of Protection') and not IsSpellOnCD('Blessing of Protection')) then
					CastSpellByName('Blessing of Protection');
					self.message = "Cast Blessing of Protection...";
					return 0;
				end
			end

			-- Check: Heal ourselves if below heal health or we are immune to physical damage
			if (localHealth < self.healHealth or 
				((localObj:HasBuff('Blessing of Protection') or localObj:HasBuff('Divine Protection')) and localHealth < 90) ) then 
				-- Check: If we have multiple targets attacking us, use BoP before healing
				if(script_paladin:enemiesAttackingUs(5) > 2 and HasSpell('Blessing of Protection') 
					and not IsSpellOnCD('Blessing of Protection') and not localObj:HasDebuff('Forbearance')) then
					if (Buff('Blessing of Protection', localObj)) then 
						self.message = "Cast Blessing of Protection...";
						return 0;
					end
				end

				-- Check: If we have multiple targets attacking us, use Divine Shield before healing
				if(script_paladin:enemiesAttackingUs(5) > 2 and HasSpell('Divine Shield') and not localObj:HasDebuff('Forbearance')
					and not IsSpellOnCD('Divine Shield')) then
					CastSpellByName('Divine Shield');
					self.message = "Cast Divine Shield...";
					return 0;
				end

				-- Check: If we have multiple targets attacking us, use Divine Protection before healing
				if(script_paladin:enemiesAttackingUs(5) > 2 and HasSpell('Divine Protection') and not localObj:HasDebuff('Forbearance')
					and not IsSpellOnCD('Divine Protection')) then
					CastSpellByName('Divine Protection');
					self.message = "Cast Divine Protection...";
					return 0;
				end

				-- Check: Stun with HoJ before healing if available
				if (targetObj:GetDistance() < 5 and HasSpell('Hammer of Justice') and not IsSpellOnCD('Hammer of Justice')) then
					if (Cast('Hammer of Justice', targetObj)) then self.waitTimer = GetTimeEX() + 1750; return 0; end
				end
				
				if (Buff('Holy Light', localObj)) then 
					self.waitTimer = GetTimeEX() + 5000;
					self.message = "Healing: Holy Light...";
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

			-- Check: Remove desease or poison
			if (localObj:HasDebuff('Rabies') or localObj:HasDebuff('Poison') or localObj:HasDebuff('Fevered Fatigue')
				or localObj:HasDebuff('Dark Sludge') or localObj:HasDebuff('Corrosive Poison') or localObj:HasDebuff('Slowing Poison')) then
				if(HasSpell('Cleanse')) then
					if (Buff('Cleanse', localObj)) then 
						self.message = 'Cleansing...'; 
						self.waitTimer = GetTimeEX() + 1750; 
						return 0; 
					end
				end
				if(HasSpell('Purify')) then
					if (Buff('Purify', localObj)) then 
						self.message = 'Purifying...'; 
						self.waitTimer = GetTimeEX() + 1750; 
						return 0; 
					end
				end
			end

			-- Check: Remove movement disables with Freedom
			if (localObj:IsMovementDisabed() and HasSpell('Blessing of Freedom')) then
				Buff('Blessing of Freedom', localObj);
				return 0;
			end

			-- Check: Exorcism
			if (targetObj:GetCreatureType() == "Demon" or targetObj:GetCreatureType() == "Undead") then
				if (targetObj:GetDistance() < 30 and HasSpell('Exorcism') and not IsSpellOnCD('Exorcism')) then
					if (Cast('Exorcism', targetObj)) then 
						return 0;
					end
				end
			end

			-- Check: If we are in meele range, do meele attacks
			if (targetObj:GetDistance() < self.meeleDistance) then

				if (targetObj:IsCasting() and targetObj:IsFleeing() and HasSpell('Hammer of Justice') and not IsSpellOnCD('Hammer of Justice')) then
					if (Cast('Hammer of Justice', targetObj)) then self.waitTimer = GetTimeEX() + 2000; return 0; end
				end

				-- Combo Check 1: Stun the target if we have HoJ and SoC
				if (HasSpell('Hammer of Justice') and not IsSpellOnCD('Hammer of Justice') and targetHealth > 50 and targetObj:HasDebuff("Judgement of the Crusader")
					and localObj:HasBuff('Seal of Command') and localMana > 50 and not IsSpellOnCD('Judgement')) then
					if (Cast('Hammer of Justice', targetObj)) then self.waitTimer = GetTimeEX() + 1750; return 0; end
				end
		
				-- Combo Check 2: Use Judgement on the stunned target
				if (targetObj:HasDebuff('Hammer of Justice') and localObj:HasBuff('Seal of Command') and targetObj:GetDistance() < 10) then
					if (Cast('Judgement', targetObj)) then self.waitTimer = GetTimeEX() + 2000; return 0; end
				end

				-- Check: Seal of the Crusader until we used judgement
				if (not targetObj:HasDebuff("Judgement of the Crusader") and targetHealth > 20
					and not localObj:HasBuff("Seal of the Crusader")) then
					if (Buff('Seal of the Crusader', localObj)) then self.waitTimer = GetTimeEX() + 2000; return 0; end
				end 

				-- Check: Judgement when we have crusader
				if (targetObj:GetDistance() < 10 and not targetObj:HasDebuff("Judgement of the Crusader") and
					not IsSpellOnCD('Judgement') and HasSpell('Judgement') and localObj:HasBuff("Seal of the Crusader")) then
						if (Cast('Judgement', targetObj)) then self.waitTimer = GetTimeEX() + 2000; return 0; end 
				end

				-- Check: Seal of Righteousness (before we have SoC)
				if (not localObj:HasBuff("Seal of Righteousness") and not localObj:HasBuff("Seal of the Crusader") and not HasSpell('Seal of Command')) then 
					if (Buff('Seal of Righteousness', localObj)) then self.waitTimer = GetTimeEX() + 2000; return 0; end
				end

				-- Check: Judgement with Righteousness or Command if we have a lot of mana
				if ((localObj:HasBuff("Seal of Righteousness") or localObj:HasBuff("Seal of Command"))
					 and not IsSpellOnCD('Judgement') and localMana > 80) then 
					if (Cast('Judgement', targetObj)) then self.waitTimer = GetTimeEX() + 2000; return 0; end 
				end

				-- Check: Use judgement if we are buffed with Righteousness or Command and the target is low
				if ((localObj:HasBuff('Seal of Righteousness') or localObj:HasBuff('Seal of Command'))
					and targetObj:GetDistance() < 10 and targetHealth < 10) then
					if (Cast('Judgement', targetObj)) then self.waitTimer = GetTimeEX() + 2000; return 0; end
				end

				-- Check: Seal of Command
				if (not localObj:HasBuff("Seal of Command") and not localObj:HasBuff("Seal of the Crusader")) then 
					if (Buff('Seal of Command', localObj)) then self.waitTimer = GetTimeEX() + 2000; return 0; end
				end

				-- Consecration when we have adds
				if (script_grind:enemiesAttackingUs() >= 2 and localMana > self.consecrationMana and targetHealth > 25 and HasSpell('Consecration') 
					and not IsSpellOnCD('Consecration') and targetObj:HasDebuff("Judgement of the Crusader")) then
					CastSpellByName('Consecration'); self.waitTimer = GetTimeEX() + 2000; return 0;	
				end 

				-- Always face the target
				targetObj:FaceTarget(); 
				return 0; 
			end
			return 0;
		end
	end
end

function script_paladin:rest()
	if(not self.isSetup) then
		script_paladin:setup();
	end

	local localObj = GetLocalPlayer();
	local localLevel = localObj:GetLevel();
	local localHealth = localObj:GetHealthPercentage();
	local localMana = localObj:GetManaPercentage();

	-- Buff with Blessing
	if (self.blessing ~= 0 and HasSpell(self.blessing) and not IsMounted()) then
		if (localMana > 10 and not localObj:HasBuff(self.blessing)) then
			Buff(self.blessing, localObj);
			return false;
		end
	end

	-- Stop moving before we can rest
	if(localHealth < self.eatHealth or localMana < self.drinkMana) then
		if (IsMoving()) then
			StopMoving();
			return true;
		end
	end

	-- Heal up: Holy Light
	if (localMana > 20 and localHealth < self.eatHealth) then
		if (Buff('Holy Light', localObj)) then
			script_grind:setWaitTimer(5000);
			self.message = "Healing: Holy Light...";
		end
		return true;
	end

	-- Heal up: Flash of Light
	if (localMana > 10 and localHealth < 90 and HasSpell('Flash of Light')) then
		if (Buff('Flash of Light', localObj)) then
			script_grind:setWaitTimer(2500);
			self.message = "Healing: Flash of Light...";
		end
		return true;
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
	
	-- Set aura
	if (self.aura ~= 0 and not IsMounted()) then
		if (not localObj:HasBuff(self.aura) and HasSpell(self.aura)) then
			CastSpellByName(self.aura); 
		end
	end

	-- Don't need to rest
	return false;
end

function script_paladin:mount()
	return false;
end

function script_paladin:window()

	if (self.isChecked) then
	
		--Close existing Window
		EndWindow();

		if(NewWindow("Class Combat Options", 200, 200)) then
			script_paladin:menu();
		end
	end
end

function script_paladin:menu()
	if (CollapsingHeader("[Paladin - Retribution")) then
		local wasClicked = false;
		Text('Aura and Blessing options:');
		self.aura = InputText("Aura", self.aura);
		self.blessing = InputText("Blessing", self.blessing);
		Separator();
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
		self.lohHealth = SliderFloat("Lay on Hands below HP%", 1, 99, self.lohHealth);
		self.bopHealth = SliderFloat("BoP below HP%", 1, 99, self.bopHealth);
		self.consecrationMana = SliderFloat("Consecration above Mana%", 1, 99, self.consecrationMana);
	end
end
