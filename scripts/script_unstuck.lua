script_unstuck = {
	timer = 0,
	message = 'Unstuck...',
	pause = false,
	_lx = 0,
	_ly = 0,
	_lz = 0,
	_x = 0,
	_y = 0,
	_z = 0,
	_xp = 0,
	_yp = 0,
	_zp = 0,
	_xpl = 0,
	_ypl = 0,
	_zpl = 0,
	_xpr = 0,
	_ypr = 0,
	_zpr = 0,
	_angle = 0,
	unstuckAngle = 0,
	unstuckTime = GetTimeEX()
}

function script_unstuck:DeBugInfo()
	-- color
	local r = 255;
	local g = 2;
	local b = 233;
	
	-- position
	local y = 152;
	local x = 25;
	
	-- info
	DrawRectFilled(x - 10, y - 2, x + 350, y + 16, 0, 0, 0, 160, 10, -10);
	DrawLine(x - 10, y - 2, x - 10, y + 16, r, g, b, 2);
	DrawText(self.message, x, y, r, g, b); y = y + 15;
	
end

function script_unstuck:draw()

	script_unstuck:DeBugInfo();

	script_unstuck:drawChecks();
end

function script_unstuck:drawChecks()
	local tX, tY, onScreen = WorldToScreen(_lx, _ly, _lz);
	DrawText("Path Check", tX+50, tY-130, 255, 2, 233);

	for i = 8, 10 do

		tX, tY, onScreen = WorldToScreen(_lx, _ly, _lz+(i*0.2));
		local X, Y, onScreens = WorldToScreen(_xpl, _ypl, _zpl+(i*0.2));
	
		if (onScreen and onScreens) then
			DrawLine(tX, tY, X, Y, 255, 2, 233, 2);
		end
	end

	for i = 8, 10 do

		tX, tY, onScreen = WorldToScreen(_lx, _ly, _lz+(i*0.2));
		X, Y, onScreens = WorldToScreen(_xp, _yp, _zp+(i*0.2));
	
		if (onScreen and onScreens) then
			DrawLine(tX, tY, X, Y, 255, 2, 233, 2);
		end
	end

	for i = 8, 10 do

		tX, tY, onScreen = WorldToScreen(_lx, _ly, _lz+(i*0.2));
		local X, Y, onScreens = WorldToScreen(_xpr, _ypr, _zpr+(i*0.2));
	
		if (onScreen and onScreens) then
			DrawLine(tX, tY, X, Y, 255, 2, 233, 2);
		end
	end

	tX, tY, onScreen = WorldToScreen(_lx, _ly, _lz+0.8);
	DrawText("Jump Check", tX+50, tY, 255, 255, 0);
	for i = 4, 6 do
		
		tX, tY, onScreen = WorldToScreen(_lx, _ly, _lz+(i*0.2));
		local X, Y, onScreens = WorldToScreen(_x, _y, _z+(i*0.2));
	
		if (onScreen and onScreens) then
			DrawLine(tX, tY, X, Y, 255, 255, 0, 2);
		end
	end
end

function script_unstuck:turn(changeAngle)
	_lx, _ly, _lz = GetLocalPlayer():GetPosition();
	_angle = GetLocalPlayer():GetAngle() + changeAngle;
	self.unstuckAngle = _angle;
	FacePosition(_lx+math.cos(_angle), _ly+math.sin(_angle), _lz);
end

function script_unstuck:walkForward(yards)
	_lx, _ly, _lz = GetLocalPlayer():GetPosition();
	if (self.unstuckTime < GetTimeEX()) then
		self.unstuckTime = GetTimeEX() + 2000;
		script_nav:moveToTarget(GetLocalPlayer(), _lx+yards*math.cos(self.unstuckAngle), _ly+yards*math.sin(self.unstuckAngle), _lz);
	end
end

function script_unstuck:getSlope(yardsInfront)
	-- our pos plus 5 yards
	_lx, _ly, _lz = GetLocalPlayer():GetPosition();
	_angle = GetLocalPlayer():GetAngle();	
	_lx, _ly = _lx+5*math.cos(_angle), _ly+5*math.sin(_angle);
	
	for i = 1, 100 do	

		-- pos 1 - yardsInfront 
		for y = 1, yardsInfront do
			local _xpu, _ypu, _zpu = _lx+((5+y)*math.cos(_angle-i*0.01)), _ly+((5+y)*math.sin(_angle-i*0.01)), _lz;
			local _xpd, _ypd, _zpd = _lx+((5+y)*math.cos(_angle+i*0.01)), _ly+((5+y)*math.sin(_angle+i*0.01)), _lz;
		
			local hitDown, _, _, _ = Raycast(_lx, _ly, _lz + (i*0.2),  _xpd, _ypd, _zpd - (i*0.2));

			if(not hitDown) then
				return -(i*0.2);
			end
		end

	end

	return 0;
end

function script_unstuck:jumpObstacles()

	if ( (script_unstuck:getObsMin(1) >= 0.3 and script_unstuck:getObsMax(1) < 2.2 and script_unstuck:getObsMax(1) > 1) or 
		(script_unstuck:getObsMin(2) >= 0.3 and  script_unstuck:getObsMax(2) < 2.2 and script_unstuck:getObsMax(2) > 1) ) then
		self.message = "Jumping over obstacle";
		JumpOrAscendStart();
	end
end

function script_unstuck:unstuck()
	if (script_unstuck:pathClearAuto(1) or script_unstuck:pathClearAuto(2)) then
		script_unstuck:walkForward(2);
	end
end

function script_unstuck:pathClearAuto(yardsInfront)

	-- Jump over obstacles
	if (IsMoving()) then script_unstuck:jumpObstacles(); end

	-- our pos
	_lx, _ly, _lz = GetLocalPlayer():GetPosition();

	_angle = GetLocalPlayer():GetAngle();	
	
	for i = 1, 2 do	

		-- pos 1 - yardsInfront 
		for y = 1, yardsInfront do
			_xp, _yp, _zp = _lx+(y*math.cos(_angle)), _ly+(y*math.sin(_angle)), _lz;
			_xpl, _ypl, _zpl = _lx+(y*math.cos(_angle-i*0.16)), _ly+(y*math.sin(_angle-i*0.16)), _lz;
			_xpr, _ypr, _zpr = _lx+(y*math.cos(_angle+i*0.16)), _ly+(y*math.sin(_angle+i*0.16)), _lz;
	
			local hitM, _, _, _ = Raycast(_lx, _ly, _lz + (i*1.6),  _xp, _yp, _zp + (i*1.6));
			local hitL, _, _, _ = Raycast(_lx, _ly, _lz + (i*1.6),  _xpl, _ypl, _zpl + (i*1.6));	
			local hitR, _, _, _ = Raycast(_lx, _ly, _lz + (i*1.6),  _xpr, _ypr, _zpr + (i*1.6));

			if(not hitM and not hitL) then
				-- Path isn't clear
				self.message = "Path not clear, turning left...";
				DEFAULT_CHAT_FRAME:AddMessage('script_unstuck: Turning left.');
				script_unstuck:turn(3.14/2);
				return false;
			end

			if(not hitM and not hitR) then
				-- Path isn't clear
				self.message = "Path not clear, turning right...";
				DEFAULT_CHAT_FRAME:AddMessage('script_unstuck: Turning right.');
				script_unstuck:turn(-3.14/2);
				return false;
			end

			if(not hitL) then
				-- Path isn't clear
				self.message = "Path not clear, turning left..."
				DEFAULT_CHAT_FRAME:AddMessage('script_unstuck: Turning left.');
				script_unstuck:turn(0.5);
				return false;
			end

			if(not hitR) then
				-- Path isn't clear
				self.message = "Path not clear, turning right..."
				DEFAULT_CHAT_FRAME:AddMessage('script_unstuck: Turning right.');
				script_unstuck:turn(-0.5);
				return false;
			end
			
		end

	end
	
	return true;
end

function script_unstuck:getObsMin(yardsInfront)

	_lx, _ly, _lz = GetLocalPlayer():GetPosition();

	_angle = GetLocalPlayer():GetAngle();

	_x, _y, _z = _lx+(yardsInfront*math.cos(_angle)), _ly+(yardsInfront*math.sin(_angle)), _lz;	
	
	for i = 1, 20 do	

		local hit, _, _, _ = Raycast(_lx, _ly, _lz + (i*0.2),  _x, _y, _z + (i*0.2));
	
		local hitL, _, _, _ = Raycast(_lx, _ly, _lz + (i*0.2),  _x+(yardsInfront*math.cos(_angle-i*0.02)), _y+(yardsInfront*math.sin(_angle-i*0.02)), _z + (i*0.2));	

		local hitR, _, _, _ = Raycast(_lx, _ly, _lz + (i*0.2),  _x+(yardsInfront*math.cos(_angle+i*0.02)), _y+(yardsInfront*math.sin(_angle+i*0.02)), _z + (i*0.2));		
	
		if(not hit or not hitL or not hitR) then
			return i * 0.2;
		end

	end
	
	return 0;
end

function script_unstuck:getObsMax(yardsInfront)

	_lx, _ly, _lz = GetLocalPlayer():GetPosition();

	_angle = GetLocalPlayer():GetAngle();

	_x, _y, _z = _lx+(yardsInfront*math.cos(_angle)), _ly+(yardsInfront*math.sin(_angle)), _lz;	
	
	local zHit = 0;

	for i = 1, 20 do	

		local hit, _, _, _ = Raycast(_lx, _ly, _lz + (i*0.2),  _x, _y, _z + (i*0.2));
	
		local hitL, _, _, _ = Raycast(_lx, _ly, _lz + (i*0.2),  _x+(yardsInfront*math.cos(_angle-i*0.02)), _y+(yardsInfront*math.sin(_angle-i*0.02)), _z + (i*0.2));	

		local hitR, _, _, _ = Raycast(_lx, _ly, _lz + (i*0.2),  _x+(yardsInfront*math.cos(_angle+i*0.02)), _y+(yardsInfront*math.sin(_angle+i*0.02)), _z + (i*0.2));		
	
		if(not hit or not hitL or not hitR) then
			zHit = i * 0.2;
		end

	end
	
	return zHit;
end

function script_unstuck:run()
	local localObj = GetLocalPlayer();

	if (self.timer == 0) then
		self.timer = GetTimeEX();
	end

	if (self.timer > GetTimeEX()) then
		return;
	end

	self.timer = GetTimeEX() + 150;

	if (not IsMoving()) then
		self.message = "Try to run into walls and over small obstacles...";
	else
		self.message = "Slope Z: " .. script_unstuck:getSlope(3) .. ' | Obstacle min-Z: ' .. script_unstuck:getObsMin(2) .. ' | Obstacle max-Z: ' .. script_unstuck:getObsMax(2);
	end

	if (script_unstuck:pathClearAuto(2)) then
	else
		StopMoving();
	end
end

