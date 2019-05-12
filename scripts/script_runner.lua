script_runner = {
        nRcombo = 0, -- selected destination number (combo box)
        runit = false, 
        distDestination = 0,
	useNaveMesh = false,
	lastnavIndex = 0,
        nextNodeDistance = 5,
        tx = 0,
        ty = 0,
        tz = 0,
	dx = 0,
	dy = 0,
	dz = 0,
        _x = 0,
        _y = 0,
        _z = 0,
	avoidX = 0,
	avoidY = 0,
	avoidZ = 0,
	destination = {},
	destinationName = {},
	destNum = 1,
	isSetup = false,
	tic = 150,
	timer = 0,
	destinationChanged = false,
	genTimer = 0,
	generating = false,
	avoidTimer = 0,
	destinationReached = false,
	avoidAggro = true,
	safeDistance = 5,
	genTime = GetTimeEX()
}

function script_runner:window()

	--Close existing Window
	EndWindow();

	if(NewWindow("[Runner", 200, 200)) then
		script_runner:menu();
	end

end

function script_runner:DrawCircles(pointX,pointY,pointZ,radius)
	-- thx benjamin
	local r = 255;
	local g = 255;
	local b = 0;
	-- position
	local x = 25;

	-- we will go by radians, not degrees
	local sqrt, sin, cos, PI, theta, points, point = math.sqrt, math.sin, math.cos,math.pi, 0, {}, 0;
	while theta <= 2*PI do
		point = point + 1 -- get next table slot, starts at 0 
		points[point] = { x = pointX + radius*cos(theta), y = pointY + radius*sin(theta) }
		theta = theta + 2*PI / 50 -- get next theta
	end
	for i = 1, point do
		local firstPoint = i
		local secondPoint = i + 1
		if firstPoint == point then
			secondPoint = 1
		end
		if points[firstPoint] and points[secondPoint] then
			local x1, y1, onScreen1 = WorldToScreen(points[firstPoint].x, points[firstPoint].y, pointZ)
			
			local x2, y2, onScreen2 = WorldToScreen(points[secondPoint].x, points[secondPoint].y, pointZ)
			-- make boolean string so i can post it to console
			onScreen1String = tostring(onScreen1);
			
			--ToConsole('x1 inside draw cirlces: ' .. x1 .. 'onScreen1: ' .. onScreen1String .. y1 .. x2 .. y2 .. redVar .. greenVar .. blueVar .. lineThickness);
			if onScreen1 == true and onScreen2 == true then
				DrawLine(x1, y1, x2, y2, r, g, b, 2)
				
			end
		end
	end
end

function script_runner:avoidToAggro(safeMargin) 
	local countUnitsInRange = 0;
	local currentObj, typeObj = GetFirstObject();
	local localObj = GetLocalPlayer();
	local closestEnemy = 0;
	local closestDist = 999;
	local aggro = 0;

	while currentObj ~= 0 do
 		if typeObj == 3 then
			aggro = currentObj:GetLevel() - localObj:GetLevel() + 21;
			local range = aggro + safeMargin;
			if currentObj:CanAttack() and not currentObj:IsDead() and not currentObj:IsCritter() and currentObj:GetDistance() <= range then	
				if (closestEnemy == 0) then
					closestEnemy = currentObj;
				else
					local dist = currentObj:GetDistance();
					if (dist < closestDist) then
						closestDist = dist;
						closestEnemy = currentObj;
					end
				end
 			end
 		end
 		currentObj, typeObj = GetNextObject(currentObj);
 	end

	-- avoid the closest mob
	if (closestEnemy ~= 0) then

			local xT, yT, zT = closestEnemy:GetPosition();

 			local xP, yP, zP = localObj:GetPosition();

			local safeRange = safeMargin+1;
			local intersectMob = script_runner:aggroIntersect(closestEnemy);
			if (intersectMob ~= nil) then
				local aggroRange = intersectMob:GetLevel() - localObj:GetLevel() + 21 + aggro; 
				local x, y, z = closestEnemy:GetPosition();
				local xx, yy, zz = intersectMob:GetPosition();
				local centerX, centerY = (x+xx)/2, (y+yy)/2;
				script_runner:avoid(centerX, centerY, zP, aggroRange, safeRange);
			else
				script_runner:avoid(xT, yT, zP, aggro, safeRange);
			end

			return true;
	end

	return false;
end

function script_runner:aggroIntersect(target)
	local x, y,z = target:GetPosition();
	while currentObj ~= 0 do
 		if typeObj == 3 then
			aggro = currentObj:GetLevel() - localObj:GetLevel() + 21;
			local range = aggro + safeMargin;
			if currentObj:CanAttack() and not currentObj:IsDead() and not currentObj:IsCritter() and currentObj:GetDistance() <= range then	
				local xx, yy, zz = currentObj:GetPosition();
				local dist = math.sqrt((x-xx)^2 +(y-yy)^2);
				if (dist < aggro*2) then
					return currentObj;
				end
 			end
 		end
 		currentObj, typeObj = GetNextObject(currentObj);
 	end
	return nil;
end

function script_runner:avoid(pointX,pointY,pointZ, radius, safeDist)
	-- thx benjamin
	local r = 255;
	local g = 255;
	local b = 0;
	-- position
	local x = 25;

	-- we will go by radians, not degrees
	local sqrt, sin, cos, PI, theta, points, pointsTwo, point = math.sqrt, math.sin, math.cos,math.pi, 0, {}, {}, 0;
	
	local closestDist = 999;
	local closestPoint = 0;
	local closestTargetPoint = 0;
	local closestTargetDist = 999;
	local quality = 120;

	while theta <= 2*PI do
		point = point + 1 -- get next table slot, starts at 0 
		points[point] = { x = pointX + radius*cos(theta), y = pointY + radius*sin(theta) }
		pointsTwo[point] = { x = pointX + (safeDist+radius)*cos(theta), y = pointY + (safeDist+radius)*sin(theta) }
		theta = theta + 2*PI / quality -- get next theta
	end
	for i = 1, point do
		local firstPoint = i
		local secondPoint = i + 1

		if firstPoint == point then
			secondPoint = 1
		end

		if points[firstPoint] and points[secondPoint] then

			local myX, myY, myZ = GetLocalPlayer():GetPosition();

			local dist = math.sqrt((points[secondPoint].x-myX)^2 + (points[secondPoint].y-myY)^2);

			local distToDest = math.sqrt((points[secondPoint].x-self.tx)^2 + (points[secondPoint].y-self.ty)^2);

			-- Set target theta point
			if (distToDest < closestTargetDist) then
				closestTargetDist = distToDest;
				closestTargetPoint = i;
			end

			-- Set closest theta point to move to
			if (dist < closestDist) then
				closestDist = dist;
				closestPoint = i;
			end
		end
	end

	-- TODO use closestPoint and closestTargetPoint to calculate direction to travel

	-- Move just outside the aggro range
	local moveToPoint = closestPoint;
	
	moveToPoint = closestPoint + 4;
	
	if (moveToPoint > point) then
		moveToPoint = 1;
	end

	if (moveToPoint == 0) then
		moveToPoint = 1;
	end

	Move(pointsTwo[moveToPoint].x, pointsTwo[moveToPoint].y, pointZ);
end

function script_runner:drawAggroCircles()
	local countUnitsInRange = 0;
	local currentObj, typeObj = GetFirstObject();
	local localObj = GetLocalPlayer();
	local closestEnemy = 0;

	while currentObj ~= 0 do
 		if typeObj == 3 and not currentObj:IsDead() and currentObj:CanAttack() and not currentObj:IsCritter() then
			local aggro = currentObj:GetLevel() - localObj:GetLevel() + 21;
			local cx, cy, cz = currentObj:GetPosition();
			script_runner:DrawCircles(cx, cy, cz, aggro);
			local intersectMob = script_runner:aggroIntersect(currentObj);
			
			if (intersectMob ~= nil) then
				local aggroRange = aggro*2;
				local x, y, z = currentObj:GetPosition();
				local xx, yy, zz = intersectMob:GetPosition();
				local centerX, centerY = (x+xx)/2, (y+yy)/2;
				script_runner:DrawCircles(centerX, centerY, z, aggroRange);
			end
 		end
 		currentObj, typeObj = GetNextObject(currentObj);
 	end
end

function script_runner:setup()
	self.timer = GetTimeEX();
	self.genTimer = GetTimeEX();
	self.avoidTimer = GetTimeEX();
	-- Add Destinations
	script_runner:addDestination("Tanaris Avoid Demo Start", -7288.0126953125, -3773.5656738281, 9.1952447891235, 1, 440);
	script_runner:addDestination("Tanaris Avoid Demo Stop", -7427.31, -3759.38, 11.87, 10.79, 1, 440);
	script_runner:addDestination("Razor Hill - Durator", 323.82, -4736.34, 9.80, 1, 14);
	script_runner:addDestination("Orgrimmar - Durator", 1620.57, -4433.01, 11.07, 1, 1637);
	script_runner:addDestination("The Crossroads - The Barrens", -433.57, -2651.16, 95.96, 1, 17);
	script_runner:addDestination("Camp Taurajo - The Barrens", -2356.23, -1964.11, 96.06, 1, 17);
	script_runner:addDestination("Brackenwall Village - Dustwallow Marsh", -3154.01, -2900.93, 33.83, 0, 0);
	script_runner:addDestination("Splintertree Post - Ashenvale", 2324.94, -2546.02, 101.05, 1, 331);
	script_runner:addDestination("Bloodvenom Post - Felwood", 5105.07, -353.01, 357.25, 1, 361);
	script_runner:addDestination("Valormok - Aszhara", 3609.11, -4410.26, 114.02, 0, 0);
	script_runner:addDestination("Bloodhoof Village - Mulgore", -2335.72, -361.89, -8.56, 1, 215);
	script_runner:addDestination("Sun Rock Retreat - Stonetalon Mountains", 924.82, 906.05, 104.97, 0, 0);
	script_runner:addDestination("Freewind Post - Thousand Needles", -5455.99, -2451.29, 89.41, 0, 0);
	script_runner:addDestination("Gadgetzan - Tanaris", -7157.03, -3824.21, 8.55, 0, 0);
	script_runner:addDestination("Marshal's Refuge - Un'Goro Crater", -6149.63, -1082.23, -199.68, 0, 0);
	script_runner:addDestination("Cenarion Hold - Silithus", -6836.59, 745.39, 42.60, 0, 0);
	script_runner:addDestination("Light's Hope Chapel", 2282.57, -5317.24, 88.55, 0, 0);
	script_runner:addDestination("Brill - Tirisfal Glades", 2234.78, 251.79, 33.56, 0, 0);
	script_runner:addDestination("The Bulwark - Tirisfal Glades", 1709.83, -737.01, 54.28, 0, 0);
	script_runner:addDestination("The Sepulcher - Tirisfal Glades", 508.36, 1622.63, 125.54, 0, 130);
	script_runner:addDestination("Tarren Mill - Hillsbrad Foothills", -25.29, -930.49, 54.84, 0, 267);
	script_runner:addDestination("Southshore - Hillsbrad Foothills", -853.22, -533.52, 9.96, 0, 267);
	script_runner:addDestination("Hammerfall - Arathi Highlands", -934.21, -3522.75, 70.93, 0, 45);
	script_runner:addDestination("Refuge Pointe - Arathi Highlands", -1246.61, -2529.32, 20.61, 0, 45);	
	script_runner:addDestination("Kargath - Badlands", -6673.03, -2181.01, 243.78, 0, 3);
	script_runner:addDestination("Thorium Point - Searing Gorge", -6505.15, -1167.08, 308.81, 0, 51);
	script_runner:addDestination("Flame Crest - Burning Steppes", -7504.19, -2182.93, 165.81, 0, 46);
	script_runner:addDestination("Morgan's Vigil - Burning Steppes", -8361.44, -2753.10, 185.55, 0, 46);
	script_runner:addDestination("Stonard - Swamp of Sorrows", -10459.82, -3261.91, 20.18, 0, 8);
	script_runner:addDestination("Grom'gol - Stranglethorn Vale", -12388.52, 151.96, 2.63, 0, 33);
	script_runner:addDestination("Booty Bay - Stranglethorn Vale", -14448.18, 473.49, 15.21, 0, 33);
	script_runner:addDestination("Shadowprey Village - Desolace", -1616.38, 3115.15, 43.25, 1, 405);
	script_runner:addDestination("Camp Mojache - Feralas", -4431.41, 257.74, 37.48, 1, 357);
	script_runner:addDestination("The Forgotten Coast - Feralas", -4346.82, 2329.58, 8.33, 1, 357);
	script_runner:addDestination("Everlook - Winterspring", 6707.71, -4670.25, 721.39, 1, 618);
	script_runner:addDestination("Nighthaven - Moonglade", 7945.57, -2577.50, 489.92, 1, 493);
	script_runner:addDestination("Ratchet - The Barrens", -1028.38, -3669.89, 22.95, 1, 17);

	self.isSetup = true;
end

function script_runner:addDestination(name, x, y, z, continentID, mapID) 
	-- Extra table for the combo box
	self.destinationName[self.destNum] = name;

	self.destination[self.destNum] = {};
	self.destination[self.destNum]['name'] = name;
	self.destination[self.destNum]['x'] = x;
	self.destination[self.destNum]['y'] = y;
	self.destination[self.destNum]['z'] = z;
	self.destination[self.destNum]['continentID'] = continentID;
	self.destination[self.destNum]['mapID'] = mapID;
	self.destNum = self.destNum + 1;
end

local function rP(text, r, g, b)
	r = r or .91
	g = g or .91
	b = b or .91
	local header = "|cFFFC0000[|r|cFFFF7F00oGasai - Runner|r|cFFFC0000]|r "
	DEFAULT_CHAT_FRAME:AddMessage(header .. text, r, g, b)
end
     
local function GetDistance2D(_1x, _1y, _2x, _2y)
	return math.sqrt((_1x - _2x)^2 + (_1y - _2y)^2)
end

function script_runner:draw()
	-- Draw window
	script_runner:window();

	-- Draw path
	if (IsPathLoaded(5)) then
		if (self.lastnavIndex-1 <= GetPathSize(5)-1) then
			for index = self.lastnavIndex-1, GetPathSize(5) - 2 do
				local _x, _y, _z = GetPathPositionAtIndex(5, index);
				local _xx, _yy, _zz = GetPathPositionAtIndex(5, index+1);
				local _tX, _tY, onScreen = WorldToScreen(_x, _y, _z);
				local _tXX, _tYY, onScreens = WorldToScreen(_xx, _yy, _zz);
				if(onScreen and onScreens and _x ~= 0 and _xx ~= 0) then
					DrawLine(_tX, _tY, _tXX, _tYY, 255, 255, 0, 2);
				end
			end
		end
		
	end

	-- Draw destination
	_tX, _tY, onScreen = WorldToScreen(self.tx, self.ty, self.tz);
	if (onScreen and self.destination[self.nRcombo+1].name ~= nil) then
		DrawText("Destination:", _tX, _tY-10, 255, 255, 0);
		DrawText(tostring(self.destination[self.nRcombo+1].name), _tX, _tY, 255, 255, 0);
	end


	-- Draw aggro circles
	script_runner:drawAggroCircles();
end

function script_runner:run()

	-- Setup destinations
	if (not self.isSetup) then
		script_runner:setup();
		return;
	end

	if (GetTimeEX() < self.timer) then
		return;
	end

	self.timer = GetTimeEX() + self.tic;

	-- Update player coordinates
	local localObj = GetLocalPlayer();
	local my_x, my_y, my_z = localObj:GetPosition();
	local d_x, d_y, d_z = self.tx, self.ty, self.tz;

	-- Update distance to destination
	self.distDestination = GetDistance3D(my_x, my_y, my_z, self.tx, self.ty, self.tz);

	if (self.avoidAggro) then
		if (script_runner:avoidToAggro(self.safeDistance)) then 
			self.avoidTimer = GetTimeEX()+250;
			-- Generate a new navmesh path if we are avoiding mobs
			if (self.genTime < GetTimeEX()) then
				self.genTime = GetTimeEX() + 500;
				GeneratePath(my_x, my_y, my_z, d_x, d_y, d_z);
			end
			return; 
		end
	end 

	if (self.avoidTimer > GetTimeEX()) then
		return;
	end

	if (not self.runit) then
		return;
	end

	-- If the target destination has changed, generate a new path
	if(self.dx ~= self.tx or self.dy ~= self.ty or self.dz ~= self.tz) then

		-- update destination position
		self.dx, self.dy, self.dz = d_x, d_y, d_z;

		-- reset node index
		self.lastnavIndex = 1; 
		
		-- generate a new path
		GeneratePath(my_x, my_y, my_z, d_x, d_y, d_z);
	end	

	-- Return until path has been generated
	if (not IsPathLoaded(5)) then

		if (IsMoving()) then
			StopMoving();
		end
		
		if (not self.generating and self.genTimer < GetTimeEX()) then
			rP("Generating path to " .. tostring(self.destination[self.nRcombo+1].name) .. '...');
			self.generating = true;
			self.genTimer = GetTimeEX() + 4500;
		end
		
		if (GetTimeEX() > self.genTimer and self.generating) then
			self.generating = false;
			self.runit = false;
			self.dx = 0;
			ClearPath(5);
			rP("Failed to generate path to " .. tostring(self.destination[self.nRcombo+1].name) .. '...');
		end
	
		return;
	else
		self.generating = false;
	end

	-- Get the next node's position
	local _ix, _iy, _iz = GetPathPositionAtIndex(5, self.lastnavIndex);

	if(GetDistance3D(my_x, my_y, my_z, _ix, _iy, _iz) < self.nextNodeDistance) then

		-- If we are close to the next path node, increase our nav node index
		self.lastnavIndex = 1 + self.lastnavIndex;	

		-- Destination reached	
		if (GetPathSize(5) <= self.lastnavIndex and self.runit) then
			self.lastnavIndex = GetPathSize(5)-1;
			self.runit = false;
			StopMoving();
			rP("Destination " .. tostring(self.destination[self.nRcombo+1].name .. ' reached...'));
			return;
		end
	end

	-- Move to the next node in the path
	Move(_ix, _iy, _iz);
end

function script_runner:menu()
	--if (CollapsingHeader("[Runner")) then

		-- Setup destinations
		if (not self.isSetup) then
			script_runner:setup();
			return;
		end

		Separator();

		self.useNaveMesh = IsUsingNavmesh();
		
		if self.useNaveMesh then
		
			if not self.runit then
				if Button("Start running to destination") then
					self.runit = true;
					StartBot();
				end
			else
				if Button("Stop running") then
					StopMoving();
					self.runit = false;
				end
			end
		else
			Text("Please enable and load the nav mesh...");	
		end

		Separator();
		Text("Choose Destination");
		self.destinationChanged , self.nRcombo = ComboBox("", self.nRcombo, unpack(self.destinationName));
		
		-- Update destination position
		if self.destinationChanged or self.tx == 0 then
			self.tx = self.destination[self.nRcombo+1].x
			self.ty = self.destination[self.nRcombo+1].y
			self.tz = self.destination[self.nRcombo+1].z
			local x, y, z = GetLocalPlayer():GetPosition();
			self.distDestination = GetDistance3D(x, y, z, self.tx, self.ty, self.tz);
			self.status = "New destination selected...";
			rP("New destination selected " .. tostring(self.destination[self.nRcombo+1].name) .. '...');
		end

		Text("Distance to destination: " .. string.format("%.0f", self.distDestination) .. ' yards.')

		Separator()

		local wasClicked = false;
		wasClicked, self.avoidAggro = Checkbox("Avoid Aggro", self.avoidAggro);
		Text("Safe Distance to Mobs: " .. self.safeDistance);
		SameLine();
		if Button("+") then self.safeDistance = self.safeDistance + 1; end
		SameLine();
		if Button("-") then self.safeDistance = self.safeDistance - 1; end

		Separator()
	-- end
end