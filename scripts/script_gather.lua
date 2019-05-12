script_gather = {
	isSetup = false,
	useVendor = false,
	useMount = true,
	nodeObj = nil,
	gatherDistance = 150,
	message = 'Gather...',
	collectMinerals = true,
	collectHerbs = true,
	herbs = {},
	numHerbs = 0,
	minerals = {},
	numMinerals = 0,
	lootDistance = 3,
	timer = 0,
	nodeID = 0,
	gatherAllPossible = true
}

function script_gather:addHerb(name, id, use, req)
	self.herbs[self.numHerbs] = {}
	self.herbs[self.numHerbs][0] = name;
	self.herbs[self.numHerbs][1] = id;
	self.herbs[self.numHerbs][2] = use;
	self.herbs[self.numHerbs][3] = req;
	self.numHerbs = self.numHerbs + 1;
end

function script_gather:addMineral(name, id, use, req)
	self.minerals[self.numMinerals] = {}
	self.minerals[self.numMinerals][0] = name;
	self.minerals[self.numMinerals][1] = id;
	self.minerals[self.numMinerals][2] = use;
	self.minerals[self.numMinerals][3] = req;
	self.numMinerals = self.numMinerals + 1;
end

function script_gather:setup()
	
	self.collectMinerals = HasSpell('Find Minerals');
	self.collectHerbs = HasSpell('Find Herbs');
	
	script_gather:addHerb('Peacebloom', 269, false, 1);
	script_gather:addHerb('Silverleaf', 270, false, 1);
	script_gather:addHerb('Earthroot', 414, false, 15);
	script_gather:addHerb('Mageroyal', 268, false, 50);
	script_gather:addHerb('Briarthorn', 271, false, 70);
	script_gather:addHerb('Stranglekelp', 700, false, 85);
	script_gather:addHerb('Bruiseweed', 358, false, 100);
	script_gather:addHerb('Wild Steelbloom', 371, false, 115);
	script_gather:addHerb('Grave Moss', 357, false, 120);
	script_gather:addHerb('Kingsblood', 320, false, 125);
	script_gather:addHerb('Liferoot', 677, false, 150);
	script_gather:addHerb('Fadeleaf', 697, false, 160);
	script_gather:addHerb('Goldthorn', 698, false, 170);
	script_gather:addHerb('Khadgars Whisker', 701, false, 185);
	script_gather:addHerb('Wintersbite', 699, false, 195);
	script_gather:addHerb('Firebloom', 2312, false, 205);
	script_gather:addHerb('Purple Lotus', 2314, false, 210);
	script_gather:addHerb('Arthas Tears', 2310, false, 220);
	script_gather:addHerb('Sungrass', 2315, false, 230);
	script_gather:addHerb('Blindweed', 2311, false, 235);
	script_gather:addHerb('Ghost Mushroom', 389, false, 245);
	script_gather:addHerb('Gromsblood', 2313, false, 250);
	script_gather:addHerb('Golden Sansam', 4652, false, 260);
	script_gather:addHerb('Dreamfoil', 4635, false, 270);
	script_gather:addHerb('Mountain Silversage', 4633, false, 280);
	script_gather:addHerb('Plaguebloom', 4632, false, 285);
	script_gather:addHerb('Icecap', 4634, false, 290);
	script_gather:addHerb('Black Lotus', 4636, false, 300);

	script_gather:addMineral('Copper Vein', 310, false, 1);
	script_gather:addMineral('Incendicite Mineral Vein', 384, false, 65);
	script_gather:addMineral('Tin Vein', 315, false, 65);
	script_gather:addMineral('Lesser Bloodstone Deposit', 48, false, 75);
	script_gather:addMineral('Silver Vein', 314, false, 75);
	script_gather:addMineral('Iron Deposit', 312, false, 125);
	script_gather:addMineral('Indurium Mineral Vein', 385, false, 150);
	script_gather:addMineral('Gold Vein', 311, false, 155);
	script_gather:addMineral('Mithril Deposit', 313, false, 175);
	script_gather:addMineral('Truesilver Deposit', 314, false, 205);
	script_gather:addMineral('Dark Iron Deposit', 2571, false, 230);
	script_gather:addMineral('Small Thorium Vein', 3951, false, 230);
	script_gather:addMineral('Rich Thorium Vein', 3952, false, 255);

	
	self.timer = GetTimeEX();

	self.isSetup = true;
end

function script_gather:getHerbSkill()
	local herbSkill = 0;
	for skillIndex = 1, GetNumSkillLines() do
  		skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier,
    		skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType,
    		skillDescription = GetSkillLineInfo(skillIndex)
    		if (skillName == 'Herbalism') then
			herbSkill = skillRank;
		end
	end

	return herbSkill;
end

function script_gather:getMiningSkill()
	local miningSkill = 0;
	for skillIndex = 1, GetNumSkillLines() do
  		skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier,
    		skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType,
    		skillDescription = GetSkillLineInfo(skillIndex)
    		if (skillName == 'Mining') then
			miningSkill = skillRank;
		end
	end

	return miningSkill;
end


function script_gather:ShouldGather(id)

	local herbSkill = script_gather:getHerbSkill();
	local miningSkill = script_gather:getMiningSkill();

	if(self.collectMinerals) then
		for i=0,self.numMinerals - 1 do
			if(self.minerals[i][1] == id and (self.minerals[i][2] or ((self.minerals[i][3] <= miningSkill) and self.gatherAllPossible))) then			
				return true;		
			end
		end
	end
	
	if(self.collectHerbs) then
		for i=0,self.numHerbs - 1 do
			if(self.herbs[i][1] == id and (self.herbs[i][2]or ((self.herbs[i][3] <= herbSkill) and self.gatherAllPossible))) then			
				return true;		
			end
		end	
	end
end

function script_gather:GetNode()
	local targetObj, targetType = GetFirstObject();
	local bestDist = 9999;
	local bestTarget = nil;
	while targetObj ~= 0 do
		if (targetType == 5) then --GameObject
			if(script_gather:ShouldGather(targetObj:GetObjectDisplayID())) then
				local dist = targetObj:GetDistance();
				if(dist < self.gatherDistance and bestDist > dist) then
					local _x, _y, _z = targetObj:GetPosition();
					if(not IsNodeBlacklisted(_x, _y, _z, 5)) then
						bestDist = dist;
						bestTarget = targetObj;
					end
				end
			end
		end
		targetObj, targetType = GetNextObject(targetObj);
	end
	return bestTarget;
end

function script_gather:drawGatherNodes()

local targetObj, targetType = GetFirstObject();
	while targetObj ~= 0 do
		if (targetType == 5 and targetObj:IsGatherNode()) then 
			local id = targetObj:GetObjectDisplayID();
			local name = 'Gather Node';
			local _x, _y, _z = targetObj:GetPosition();
			local _tX, _tY, onScreen = WorldToScreen(_x, _y, _z);
			if(onScreen) then
				for i=0,self.numHerbs - 1 do
					if (self.herbs[i][1] == id) then
						name = self.herbs[i][0];
					end
				end

				for i=0,self.numMinerals - 1 do
					if (self.minerals[i][1] == id) then
						name = self.minerals[i][0];
					end
				end
					
				DrawText(name, _tX-10, _tY, 255, 255, 0);
			end
		end
		targetObj, targetType = GetNextObject(targetObj);
	end
end

function script_gather:currentGatherName()
	local name = ' ';
	if (self.nodeID ~= 0 and self.nodeID ~= nil) then
		for i=0,self.numHerbs - 1 do
			if (self.herbs[i][1] == self.nodeID) then
				name = self.herbs[i][0];
			end
		end

		for i=0,self.numMinerals - 1 do
			if (self.minerals[i][1] == self.nodeID) then
				name = self.minerals[i][0];
			end
		end
	end

	return name;
end

function script_gather:gather()
	
	if(not self.isSetup) then
		script_gather:setup();
	end

	if (self.timer > GetTimeEX()) then
		return true;
	end
	
	local tempNode = script_gather:GetNode();
	local newNode = (self.nodeObj == tempNode);

	self.nodeObj = script_gather:GetNode();

	if (self.nodeObj == nil) then
		return false;
	end

	self.nodeID = self.nodeObj:GetObjectDisplayID();
		
	if(self.nodeObj ~= nil and self.nodeObj ~= 0) then
		
		local _x, _y, _z = self.nodeObj:GetPosition();
		local dist = self.nodeObj:GetDistance();		
			
		if(dist < self.lootDistance) then
			if(IsMoving()) then
				StopMoving();
				self.timer = GetTimeEX() + 150;
			end

			if(not IsLooting() and not IsChanneling()) then
				self.nodeObj:GameObjectInteract();
				self.timer = GetTimeEX() + 1250;
			end
			if (not LootTarget()) then
				self.timer = GetTimeEX() + 650;
				return;
			end
		else
			if (_x ~= 0) then
				script_nav:moveToNav(GetLocalPlayer(), _x, _y, _z);
				self.timer = GetTimeEX() + 150;
			end
		end

		return true;
	end

	return false;
end

function script_gather:menu()

	if(not self.isSetup) then
		script_gather:setup();
	end

	local wasClicked = false;
	
	if (CollapsingHeader("[Gather options")) then
		wasClicked, script_grind.gather = Checkbox("Gather on/off", script_grind.gather);
		
		wasClicked, self.collectMinerals = Checkbox("Mining", self.collectMinerals);
		SameLine();
		wasClicked, self.collectHerbs = Checkbox("Herbalism", self.collectHerbs);

		Text('Gather Search Distance');
		self.gatherDistance = SliderFloat("GSD", 1, 150, self.gatherDistance);
		
		if (script_gather.collectMinerals or script_gather.collectHerbs) then
			wasClicked, script_gather.gatherAllPossible = Checkbox("Gather everything we can", script_gather.gatherAllPossible);
		end

		if(self.collectMinerals and not script_gather.gatherAllPossible) then
			Separator();
			Text('Minerals');
			
			for i=0,self.numMinerals - 1 do
				wasClicked, self.minerals[i][2] = Checkbox(self.minerals[i][0], self.minerals[i][2]);
				SameLine(); Text('(' .. self.minerals[i][3] .. ')');
			end
		end
		
		if(self.collectHerbs and not script_gather.gatherAllPossible) then
			Separator();
			Text('Herbs');
			
			for i=0,self.numHerbs - 1 do
				wasClicked, self.herbs[i][2] = Checkbox(self.herbs[i][0], self.herbs[i][2]);
				SameLine(); Text('(' .. self.herbs[i][3] .. ')');
			end
		end
	end
end