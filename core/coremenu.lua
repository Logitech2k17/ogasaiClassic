coremenu = {
	--Setup
	isSetup = false,
}

function coremenu:reload()
	self.isSetup = false;
	coremenu:draw();
end

function coremenu:draw()

	if (self.isSetup == false) then
		
		self.isSetup = true;
		
		DEFAULT_CHAT_FRAME:AddMessage('Loading Scripts!');
		
		--[[
			----------------------------
			Core Files
			----------------------------
		]]--
		
		include("core\\core.lua");	
        
		-- Load DBs
		include("scripts\\db\\vendorDB.lua");
		include("scripts\\db\\hotspotDB.lua");


		--[[
			----------------------------
			Class Rotations
			----------------------------
		]]--
		
		LoadScript("Frostbite - Mage", "scripts\\combat\\script_mage_frostbite.lua");
		AddScriptToCombat("Frostbite - Mage", "script_mage");

		LoadScript("Hidden - Rogue", "scripts\\combat\\script_rogue_hidden.lua");
		AddScriptToCombat("Hidden - Rogue", "script_rogue");
		
		LoadScript("Beastmaster - Hunter", "scripts\\combat\\script_hunter_beastmaster.lua");
		AddScriptToCombat("Beastmaster - Hunter", "script_hunter");
		
		LoadScript("Shadowmaster - Warlock", "scripts\\combat\\script_warlock_shadowmaster.lua");
		AddScriptToCombat("Shadowmaster - Warlock", "script_warlock");

		LoadScript("Fury - Warrior", "scripts\\combat\\script_warrior_fury.lua");
		AddScriptToCombat("Fury - Warrior", "script_warrior");

		LoadScript("Ret - Paladin", "scripts\\combat\\script_paladin_ret.lua");
		AddScriptToCombat("Ret - Paladin", "script_paladin");

		LoadScript("Disc - Priest", "scripts\\combat\\script_priest_disc.lua");
		AddScriptToCombat("Disc - Priest", "script_priest");

		LoadScript("Enhance - Shaman", "scripts\\combat\\script_shaman_enhance.lua");
		AddScriptToCombat("Enhance - Shaman", "script_shaman");

		LoadScript("Feral - Druid", "scripts\\combat\\script_druid_feral.lua");
		AddScriptToCombat("Feral - Druid", "script_druid");

		--[[
			----------------------------
			Bot Types
			----------------------------
		]]--
	
		LoadScript("Logitech's Grinder", "scripts\\script_grind.lua");
		AddScriptToMode("Logitech's Grinder", "script_grind");

		LoadScript("Logitech's Follower", "scripts\\script_follow.lua");
		AddScriptToMode("Logitech's Follower", "script_follow");

		LoadScript("Logitech's Rotation", "scripts\\script_rotation.lua");
		AddScriptToMode("Logitech's Rotation", "script_rotation");

		LoadScript("Fishing", "scripts\\script_fish.lua");
		AddScriptToMode("Fishing", "script_fish");

		-- Nav Mesh Runner by Rot, Improved by Logitech
		LoadScript("Runner", "scripts\\script_runner.lua");
		AddScriptToMode("Runner", "script_runner");

		--LoadScript("Unstuck Test", "scripts\\script_unstuck.lua");
		--AddScriptToMode("Unstuck Test", "script_unstuck");

		--LoadScript("Pather", "scripts\\script_pather.lua");
		--AddScriptToMode("Pather Debug", "script_pather");
		
		--[[
			----------------------------
			Override Settings
			----------------------------
		]]--
	
		DrawPath(true);
		
		--NewTheme(false);
		
	end

	--[[
		----------------------------
		Append To Menu
		----------------------------
	]]--

	-- Grind 
	Separator();
	if (CollapsingHeader("[Grind options")) then
		script_grindMenu:menu();
	end

	if (CollapsingHeader("[Follower options")) then
		script_followEX:menu();
	end

	if (CollapsingHeader("[Fishing options")) then
		script_fish:menu();
	end
	
	Separator();

	-- Add Combat scripts menus
	if (CollapsingHeader("[Combat options")) then
		script_mage:menu();
		script_hunter:menu();
		script_warlock:menu();
		script_paladin:menu();
		script_druid:menu();
		script_priest:menu();
		script_warrior:menu();
		script_rogue:menu();
		script_shaman:menu();
	end
	
end