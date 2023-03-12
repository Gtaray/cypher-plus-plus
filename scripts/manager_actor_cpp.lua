---------------------------------------------------------------
-- NPCs
---------------------------------------------------------------
function getCreatureLevel(rCreature)
	local creatureNode = ActorManager.getCTNode(rCreature);
	if not creatureNode then
		ActorManager.getCreatureNode(rCreature);
	end

	if not creatureNode then
		return 0;
	end

	local nBase = DB.getValue(creatureNode, "level", 0);

	return nBase;
end

---------------------------------------------------------------
-- ARMOR
---------------------------------------------------------------
-- This only cares about creatures on the CT, since it's specifically for combat
function getArmorWithMods(rActor, rTarget)
	local node = ActorManager.getCTNode(rActor);
	local nBaseArmor = DB.getValue(node, "armor", 0);

	local nEffectArmor = EffectManagerCPP.getEffectsBonusByType(rActor, "ARMOR", {}, rTarget, false);

	return nBaseArmor + nEffectArmor;
end

function getMaxEffort(rActor, sStat, sRollType)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor or (sStat or "") == "" then
		return 0;
	end

	local nBase = DB.getValue(nodeActor, "effort", 0);

	local nEffectMaxEffort = EffectManagerCPP.getEffectsBonusByType(rActor, "MAXEFF", { sStat, sRollType });

	return nBase + nEffectMaxEffort;
end

function getEdge(rActor, sStat, sRollType)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor or (sStat or "") == "" then
		return 0;
	end

	local nBase = DB.getValue(nodeActor, "abilities." .. sStat .. ".edge", 0);

	local nBonus = EffectManagerCPP.getEffectsBonusByType(rActor, "EDGE", { sStat, sRollType });

	return nBase + nBonus;
end

function getArmorSpeedCost(rActor)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return 0;
	end

	local nBase = DB.getValue(nodeActor, "armorspeedcost", 0);
	local nBonus = EffectManagerCPP.getEffectsBonusByType(rActor, "COST", { "armor" });

	return nBase + nBonus;
end

---------------------------------------------------------------
-- RESIST / VULN / IMMUNE
---------------------------------------------------------------
function isImmune(rActor, rTarget, aDmgTypes)
	local tImmune = ActorManagerCPP.getImmunities(rActor, rTarget);
	local bImmune = ActorManagerCPP.resistanceCheckerHelper(tImmune, aDmgTypes);

	return bImmune;
end

function isResistant(rActor, rTarget, aDmgTypes)
	local tResist = ActorManagerCPP.getResistances(rActor, rTarget);
	local bResist, nAmount = ActorManagerCPP.resistanceCheckerHelper(tResist, aDmgTypes);
	return bResist, nAmount;
end

function isVulnerable(rActor, rTarget, aDmgTypes)
	local tVuln = ActorManagerCPP.getVulnerabilities(rActor, rTarget);
	local bVuln, nAmount = ActorManagerCPP.resistanceCheckerHelper(tVuln, aDmgTypes);
	return bVuln, nAmount;
end

function getResistances(rActor, rTarget)
	return ActorManagerCPP.getDamageMods(rActor, "RESIST", rTarget);
end

function getImmunities(rActor, rTarget)
	return ActorManagerCPP.getDamageMods(rActor, "IMMUNE", rTarget);
end

function getVulnerabilities(rActor, rTarget)
	return ActorManagerCPP.getDamageMods(rActor, "VULN", rTarget);
end

-- sFilter can be "resist", "vuln", or "immune" and it will only get those resistances
-- If it is nil, then this returns the full list
function getDamageMods(rActor, sFilter, rTarget)
	-- Only do this for CT Nodes
	local charNode = ActorManager.getCTNode(rActor);
	if not charNode then
		return nil;
	end

	local tDmgMods = {};

	-- Start by getting values from the creature node
	for _, node in ipairs(DB.getChildList(charNode, "resistances")) do
		local sType = DB.getValue(node, "type", "");
		if sType == sFilter then
			local sDamageType = DB.getValue(node, "damagetype", "");
			local nAmount = DB.getValue(node, "amount", 0);

			if DamageTypeManager.isDamageType(sDamageType) then
				tDmgMods[sDamageType] = nAmount;
			end
		end
	end

	-- Then get values from effects
	local aEffects = EffectManagerCPP.getEffectsByType(rActor, sFilter, rTarget);
	for _,v in pairs(aEffects) do
		for _,vType in pairs(v.remainder) do
			if tDmgMods[vType] then
				-- Merge the mods
				tDmgMods[vType] = tDmgMods[vType] + v.mod
			else
				tDmgMods[vType] = v.mod;	
			end
		end
	end

	return tDmgMods;
end

function resistanceCheckerHelper(tDmgMods, aDmgTypes)
	if type(aDmgTypes) == "string" then
		aDmgTypes = { aDmgTypes }
	end

	if tDmgMods["all"] then
		return true, tDmgMods["all"];
	end

	for _, sType in ipairs(aDmgTypes) do
		if tDmgMods[sType] and tDmgMods[sType] > 0 then 
			return true, tDmgMods[sType];
		end
	end

	return false, 0;
end