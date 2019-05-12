script_nav = {
	useNavMesh = true,
	nextNavNodeDistance = 5, -- for mobs and loot
	nextPathNodeDistance = 5, -- for walking paths
	lastPathIndex = -1,
	navPosition = {},
	navPathPosition = {},
	lastnavIndex = 0,
	lastpathnavIndex = 0,
	navPath = nil,
	savedLocations = {},
	numSavedLocation = 0,
	currentGoToLocation = 0,
	currentHotSpotX = 0,
	currentHotSpotY = 0,
	currentHotSpotZ = 0,
	currentHotSpotName = 0,
	hotSpotDist = 0,
	drawNav = true
}

function script_nav:setup()
	DEFAULT_CHAT_FRAME:AddMessage('script_nav: loaded...');
end

function script_nav:resetPath()
	self.lastnavIndex = 0;
	self.navPosition['x'], self.navPosition['y'], self.navPosition['z'] = 0, 0, 0;
	local x, y, z = GetLocalPlayer():GetPosition();
	GeneratePath(x, y, z, x+0.1, y+0.1, z);
end

function script_nav:loadHotspotDB(id)
	local hotspot = hotspotDB:getHotSpotByID(id)

	if (hotspot ~= nil and hotspot ~= -1) then
		if (self.currentHotSpotName ~= hotspot['name']) then
			script_grind.hotspotReached = false;
			self.savedLocations = {};
			self.numSavedLocation = 0;
			self.currentGoToLocation = 0;
		end
		self.currentHotSpotX , self.currentHotSpotY, self.currentHotSpotZ, self.currentHotSpotName =
			hotspot['pos']['x'], hotspot['pos']['y'], hotspot['pos']['z'], hotspot['name'];
			
			return true;
	end

	return false;
end

function script_nav:updateHotSpot(currentLevel, factionNr, useStaticHotSpot)
	
	if (useStaticHotSpot) then 
		local race, level = UnitRace("player"), GetLocalPlayer():GetLevel();
		local id = hotspotDB:getHotspotID(race, level);

		if (script_nav:loadHotspotDB(id)) then 
			return true; 
		end
	end

	-- If there is no static hotspot and no hotspot loaded: Use our current position as a hot spot
	if (self.currentHotSpotName == 0) then
		local localObj = GetLocalPlayer();
		local x, y, z = localObj:GetPosition();
		self.currentHotSpotX , self.currentHotSpotY, self.currentHotSpotZ, self.currentHotSpotName =
		x, y, z, 'Change in path options';
		return true;
	end
end

function script_nav:newHotspot(name)
	local localObj = GetLocalPlayer();
	local x, y, z = localObj:GetPosition();
	self.currentHotSpotX , self.currentHotSpotY, self.currentHotSpotZ, self.currentHotSpotName =
	x, y, z, name;
end

function script_nav:getHotSpotName()
	return self.currentHotSpotName;
end

function script_nav:setHotSpotDistance(dist)
	self.hotSpotDist = dist;
end

function script_nav:isHotSpotLoaded()
	if (self.currentHotSpotName == 0) then return false; end
	return true;
end

function script_nav:getDistanceToHotspot()
	local localObj = GetLocalPlayer();
	local _lx, _ly, _lz = localObj:GetPosition();
	if (self.currentHotSpotName ~= '') then
		return math.sqrt((self.currentHotSpotX-_lx)^2+(self.currentHotSpotY-_ly)^2);
	else
		return 0; -- no hot spot loaded
	end
end

function script_nav:moveToHotspot(localObj)
	if (self.currentHotSpotName ~= 0) then
		script_nav:moveToTarget(localObj, self.currentHotSpotX, self.currentHotSpotY, self.currentHotSpotZ); 
		return "Moving to hotspot " .. self.currentHotSpotName .. '...';
	else
		return "No hotspot has been loaded...";
	end
end

function script_nav:saveTargetLocation(target, mobLevel)
	local _tx, _ty, _tz = target:GetPosition();

	-- Check: Don't save if we are outside the hotspot distance
	if (script_nav:getDistanceToHotspot() > self.hotSpotDist) then return; end

	-- Check: Don't save if we already saved a location within 60 yd
	local saveLocation = true;
	if (self.numSavedLocation > 0) then
		for i = 0,self.numSavedLocation-1 do
			local dist = math.sqrt((_tx-self.savedLocations[i]['x'])^2+(_ty-self.savedLocations[i]['y'])^2);
			if (dist < 60) then
				saveLocation = false;
			end
		end
	end
	
	if (saveLocation) then
		self.savedLocations[self.numSavedLocation] = {};
		self.savedLocations[self.numSavedLocation]['x'] = _tx;
		self.savedLocations[self.numSavedLocation]['y'] = _ty;
		self.savedLocations[self.numSavedLocation]['z'] = _tz;
		self.savedLocations[self.numSavedLocation]['level'] = mobLevel;
		self.numSavedLocation = self.numSavedLocation + 1;
	end
end

function script_nav:moveToSavedLocation(localObj, minLevel, maxLevel, useStaticHotSpot)
	-- Check: Load/update the hotspot
	if (self.currentHotSpotName ~= 0) then
		script_nav:updateHotSpot(localObj:GetLevel(), GetFaction(), useStaticHotSpot); 
	end
	
	-- Let's get at least 2 path nodes around the hot spot before we navigate through them
	if (self.numSavedLocation < 2) then
		return script_nav:moveToHotspot(localObj);
	end

	-- Check: If we reached the last location index
	if (self.currentGoToLocation > (self.numSavedLocation - 1)) then
		self.currentGoToLocation = 0;
	end
	
	-- Check: Move to the next location index
	local _lx, _ly, _lz = localObj:GetPosition();
	local currentDist = math.sqrt((_lx-self.savedLocations[self.currentGoToLocation]['x'])^2+(_ly-self.savedLocations[self.currentGoToLocation]['y'])^2);
	if (currentDist < 5 
		or self.savedLocations[self.currentGoToLocation]['level'] < minLevel
		or self.savedLocations[self.currentGoToLocation]['level'] > maxLevel) then
		self.currentGoToLocation = self.currentGoToLocation + 1;
		return "Changing go to location...";
	end

	script_nav:moveToTarget(localObj, self.savedLocations[self.currentGoToLocation]['x'], self.savedLocations[self.currentGoToLocation]['y'], self.savedLocations[self.currentGoToLocation]['z']);
	
	return "Moving to auto path node: " .. self.currentGoToLocation+1 .. "...";
end

function script_nav:drawSavedTargetLocations()
	for i = 0,self.numSavedLocation-1 do
		local tX, tY, onScreen = WorldToScreen(self.savedLocations[i]['x'], self.savedLocations[i]['y'], self.savedLocations[i]['z']);
		if (onScreen) then
			DrawText('Auto Path Node', tX, tY-20, 0, 255, 255);
			DrawText('ID: ' .. i+1, tX, tY-10, 0, 255, 255);
			DrawText('ML: ' .. self.savedLocations[i]['level'], tX, tY, 255, 255, 0);
		end
	end
	if (self.currentHotSpotName ~= 0) then
		local tX, tY, onScreen = WorldToScreen(self.currentHotSpotX , self.currentHotSpotY, self.currentHotSpotZ);
		if (onScreen) then
			DrawText('HOTSPOT: ' .. self.currentHotSpotName, tX, tY, 0, 255, 255);
		end
	end
end

function script_nav:drawUnitsDataOnScreen()
	local i, targetType = GetFirstObject();
	while i ~= 0 do
		if (targetType == 3 and not i:IsCritter() and not i:IsDead() and i:CanAttack()) then
			script_nav:drawMonsterDataOnScreen(i);
		end
		if (targetType == 4 and not i:IsCritter() and not i:IsDead()) then
			script_nav:drawPlayerDataOnScreen(i);
		end
		i, targetType = GetNextObject(i);
	end
end

function script_nav:drawMonsterDataOnScreen(target)
	local player = GetLocalPlayer();
	local distance = target:GetDistance();
	local tX, tY, onScreen = WorldToScreen(target:GetPosition());
	if (onScreen) then
		DrawText(target:GetCreatureType() .. ' - ' .. target:GetLevel(), tX, tY-10, 255, 255, 0);
		if (GetTarget() == target) then 
			DrawText('(targeted)', tX, tY-20, 255, 0, 0); 
		end
		if (script_grind:isTargetBlacklisted(target:GetGUID())) then
			DrawText('(blacklisted)', tX, tY-20, 255, 0, 0);
		end
		DrawText('HP: ' .. math.floor(target:GetHealthPercentage()) .. '%', tX, tY, 255, 0, 0);
		DrawText('' .. math.floor(distance) .. ' yd.', tX, tY+10, 255, 255, 255);
	end
end

function script_nav:drawPlayerDataOnScreen(target)
	local player = GetLocalPlayer();
	if (target:GetGUID() ~= player:GetGUID()) then 
		local distance = target:GetDistance();
		local tX, tY, onScreen = WorldToScreen(target:GetPosition());
		if (onScreen) then
			if (target:CanAttack()) then 
				DrawText('' .. target:GetUnitName() .. ' - ' .. target:GetLevel(), tX, tY-10, 255, 0, 0);
			else 
				DrawText('' .. target:GetUnitName() .. ' - ' .. target:GetLevel(), tX, tY-10, 0, 255, 0);
			end
			DrawText('HP: ' .. math.floor(target:GetHealthPercentage()) .. '%', tX, tY, 255, 0, 0);
			DrawText('' .. math.floor(distance) .. ' yd.', tX, tY+10, 255, 255, 255);
			if (target:GetUnitsTarget() ~= 0) then
				if (target:GetUnitsTarget():GetGUID() == player:GetGUID()) then 
					DrawText('TARGETING US!', tX, tY+20, 255, 0, 0); 
				end
			end
		end
	end
end

function script_nav:setNextToNodeDist(distance)
	self.nextNavNodeDistance = distance;
	self.nextPathNodeDistance = distance;
end

function script_nav:drawPath()
	local firstIndex = 0;
	local mx, my, mz = GetLocalPlayer():GetPosition();
	if (IsPathLoaded(5)) then
		if (self.drawNav) then
			firstIndex = self.lastpathnavIndex;
		else
			firstIndex = self.lastnavIndex;
		end
		if (self.lastnavIndex-1 <= GetPathSize(5)-1) then
			for index = firstIndex, GetPathSize(5) - 2 do
				local _x, _y, _z = GetPathPositionAtIndex(5, index);
				local _xx, _yy, _zz = GetPathPositionAtIndex(5, index+1);
				local _tX, _tY, onScreen = WorldToScreen(_x, _y, _z);
				local _tXX, _tYY, onScreens = WorldToScreen(_xx, _yy, _zz);
				if(onScreen and onScreens) then
					DrawLine(_tX, _tY, _tXX, _tYY, 255, 255, 0, 1);
					if (GetDistance3D(mx, my, mz, _xx, _yy, _zz) < 100) then
						script_aggro:DrawCircles(_x, _y, _z, 0.2);
						script_aggro:DrawCircles(_xx, _yy, _zz, 0.2);
					end
				end
			end
		end
	end
end

function script_nav:drawPullRange(range)
	local localObj = GetLocalPlayer();
end

function script_nav:getLootTarget(lootRadius)
	local targetObj, targetType = GetFirstObject();
	local bestDist = lootRadius;
	local bestTarget = nil;
	while targetObj ~= 0 do
		if (targetType == 3) then -- Unit
			if(targetObj:IsDead()) then
				if (targetObj:IsLootable()) then
					local dist = targetObj:GetDistance();
					if(dist < lootRadius and bestDist > dist) then
					local _x, _y, _z = targetObj:GetPosition();
						if(not IsNodeBlacklisted(_x, _y, _z, self.nextNavNodeDistance)) then
							bestDist = dist;
							bestTarget = targetObj;
						end
					end
				end
			end
		end
		targetObj, targetType = GetNextObject(targetObj);
	end

	return bestTarget;
end

function script_nav:moveToTarget(localObj, _x, _y, _z) -- use when moving to moving targets

	-- Please load and enable the nav mesh
	if (not IsUsingNavmesh() and self.useNavMesh) then
		return "Please load and and enable the nav mesh...";
	end

	self.drawNav = false;

	-- Fetch our current position
	localObj = GetLocalPlayer();
	local _lx, _ly, _lz = localObj:GetPosition();

	local _ix, _iy, _iz = GetPathPositionAtIndex(5, self.lastnavIndex);	

	-- If the target moves more than 2 yard then make a new path
	if(GetDistance3D(_x, _y, _z, self.navPosition['x'], self.navPosition['y'], self.navPosition['z']) > 2
		or GetDistance3D(_lx, _ly, _lz, _ix, _iy, _iz) > 25) then
		self.navPosition['x'] = _x;
		self.navPosition['y'] = _y;
		self.navPosition['z'] = _z;
		GeneratePath(_lx, _ly, _lz, _x, _y, _z);
		self.lastnavIndex = 1; -- start at index 1, index 0 is our position
	end	

	if (not IsPathLoaded(5)) then
		return "Generating path...";
	end

	-- Get the current path node's coordinates
	_ix, _iy, _iz = GetPathPositionAtIndex(5, self.lastnavIndex);

	-- If we are close to the next path node, increase our nav node index
	if(GetDistance3D(_lx, _ly, _lz, _ix, _iy, _iz) < self.nextNavNodeDistance) then
		self.lastnavIndex = 1 + self.lastnavIndex;		
		if (GetPathSize(5) <= self.lastnavIndex) then
			self.lastnavIndex = GetPathSize(5)-1;
		end
	end

	-- Check: If move to coords are too far away, something wrong, dont move... BUT WHY ?!
	if (GetDistance3D(_lx, _ly, _lz, _ix, _iy, _iz) > 25) then
		GeneratePath(_lx, _ly, _lz, _lx+2, _ly+2, _lz);
		return "Generating a new path...";
	end

	-- Move to the next destination in the path
	Move(_ix, _iy, _iz);

	return "Moving to target...";
end

function script_nav:moveToNav(localObj, _x, _y, _z)

	-- Please load and enable the nav mesh
	if (not IsUsingNavmesh() and self.useNavMesh) then
		return "Please load and and enable the nav mesh...";
	end
	
	self.drawNav = true;

	-- Fetch our current position
	local _lx, _ly, _lz = localObj:GetPosition();

	local _ix, _iy, _iz = GetPathPositionAtIndex(5, self.lastpathnavIndex);
			
	-- If we have a new destination, generate a new path to it
	if(self.navPathPosition['x'] ~= _x or self.navPathPosition['y'] ~= _y or self.navPathPosition['z'] ~= _z
		or GetDistance3D(_lx, _ly, _lz, _ix, _iy, _iz) > 25) then
		self.navPathPosition['x'] = _x;
		self.navPathPosition['y'] = _y;
		self.navPathPosition['z'] = _z;
		GeneratePath(_lx, _ly, _lz, _x, _y, _z);
		self.lastpathnavIndex = 1; 
	end	

	if (not IsPathLoaded(5)) then
		return "Generating path...";
	end
	
	-- Get the current path node's coordinates
	_ix, _iy, _iz = GetPathPositionAtIndex(5, self.lastpathnavIndex);

	-- When dead use 2D distance
	if (localObj:IsDead()) then
		if (math.sqrt((_lx - _ix)^2 + (_ly - _iy)^2) < self.nextNavNodeDistance) then
			self.lastpathnavIndex = self.lastpathnavIndex + 1;	
			if (GetPathSize(5) <= self.lastpathnavIndex) then
				self.lastpathnavIndex = GetPathSize(5)-1;
			end
		end
	else
		-- If we are close to the next path node, increase our nav node index
		if(GetDistance3D(_lx, _ly, _lz, _ix, _iy, _iz) < self.nextNavNodeDistance) then
			self.lastpathnavIndex = self.lastpathnavIndex + 1;	
			if (GetPathSize(5) <= self.lastpathnavIndex) then
				self.lastpathnavIndex = GetPathSize(5)-1;
			end
		end
	end

	-- Check: If the move to coords are too far away, something wrong don't use those
	if (GetDistance3D(_lx, _ly, _lz, _ix, _iy, _iz) > 25) then
		return "Moving to target...";
	end

	-- Move to the next destination in the path
	Move(_ix, _iy, _iz);

	return "Navigating to location...";
end

function script_nav:resetNavPos() -- navPosition used for moveToTarget
	self.navPosition['x'] = 0;
	self.navPosition['y'] = 0;
	self.navPosition['z'] = 0;
end

function script_nav:resetNavigate() -- navPathPosition used for navigate
	self.navPathPosition['x'] = 0;
	self.navPathPosition['y'] = 0;
	self.navPathPosition['z'] = 0;
	self.lastPathIndex = -1;
end

function script_nav:findClosestPathNode(localObj, currentIndex, pathType, maxHeightLevel)
	local _bestDist = 9999;
	local pathSize = GetPathSize(pathType);	
	local bestIndex = 0; 

	if (pathSize-1 > currentIndex+1) then
		for index = currentIndex+1, pathSize - 1 do
			local _x, _y, _z = GetPathPositionAtIndex(pathType, index);
			local _lx, _ly, _lz = localObj:GetPosition();				
			for heightLevel = 0, maxHeightLevel do
				local isVis, _hx, _hy, _hz = Raycast(_x, _y, _z + heightLevel, _lx, _ly, _lz + heightLevel);			
				if(GetDistance3D(_x, _y, _z, _lx, _ly, _lz) < _bestDist) then
					_bestDist = GetDistance3D(_x, _y, _z, _lx, _ly, _lz);
					bestIndex = index;
				end
			end
		end
	else
		return pathSize-1;
	end
	return bestIndex;
end

function script_nav:navigate(localObj)
	-- Please load the nav mesh
	if (not IsUsingNavmesh() and self.useNavMesh) then
		return "Please load the nav mesh...";
	end
	
	if(IsPathLoaded(0)) then
		local pathSize = GetPathSize(0); -- walkPath = 0
		local _lx, _ly, _lz = localObj:GetPosition();

		-- At start get the closest walk path node
		if(self.lastPathIndex == -1) then
			self.lastPathIndex = script_nav:findClosestPathNode(localObj, -1, 0, 5);
		end

		local _x, _y, _z = GetPathPositionAtIndex(0, self.lastPathIndex);

		-- Check: If we are close to the next node in the walking path, hop to the next one		
		if(GetDistance3D(_x, _y, _z, _lx, _ly, _lz) < self.nextPathNodeDistance) then
			self.lastPathIndex = self.lastPathIndex + 1;
		end
			
		-- Check: If we reached the end node, start over at node 1
		if(self.lastPathIndex >= pathSize) then
			self.lastPathIndex = 0;
		end
			
		script_nav:moveToNav(localObj, _x, _y, _z);
		
		return "Navigating to path index: " .. self.lastPathIndex;
	else
		-- Please load a path...
		return "No walk path has been loaded...";
	end
end


function script_nav:runBackwards(count, range) -- Run backwards if there is atleast count of monsters within range
	local countUnitsInRange = 0;
	local currentObj, typeObj = GetFirstObject();
	local localObj = GetLocalPlayer();
	local closestEnemy = 0;
	while currentObj ~= 0 do
 		if typeObj == 3 or typeObj == 4 then
			if currentObj:CanAttack() and not currentObj:IsCritter() and currentObj:GetDistance() <= range and not currentObj:IsDead() then	
				countUnitsInRange = countUnitsInRange + 1;
				if (closestEnemy ~= 0) then
					if (currentObj:GetDistance() < closestEnemy:GetDistance()) then			
						closestEnemy = currentObj;
					end
				else
					closestEnemy = currentObj;
				end
 			end
 		end
 		currentObj, typeObj = GetNextObject(currentObj);
 	end
 	
 	if closestEnemy ~= 0 then
 			local xT, yT, zT = closestEnemy:GetPosition();
 			local xP, yP, zP = localObj:GetPosition();
 			local xV, yV, zV = xP - xT, yP - yT, zP - zT;	
 			local vectorLength = math.sqrt(xV^2 + yV^2 + zV^2);
 			local xUV, yUV, zUV = (1/vectorLength)*xV, (1/vectorLength)*yV, (1/vectorLength)*zV;		
 		if countUnitsInRange >= count then
			script_nav:moveToTarget(localObj, moveX, moveY, moveZ);
			return true;
		end
	end
end

function script_nav:avoidElite(range) -- Runs away if there is atleast one elite within range
	local currentObj, typeObj = GetFirstObject();
	local localObj = GetLocalPlayer();
	while currentObj ~= 0 do
 		if typeObj == 3 and (currentObj:GetClassification() == 1 or currentObj:GetClassification() == 2) then
			if currentObj:CanAttack() and currentObj:GetDistance() <= range and not currentObj:IsDead() then	
				local xT, yT, zT = currentObj:GetPosition();
 				local xP, yP, zP = localObj:GetPosition();
 				local xV, yV, zV = xP - xT, yP - yT, zP - zT;	
 				local vectorLength = math.sqrt(xV^2 + yV^2 + zV^2);
 				local xUV, yUV, zUV = (1/vectorLength)*xV, (1/vectorLength)*yV, (1/vectorLength)*zV;		
 				local moveX, moveY, moveZ = xT + xUV*100, yT + yUV*100, zT + zUV;			
				script_nav:moveToTarget(localObj, moveX, moveY, moveZ);
				return true;
 			end
 		end
 		currentObj, typeObj = GetNextObject(currentObj);
 	end
	return false;
end