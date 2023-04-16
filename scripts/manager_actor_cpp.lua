---------------------------------------------------------------
-- NPCs
---------------------------------------------------------------
function getCreatureLevel(rCreature)
	local creatureNode = rCreature;
	if type(rCreature) ~= "databasenode" then
		creatureNode = ActorManager.getCTNode(rCreature);
		if not creatureNode then
			creatureNode = ActorManager.getCreatureNode(rCreature);
		end
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
		if sType:lower() == sFilter:lower() then
			local sDamageType = DB.getValue(node, "damagetype", ""):lower();
			local nAmount = DB.getValue(node, "amount", 0);

			-- Don't care if it's assigned or not.
			-- if DamageTypeManager.isDamageType(sDamageType) then
				
			-- end

			tDmgMods[sDamageType] = nAmount;
		end
	end

	-- Then get values from effects
	local aEffects = EffectManagerCPP.getEffectsByType(rActor, sFilter, rTarget);
	for _,v in pairs(aEffects) do
		-- If there's no type specified, then set it to all
		if #(v.remainder) == 0 then
			tDmgMods["all"] = (tDmgMods["all"] or 0) + v.mod
		end
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
		if tDmgMods[sType] and tDmgMods[sType] >= 0 then 
			return true, tDmgMods[sType];
		end
	end

	return false, 0;
end

---------------------------------------------------------------
-- EQUIPPED WEAPONS
---------------------------------------------------------------
function getEquippedWeaponNode(nodeActor)
	for _, node in ipairs(DB.getChildList(nodeActor, "attacklist")) do
		if DB.getValue(node, "equipped", 0) == 1 then
			return node;
		end
	end
end

function getEquippedWeapon(nodeActor)
	local node = ActorManagerCPP.getEquippedWeaponNode(nodeActor);
	if not node then
		return {};
	end

	local rWeapon = {};
	rWeapon.sLabel = DB.getValue(node, "name", "");
	rWeapon.sAttackRange = DB.getValue(node, "atkrange", "");
	rWeapon.sStat = RollManagerCPP.resolveStat(DB.getValue(node, "stat", ""), "might");
	rWeapon.sTraining = DB.getValue(node, "training", "");
	rWeapon.nAssets = DB.getValue(node, "asset", 0);
	rWeapon.nModifier = DB.getValue(node, "modifier", 0);

	rWeapon.nDamage = DB.getValue(node, "damage", 0);
	rWeapon.sDamageType = DB.getValue(node, "damagetype", "");
	rWeapon.sStatDamage = RollManagerCPP.resolveStat(DB.getValue(node, "statdmg", ""), "might");
	rWeapon.bPierce = DB.getValue(node, "pierce", "") == "yes";
	rWeapon.sWeaponType = DB.getValue(node, "weapontype", "");

	if rWeapon.bPierce then
		rWeapon.nPierceAmount = DB.getValue(node, "pierceamount", 0);	
	end

	return rWeapon;
end

function setEquippedWeapon(nodeActor, nodeWeapon)
	local sWeaponNode = DB.getName(nodeWeapon)
	for _, node in ipairs(DB.getChildList(nodeActor, "attacklist")) do
		-- Set every weapon other than the specified one to unequipped
		if DB.getName(node) ~= sWeaponNode then
			DB.setValue(node, "equipped", "number", 0);
		end
	end
end