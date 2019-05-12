script_talent = {
	talentTimer = 0;
	currentTalentPoint = 0;
	palaTalents = {},
	warTalents = {},
	rogueTalents = {},
	druidTalents = {},		
	priestTalents = {},
	mageTalents = {},
	hunterTalents = {},
	lockTalents = {},
	shamTalents = {},
	currentTalentTable = {},
	isSetup = false
}

function script_talent:setup()
	if (not self.isSetup) then

		-- Paladin ret talent points in order 1-31, (3; = ret tab, 1; would be holy tab etc)
		self.palaTalents = { 
			"3;Benediction", "3;Benediction", "3;Benediction", "3;Benediction", "3;Benediction",
			"3;Improved Judgement", "3;Improved Judgement",
			"3;Deflection", "3;Deflection", "3;Deflection",
			"3;Seal of Command",
			"3;Conviction", "3;Conviction", "3;Conviction", "3;Conviction", "3;Conviction",
			"3;Vindication", "3;Vindication", "3;Vindication",
			"3;Deflection",
			"3;Sanctity Aura",
			"3;Two-Handed Weapon Specialization", "3;Two-Handed Weapon Specialization", "3;Two-Handed Weapon Specialization",
			"3;Deflection",
			"3;Vengeance", "3;Vengeance", "3;Vengeance", "3;Vengeance", "3;Vengeance"
		}

		-- Warrior fury talent points in order 1-31
		self.warTalents = {
			"2;Cruelty", "2;Cruelty", "2;Cruelty", "2;Cruelty", "2;Cruelty",
			"2;Unbridled Wrath", "2;Unbridled Wrath", "2;Unbridled Wrath", "2;Unbridled Wrath", "2;Unbridled Wrath",
			"2;Blood Craze", "2;Blood Craze", "2;Blood Craze",
			"2;Improved Battle Shout", "2;Improved Battle Shout",
			"2;Enrage", "2;Enrage", "2;Enrage", "2;Enrage", "2;Enrage",
			"2;Dual Wield Specialization", "2;Dual Wield Specialization", "2;Dual Wield Specialization", "2;Dual Wield Specialization",
			"2;Death Wish",
			"2;Flurry",  "2;Flurry", "2;Flurry", "2;Flurry", "2;Flurry",
			"2;Bloodthirst"
		}

		-- Rogue combat talent points in order 1-31
		self.rogueTalents = {
			"2;Improved Sinister Strike", "2;Improved Sinister Strike",
			"2;Lightning Reflexes", "2;Lightning Reflexes", "2;Lightning Reflexes",
			"2;Precision", "2;Precision", "2;Precision", "2;Precision", "2;Precision", 
			"2;Deflection", "2;Deflection", "2;Deflection", "2;Deflection", "2;Deflection",
			"2;Riposte",
			"2;Dual Wield Specialization", "2;Dual Wield Specialization", "2;Dual Wield Specialization", "2;Dual Wield Specialization",
			"2;Blade Flurry",
			"2;Sword Specialization", "2;Sword Specialization", "2;Sword Specialization", "2;Sword Specialization",
			"2;Weapon Expertise", "2;Weapon Expertise",
			"2;Aggression", "2;Aggression", "2;Aggression", 
			"2;Adrenaline Rush"
		}

		-- Druid feral talent points in order 1-31
		self.druidTalents = {
			"2;Ferocity", "2;Ferocity", "2;Ferocity", "2;Ferocity", "2;Ferocity",
			"2;Feral Aggression", "2;Feral Aggression", "2;Feral Aggression", "2;Feral Aggression", "2;Feral Aggression", 
			"2;Feline Swiftness", "2;Feline Swiftness",
			"2;Sharpened Claws", "2;Sharpened Claws", "2;Sharpened Claws",
			"2;Blood Frenzy", "2;Blood Frenzy",
			"2;Predatory Strikes", "2;Predatory Strikes", "2;Predatory Strikes",
			"2;Faerie Fire (Feral)",
			"2;Savage Fury", "2;Savage Fury",
			"2;Heart of the Wild", "2;Heart of the Wild", "2;Heart of the Wild", "2;Heart of the Wild", "2;Heart of the Wild",
			"2;Leader of the Pack"
		}
		
		-- Priest shadow talent points in order 1-31
		self.priestTalents = {
			"3;Blackout", "3;Blackout", "3;Blackout", "3;Blackout", "3;Blackout", 
			"3;Improved Shadow Word: Pain", "3;Improved Shadow Word: Pain", 
			"3;Shadow Focus", "3;Shadow Focus", "3;Shadow Focus", 
			"3;Mind Flay",
			"3;Improved Mind Blast", "3;Improved Mind Blast", "3;Improved Mind Blast", "3;Improved Mind Blast", 
			"3;Shadow Weaving", "3;Shadow Weaving", "3;Shadow Weaving", "3;Shadow Weaving", "3;Shadow Weaving", 
			"3;Vampiric Embrace",
			"3;Improved Vampiric Embrace", "3;Improved Vampiric Embrace", 
			"3;Shadow Focus", "3;Shadow Focus", 
			"3;Darkness", "3;Darkness", "3;Darkness", "3;Darkness", "3;Darkness", 
			"3;Shadowform"
		}
		
		-- Mage frost talent points in order 1-31
		self.mageTalents = {
			"3;Elemental Precision", "3;Elemental Precision", "3;Elemental Precision",
			"3;Improved Frostbolt", "3;Improved Frostbolt",
			"3;Frostbite", "3;Frostbite", "3;Frostbite",
			"3;Improved Frost Nova", "3;Improved Frost Nova", 
			"3;Ice Shards", "3;Ice Shards", "3;Ice Shards", "3;Ice Shards", "3;Ice Shards", 
			"3;Shatter", "3;Shatter", "3;Shatter", "3;Shatter", "3;Shatter", 
			"3;Cold Snap",
			"3;Ice Block",
			"3;Piercing Ice", "3;Piercing Ice", "3;Piercing Ice",
			"3;Winter's Chill", "3;Winter's Chill", "3;Winter's Chill", "3;Winter's Chill", "3;Winter's Chill", 
			"3;Ice Barrier"
		}
		
		-- Hunter beastmaster talent points in order 1-31
		self.hunterTalents = {
			"1;Endurance Training", "1;Endurance Training", "1;Endurance Training", "1;Endurance Training", "1;Endurance Training",
			"1;Thick Hide", "1;Thick Hide", "1;Thick Hide",
			"1;Improved Revive Pet", "1;Improved Revive Pet",
			"1;Bestial Swiftness",
			"1;Unleashed Fury", "1;Unleashed Fury", "1;Unleashed Fury", "1;Unleashed Fury",
			"1;Ferocity", "1;Ferocity", "1;Ferocity", "1;Ferocity", "1;Ferocity",
			"1;Intimidation",
			"1;Spirit Bond", "1;Spirit Bond",
			"1;Bestial Discipline", "1;Bestial Discipline",
			"1;Frenzy", "1;Frenzy", "1;Frenzy", "1;Frenzy", "1;Frenzy",
			"1;Bestial Wrath"
		}
		
		-- Warlock talent points 1-21 Affliction, 22-51 Demonology
		self.lockTalents = {
			"1;Improved Corruption", "1;Improved Corruption", "1;Improved Corruption", "1;Improved Corruption", "1;Improved Corruption",
			"1;Suppression", "1;Suppression", "1;Suppression", "1;Suppression", "1;Suppression",
			"1;Improved Curse of Agony", "1;Improved Curse of Agony", "1;Improved Curse of Agony",
			"1;Fel Concentration", "1;Fel Concentration",  
			"1;Nightfall", "1;Nightfall",
			"1;Improved Life Tap",
			"1;Fel Concentration", "1;Fel Concentration", "1;Fel Concentration", 
			"1;Siphon Life",
			"2;Demonic Embrace", "2;Demonic Embrace", "2;Demonic Embrace", "2;Demonic Embrace", "2;Demonic Embrace",
			"2;Improved Voidwalker", "2;Improved Voidwalker", "2;Improved Voidwalker", 
			"2;Improved Healthstone", "2;Improved Healthstone",
			"2;Fel Stamina", "2;Fel Stamina", "2;Fel Stamina", 
			"2;Improved Health Funnel", "2;Improved Health Funnel",
			"2;Unholy Power", "2;Unholy Power", "2;Unholy Power", "2;Unholy Power", "2;Unholy Power", 
			"2;Demonic Sacrifice",
			"2;Fel Intellect", "2;Fel Intellect", "2;Fel Intellect", 
			"2;Fel Domination",
			"2;Master Demonologist", "2;Master Demonologist", "2;Master Demonologist", "2;Master Demonologist", "2;Master Demonologist"		
		}

		-- Shaman Enhancement talent points in order 1-31
		self.shamTalents = {
			"2;Ancestral Knowledge", "2;Ancestral Knowledge", "2;Ancestral Knowledge", "2;Ancestral Knowledge", "2;Ancestral Knowledge", 
			"2;Thundering Strikes", "2;Thundering Strikes", "2;Thundering Strikes", "2;Thundering Strikes", "2;Thundering Strikes", 
			"2;Two-Handed Axes and Maces",
			"2;Improved Ghost Wolf", "2;Improved Ghost Wolf", 
			"2;Improved Lightning Shield", "2;Improved Lightning Shield",
			"2;Flurry", "2;Flurry", "2;Flurry", "2;Flurry", "2;Flurry", 
			"2;Elemental Weapons", "2;Elemental Weapons", "2;Elemental Weapons", 
			"2;Parry", 
			"2;Improved Lightning Shield",
			"2;Weapon Mastery", "2;Weapon Mastery", "2;Weapon Mastery", "2;Weapon Mastery", "2;Weapon Mastery", 
			"2;Stormstrike"
		}

		-- Set talent table depending on the class
		local class, _ = UnitClass("player");

		if (class == "Paladin") then
			self.currentTalentTable = self.palaTalents;
		elseif (class == "Warrior") then
			self.currentTalentTable = self.warTalents;
		elseif (class == "Rogue") then
			self.currentTalentTable = self.rogueTalents;
		elseif (class == "Druid") then
			self.currentTalentTable = self.druidTalents;
		elseif (class == "Priest") then
			self.currentTalentTable = self.priestTalents;
		elseif (class == "Mage") then
			self.currentTalentTable = self.mageTalents;
		elseif (class == "Hunter") then
			self.currentTalentTable = self.hunterTalents;
		elseif (class == "Warlock") then
			self.currentTalentTable = self.lockTalents;
		elseif (class == "Shaman") then
			self.currentTalentTable = self.shamTalents;
		end

	end

	self.currentTalentPoint = 1;

	self.talentTimer = GetTimeEX();	

	DEFAULT_CHAT_FRAME:AddMessage('script_talent: loaded...');
	self.isSetup = true;
end

function script_talent:learnTalents()

	local level = GetLocalPlayer():GetLevel();
	local lastTalentPointNr = (level-9);

	-- Do nothing if we are below level 10 
	if (level < 10) then
		return false;
	end

	-- Do nothing if we spent the talent points
	if (self.currentTalentPoint > lastTalentPointNr) then
		return false;
	end

	if (self.talentTimer < GetTimeEX()) then

		-- Spend talent points
		script_talent:learnClassTalents();

		self.talentTimer = GetTimeEX() + 250;

	end

	return true;
end

function script_talent:getMaxRank(talentName)
	local maxRank = 0;
	local currentTalent = {};

	for i = 1, 61 do

		if (self.currentTalentTable[self.currentTalentPoint] ~= nil) then
			
			if (self.currentTalentTable[i] ~= nil) then
				-- Split the talent-string into the talent tab number and the talent name
				currentTalent = script_talent:stringSplit(self.currentTalentTable[i]);

				if (talentName == currentTalent[2]) then
					maxRank = maxRank + 1;
				end
			end

		end
	end

	return maxRank;
end

function script_talent:learnTalent(tabIndex, talentName)
	
	local talentIndex = script_talent:getTalentIndex(tabIndex, talentName);
	
	if (talentIndex ~= 0) then
		LearnTalent(tabIndex, talentIndex);
	end

end

function script_talent:getTalentIndex(tabIndex, talentName)
	local numTalents = GetNumTalents(tabIndex, false, false);

	local talentIndex = 0;
	
	-- Fetch the talent index 
	for i = 1, numTalents do
		local name, _, _, _, rank, _, _, _, _, _ = GetTalentInfo(tabIndex, i, false, false);	

		-- Fetch the index with the talent name
		if (name == talentName) then
			-- Check if we should really add more ranks
			if (rank ~= nil) then
				if (rank < script_talent:getMaxRank(talentName)) then
					talentIndex = i;
				end
			else
				talentIndex = i;
			end
		end
	end

	return talentIndex;
end

function script_talent:getNextTalentName()
	local talentName = " ";
	
	if (self.currentTalentTable[self.currentTalentPoint] ~= nil) then

		-- Split the talent-string into the talent tab number and the talent name
		currentTalent = script_talent:stringSplit(self.currentTalentTable[self.currentTalentPoint]);

		talentName = currentTalent[2];
	end

	return talentName;
end

function script_talent:learnClassTalents()

	local currentTalent = nil;
	local tabIndex = nil;
	local talentName = nil;
	
	if (self.currentTalentTable[self.currentTalentPoint] ~= nil) then

		-- Split the talent-string into the talent tab number and the talent name
		currentTalent = script_talent:stringSplit(self.currentTalentTable[self.currentTalentPoint]);

		tabIndex = currentTalent[1];
		talentName = currentTalent[2];

	end

	if (tabIndex ~= nil and talentName ~= nil) then

		-- Learn the current talent
		script_talent:learnTalent(tabIndex, talentName);

	end

	-- Increase the talent number for next call
	self.currentTalentPoint = self.currentTalentPoint + 1;

end

function script_talent:stringSplit(str)

  	 if string.find(str, ";") == nil then
     		 return { str }
  	 end

	local result = {}
	local pat = "(.-)" .. ";" .. "()"
	local nb = 0
	local lastPos
	local maxNb = 2

	for part, pos in string.gfind(str, pat) do
		nb = nb + 1
		result[nb] = part
		lastPos = pos
		if nb == maxNb then
			break
		end
	end

	-- Handle the last field
	if nb ~= maxNb then
		result[nb + 1] = string.sub(str, lastPos)
	end

	return result
end
