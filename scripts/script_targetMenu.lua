script_targetMenu = {
}

function script_targetMenu:menu()
	if (CollapsingHeader("[Target options")) then
		local wasClicked = false;
		wasCLicked, script_grind.skipHardPull = Checkbox("Blacklist target with more than 1 add", script_grind.skipHardPull);
		wasClicked, script_grindEX.avoidBlacklisted = Checkbox("Avoid blacklisted targets (buggy)", script_grindEX.avoidBlacklisted);
		Text("Search for target distance"); script_grind.pullDistance = SliderFloat("PD (yd)", 1, 150, script_grind.pullDistance); Separator();
		Text('Target level'); script_grind.minLevel = SliderInt("Min lvl", 1, 60, script_grind.minLevel); script_grind.maxLevel = SliderInt("Max lvl", 1, 60, script_grind.maxLevel); Separator();
		wasClicked, script_grind.avoidElite = Checkbox("Avoid elites", script_grind.avoidElite);
		Text("Avoid elite range"); script_grind.avoidRange = SliderInt("ER (yd)", 1, 100, script_grind.avoidRange); Separator();
		Text('Blacklist time'); script_grind.blacklistTime = SliderInt("BT (s)", 1, 120, script_grind.blacklistTime); Separator();
		Text("Skip creature type(s)");
		wasClicked, script_grind.skipElites = Checkbox("Skip elites", script_grind.skipElites);
		SameLine(); wasClicked, script_grind.skipHumanoid = Checkbox("Skip humanoids", script_grind.skipHumanoid);
		wasClicked, script_grind.skipElemental = Checkbox("Skip elementals", script_grind.skipElemental);
		SameLine(); wasClicked, script_grind.skipUndead = Checkbox("Skip undeads", script_grind.skipUndead);
		wasClicked, script_grind.skipDemon = Checkbox("Skip demons", script_grind.skipDemon);
		SameLine(); wasClicked, script_grind.skipBeast = Checkbox("Skip beasts", script_grind.skipBeast);
		wasClicked, script_grind.skipAberration = Checkbox("Skip abberations", script_grind.skipAberration);
		SameLine(); wasClicked, script_grind.skipDragonkin = Checkbox("Skip dragonkin", script_grind.skipDragonkin);
		wasClicked, script_grind.skipGiant = Checkbox("Skip giants", script_grind.skipGiant);
		SameLine(); wasClicked, script_grind.skipMechanical = Checkbox("Skip mechanicals", script_grind.skipMechanical);
	end
end