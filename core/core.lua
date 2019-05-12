function Cast(spellName, target)
	if (HasSpell(spellName)) then
		if (target:IsSpellInRange(spellName)) then
			if (not IsSpellOnCD(spellName)) then
				if (not IsAutoCasting(spellName)) then
					target:FaceTarget();
					target:TargetEnemy();
					return target:CastSpell(spellName);
				end
			end
		end
	end
	return false;
end

function Buff(spellName, player)
	if (IsStanding()) then
		if (HasSpell(spellName)) then
			if (not player:HasBuff(spellName)) then
				return player:CastSpell(spellName);
			end
		end
	end
	return false;
end