script_pather = {
	timer = 0,
	message = "Left Click to test path generation...",
	nodeDist = 5,
	path = {},
	pathSize = 0,
	maxZSlope = 0.5,
	dX = 0,
	dY = 0,
	dZ = 0,
	dx = 0,
	dy = 0,
	dz = 0,
	status = 0, -- 0 idle 1 generating 2 gen new path
	goToIndex = 1;
}

function script_pather:DeBugInfo()
	DrawRectFilled(100, 100, 450, 116, 0, 0, 0, 100, 10, -10);
	DrawText(self.message, 110, 100, 255, 255, 0);
end

function script_pather:draw()

	script_pather:DeBugInfo();

	-- Draw path
	script_pather:drawPath()
end

function script_pather:drawPath()
	if (self.pathSize >= 3 and self.status == 0) then
		for i = 1, self.pathSize-2 do
			local x1, y1, ss = WorldToScreen(self.path[i]['x'], self.path[i]['y'], self.path[i]['z']);
			local x2, y2, sss = WorldToScreen(self.path[i+1]['x'], self.path[i+1]['y'], self.path[i+1]['z']);
			if (ss and sss) then
				DrawText('PN: '.. i, x1, y1, 255, 255, 0);
				DrawLine(x1, y1, x2, y2, 255, 255, 0, 2);
			end	
			if (i == self.pathSize-2 and self.pathSize > 3) then
				if (sss) then
					DrawText('PN: '.. i+1, x2, y2, 255, 255, 0)
				end
				local x3, y3, ssss = WorldToScreen(self.path[i+2]['x'], self.path[i+2]['y'], self.path[i+2]['z']);
				if (ssss) then
					DrawLine(x2, y2, x3, y3, 255, 255, 0, 2);
					DrawText('PN: '.. i+2, x3, y3, 255, 255, 0)
				end
			end		

		end
	end
end

function script_pather:floorNextZ(x, y, z, a, dist)

	-- Destination x,y
	local dx, dy = x+dist*math.cos(a), y+dist*math.sin(a);
	local roofZ = z+30;
	local floorZ = z;
	
	-- Check for roof and floor Z
	for i = 1, 10 do
		local dxx, dyy = x+i*dist/10*math.cos(a), y+i*dist/10*math.sin(a);
		local hitF, _, _, hitZF = Raycast(dxx, dyy, floorZ+1, dxx, dyy, z-30);
		local hitR, _, _, hitZR = Raycast(dxx, dyy, floorZ+1, dxx, dyy, z+30);
		if (not hitF) then
			floorZ = hitZF;
		end
		
		if (not hitR) then
			roofZ = hitZR;
		end
	end
	
	hit, _, _, hitZ = Raycast(dx, dy, roofZ-0.01, dx, dy, floorZ-30);
	if (not hit) then
		return hitZ;
	end


	return z;
end

function script_pather:floorZ(x, y, z)

	local hit, _, _, hitZ = Raycast(x, y, z+10, dx, dy, z-10);
	if (not hit) then
		return hitZ;
	end

	return z;
end

function script_pather:getNextNode(nX, nY, nZ, nA, dX, dY, dZ)

	local pathNode = {};
	pathNode['x'], pathNode['y'], pathNode['z'], pathNode['a'] = 0, 0, 0, 0;
	
	local closestDist = 9999;
	local newAngle = 0;
	local pathClear = true;

	local dist = math.min(self.nodeDist, GetDistance3D(nX, nY, nZ, dX, dY, dZ));
	
	-- angle check
	for y = 0, 64 do 

		newAngle = nA - y*(2*math.pi/64);	
		pathClear = true;

		-- Z check
		for i = 0, 10 do 

			-- Start positions 
			local mx, my, mz = nX, nY, nZ;
			mz = mz + 0.8 + i*0.24;
			local mlx, mly = mx+(0.5*math.cos(nA+3.14/2)), my+(0.5*math.sin(nA+3.14/2));
			local mrx, mry = mx+(0.5*math.cos(nA-3.14/2)), my+(0.5*math.sin(nA-3.14/2));
		
			-- End positions
			local pathNodeZ = script_pather:floorNextZ(nX, nY, nZ, newAngle, dist);
			local endZ = pathNodeZ + 0.8 + i*0.24;

			local _xpc, _ypc, _zpc = mx+self.nodeDist*math.cos(newAngle), my+self.nodeDist*math.sin(newAngle), endZ;
			local _xpl, _ypl, _zpl = mlx+self.nodeDist*math.cos(newAngle), mly+self.nodeDist*math.sin(newAngle), endZ;
			local _xpr, _ypr, _zpr = mrx+self.nodeDist*math.cos(newAngle), mry+self.nodeDist*math.sin(newAngle), endZ;

			local hitC, cX, cY, cZ = Raycast(mx, my, mz, _xpc, _ypc, _zpc);
			local hitL, lX, lY, lZ = Raycast(mlx, mly, mz, _xpl, _ypl, _zpl);	
			local hitR, rX, rY, rZ = Raycast(mrx, mry, mz, _xpr, _ypr, _zpr);

			local zDiff = math.abs(nZ-pathNodeZ);
			local zSlope = zDiff/self.nodeDist;
				
			if ((not hitC) or (not hitL) or (not hitR)) then
					pathClear = false;
			end
			
			if (i == 10 and pathClear) then
				if(zSlope < self.maxZSlope) then
					--local currNodeDist = GetDistance3D(_xpc, _ypc, pathNodeZ, dX, dY, dZ);
					currNodeDist = math.sqrt((_xpc-dX)^2+(_ypc-dY)^2);
					if (currNodeDist < closestDist) then
						closestDist = currNodeDist;
						pathNode['x'], pathNode['y'], pathNode['z'], pathNode['a'] = _xpc, _ypc, pathNodeZ, newAngle;
					end
				end
			end

		end	

	end
	
	return pathNode;
end

function script_pather:generatePath(dx, dy, dz)

	if (self.status == 1) then
		return true;
	end

	if (self.status == 2) then
		self.dX, self.dY, self.dZ = 0, 0, 0;
	end

	self.status = 1;
	pathSize = 0;
	local path = {};
	local mx, my, mz = GetLocalPlayer():GetPosition();
	local a = GetLocalPlayer():GetAngle();
	
	if (GetDistance3D(self.dX, self.dY, self.dZ, dx, dy, dz) > 2) then
		self.dX, self.dY, self.dZ = dx, dy, dz;
	else
		self.status = 0;
		return true;
	end

	local pathGen = false;

	-- first node
	path[1] = {};
	path[1] = script_pather:getNextNode(mx, my, mz, a, dx, dy, dz);
	
	if (GetDistance3D(mx, my, mz, dx, dy, dz) < self.nodeDist) then
		self.status = 0;
		self.path = path;
		self.pathSize = 1;
		self.goToIndex = 1;
		return true;
	end

	-- path all the rest nodes
	for i = 2, 50 do
		path[i] = {};
		path[i] = script_pather:getNextNode(path[i-1]['x'], path[i-1]['y'], path[i-1]['z'], path[i-1]['a'], dx, dy, dz);
		self.pathSize = i;

		-- Couldn't find the next path node
		if (path[i]['x'] == 0) then
			self.status = 0;
			pathGen = false;
			break;
		end

		-- Reached the destination
		if (GetDistance3D(path[i]['x'], path[i]['y'], path[i]['z'], dx, dy, dz) < self.nodeDist or i == 50) then
			self.status = 0;
			pathGen = true;
			break;
		end	

	end

	-- last node
	pathSize = self.pathSize+1;
	path[pathSize] = {};
	path[pathSize]['x'], path[pathSize]['y'], path[pathSize]['z'] = dx, dy, dz;
		
	self.status = 0;

	if (pathGen) then
		self.path = path;
		self.pathSize = pathSize;
		self.goToIndex = 1;
	else
		self.path = {};
		self.pathSize = 0;
	end

	return pathGen;
end

function script_pather:moveToTarget(x, y, z)

	if (not script_pather:generatePath(x, y, z)) then
		return false;
	end

	if (self.status == 1) then
		return true;
	end

	if (self.pathSize == 0) then
		return true;
	end
	
	local x, y, z = GetLocalPlayer():GetPosition();	

	-- If are far away from the go to node, generate a new path
	if (GetDistance3D(x, y, z, self.path[self.goToIndex]['x'], self.path[self.goToIndex]['y'], self.path[self.goToIndex]['z']) > self.nodeDist*3) then
		self.message = 'Generating a new path';
		self.status = 2;
		script_pather:generatePath(self.dX, self.dY, self.dZ);
		return;
	end

	-- If we are at destination
	if (GetDistance3D(x, y, z, self.path[self.pathSize]['x'], self.path[self.pathSize]['y'], self.path[self.pathSize]['z']) < 2) then
		if (IsMoving()) then
			self.path = {};
			self.pathSize = 0;
			self.message = 'Destination reached...';
			StopMoving();
		end
		return;
	end

	-- Increase go to index
	if (self.pathSize > self.goToIndex) then
		if (GetDistance3D(x, y, z, self.path[self.goToIndex]['x'], self.path[self.goToIndex]['y'], self.path[self.goToIndex]['z']) < math.min(self.nodeDist/2, 2)) then
			self.goToIndex = self.goToIndex + 1;
			self.message = 'Moving to path node ' .. self.goToIndex;
		end
	end

	Move(self.path[self.goToIndex]['x'], self.path[self.goToIndex]['y'], self.path[self.goToIndex]['z']);
end

function script_pather:run()
	local localObj = GetLocalPlayer();

	if (self.timer == 0) then
		self.timer = GetTimeEX();
	end

	if (self.timer > GetTimeEX()) then
		return;
	end

	self.timer = GetTimeEX() + 250;

	local x, y, z = GetLocalPlayer():GetPosition();
	local a = GetLocalPlayer():GetAngle();

	self.dx, self.dy, self.dz = GetTerrainClick();

	script_pather:moveToTarget(self.dx, self.dy, self.dz);
end