script_helper = {
	water = {},
	numWater = 0,
	food = {},
	numFood = 0,
	myMounts = {},
	numMounts = 0,
	healthPotion = {},
	manaPotion = {},
	numHealthPotion = 0,
	numManaPotion = 0
}

function script_helper:enemiesAttackingUs(range) -- returns number of enemies attacking us within range
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

function script_helper:addHealthPotion(name)

	self.healthPotion[self.numHealthPotion] = name;
	self.numHealthPotion = self.numHealthPotion + 1;

end

function script_helper:addManaPotion(name)

	self.manaPotion[self.numManaPotion] = name;
	self.numManaPotion = self.numManaPotion + 1;

end

function script_helper:useHealthPotion()

	-- Search for potion
	local potionIndex = -1;
	for i=0,self.numHealthPotion do
		if (HasItem(self.healthPotion[i])) then
			potionIndex = i;
			break;
		end
	end
		
	if(HasItem(self.healthPotion[potionIndex])) then
		if (UseItem(self.healthPotion[potionIndex])) then
			return true;
		end
	end
end

function script_helper:useManaPotion()

	-- Search for potion
	local potionIndex = -1;
	for i=0,self.numManaPotion do
		if (HasItem(self.manaPotion[i])) then
			potionIndex = i;
			break;
		end
	end
		
	if(HasItem(self.manaPotion[potionIndex])) then
		if (UseItem(self.manaPotion[potionIndex])) then
			return true;
		end
	end
end

function script_helper:addWater(name)
	self.water[self.numWater] = name;
	self.numWater = self.numWater + 1;
end

function script_helper:addFood(name)
	self.food[self.numFood] = name;
	self.numFood = self.numFood + 1;
end

function script_helper:addMount(name)
	self.myMounts[self.numMounts] = name;
	self.numMounts = self.numMounts + 1;
end

function script_helper:setup()
	-- Add Health Potions
	script_helper:addHealthPotion("Minor Healing Potion");
	script_helper:addHealthPotion("Lesser Healing Potion");
	script_helper:addHealthPotion("Healing Potion");
	script_helper:addHealthPotion("Superior Healing Potion");
	script_helper:addHealthPotion("Major Healing Potion");

	-- Add Mana Potions
	script_helper:addManaPotion("Minor Mana Potion");
	script_helper:addManaPotion("Lesser Mana Potion");
	script_helper:addManaPotion("Mana Potion");
	script_helper:addManaPotion("Superior Mana Potion");
	script_helper:addManaPotion("Major Mana Potion");

	-- Vendor water
	script_helper:addWater('Morning Glory Dew');
	script_helper:addWater('Moonberry Juice');
	script_helper:addWater('Sweet Nectar');
	script_helper:addWater('Melon Juice');
	script_helper:addWater('Ice Cold Milk');
	script_helper:addWater('Refreshing Spring Water');

	-- Mage water
	script_helper:addWater('Conjured Crystal Water');
	script_helper:addWater('Conjured Sparkling Water');
	script_helper:addWater('Conjured Mineral Water');
	script_helper:addWater('Conjured Spring Water');
	script_helper:addWater('Conjured Purified Water');
	script_helper:addWater('Conjured Fresh Water');
	script_helper:addWater('Conjured Water');

	-- Vendor mushroom food
	script_helper:addFood('Dried King Bolete');	
	script_helper:addFood('Raw Black Truffle');	
	script_helper:addFood('Delicious Cave Mold');	
	script_helper:addFood('Spongy Morel');
	script_helper:addFood("Red-speckled Mushroom");
	script_helper:addFood('Forest Mushroom Cap');

	-- Vendor fruit food
	script_helper:addFood('Deep Fried Plantains');
	script_helper:addFood('Moon Harvest Pumpkin');
	script_helper:addFood('Goldenbark Apple');
	script_helper:addFood('Snapvine Watermelon');
	script_helper:addFood("Tel'Abim Banana");
	script_helper:addFood('Shiny Red Apple');

	-- Vendor baked food
	script_helper:addFood('Tough Hunk of Bread');
	script_helper:addFood('Freshly Baked Bread');
	script_helper:addFood('Moist Cornbread');
	script_helper:addFood('Mulgore Spice Bread');
	script_helper:addFood('Soft Banana Bread');
	script_helper:addFood('Homemade Cherry Pie');
	
	-- Vendor meat food
	script_helper:addFood('Cured Ham Steak');
	script_helper:addFood('Haunch of Meat');
	script_helper:addFood('Mutton Chop');
	script_helper:addFood('Roasted Quail');
	script_helper:addFood('Tough Jerky');
	script_helper:addFood('Wild Hog Shank');
	
	-- Vendor cheese
	script_helper:addFood('Alterac Swiss');
	script_helper:addFood('Fine Aged Cheddar');
	script_helper:addFood('Stormwind Brie');
	script_helper:addFood('Dwarven Mild');
	script_helper:addFood('Dalaran Sharp');
	script_helper:addFood('Darnassian Bleu');
	
	-- Vendor fish food
	script_helper:addFood('Spinefin Halibut');
	script_helper:addFood('Striped Yellowtail');
	script_helper:addFood('Rockscale Cod');
	script_helper:addFood('Bristle Whisker Catfish');
	script_helper:addFood('Slitherskin Mackerel');
	script_helper:addFood('Longjaw Mud Snapper');

	-- Mage food
	script_helper:addFood('Conjured Cinnamon Roll');
	script_helper:addFood('Conjured Sweet Roll');
	script_helper:addFood('Conjured Sourdough')
	script_helper:addFood('Conjured Pumpernickel');
	script_helper:addFood('Conjured Rye');
	script_helper:addFood('Conjured Bread');
	script_helper:addFood('Conjured Muffin');

	-- Epic mounts
	script_helper:addMount("Deathcharger's Reins");
	script_helper:addMount('Black War Kodo');
	script_helper:addMount('Black War Ram');
	script_helper:addMount('Black War Steed Bridle');
	script_helper:addMount('Great Brown Kodo');
	script_helper:addMount('Great Gray Kodo');
	script_helper:addMount('Great White Kodo');
	script_helper:addMount('Green Kodo');
	script_helper:addMount('Horn of the Black War Wolf');
	script_helper:addMount('Horn of the Frostwolf Howler');
	script_helper:addMount('Horn of the Swift Brown Wolf');
	script_helper:addMount('Horn of the Swift Gray Wolf');
	script_helper:addMount('Horn of the Swift Timber Wolf');
	script_helper:addMount('Red Skeletal Warhorse');
	script_helper:addMount('Reins of the Black War Tiger');
	script_helper:addMount('Stormspike Battle Charger');
	script_helper:addMount('Swift Blue Raptor');
	script_helper:addMount('Swift Brown Ram');
	script_helper:addMount('Swift Brown Steed');
	script_helper:addMount('Swift Gray Ram');
	script_helper:addMount('Swift Green Mechanostrider');
	script_helper:addMount('Swift Olive Raptor');
	script_helper:addMount('Swift Orange Raptor');
	script_helper:addMount('Swift Palomino');
	script_helper:addMount('Swift Razzashi Raptor');
	script_helper:addMount('Swift White Mechanostrider');
	script_helper:addMount('Swift White Ram');
	script_helper:addMount('Swift White Steed');
	script_helper:addMount('Swift Yellow Mechanostrider');
	script_helper:addMount('Swift Zulian Tiger');
	script_helper:addMount('Teal Kodo');
	script_helper:addMount("The Phylactery of Kel'Thuzad");
	script_helper:addMount('Warlords Deck');
	script_helper:addMount('Whistle of the Black War Raptor');
	script_helper:addMount('Whistle of the Ivory Raptor');
	script_helper:addMount('Whistle of the Mottled Red Raptor');

	-- Level 40 mounts
	script_helper:addMount('Black Stallion Bridle');
	script_helper:addMount('Blue Mechanostrider');
	script_helper:addMount('Blue Skeletal Horse');
	script_helper:addMount('Brown Horse Bridle');
	script_helper:addMount('Brown Kodo');
	script_helper:addMount('Brown Ram');
	script_helper:addMount('Brown Skeletal Horse');
	script_helper:addMount('Chestnut Mare Bridle');
	script_helper:addMount('Gray Kodo');
	script_helper:addMount('Gray Ram');
	script_helper:addMount('Green Mechanostrider');
	script_helper:addMount('Horn of the Brown Wolf');
	script_helper:addMount('Horn of the Dire Wolf');
	script_helper:addMount('Horn of the Timber Wolf');
	script_helper:addMount('Pinto Bridle');
	script_helper:addMount('Red Mechanostrider');
	script_helper:addMount('Red Skeletal Horse');
	script_helper:addMount('Unpainted Mechanostrider');
	script_helper:addMount('Whistle of the Emerald Raptor');
	script_helper:addMount('Whistle of the Turquoise Raptor');
	script_helper:addMount('Whistle of the Violet Raptor');
	script_helper:addMount('White Ram');
	script_helper:addMount('Reins of the Spotted Frostsaber');
	script_helper:addMount('Reins of the Striped Frostsaber');
	script_helper:addMount('Reins of the Striped Nightsaber');

	DEFAULT_CHAT_FRAME:AddMessage('script_helper: loaded...');
end

function script_helper:eat()
	for i=0,self.numFood do
		if (HasItem(self.food[i])) then
			if (UseItem(self.food[i])) then
				return true;
			end
		end
	end
	return false;
end

function script_helper:drinkWater()
	for i=0,self.numWater do
		if (HasItem(self.water[i])) then
			if (UseItem(self.water[i])) then
				return true;
			end
		end
	end
	return false;
end

function script_helper:useMount()
	if (HasSpell("Summon Dreadsteed")) then
		CastSpellByName("Summon Dreadsteed");
		return true;
	end
	
	if (HasSpell("Summon Felsteed")) then
		CastSpellByName("Summon Felsteed");
		return true;
	end

	if (HasSpell("Summon Charger")) then
		CastSpellByName("Summon Charger");
		return true;
	end

	if (HasSpell("Summon Warhorse")) then
		CastSpellByName("Summon Warhorse");
		return true;
	end
	
	for i=0,self.numMounts do
		if (HasItem(self.myMounts[i])) then
			if (UseItem(self.myMounts[i])) then
				return true;
			end
		end
	end
	return false;
end
